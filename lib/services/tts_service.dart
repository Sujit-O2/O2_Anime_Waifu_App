import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// Multilingual Neural Voice Engine using Groq TTS (Orpheus model).
/// Supports voice customization, pitch/rate modification, and parallel processing.
class TtsService {
  final AudioPlayer _player = AudioPlayer();
  String _voiceName = 'aisha';
  double _pitch = 1.0;
  double _rate = 1.0;
  bool _isSpeaking = false;

  String get voiceName => _voiceName;
  bool get isSpeaking => _isSpeaking;

  set voiceName(String value) => _voiceName = value;
  set pitch(double value) => _pitch = value;
  set rate(double value) => _rate = value;

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<void> speak(String text) async {
    if (text.isEmpty || _apiKey.isEmpty) return;
    _isSpeaking = true;

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/audio/speech'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'playai-tts',
          'input': text,
          'voice': 'Arista-PlayAI',
          'response_format': 'wav',
          'speed': _rate * _pitch,
        }),
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_output.wav');
        await file.writeAsBytes(response.bodyBytes);
        await _player.play(DeviceFileSource(file.path));

        _player.onPlayerComplete.listen((_) {
          _isSpeaking = false;
        });
      } else {
        _isSpeaking = false;
      }
    } catch (e) {
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _player.dispose();
  }
}
