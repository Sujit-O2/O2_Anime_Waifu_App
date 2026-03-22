import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Whisper-based Speech-to-Text using Groq's whisper-large-v3-turbo.
/// Supports multi-language with automatic code-switching.
class SpeechService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isListening = false;
  String? _currentRecordingPath;
  String _language = 'en';
  int _timeoutMs = 30000;

  bool get isListening => _isListening;

  set language(String value) => _language = value;
  set timeoutMs(int value) => _timeoutMs = value;

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<bool> startListening() async {
    if (_isListening) return false;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return false;

    final tempDir = await getTemporaryDirectory();
    _currentRecordingPath = '${tempDir.path}/stt_recording.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _currentRecordingPath!,
    );

    _isListening = true;
    return true;
  }

  Future<String?> stopAndTranscribe() async {
    if (!_isListening) return null;
    _isListening = false;

    final path = await _recorder.stop();
    if (path == null) return null;

    return await _transcribe(path);
  }

  Future<String?> _transcribe(String filePath) async {
    if (_apiKey.isEmpty) return null;

    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );

      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['model'] = 'whisper-large-v3-turbo';
      request.fields['language'] = _language;
      request.fields['response_format'] = 'json';

      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return data['text'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
