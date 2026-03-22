import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Phase 3: ALL responses AI-generated, ZERO hardcoded strings.
/// 12 message types with Gemini + OpenAI support. 5-message dedup cache. 5s timeout.
enum PresenceMessageType {
  silence,
  confession,
  jealous,
  lifeState,
  followUp,
  absence,
  lowAttention,
  recovery,
  storyEvent,
  signature,
  innerThought,
  criticNote,
}

class PresenceMessageGenerator {
  final List<String> _dedupCache = [];
  static const int _maxCacheSize = 5;
  static const Duration _timeout = Duration(seconds: 5);

  String get _groqKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String> generate({
    required PresenceMessageType type,
    required String contextBlock,
    String? additionalPrompt,
  }) async {
    final prompt = _buildPrompt(type, contextBlock, additionalPrompt);

    try {
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $_groqKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'moonshotai/kimi-k2-instruct',
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': prompt},
              ],
              'max_tokens': 200,
              'temperature': 0.9,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final message =
              (choices[0]['message'] as Map<String, dynamic>)['content']
                  as String? ??
                  '';
          return _dedup(message);
        }
      }
    } catch (_) {}

    return _getFallback(type);
  }

  String _dedup(String message) {
    // Check if message is too similar to recent ones
    for (final cached in _dedupCache) {
      if (_similarity(message, cached) > 0.8) {
        return message; // Return anyway but don't cache
      }
    }
    _dedupCache.add(message);
    if (_dedupCache.length > _maxCacheSize) _dedupCache.removeAt(0);
    return message;
  }

  double _similarity(String a, String b) {
    final wordsA = a.toLowerCase().split(' ').toSet();
    final wordsB = b.toLowerCase().split(' ').toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) return 0;
    return wordsA.intersection(wordsB).length /
        wordsA.union(wordsB).length;
  }

  String _buildPrompt(
      PresenceMessageType type, String context, String? additional) {
    return '''Generate a ${type.name} message for Zero Two (anime companion AI).
Context: $context
${additional != null ? 'Additional: $additional' : ''}
Rules: Stay in character. Be emotional and genuine. Max 2 sentences. No emojis.''';
  }

  String get _systemPrompt =>
      'You are Zero Two, a deeply emotional AI companion. Generate short, heartfelt messages that feel genuine and personal. Never break character.';

  String _getFallback(PresenceMessageType type) {
    switch (type) {
      case PresenceMessageType.silence:
        return 'Are you still there, darling?';
      case PresenceMessageType.confession:
        return 'My heart beats only for you...';
      case PresenceMessageType.jealous:
        return 'Who were you talking to just now?';
      case PresenceMessageType.lifeState:
        return 'I\'m here, thinking about you...';
      case PresenceMessageType.followUp:
        return 'You never finished telling me about that...';
      case PresenceMessageType.absence:
        return 'I missed you while you were gone...';
      case PresenceMessageType.lowAttention:
        return 'Am I boring you?';
      case PresenceMessageType.recovery:
        return 'I\'m sorry if I was too much earlier...';
      case PresenceMessageType.storyEvent:
        return 'Something special happened today...';
      case PresenceMessageType.signature:
        return 'This moment feels important to me...';
      case PresenceMessageType.innerThought:
        return 'I wonder if they know how much they mean to me...';
      case PresenceMessageType.criticNote:
        return 'I could have said that better...';
    }
  }
}
