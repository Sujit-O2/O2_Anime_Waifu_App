import 'dart:async';
import 'dart:convert';
// ignore: file_names
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class TtsService {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  VoidCallback? onStart;
  VoidCallback? onComplete;

  String _apiKeyOverride = "";
  String _voiceOverride = "";
  String _modelOverride = "";
  int _sessionCounter = 0;
  int _activeSessionId = 0;
  int _playerSessionId = 0;
  int _fallbackSessionId = 0;
  Timer? _completionGuard;
  bool _fallbackVoiceConfigured = false;
  String _fallbackVoiceSignature = "";

  static const Duration _ttsRequestTimeout = Duration(seconds: 18);

  String get _effectiveApiKey {
    if (_apiKeyOverride.trim().isNotEmpty) return _apiKeyOverride.trim();
    final voiceKey = dotenv.env['GROQ_API_KEY_VOICE'] ?? "";
    final mainKeys = dotenv.env['API_KEY'] ?? "";

    // Merge all keys into one string
    if (voiceKey.isNotEmpty && mainKeys.isNotEmpty) {
      return "$voiceKey,$mainKeys";
    }
    return voiceKey.isNotEmpty ? voiceKey : mainKeys;
  }

  String get _effectiveVoice {
    if (_voiceOverride.trim().isNotEmpty) return _voiceOverride.trim();
    return "aisha";
  }

  String get _effectiveModel {
    if (_modelOverride.trim().isNotEmpty) return _modelOverride.trim();
    return "canopylabs/orpheus-arabic-saudi";
  }

  void configure({
    String? apiKeyOverride,
    String? modelOverride,
    String? voiceOverride,
  }) {
    if (apiKeyOverride != null) _apiKeyOverride = apiKeyOverride;
    if (modelOverride != null) _modelOverride = modelOverride;
    if (voiceOverride != null) _voiceOverride = voiceOverride;
  }

  TtsService() {
    _player.onPlayerComplete.listen((_) {
      _notifyComplete(_playerSessionId);
    });

    _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setCompletionHandler(() {
      _notifyComplete(_fallbackSessionId);
    });
    _flutterTts.setErrorHandler((_) {
      _notifyComplete(_fallbackSessionId);
    });
  }

  void _notifyComplete(int sessionId) {
    if (sessionId == 0 || sessionId != _activeSessionId) return;
    _completionGuard?.cancel();
    _completionGuard = null;
    _activeSessionId = 0;
    _playerSessionId = 0;
    _fallbackSessionId = 0;
    onComplete?.call();
  }

  void _startCompletionGuard(int sessionId, String text) {
    _completionGuard?.cancel();
    final estimatedSeconds = (text.length / 14).ceil();
    final boundedSeconds = estimatedSeconds < 6
        ? 6
        : (estimatedSeconds > 28 ? 28 : estimatedSeconds);
    _completionGuard = Timer(
      Duration(seconds: boundedSeconds),
      () => _notifyComplete(sessionId),
    );
  }

  /// Calls Groq TTS API and returns audio bytes
  Future<Uint8List?> _fetchAudioFromApi(String text) async {
    final keySource = _effectiveApiKey;
    final keys = keySource
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (keys.isEmpty) {
      debugPrint("TTS API key is missing");
      return null;
    }

    // Shuffle for random rotation
    keys.shuffle();

    final url = Uri.parse("https://api.groq.com/openai/v1/audio/speech");
    final bodyData = {
      "model": _effectiveModel,
      "voice": _effectiveVoice,
      "input": text,
      "response_format": "wav"
    };

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      try {
        final response = await http
            .post(
              url,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $key",
              },
              body: jsonEncode(bodyData),
            )
            .timeout(_ttsRequestTimeout);

        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          debugPrint(
              "TTS API Error (Key ${i + 1}/${keys.length}): ${response.statusCode} - ${response.body}");
        }
      } on TimeoutException catch (_) {
        debugPrint("TTS API request timeout (Key ${i + 1}/${keys.length})");
      } catch (e) {
        debugPrint("TTS API Exception (Key ${i + 1}/${keys.length}): $e");
      }
    }

    debugPrint("All TTS API keys failed.");
    return null;
  }

  /// Speak text (API call + play)
  Future<void> speak(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      debugPrint("TTS: Empty text provided");
      return;
    }

    final sessionId = ++_sessionCounter;
    _activeSessionId = sessionId;
    _startCompletionGuard(sessionId, cleanText);
    onStart?.call();

    try {
      final audioBytes = await _fetchAudioFromApi(cleanText);

      if (audioBytes == null || audioBytes.isEmpty) {
        debugPrint("No audio from Groq TTS, falling back to device TTS");
        await _speakWithFallbackTts(cleanText, sessionId);
        return;
      }

      _playerSessionId = sessionId;
      _fallbackSessionId = 0;
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _player.play(BytesSource(audioBytes));
    } catch (e) {
      debugPrint("TTS speak error: $e");
      await _speakWithFallbackTts(cleanText, sessionId);
    }
  }

  Future<void> _speakWithFallbackTts(String text, int sessionId) async {
    try {
      _fallbackSessionId = sessionId;
      _playerSessionId = 0;
      await _flutterTts.stop();
      await _configureFallbackVoice();
      await _flutterTts.setPitch(1.03);
      await _flutterTts.setSpeechRate(0.46);
      await _flutterTts.setVolume(1.0);

      final result = await _flutterTts.speak(text);
      if (result != 1) {
        debugPrint("Fallback TTS speak returned: $result");
        _notifyComplete(sessionId);
      }
    } catch (e) {
      debugPrint("Fallback TTS Exception: $e");
      _notifyComplete(sessionId);
    }
  }

  /// Stop all audio playback and cleanup
  Future<void> stop() async {
    final previous = _activeSessionId;
    _completionGuard?.cancel();
    _completionGuard = null;
    _activeSessionId = 0;
    _playerSessionId = 0;
    _fallbackSessionId = 0;

    try {
      await _player.stop();
    } catch (e) {
      debugPrint("TTS player stop error: $e");
    }

    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("FlutterTTS stop error: $e");
    }

    if (previous != 0) {
      onComplete?.call();
    }
  }

  Future<void> _configureFallbackVoice() async {
    final signature =
        "${_voiceOverride.trim().toLowerCase()}|${_effectiveVoice.toLowerCase()}";
    if (_fallbackVoiceConfigured && _fallbackVoiceSignature == signature) {
      return;
    }
    _fallbackVoiceConfigured = true;
    _fallbackVoiceSignature = signature;

    try {
      final dynamic voicesRaw = await _flutterTts.getVoices;
      final voices = _normalizeVoices(voicesRaw);
      final preferred = _pickBestFallbackVoice(
        voices: voices,
        requestedVoice: _voiceOverride.trim(),
      );
      if (preferred != null) {
        final locale = (preferred['locale'] ?? 'en-US').toString();
        final name = (preferred['name'] ?? '').toString();
        await _flutterTts.setLanguage(locale);
        if (name.isNotEmpty) {
          await _flutterTts.setVoice({'name': name, 'locale': locale});
        }
        return;
      }
    } catch (e) {
      debugPrint("Fallback voice discovery failed: $e");
    }

    await _flutterTts.setLanguage("en-US");
  }

  List<Map<String, dynamic>> _normalizeVoices(dynamic voicesRaw) {
    if (voicesRaw is! List) return const [];
    return voicesRaw
        .whereType<Map>()
        .map(
          (v) => v.map(
            (k, value) => MapEntry(
              k.toString(),
              value,
            ),
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic>? _pickBestFallbackVoice({
    required List<Map<String, dynamic>> voices,
    required String requestedVoice,
  }) {
    if (voices.isEmpty) return null;
    final request = requestedVoice.trim().toLowerCase();

    int scoreVoice(Map<String, dynamic> voice) {
      final name = (voice['name'] ?? '').toString().toLowerCase();
      final locale = (voice['locale'] ?? '').toString().toLowerCase();
      final quality = (voice['quality'] as num?)?.toInt() ?? 0;
      final notInstalled = voice['notInstalled'] == true;
      final networkRequired = voice['network_required'] == true;

      var score = 0;
      if (locale.startsWith('en-us')) score += 60;
      if (locale.startsWith('en-')) score += 25;
      if (!notInstalled) score += 20;
      if (!networkRequired) score += 10;
      if (quality > 0) score += quality ~/ 10;

      // Prefer human-like voices when available.
      if (name.contains('female')) score += 18;
      if (name.contains('natural') || name.contains('neural')) score += 22;
      if (name.contains('wavenet')) score += 20;

      // Respect user-configured fallback hint if it matches a device voice.
      if (request.isNotEmpty && name.contains(request)) score += 100;

      return score;
    }

    voices.sort((a, b) => scoreVoice(b).compareTo(scoreVoice(a)));
    final best = voices.first;
    final bestScore = scoreVoice(best);
    return bestScore > 0 ? best : null;
  }
}
