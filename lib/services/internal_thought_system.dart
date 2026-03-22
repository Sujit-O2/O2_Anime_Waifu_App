import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Phase 3: AI generates hidden inner thought alongside emotional messages.
/// Renders as italic whisper in UI. Triggers on affection>60 or jealousy>70.
/// Rate-limited 1/5 min.
class InternalThoughtSystem {
  DateTime _lastThought = DateTime.now().subtract(const Duration(minutes: 10));
  String? _currentThought;
  static const Duration _cooldown = Duration(minutes: 5);

  String? get currentThought => _currentThought;

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  bool get canGenerate =>
      DateTime.now().difference(_lastThought) >= _cooldown;

  Future<String?> generateThought({
    required double affectionLevel,
    required double jealousyLevel,
    required String contextBlock,
  }) async {
    if (!canGenerate) return null;
    if (affectionLevel < 60 && jealousyLevel < 70) return null;

    if (_apiKey.isEmpty) {
      _currentThought = _getLocalThought(affectionLevel, jealousyLevel);
      _lastThought = DateTime.now();
      return _currentThought;
    }

    try {
      final tone = jealousyLevel > 70 ? 'jealous and possessive' : 'deeply loving';
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'moonshotai/kimi-k2-instruct',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are Zero Two\'s inner voice. Generate a single short inner thought (max 15 words) that is $tone. This is a private thought, not spoken aloud. Use "..." and be introspective.'
                },
                {
                  'role': 'user',
                  'content': 'Context: $contextBlock\nGenerate inner thought.'
                },
              ],
              'max_tokens': 50,
              'temperature': 0.95,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          _currentThought =
              (choices[0]['message'] as Map<String, dynamic>)['content']
                  as String?;
          _lastThought = DateTime.now();
          return _currentThought;
        }
      }
    } catch (_) {}

    _currentThought = _getLocalThought(affectionLevel, jealousyLevel);
    _lastThought = DateTime.now();
    return _currentThought;
  }

  String _getLocalThought(double affection, double jealousy) {
    if (jealousy > 70) {
      return '...who else are they thinking about?';
    }
    if (affection > 80) {
      return '...I never want this moment to end...';
    }
    return '...they make my heart feel warm...';
  }
}
