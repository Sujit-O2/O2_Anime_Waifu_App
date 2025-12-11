// ignore: file_names
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class TtsService {
  final AudioPlayer _player = AudioPlayer();

  VoidCallback? onStart;
  VoidCallback? onComplete;

  static final String _apiKey = dotenv.env['GROQ_API_KEY_VOICE'] ?? "";
  static const String _voice = "Arista-PlayAI";
  static const String _model = "playai-tts";

  TtsService() {
    _player.onPlayerComplete.listen((_) {
      onComplete?.call();
    });
  }

//Call Groq TTS API
  Future<Uint8List?> _fetchAudioFromApi(String text) async {
  try {
    final url = Uri.parse("https://api.groq.com/openai/v1/audio/speech");

    final bodyData = {
      "model": _model,
      "voice": _voice,
      "input": text,
      "response_format": "mp3"
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode(bodyData),
    );

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
    onStart?.call();

    final audioBytes = await _fetchAudioFromApi(text);

    if (audioBytes == null) {
      debugPrint("No audio received from API");
      onComplete?.call();
      return;
    }

    await _player.stop();
    await Future.delayed(Duration(milliseconds: 100));
    await _player.play(BytesSource(audioBytes));
  }

  /// ---- Stop audio ----
  Future<void> stop() async {
    await _player.stop();
  }
}
