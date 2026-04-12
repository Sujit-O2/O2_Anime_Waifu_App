import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';

/// Gladia streaming STT service.
///
/// Flow:
///   1. POST /v2/live  →  get WebSocket URL
///   2. Open WebSocket →  stream raw audio chunks
///   3. Receive partial + final transcripts
///
/// Multi-key rotation for load-balancing / rate-limit resilience.
class GladiaSttService {
  final AudioRecorder _recorder = AudioRecorder();
  static final Random _rng = Random();

  Function(String)? onStatus;
  Function(String)? onError;
  Function(String, bool)? onResult;

  bool listening = false;
  bool _available = false;
  bool _starting = false;
  bool _stopping = false;

  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  Timer? _maxDurationTimer;
  Timer? _silenceTimer;
  String? _currentPath;
  DateTime? _startAt;
  DateTime? _lastTranscriptAt;

  // Accumulated transcript from partials
  String _accumulatedText = '';

  static const Duration _maxListenDuration = Duration(seconds: 50);
  static const Duration _silenceStopAfter = Duration(milliseconds: 2000);
  static const String _gladiaLiveUrl = 'https://api.gladia.io/v2/live';

  /// Returns all Gladia API keys from .env (comma-separated).
  List<String> get _allKeys {
    final raw = dotenv.env['GladiaSTT'] ?? '';
    return raw.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
  }

  Future<void> init() async {
    _available = await _recorder.hasPermission();
  }

  Future<bool> startListening() async {
    if (listening || _starting || _stopping) return false;

    _starting = true;
    if (!_available) await init();
    if (!_available) {
      _starting = false;
      if (onError != null) onError!('record_permission_denied');
      return false;
    }

    final keys = _allKeys;
    if (keys.isEmpty) {
      _starting = false;
      if (onError != null) onError!('gladia_no_api_key');
      return false;
    }

    // Try each key until one works
    final startIdx = _rng.nextInt(keys.length);
    String? wsUrl;

    for (int attempt = 0; attempt < keys.length; attempt++) {
      final key = keys[(startIdx + attempt) % keys.length];
      wsUrl = await _initSession(key);
      if (wsUrl != null) break;
    }

    if (wsUrl == null) {
      _starting = false;
      if (onError != null) onError!('gladia_session_init_failed');
      return false;
    }

    try {
      // Connect WebSocket
      _ws = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _ws!.ready;

      // Start recording PCM audio to stream
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final wavPath = '${dir.path}${Platform.pathSeparator}gladia_$ts.wav';
      _currentPath = wavPath;

      // Record as WAV 16kHz mono for streaming
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: wavPath,
      );

      listening = true;
      _starting = false;
      _startAt = DateTime.now();
      _lastTranscriptAt = DateTime.now();
      _accumulatedText = '';
      if (onStatus != null) onStatus!('listening');

      // Listen for WebSocket messages
      _wsSub = _ws!.stream.listen(
        _handleWsMessage,
        onError: (error) {
          debugPrint('[GladiaSTT] WebSocket error: $error');
          if (onError != null) onError!('gladia_ws_error: $error');
        },
        onDone: () {
          debugPrint('[GladiaSTT] WebSocket closed');
          if (listening) {
            // Server closed the connection — finalize
            _finalizeTranscription();
          }
        },
        cancelOnError: false,
      );

      // Stream audio chunks to WebSocket every 250ms
      _startAudioStreaming(wavPath);

      // Silence auto-stop: if no transcripts received for a while
      _silenceTimer?.cancel();
      _silenceTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!listening || _stopping) return;
        final now = DateTime.now();
        final lastActivity = _lastTranscriptAt ?? _startAt ?? now;
        if (now.difference(lastActivity) >= _silenceStopAfter) {
          stopListening();
        }
      });

      // Hard max-duration guard
      _maxDurationTimer?.cancel();
      _maxDurationTimer = Timer(_maxListenDuration, () {
        if (listening && !_stopping) stopListening();
      });

      return true;
    } catch (e) {
      debugPrint('[GladiaSTT] Start error: $e');
      listening = false;
      _starting = false;
      if (onError != null) onError!('gladia_start_failed: $e');
      return false;
    }
  }

  /// Initialise a Gladia live session and return the WebSocket URL.
  Future<String?> _initSession(String apiKey) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(_gladiaLiveUrl));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('x-gladia-key', apiKey);
      request.write(jsonEncode({
        'encoding': 'wav/pcm',
        'sample_rate': 16000,
        'bit_depth': 16,
        'channels': 1,
        'model': 'fast',
        'language_config': {
          'languages': ['en'],
        },
      }));

      final response = await request.close().timeout(const Duration(seconds: 8));
      final body = await response.transform(utf8.decoder).join();
      client.close(force: false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final url = json['url'] as String?;
        if (url != null && url.isNotEmpty) {
          debugPrint('[GladiaSTT] Session created, WebSocket URL obtained');
          return url;
        }
      }

      debugPrint('[GladiaSTT] Session init failed: ${response.statusCode} $body');
      return null;
    } on TimeoutException {
      debugPrint('[GladiaSTT] Session init timed out');
      return null;
    } catch (e) {
      debugPrint('[GladiaSTT] Session init error: $e');
      return null;
    }
  }

  /// Periodically reads the growing WAV file and streams new bytes to WebSocket.
  void _startAudioStreaming(String wavPath) {
    // We'll read audio data from the file periodically and send chunks.
    // WAV header is 44 bytes — we skip it on first read.
    int bytesSent = 44; // Skip WAV header

    Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      if (!listening || _stopping || _ws == null) {
        timer.cancel();
        return;
      }

      try {
        final file = File(wavPath);
        if (!await file.exists()) return;

        final length = await file.length();
        if (length <= bytesSent) return; // No new data

        // Read new chunk
        final raf = await file.open(mode: FileMode.read);
        await raf.setPosition(bytesSent);
        final newBytes = await raf.read(length - bytesSent);
        await raf.close();

        if (newBytes.isNotEmpty) {
          // Send as base64 JSON message
          _ws?.sink.add(jsonEncode({
            'type': 'audio_chunk',
            'data': {
              'chunk': base64Encode(newBytes),
            },
          }));
          bytesSent = length;
        }
      } catch (e) {
        // File might be locked by recorder — just retry next cycle
      }
    });
  }

  void _handleWsMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      if (type == 'transcript') {
        final transcription = data['data'] as Map<String, dynamic>? ?? {};
        final isFinal = transcription['is_final'] as bool? ?? false;
        
        String text = '';
        final utterance = transcription['utterance'];
        if (utterance is String) {
          text = utterance;
        } else if (utterance is Map) {
          text = utterance['text']?.toString() ?? '';
        } else {
          text = transcription['transcript']?.toString() ?? '';
        }
        text = text.trim();

        if (text.isNotEmpty) {
          _lastTranscriptAt = DateTime.now();

          if (isFinal) {
            if (_accumulatedText.isNotEmpty) {
              _accumulatedText += ' $text';
            } else {
              _accumulatedText = text;
            }
            // Emit partial update with accumulated text
            if (onResult != null) onResult!(_accumulatedText.trim(), false);
          } else {
            // Partial — show accumulated + current partial
            final display = _accumulatedText.isNotEmpty
                ? '${_accumulatedText.trim()} $text'
                : text;
            if (onResult != null) onResult!(display.trim(), false);
          }
        }
      } else if (type == 'error') {
        final errorMsg = data['data']?['message'] ?? data['message'] ?? 'Unknown error';
        debugPrint('[GladiaSTT] Server error: $errorMsg');
        if (onError != null) onError!('gladia_server_error: $errorMsg');
      }
    } catch (e) {
      debugPrint('[GladiaSTT] Parse error: $e');
    }
  }

  Future<void> stopListening() async {
    if (!listening || _stopping) return;
    _stopping = true;

    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();

    // Send stop signal
    try {
      _ws?.sink.add(jsonEncode({'type': 'stop_recording'}));
      // Give server a moment to send final transcript
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {}

    // Stop recording
    try {
      await _recorder.stop();
    } catch (e) {
      debugPrint('[GladiaSTT] Recorder stop error: $e');
    }

    _finalizeTranscription();
  }

  void _finalizeTranscription() {
    listening = false;
    _stopping = false;
    _starting = false;
    if (onStatus != null) onStatus!('done');

    // Close WebSocket
    _wsSub?.cancel();
    _wsSub = null;
    try {
      _ws?.sink.close();
    } catch (_) {}
    _ws = null;

    // Emit final result
    final finalText = _accumulatedText.trim();
    if (onResult != null) onResult!(finalText, true);
    _accumulatedText = '';

    // Cleanup temp file
    if (_currentPath != null) {
      _deleteFile(_currentPath!);
      _currentPath = null;
    }
    _startAt = null;
    _lastTranscriptAt = null;
  }

  Future<void> cancel() async {
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    _wsSub?.cancel();
    _wsSub = null;

    try {
      _ws?.sink.close();
    } catch (_) {}
    _ws = null;

    try {
      if (listening) await _recorder.stop();
    } catch (_) {}

    listening = false;
    _starting = false;
    _stopping = false;
    _accumulatedText = '';

    if (_currentPath != null) {
      _deleteFile(_currentPath!);
      _currentPath = null;
    }
    _startAt = null;
    _lastTranscriptAt = null;

    if (onStatus != null) onStatus!('notListening');
  }

  Future<bool> recover() async {
    await cancel();
    await init();
    return _available;
  }

  void _deleteFile(String path) {
    () async {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }();
  }
}


