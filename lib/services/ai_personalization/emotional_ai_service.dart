import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Emotional AI Service
/// Detects user emotional state and generates comfort/motivation
class EmotionalAIService {
  static final EmotionalAIService _instance = EmotionalAIService._internal();

  factory EmotionalAIService() {
    return _instance;
  }

  EmotionalAIService._internal();

  late SharedPreferences _prefs;
  final Map<DateTime, EmotionalState> _emotionalHistory = {};
  final Map<String, ComfortResponse> _comfortResponses = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadEmotionalHistory();
    await _initializeComfortResponses();
    debugPrint('[EmotionalAI] Service initialized');
  }

  // ===== EMOTION DETECTION =====
  /// Detect emotional state from user input
  Future<DetectedEmotion> detectEmotion(String userInput) async {
    final cleanInput = userInput.toLowerCase();
    
    // Analyze text for emotional markers
    double sadness = 0, happiness = 0, anxiety = 0, anger = 0, calm = 0;

    // Sad indicators
    final sadWords = ['sad', 'depressed', 'lonely', 'empty', 'worthless', 'cry', 'painful', 'hurt', 'grief', 'miserable'];
    for (final word in sadWords) {
      if (cleanInput.contains(word)) sadness += 0.3;
    }

    // Happy indicators
    final happyWords = ['happy', 'excited', 'joyful', 'blessed', 'grateful', 'amazing', 'wonderful', 'love', 'smile'];
    for (final word in happyWords) {
      if (cleanInput.contains(word)) happiness += 0.3;
    }

    // Anxious indicators
    final anxiousWords = ['anxious', 'worried', 'scared', 'nervous', 'panic', 'stress', 'overwhelmed', 'unsure'];
    for (final word in anxiousWords) {
      if (cleanInput.contains(word)) anxiety += 0.3;
    }

    // Angry indicators
    final angryWords = ['angry', 'furious', 'hate', 'annoyed', 'irritated', 'frustrated'];
    for (final word in angryWords) {
      if (cleanInput.contains(word)) anger += 0.3;
    }

    // Calm indicators
    final calmWords = ['relax', 'calm', 'peace', 'serene', 'quiet', 'rest'];
    for (final word in calmWords) {
      if (cleanInput.contains(word)) calm += 0.3;
    }

    // Normalize
    final total = sadness + happiness + anxiety + anger + calm;
    if (total > 0) {
      sadness /= total;
      happiness /= total;
      anxiety /= total;
      anger /= total;
      calm /= total;
    }

    // Determine primary emotion
    final emotions = {
      'sadness': sadness,
      'happiness': happiness,
      'anxiety': anxiety,
      'anger': anger,
      'calm': calm,
    };

    final primaryEmotion = emotions.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Store in history
    final state = EmotionalState(
      timestamp: DateTime.now(),
      primaryEmotion: primaryEmotion,
      emotionScores: emotions,
      intensity: total.clamp(0.0, 1.0),
      trigger: _extractTrigger(userInput),
    );

    _emotionalHistory[DateTime.now()] = state;
    await _saveEmotionalHistory();

    return DetectedEmotion(
      primaryEmotion: primaryEmotion,
      emotionScores: emotions,
      intensity: total.clamp(0.0, 1.0),
      confidence: total > 0 ? 0.8 : 0.5,
      recommendation: await _generateRecommendation(primaryEmotion, total),
    );
  }

  // ===== MOOD SUPPORT =====
  /// Get comfort response for detected emotion
  Future<String> getComfortResponse(String emotion) async {
    final response = _comfortResponses[emotion];
    if (response != null) {
      // Rotate through responses
      return response.responses[
        DateTime.now().millisecond % response.responses.length
      ];
    }
    return 'I\'m here for you. Tell me what\'s on your mind.';
  }

  /// Get anime recommendation for current mood
  Future<List<String>> getAnimeRecommendationForMood(String emotion) async {
    switch (emotion) {
      case 'sadness':
        return [
          'A Place Further Than the Universe (inspiring)',
          'Your Name (emotional journey)',
          'Clannad: After Story (cathartic)',
          'Violet Evergarden (healing)',
        ];
      case 'anxiety':
        return [
          'Haikyu!! (motivational)',
          'My Hero Academia (empowering)',
          'Demon Slayer (action-focused)',
          'Jujutsu Kaisen (engaging)',
        ];
      case 'anger':
        return [
          'Demon Slayer (action)',
          'One Punch Man (humorous)',
          'Kill la Kill (cathartic)',
          'Trigun (philosophical)',
        ];
      case 'happiness':
        return [
          'K-On! (relaxing)',
          'Nichijou (comedy)',
          'Love is War (entertainment)',
          'Tonikawa (wholesome)',
        ];
      default:
        return [
          'Steins;Gate (engaging)',
          'Death Note (thought-provoking)',
          'Attack on Titan (gripping)',
          'Demon Slayer (captivating)',
        ];
    }
  }

  /// Get wellness activity recommendation
  Future<String> getWellnessActivity(String emotion) async {
    switch (emotion) {
      case 'sadness':
        return 'Try a breathing exercise or take a walk in nature 🌳';
      case 'anxiety':
        return 'Let\'s do some progressive muscle relaxation 🧘';
      case 'anger':
        return 'Channel that energy into a workout or sport 💪';
      case 'happiness':
        return 'Spread the joy - share your favorite anime with someone! 🌟';
      default:
        return 'How about some mindfulness meditation? 🎧';
    }
  }

  /// Get mental health tip
  Future<String> getMentalHealthTip(String emotion) async {
    switch (emotion) {
      case 'sadness':
        return 'Remember: This feeling is temporary. You are stronger than you think.';
      case 'anxiety':
        return 'Focus on what you can control. Take it one moment at a time.';
      case 'anger':
        return 'Take a pause. Deep breaths can help regulate your emotions.';
      case 'happiness':
        return 'Gratitude amplifies joy. What are you most thankful for today?';
      default:
        return 'Be kind to yourself. You deserve compassion.';
    }
  }

  // ===== EMOTIONAL TRENDS =====
  /// Get emotional trend
  Future<EmotionalTrend> getEmotionalTrend({int daysBack = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
    final relevant = _emotionalHistory.values
        .where((e) => e.timestamp.isAfter(cutoffDate))
        .toList();

    if (relevant.isEmpty) {
      return EmotionalTrend(
        averageIntensity: 0.5,
        dominantEmotion: 'neutral',
        trend: 'insufficient_data',
        emotionalStability: 0.5,
      );
    }

    final avgIntensity = relevant.fold<double>(0, (a, b) => a + b.intensity) / relevant.length;
    
    final emotionCounts = <String, int>{};
    for (final state in relevant) {
      emotionCounts[state.primaryEmotion] = (emotionCounts[state.primaryEmotion] ?? 0) + 1;
    }

    final dominantEmotion = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Calculate emotional stability (lower variance = more stable)
    final variance = relevant.fold<double>(0, (sum, e) => 
      sum + (e.intensity - avgIntensity) * (e.intensity - avgIntensity)
    ) / relevant.length;
    final stability = 1.0 - (variance.clamp(0.0, 1.0));

    return EmotionalTrend(
      averageIntensity: avgIntensity,
      dominantEmotion: dominantEmotion,
      trend: _calculateEmotionalTrend(relevant),
      emotionalStability: stability,
    );
  }

  /// Get emotional breakdown
  Future<Map<String, double>> getEmotionalBreakdown({int daysBack = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
    final relevant = _emotionalHistory.values
        .where((e) => e.timestamp.isAfter(cutoffDate))
        .toList();

    final breakdown = <String, double>{};
    for (final state in relevant) {
      breakdown[state.primaryEmotion] = (breakdown[state.primaryEmotion] ?? 0) + 1;
    }

    if (breakdown.isEmpty) return {};

    final total = breakdown.values.fold<double>(0, (a, b) => a + b);
    breakdown.forEach((k, v) {
      breakdown[k] = v / total;
    });

    return breakdown;
  }

  /// Get emotional insights
  Future<String> getEmotionalInsights() async {
    final trend = await getEmotionalTrend(daysBack: 7);
    final breakdown = await getEmotionalBreakdown(daysBack: 30);

    return '''
=== EMOTIONAL INSIGHTS ===
Last 7 Days:
- Average Intensity: ${(trend.averageIntensity * 100).toStringAsFixed(1)}%
- Dominant Emotion: ${trend.dominantEmotion}
- Emotional Stability: ${(trend.emotionalStability * 100).toStringAsFixed(1)}%
- Trend: ${trend.trend}

Last 30 Days Breakdown:
${breakdown.entries.map((e) => '- ${e.key}: ${(e.value * 100).toStringAsFixed(1)}%').join('\n')}

${trend.emotionalStability > 0.7 ? '✓ Your emotional state is stable and healthy!' : '⚠ Consider taking time for self-care and reflection.'}
''';
  }

  // ===== COPING STRATEGIES =====
  /// Get personalized coping strategies
  Future<List<CopingStrategy>> getCopingStrategies(String emotion) async {
    switch (emotion) {
      case 'sadness':
        return [
          CopingStrategy(
            name: 'Gratitude Practice',
            description: 'List 3 things you\'re grateful for',
            difficulty: 'easy',
            duration: 10,
          ),
          CopingStrategy(
            name: 'Anime Comfort Watch',
            description: 'Rewatch your favorite feel-good anime',
            difficulty: 'easy',
            duration: 30,
          ),
          CopingStrategy(
            name: 'Journal Your Feelings',
            description: 'Write about what\'s troubling you',
            difficulty: 'medium',
            duration: 20,
          ),
        ];
      case 'anxiety':
        return [
          CopingStrategy(
            name: 'Box Breathing',
            description: '4-4-4-4 pattern breathing exercise',
            difficulty: 'easy',
            duration: 5,
          ),
          CopingStrategy(
            name: 'Progressive Relaxation',
            description: 'Tense and release muscle groups',
            difficulty: 'medium',
            duration: 15,
          ),
          CopingStrategy(
            name: 'Grounding Technique',
            description: '5-4-3-2-1 sensory awareness',
            difficulty: 'easy',
            duration: 10,
          ),
        ];
      default:
        return [
          CopingStrategy(
            name: 'Mindfulness Meditation',
            description: 'Guided meditation session',
            difficulty: 'medium',
            duration: 15,
          ),
          CopingStrategy(
            name: 'Physical Activity',
            description: 'Light exercise or yoga',
            difficulty: 'medium',
            duration: 20,
          ),
        ];
    }
  }

  // ===== INTERNAL HELPERS =====
  String _extractTrigger(String input) {
    if (input.contains('anime')) return 'anime';
    if (input.contains('work') || input.contains('job')) return 'work';
    if (input.contains('friend') || input.contains('family')) return 'relationship';
    if (input.contains('sleep') || input.contains('tired')) return 'fatigue';
    return 'unknown';
  }

  Future<String> _generateRecommendation(String emotion, double intensity) async {
    if (intensity < 0.3) {
      return 'You seem to be doing well. Want to chat or watch your favorite anime?';
    }

    if (emotion == 'sadness' && intensity > 0.5) {
      final recs = await getAnimeRecommendationForMood('sadness');
      return 'I sense you might need some comfort. How about watching ${recs.first}?';
    }

    if (emotion == 'anxiety') {
      return 'Let\'s take some deep breaths together. You\'ll get through this.';
    }

    return 'I\'m here to listen. Tell me more about how you\'re feeling.';
  }

  String _calculateEmotionalTrend(List<EmotionalState> states) {
    if (states.length < 2) return 'insufficient_data';

    final recent = states.sublist((states.length * 0.7).toInt());
    final older = states.sublist(0, (states.length * 0.3).toInt());

    final avgRecent = recent.fold<double>(0, (a, b) => a + b.intensity) / recent.length;
    final avgOlder = older.fold<double>(0, (a, b) => a + b.intensity) / older.length;

    if (avgRecent > avgOlder + 0.1) return 'worsening';
    if (avgRecent < avgOlder - 0.1) return 'improving';
    return 'stable';
  }

  Future<void> _initializeComfortResponses() async {
    _comfortResponses['sadness'] = ComfortResponse(
      emotion: 'sadness',
      responses: [
        'I can sense you\'re going through a tough time. That\'s okay. I\'m here for you 💙',
        'Your feelings are valid. Let\'s talk about what\'s troubling you.',
        'Remember, storms pass. You\'re stronger than you think.',
        'It\'s okay to not be okay sometimes. What can I do to help?',
      ],
    );

    _comfortResponses['anxiety'] = ComfortResponse(
      emotion: 'anxiety',
      responses: [
        'I can feel your worry. Let\'s take this one step at a time.',
        'You\'re safe. Your anxiety is just your mind trying to protect you.',
        'Breathe with me - in for 4, hold for 4, out for 4.',
        'What\'s the worst that could happen? And could you handle it?',
      ],
    );

    _comfortResponses['happiness'] = ComfortResponse(
      emotion: 'happiness',
      responses: [
        'Your joy is contagious! I\'m happy for you! 🌟',
        'This energy is amazing! Let\'s celebrate this moment!',
        'You\'re radiating happiness. Keep shining! ✨',
        'I love seeing you this happy. What\'s making you feel so good?',
      ],
    );
  }

  Future<void> _saveEmotionalHistory() async {
    final data = _emotionalHistory.entries
        .map((e) => jsonEncode({
          'date': e.key.toIso8601String(),
          'state': e.value.toJson(),
        }))
        .toList();
    await _prefs.setStringList('emotional_history', data);
  }

  Future<void> _loadEmotionalHistory() async {
    final data = _prefs.getStringList('emotional_history') ?? [];
    for (final item in data) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final date = DateTime.parse(decoded['date'] as String);
        final state = EmotionalState.fromJson(decoded['state'] as Map<String, dynamic>);
        _emotionalHistory[date] = state;
      } catch (e) {
        debugPrint('[EmotionalAI] Error loading state: $e');
      }
    }
  }
}

// ===== DATA MODELS =====

class DetectedEmotion {
  final String primaryEmotion;
  final Map<String, double> emotionScores;
  final double intensity;
  final double confidence;
  final String recommendation;

  DetectedEmotion({
    required this.primaryEmotion,
    required this.emotionScores,
    required this.intensity,
    required this.confidence,
    required this.recommendation,
  });
}

class EmotionalState {
  final DateTime timestamp;
  final String primaryEmotion;
  final Map<String, double> emotionScores;
  final double intensity;
  final String trigger;

  EmotionalState({
    required this.timestamp,
    required this.primaryEmotion,
    required this.emotionScores,
    required this.intensity,
    required this.trigger,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'primaryEmotion': primaryEmotion,
    'emotionScores': emotionScores,
    'intensity': intensity,
    'trigger': trigger,
  };

  factory EmotionalState.fromJson(Map<String, dynamic> json) {
    return EmotionalState(
      timestamp: DateTime.parse(json['timestamp'] as String),
      primaryEmotion: json['primaryEmotion'] as String,
      emotionScores: Map<String, double>.from(
        (json['emotionScores'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()))
      ),
      intensity: (json['intensity'] as num).toDouble(),
      trigger: json['trigger'] as String? ?? 'unknown',
    );
  }
}

class EmotionalTrend {
  final double averageIntensity;
  final String dominantEmotion;
  final String trend;
  final double emotionalStability;

  EmotionalTrend({
    required this.averageIntensity,
    required this.dominantEmotion,
    required this.trend,
    required this.emotionalStability,
  });
}

class CopingStrategy {
  final String name;
  final String description;
  final String difficulty;
  final int duration;

  CopingStrategy({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.duration,
  });
}

class ComfortResponse {
  final String emotion;
  final List<String> responses;

  ComfortResponse({
    required this.emotion,
    required this.responses,
  });
}


