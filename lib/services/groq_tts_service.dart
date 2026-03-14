import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Groq TTS service using the OpenAI-compatible /audio/speech endpoint.
///
/// Uses the existing GROQ_API_KEY_VOICE from .env — no extra key needed.
/// Voices available: "Fritz-PlayAI", "Arista-PlayAI", "Atlas-PlayAI",
///   "Briggs-PlayAI", "Calum-PlayAI", "Celeste-PlayAI", "Cheyenne-PlayAI",
///   "Chip-PlayAI", "Cillian-PlayAI", "Deedee-PlayAI", "Gail-PlayAI",
///   "Indigo-PlayAI", "Mamaw-PlayAI", "Mason-PlayAI", "Mikail-PlayAI",
///   "Mist-PlayAI", "Quinn-PlayAI"
///
/// Usage:
///   final ok = await GroqTtsService.instance.speak("Hello darling~");
///   if (!ok) { /* fallback to flutter_tts */ }
class GroqTtsService {
  GroqTtsService._();
  static final instance = GroqTtsService._();

  static const _endpoint = 'https://api.groq.com/openai/v1/audio/speech';
  static const _model = 'playai-tts';

  // ── Config ────────────────────────────────────────────────────────────────

  /// Anime-appropriate female voice. Can be overridden at runtime.
  String voice = 'Celeste-PlayAI';

  /// Available Groq PlayAI voices users can choose from.
  static const availableVoices = [
    'Celeste-PlayAI',
    'Arista-PlayAI',
    'Mist-PlayAI',
    'Quinn-PlayAI',
    'Cheyenne-PlayAI',
    'Deedee-PlayAI',
    'Gail-PlayAI',
    'Indigo-PlayAI',
    'Fritz-PlayAI',
    'Atlas-PlayAI',
    'Briggs-PlayAI',
    'Calum-PlayAI',
    'Chip-PlayAI',
    'Cillian-PlayAI',
    'Mamaw-PlayAI',
    'Mason-PlayAI',
    'Mikail-PlayAI',
  ];

  // ── State ─────────────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  bool _speaking = false;
  bool _enabled = false; // opt-in: user enables in settings

  bool get isSpeaking => _speaking;
  bool get isEnabled => _enabled;
  void setEnabled(bool v) => _enabled = v;

  String get _apiKey =>
      dotenv.maybeGet('GROQ_API_KEY_VOICE') ??
      dotenv.maybeGet('GROQ_API_KEY') ??
      '';

  bool get isConfigured => _apiKey.isNotEmpty;

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> stop() async {
    await _player.stop();
    _speaking = false;
  }

  /// Synthesise [text] and play it. Returns true on success.
  /// On failure the caller should fall back to flutter_tts.
  Future<bool> speak(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    if (!_enabled || !isConfigured || text.trim().isEmpty) return false;

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'input': text,
              'voice': voice,
              'response_format': 'mp3',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint('[GroqTTS] ${response.statusCode}: ${response.body}');
        return false;
      }

      // Save to temp and play
      final dir = await getTemporaryDirectory();
      final f = File(
          '${dir.path}/groq_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await f.writeAsBytes(response.bodyBytes);

      _speaking = true;
      onStart?.call();

      await _player.stop();
      await _player.play(DeviceFileSource(f.path));
      await _player.onPlayerComplete.first
          .timeout(const Duration(minutes: 5), onTimeout: () {});

      _speaking = false;
      onComplete?.call();

      f.deleteSync();
      return true;
    } catch (e) {
      debugPrint('[GroqTTS] speak() error: $e');
      _speaking = false;
      return false;
    }
  }

  void dispose() => _player.dispose();
}
