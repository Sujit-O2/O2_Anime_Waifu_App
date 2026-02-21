// ignore: file_names
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  static const Duration _ttsRequestTimeout = Duration(seconds: 18);

  String get _effectiveApiKey {
    if (_apiKeyOverride.trim().isNotEmpty) return _apiKeyOverride.trim();
    return dotenv.env['GROQ_API_KEY_VOICE'] ?? "";
  }

  String get _effectiveVoice {
    if (_voiceOverride.trim().isNotEmpty) return _voiceOverride.trim();
    return "lulwa";
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
    _activeSessionId = 0;
    onComplete?.call();
  }

//Call Groq TTS API
  Future<Uint8List?> _fetchAudioFromApi(String text) async {
    try {
      if (_effectiveApiKey.isEmpty) {
        return null;
      }
      final url = Uri.parse("https://api.groq.com/openai/v1/audio/speech");

      final bodyData = {
        "model": _effectiveModel,
        "voice": _effectiveVoice,
        "input": text,
        "response_format": "wav"
      };

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $_effectiveApiKey",
            },
            body: jsonEncode(bodyData),
          )
          .timeout(_ttsRequestTimeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint("TTS API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("TTS API Exception: $e");
      return null;
    }
  }

  //Speak text (API call + play)
  Future<void> speak(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return;
    }

    final sessionId = ++_sessionCounter;
    _activeSessionId = sessionId;
    onStart?.call();

    final audioBytes = await _fetchAudioFromApi(cleanText);

    if (audioBytes == null || audioBytes.isEmpty) {
      debugPrint("No audio from Groq TTS, falling back to free device TTS");
      await _speakWithFallbackTts(cleanText, sessionId);
      return;
    }

    _playerSessionId = sessionId;
    _fallbackSessionId = 0;
    await _player.stop();
    await Future.delayed(const Duration(milliseconds: 100));
    await _player.play(BytesSource(audioBytes));
  }

  Future<void> _speakWithFallbackTts(String text, int sessionId) async {
    try {
      _fallbackSessionId = sessionId;
      _playerSessionId = 0;
      await _flutterTts.stop();
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.47);
      final result = await _flutterTts.speak(text);
      if (result != 1) {
        _notifyComplete(sessionId);
      }
    } catch (e) {
      debugPrint("Fallback TTS Exception: $e");
      _notifyComplete(sessionId);
    }
  }

  /// ---- Stop audio ----
  Future<void> stop() async {
    final previous = _activeSessionId;
    _activeSessionId = 0;
    _playerSessionId = 0;
    _fallbackSessionId = 0;
    await _player.stop();
    await _flutterTts.stop();
    if (previous != 0) {
      onComplete?.call();
    }
  }
}
