import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Silent STT using [AudioRecorder] → Groq Whisper transcription.
/// No system beeps. Silence-based auto-stop. Random API key rotation.
class SpeechService {
  final AudioRecorder _recorder = AudioRecorder();
  static final Random _rng = Random();

  Function(String)? onStatus;
  Function(String)? onError;
  Function(String, bool)? onResult;

  bool listening = false;
  bool _available = false;
  bool _starting = false;
  bool _stopping = false;
  bool _transcribing = false;

  String _apiKeyOverride = '';
  String _transcriptionModelOverride = '';
  String _transcriptionUrlOverride = '';
  String _transcriptionLanguageOverride = '';

  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _silenceTimer;
  Timer? _maxDurationTimer;
  DateTime? _lastVoiceAt;
  DateTime? _startAt;
  String? _currentPath;
  bool _hadVoiceSignal = false;

  // ── Timing constants ───────────────────────────────────────────────────────
  static const Duration _maxListenDuration = Duration(seconds: 14);
  static const Duration _silenceStopAfter = Duration(milliseconds: 1500);
  static const Duration _minListenBeforeSilenceCheck =
      Duration(milliseconds: 500);
  static const Duration _noSpeechAbortAfter = Duration(seconds: 3);
  static const double _voiceThresholdDb = -40.0;
  static const Duration _transcriptionTimeout = Duration(seconds: 8);
  static const int _minUsefulAudioBytes = 1024;

  // ── Best free / reliable Whisper model on Groq ─────────────────────────────
  static const String _defaultModel = 'whisper-large-v3-turbo';
  static const String _defaultUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  // ── Key resolution: picks a random key from all comma-separated keys ───────
  List<String> get _allKeys {
    final combined = [
      ...(_apiKeyOverride.trim().split(',').map((k) => k.trim())),
      ...(dotenv.env['API_KEY'] ?? '').split(',').map((k) => k.trim()),
      ...(dotenv.env['GROQ_API_KEY_VOICE'] ?? '')
          .split(',')
          .map((k) => k.trim()),
    ].where((k) => k.isNotEmpty).toList();
    return combined;
  }

  String get _effectiveModel {
    final m = _transcriptionModelOverride.trim();
    return m.isNotEmpty ? m : _defaultModel;
  }

  String get _effectiveUrl {
    final u = _transcriptionUrlOverride.trim();
    return u.isNotEmpty ? u : _defaultUrl;
  }

  String get _effectiveLang {
    final l = _transcriptionLanguageOverride.trim();
    return l.isNotEmpty ? l : 'en';
  }

  void configure({
    String? apiKeyOverride,
    String? transcriptionModelOverride,
    String? transcriptionUrlOverride,
    String? transcriptionLanguageOverride,
  }) {
    if (apiKeyOverride != null) _apiKeyOverride = apiKeyOverride;
    if (transcriptionModelOverride != null) {
      _transcriptionModelOverride = transcriptionModelOverride;
    }
    if (transcriptionUrlOverride != null) {
      _transcriptionUrlOverride = transcriptionUrlOverride;
    }
    if (transcriptionLanguageOverride != null) {
      _transcriptionLanguageOverride = transcriptionLanguageOverride;
    }
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

    try {
      final dir = await getTemporaryDirectory();
      if (!await dir.exists()) {
        _starting = false;
        if (onError != null) onError!('temp_dir_unavailable');
        return false;
      }

      final ts = DateTime.now().millisecondsSinceEpoch;
      final m4aPath = '${dir.path}${Platform.pathSeparator}stt_$ts.m4a';
      final wavPath = '${dir.path}${Platform.pathSeparator}stt_$ts.wav';
      var activePath = m4aPath;

      // Try AAC first (smaller), fall back to WAV.
      try {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 64000,
            echoCancel: true,
            noiseSuppress: true,
          ),
          path: m4aPath,
        );
      } catch (_) {
        activePath = wavPath;
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 96000,
            echoCancel: true,
            noiseSuppress: true,
          ),
          path: wavPath,
        );
      }

      _currentPath = activePath;
      listening = true;
      _starting = false;
      _startAt = DateTime.now();
      _lastVoiceAt = _startAt;
      _hadVoiceSignal = false;
      if (onStatus != null) onStatus!('listening');

      // Amplitude-based voice-activity detection.
      _amplitudeSub?.cancel();
      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amp) {
        if (amp.current > _voiceThresholdDb) {
          _hadVoiceSignal = true;
          _lastVoiceAt = DateTime.now();
        }
      });

      // Silence / no-speech auto-stop loop.
      _silenceTimer?.cancel();
      _silenceTimer =
          Timer.periodic(const Duration(milliseconds: 180), (timer) async {
        if (!listening || _stopping) return;
        final startedAt = _startAt ?? DateTime.now();
        final now = DateTime.now();
        final elapsed = now.difference(startedAt);
        if (elapsed < _minListenBeforeSilenceCheck) return;
        if (!_hadVoiceSignal && elapsed >= _noSpeechAbortAfter) {
          await stopListening();
          return;
        }
        final lastVoice = _lastVoiceAt ?? startedAt;
        if (now.difference(lastVoice) >= _silenceStopAfter) {
          await stopListening();
        }
      });

      // Hard max-duration guard.
      _maxDurationTimer?.cancel();
      _maxDurationTimer = Timer(_maxListenDuration, () async {
        if (listening && !_stopping) await stopListening();
      });

      return true;
    } catch (e) {
      listening = false;
      _starting = false;
      if (onError != null) onError!('record_start_failed: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!listening || _stopping) return;
    _stopping = true;

    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      debugPrint('Record stop error: $e');
      if (onError != null) onError!('record_stop_failed: $e');
    }

    listening = false;
    _stopping = false;
    _starting = false;
    if (onStatus != null) onStatus!('done');

    final targetPath = path ?? _currentPath;
    _currentPath = null;
    _startAt = null;
    _lastVoiceAt = null;
    final hadVoiceSignal = _hadVoiceSignal;
    _hadVoiceSignal = false;

    if (targetPath == null || targetPath.isEmpty) {
      if (onResult != null) onResult!('', true);
      return;
    }

    // Check file size — amplitude can be unreliable on some devices/encoders.
    var fileLength = 0;
    try {
      final f = File(targetPath);
      if (await f.exists()) fileLength = await f.length();
    } catch (_) {}

    final skipTranscription =
        !hadVoiceSignal && fileLength < (_minUsefulAudioBytes * 2);

    if (skipTranscription) {
      if (onResult != null) onResult!('', true);
      _deleteFile(targetPath);
      return;
    }

    String text = '';
    if (_transcribing) {
      if (onError != null) onError!('transcription_busy');
    } else {
      _transcribing = true;
      try {
        text = await _transcribeFile(targetPath);
      } finally {
        _transcribing = false;
      }
    }
    if (onResult != null) onResult!(text, true);
    _deleteFile(targetPath);
  }

  Future<void> cancel() async {
    final pendingPath = _currentPath;
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    try {
      if (listening) await _recorder.stop();
    } catch (_) {}

    listening = false;
    _starting = false;
    _stopping = false;
    _currentPath = null;
    _startAt = null;
    _lastVoiceAt = null;
    _hadVoiceSignal = false;

    if (pendingPath != null) _deleteFile(pendingPath);
    if (onStatus != null) onStatus!('notListening');
  }

  Future<bool> recover() async {
    await cancel();
    await init();
    return _available;
  }

  // ── Transcription ──────────────────────────────────────────────────────────

  Future<String> _transcribeFile(String path) async {
    final keys = _allKeys;
    if (keys.isEmpty) {
      debugPrint('STT: No API key available for transcription');
      if (onError != null) onError!('stt_no_api_key');
      return '';
    }

    final file = File(path);
    if (!await file.exists()) {
      debugPrint('STT: Audio file not found: $path');
      return '';
    }
    final fileLength = await file.length();
    if (fileLength < _minUsefulAudioBytes) {
      debugPrint('STT: Audio file too small ($fileLength bytes), skipping');
      return '';
    }

    // Start at a random key index for load distribution, then rotate on failure.
    final startIdx = _rng.nextInt(keys.length);
    String lastError = '';

    for (int attempt = 0; attempt < keys.length; attempt++) {
      final key = keys[(startIdx + attempt) % keys.length];
      try {
        final uri = Uri.parse(_effectiveUrl);
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer $key';
        request.fields['model'] = _effectiveModel;
        request.fields['language'] = _effectiveLang;
        request.files.add(await http.MultipartFile.fromPath('file', path));

        final streamed = await request.send().timeout(_transcriptionTimeout);
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode == 429 || response.statusCode == 401) {
          // Rate-limited or invalid key — try next key.
          lastError = 'key_${attempt + 1}_${response.statusCode}';
          debugPrint(
              'STT: Key ${attempt + 1}/${keys.length} failed (${response.statusCode}), trying next...');
          continue;
        }

        if (response.statusCode != 200) {
          lastError = 'http_${response.statusCode}';
          debugPrint('STT: Transcription error ${response.statusCode}');
          continue;
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['text'] ?? '').toString().trim();
      } on TimeoutException {
        lastError = 'timeout_key_${attempt + 1}';
        debugPrint(
            'STT: Key ${attempt + 1}/${keys.length} timed out, trying next...');
        continue;
      } catch (e) {
        lastError = 'exception_key_${attempt + 1}';
        debugPrint('STT: Key ${attempt + 1}/${keys.length} exception: $e');
        continue;
      }
    }

    // All keys exhausted.
    debugPrint('STT: All ${keys.length} key(s) failed. Last error: $lastError');
    if (onError != null) onError!('stt_all_keys_failed: $lastError');
    return '';
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
