import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SpeechService {
  final AudioRecorder _recorder = AudioRecorder();

  Function(String)? onStatus;
  Function(String)? onError;
  Function(String, bool)? onResult;

  bool listening = false;
  bool _available = false;
  bool _starting = false;
  bool _stopping = false;
  bool _transcribing = false;

  String _apiKeyOverride = "";
  String _transcriptionModelOverride = "";
  String _transcriptionUrlOverride = "";

  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _silenceTimer;
  Timer? _maxDurationTimer;
  DateTime? _lastVoiceAt;
  DateTime? _startAt;
  String? _currentPath;

  static const Duration _maxListenDuration = Duration(seconds: 20);
  static const Duration _silenceStopAfter = Duration(seconds: 2);
  static const Duration _minListenBeforeSilenceCheck =
      Duration(milliseconds: 900);
  static const double _voiceThresholdDb = -38.0;
  static const Duration _transcriptionTimeout = Duration(seconds: 25);
  static const int _minUsefulAudioBytes = 2048;

  String get _effectiveApiKey {
    if (_apiKeyOverride.trim().isNotEmpty) return _apiKeyOverride.trim();
    return dotenv.env['API_KEY'] ?? "";
  }

  String get _effectiveTranscriptionModel {
    if (_transcriptionModelOverride.trim().isNotEmpty) {
      return _transcriptionModelOverride.trim();
    }
    return "whisper-large-v3-turbo";
  }

  String get _effectiveTranscriptionUrl {
    if (_transcriptionUrlOverride.trim().isNotEmpty) {
      return _transcriptionUrlOverride.trim();
    }
    return "https://api.groq.com/openai/v1/audio/transcriptions";
  }

  void configure({
    String? apiKeyOverride,
    String? transcriptionModelOverride,
    String? transcriptionUrlOverride,
  }) {
    if (apiKeyOverride != null) _apiKeyOverride = apiKeyOverride;
    if (transcriptionModelOverride != null) {
      _transcriptionModelOverride = transcriptionModelOverride;
    }
    if (transcriptionUrlOverride != null) {
      _transcriptionUrlOverride = transcriptionUrlOverride;
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
      if (onError != null) onError!("record_permission_denied");
      return false;
    }

    try {
      final dir = await getTemporaryDirectory();
      if (!await dir.exists()) {
        _starting = false;
        if (onError != null) onError!("temp_dir_unavailable");
        return false;
      }

      final fileName = "stt_${DateTime.now().millisecondsSinceEpoch}.wav";
      final filePath = "${dir.path}${Platform.pathSeparator}$fileName";
      _currentPath = filePath;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 96000,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: filePath,
      );

      listening = true;
      _starting = false;
      _startAt = DateTime.now();
      _lastVoiceAt = _startAt;
      if (onStatus != null) onStatus!("listening");

      _amplitudeSub?.cancel();
      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen((amp) {
        if (amp.current > _voiceThresholdDb) {
          _lastVoiceAt = DateTime.now();
        }
      });

      _silenceTimer?.cancel();
      _silenceTimer =
          Timer.periodic(const Duration(milliseconds: 250), (timer) async {
        if (!listening || _stopping) return;
        final startedAt = _startAt ?? DateTime.now();
        if (DateTime.now().difference(startedAt) <
            _minListenBeforeSilenceCheck) {
          return;
        }
        final lastVoice = _lastVoiceAt ?? startedAt;
        if (DateTime.now().difference(lastVoice) >= _silenceStopAfter) {
          await stopListening();
        }
      });

      _maxDurationTimer?.cancel();
      _maxDurationTimer = Timer(_maxListenDuration, () async {
        if (listening && !_stopping) {
          await stopListening();
        }
      });

      return true;
    } catch (e) {
      listening = false;
      _starting = false;
      if (onError != null) onError!("record_start_failed: $e");
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
      debugPrint("Record stop error: $e");
      if (onError != null) onError!("record_stop_failed: $e");
    }

    listening = false;
    _stopping = false;
    _starting = false;
    if (onStatus != null) onStatus!("done");

    final targetPath = path ?? _currentPath;
    _currentPath = null;
    _startAt = null;
    _lastVoiceAt = null;

    if (targetPath == null || targetPath.isEmpty) {
      if (onResult != null) onResult!("", true);
      return;
    }

    String text = "";
    if (_transcribing) {
      if (onError != null) onError!("transcription_busy");
    } else {
      _transcribing = true;
      try {
        text = await _transcribeFile(targetPath);
      } finally {
        _transcribing = false;
      }
    }
    if (onResult != null) onResult!(text, true);

    // Robust cleanup with multiple attempts
    try {
      final f = File(targetPath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e) {
      debugPrint("File cleanup error: $e");
    }
  }

  Future<void> cancel() async {
    final pendingPath = _currentPath;
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    try {
      if (listening) {
        await _recorder.stop();
      }
    } catch (_) {}
    listening = false;
    _starting = false;
    _stopping = false;
    _currentPath = null;
    _startAt = null;
    _lastVoiceAt = null;
    if (pendingPath != null) {
      try {
        final f = File(pendingPath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
    if (onStatus != null) onStatus!("notListening");
  }

  Future<bool> recover() async {
    await cancel();
    await init();
    return _available;
  }

  Future<String> _transcribeFile(String path) async {
    final key = _effectiveApiKey;
    if (key.isEmpty) {
      debugPrint("API_KEY missing for transcription");
      if (onError != null) onError!("API_KEY missing for transcription");
      return "";
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint("Audio file not found: $path");
        return "";
      }

      final fileLength = await file.length();
      if (fileLength < _minUsefulAudioBytes) {
        debugPrint("Audio file too small: $fileLength bytes");
        return "";
      }

      final uri = Uri.parse(_effectiveTranscriptionUrl);
      final request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] = "Bearer $key";
      request.fields["model"] = _effectiveTranscriptionModel;
      request.files.add(await http.MultipartFile.fromPath("file", path));

      final streamed = await request.send().timeout(_transcriptionTimeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        debugPrint("Transcription API error: ${response.statusCode} - ${response.body}");
        if (onError != null) {
          onError!("transcription_failed: ${response.statusCode}");
        }
        return "";
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (json["text"] ?? "").toString().trim();
      return text;
    } on TimeoutException catch (_) {
      debugPrint("Transcription request timeout");
      if (onError != null) onError!("transcription_timeout");
      return "";
    } catch (e) {
      debugPrint("Transcription error: $e");
      if (onError != null) onError!("transcription_exception: $e");
      return "";
    }
  }
}
