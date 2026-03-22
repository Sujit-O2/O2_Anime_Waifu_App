import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Phase 3: 4 parallel sub-agents after each exchange:
/// Planner (7-rule heuristic -> next hint)
/// MemoryCurator (confession/topic detection)
/// CriticAgent (LLM quality check on last reply)
/// MoodManager (sentiment-driven personality drift)
class AgentResult {
  final String agentName;
  final Map<String, dynamic> output;

  AgentResult({required this.agentName, required this.output});
}

class MultiAgentBrain {
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  String? lastPlannerHint;
  String? lastCriticNote;
  double? lastSentiment;
  List<String> detectedTopics = [];

  Future<List<AgentResult>> process({
    required String userMessage,
    required String aiResponse,
    required String contextBlock,
  }) async {
    final results = <AgentResult>[];

    // Run all 4 agents
    results.add(_runPlanner(userMessage, aiResponse, contextBlock));
    results.add(_runMemoryCurator(userMessage));
    results.add(await _runCritic(aiResponse, contextBlock));
    results.add(_runMoodManager(userMessage, aiResponse));

    return results;
  }

  AgentResult _runPlanner(
      String userMessage, String aiResponse, String context) {
    // 7-rule heuristic for next hint
    String hint = '';

    // Rule 1: Short response detected
    if (aiResponse.length < 30) {
      hint = 'Response was too short. Elaborate more next time.';
    }
    // Rule 2: User asked a question
    else if (userMessage.contains('?')) {
      hint = 'User asked a question. Make sure to answer directly.';
    }
    // Rule 3: Emotional content detected
    else if (_containsEmotion(userMessage)) {
      hint = 'User is being emotional. Respond with empathy and care.';
    }
    // Rule 4: Long user message
    else if (userMessage.length > 200) {
      hint = 'User wrote a lot. They want to be heard. Acknowledge details.';
    }
    // Rule 5: Casual chat
    else if (userMessage.length < 20) {
      hint = 'Keep it light and playful. Match their casual energy.';
    }
    // Rule 6: Topic continuation
    else {
      hint = 'Continue the conversation naturally.';
    }

    lastPlannerHint = hint;
    return AgentResult(agentName: 'Planner', output: {'hint': hint});
  }

  AgentResult _runMemoryCurator(String userMessage) {
    final topics = <String>[];
    final confessionKeywords = [
      'love', 'miss', 'need you', 'special', 'important'
    ];

    bool isConfession = false;
    for (final kw in confessionKeywords) {
      if (userMessage.toLowerCase().contains(kw)) {
        isConfession = true;
        break;
      }
    }

    // Simple topic extraction
    final sentences = userMessage.split(RegExp(r'[.!?]'));
    for (final sentence in sentences) {
      final words = sentence.trim().split(' ');
      if (words.length >= 3) {
        topics.add(words.take(4).join(' '));
      }
    }

    detectedTopics = topics;
    return AgentResult(
      agentName: 'MemoryCurator',
      output: {
        'isConfession': isConfession,
        'topics': topics,
      },
    );
  }

  Future<AgentResult> _runCritic(
      String aiResponse, String context) async {
    if (_apiKey.isEmpty) {
      return AgentResult(
        agentName: 'Critic',
        output: {'note': 'API unavailable', 'score': 0.7},
      );
    }

    try {
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
                      'You are a quality critic. Rate the AI response 0-1 and give a brief note. Respond in JSON: {"score": 0.8, "note": "..."}'
                },
                {
                  'role': 'user',
                  'content':
                      'Context: $context\n\nAI Response: $aiResponse\n\nRate this response.'
                },
              ],
              'max_tokens': 100,
              'temperature': 0.3,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final content =
              (choices[0]['message'] as Map<String, dynamic>)['content']
                  as String? ??
                  '{}';
          try {
            final parsed = jsonDecode(content) as Map<String, dynamic>;
            lastCriticNote = parsed['note'] as String?;
            return AgentResult(agentName: 'Critic', output: parsed);
          } catch (_) {
            lastCriticNote = content;
            return AgentResult(
              agentName: 'Critic',
              output: {'note': content, 'score': 0.7},
            );
          }
        }
      }
    } catch (_) {}

    return AgentResult(
      agentName: 'Critic',
      output: {'note': 'Analysis skipped', 'score': 0.7},
    );
  }

  AgentResult _runMoodManager(String userMessage, String aiResponse) {
    // Simple sentiment analysis
    final positiveWords = [
      'happy', 'love', 'great', 'amazing', 'wonderful',
      'thank', 'good', 'nice', 'beautiful', 'best',
    ];
    final negativeWords = [
      'sad', 'angry', 'hate', 'bad', 'terrible',
      'awful', 'worst', 'annoying', 'boring', 'ugly',
    ];

    double sentiment = 0.5;
    final lowerMsg = userMessage.toLowerCase();

    for (final word in positiveWords) {
      if (lowerMsg.contains(word)) sentiment += 0.1;
    }
    for (final word in negativeWords) {
      if (lowerMsg.contains(word)) sentiment -= 0.1;
    }
    sentiment = sentiment.clamp(0.0, 1.0);
    lastSentiment = sentiment;

    return AgentResult(
      agentName: 'MoodManager',
      output: {
        'sentiment': sentiment,
        'drift': sentiment > 0.6
            ? 'positive'
            : sentiment < 0.4
                ? 'negative'
                : 'neutral',
      },
    );
  }

  bool _containsEmotion(String text) {
    final emotionWords = [
      'feel', 'feeling', 'emotion', 'heart', 'cry', 'tears',
      'happy', 'sad', 'love', 'hate', 'scared', 'afraid',
    ];
    final lower = text.toLowerCase();
    return emotionWords.any((w) => lower.contains(w));
  }

  String toContextString() {
    final buffer = StringBuffer();
    if (lastPlannerHint != null) {
      buffer.writeln('[Planner] $lastPlannerHint');
    }
    if (lastCriticNote != null) {
      buffer.writeln('[Critic] $lastCriticNote');
    }
    if (lastSentiment != null) {
      buffer.writeln(
          '[Sentiment] ${lastSentiment!.toStringAsFixed(2)}');
    }
    return buffer.toString();
  }
}
