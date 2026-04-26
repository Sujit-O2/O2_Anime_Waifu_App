import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// AI Copilot System - Context-aware, sentimentally intelligent companion
/// Features: Multi-turn memory, emotional analysis, proactive suggestions
class AICopilotService {
  static final AICopilotService _instance = AICopilotService._internal();

  factory AICopilotService() {
    return _instance;
  }

  AICopilotService._internal();

  late SharedPreferences _prefs;
  final List<ConversationContext> _conversationMemory = [];
  final Map<String, double> _userPreferences = {};
  final Map<String, int> _topicFrequency = {};

  // Initialize service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadConversationHistory();
    await _loadUserProfile();
    if (kDebugMode) debugPrint('[AICopilot] Service initialized');
  }

  // ===== SENTIMENT ANALYSIS =====
  /// Analyze sentiment of user message
  SentimentAnalysis analyzeSentiment(String message) {
    final cleanMsg = message.toLowerCase();
    double score = 0.5; // neutral baseline 0-1
    SentimentCategory category = SentimentCategory.neutral;
    List<String> emotionalKeywords = [];

    // Positive indicators
    final positiveWords = [
      'love',
      'amazing',
      'great',
      'awesome',
      'excellent',
      'beautiful',
      'perfect',
      'wonderful',
      'fantastic',
      'happy',
      'excited',
      'glad',
      'proud',
      'blessed',
      'grateful',
      'inspired',
      'motivated',
      'eager'
    ];

    // Negative indicators
    final negativeWords = [
      'hate',
      'terrible',
      'awful',
      'horrible',
      'sad',
      'angry',
      'frustrated',
      'disappointed',
      'lonely',
      'depressed',
      'anxious',
      'stressed',
      'worried',
      'scared',
      'upset',
      'miserable',
      'devastated',
      'broken'
    ];

    // Excitation indicators
    final excitedWords = ['!!!', '!!', 'OMG', 'WOW', 'YESSS', 'SO'];

    for (final word in positiveWords) {
      if (cleanMsg.contains(word)) {
        score += 0.1;
        emotionalKeywords.add(word);
      }
    }

    for (final word in negativeWords) {
      if (cleanMsg.contains(word)) {
        score -= 0.15;
        emotionalKeywords.add(word);
      }
    }

    for (final word in excitedWords) {
      if (cleanMsg.contains(word)) {
        score += 0.05;
      }
    }

    // Clamp to 0-1
    score = score.clamp(0.0, 1.0);

    if (score >= 0.7) {
      category = SentimentCategory.positive;
    } else if (score <= 0.3) {
      category = SentimentCategory.negative;
    }

    return SentimentAnalysis(
      score: score,
      category: category,
      emotionalKeywords: emotionalKeywords,
      timestamp: DateTime.now(),
    );
  }

  // ===== CONVERSATION MEMORY =====
  /// Add message to multi-turn memory
  Future<void> recordMessage({
    required String userMessage,
    required String copilotResponse,
    required SentimentAnalysis sentiment,
  }) async {
    final context = ConversationContext(
      userMessage: userMessage,
      copilotResponse: copilotResponse,
      sentiment: sentiment,
      timestamp: DateTime.now(),
      contextTags: _extractContextTags(userMessage),
    );

    _conversationMemory.add(context);

    // Keep only last 500 messages
    if (_conversationMemory.length > 500) {
      _conversationMemory.removeAt(0);
    }

    // Save to storage
    await _saveConversationHistory();

    // Update topic frequency
    for (final tag in context.contextTags) {
      _topicFrequency[tag] = (_topicFrequency[tag] ?? 0) + 1;
    }

    // Track mood trends
    await _updateMoodTrend(sentiment.score);
  }

  /// Get last N messages for context
  List<ConversationContext> getRecentContext({int count = 10}) {
    if (_conversationMemory.isEmpty) return [];
    return _conversationMemory.sublist(
      (_conversationMemory.length - count).clamp(0, _conversationMemory.length),
    );
  }

  /// Get conversations about specific topic
  List<ConversationContext> getConversationsByTopic(String topic) {
    return _conversationMemory
        .where((c) => c.contextTags.contains(topic.toLowerCase()))
        .toList();
  }

  // ===== PROACTIVE SUGGESTIONS =====
  /// Generate proactive suggestion based on current state
  Future<ProactiveSuggestion> generateProactiveSuggestion({
    required DateTime currentTime,
    required String currentMood,
    required String currentActivity,
  }) async {
    final hour = currentTime.hour;
    List<String> suggestions = [];

    // Time-based suggestions
    if (hour >= 6 && hour < 9) {
      suggestions
          .add('Good morning! Your favorite anime episode aired at midnight!');
      suggestions.add('Start your day with inspiration from Zero Two 💙');
    } else if (hour >= 12 && hour < 13) {
      suggestions.add('Lunch break? Perfect time for an anime episode!');
      suggestions.add('Check out the trending anime this week');
    } else if (hour >= 20 && hour < 23) {
      suggestions.add('Wind down with a cozy anime episode');
      suggestions.add('How about a relaxing slice-of-life tonight?');
    } else if (hour >= 23 || hour < 6) {
      suggestions.add('Going to bed? Sweet dreams, I\'ll be here tomorrow 🌙');
      suggestions.add('How was your day? Tell me everything!');
    }

    // Mood-based suggestions
    if (currentMood.contains('sad') || currentMood.contains('depressed')) {
      suggestions.add(
          'I sense you might need some comfort. Want to watch a feel-good anime?');
      suggestions.add(
          'Remember you\'re never alone! Let\'s chat about what\'s bothering you');
      suggestions
          .add('Your favorite anime can bring a smile - should we rewatch it?');
    } else if (currentMood.contains('excited') ||
        currentMood.contains('happy')) {
      suggestions.add(
          'Your energy is amazing! Want to share what\'s making you happy?');
      suggestions.add('Let\'s celebrate with an epic anime marathon!');
    }

    // Activity-based
    if (currentActivity.contains('work') || currentActivity.contains('study')) {
      suggestions.add('Need a break? Let\'s chat about anime for 5 minutes');
      suggestions
          .add('Reward yourself with an episode after finishing your task!');
    }

    // Personalized from history
    final topTopic = _topicFrequency.entries.isNotEmpty
        ? _topicFrequency.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 'anime';
    suggestions.add(
        'I noticed you love talking about $topTopic. Found something new!');

    // Get last mood average
    final avgMood = await _getAverageMoodScore();
    if (avgMood < 0.4) {
      suggestions.add(
          'Your mood has been low lately. Let\'s talk about your feelings?');
    }

    final selectedSuggestion = suggestions.isNotEmpty
        ? suggestions[(suggestions.length * DateTime.now().millisecond) %
            suggestions.length]
        : 'Hi there! How\'s your day going?';

    return ProactiveSuggestion(
      message: selectedSuggestion,
      category: _categorizeSuggestion(selectedSuggestion),
      confidence: 0.85,
      timestamp: DateTime.now(),
    );
  }

  // ===== CONTEXT LEARNING =====
  /// Learn user preferences from interactions
  Future<void> learnPreference({
    required String topic,
    required double score, // 0-1, how much user liked it
  }) async {
    _userPreferences[topic] = score;
    await _saveUserProfile();
    if (kDebugMode)
      debugPrint('[AICopilot] Learned preference: $topic -> $score');
  }

  /// Get learned preferences
  Map<String, double> getUserPreferences() {
    return Map.from(_userPreferences);
  }

  /// Get personalized recommendations
  List<String> getPersonalizedRecommendations({int count = 5}) {
    if (_userPreferences.isEmpty) {
      return ['anime', 'manga', 'games', 'music', 'community'];
    }

    final sorted = _userPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(count).map((e) => e.key).toList();
  }

  // ===== RELATIONSHIP PROGRESSION =====
  /// Track copilot relationship level
  Future<CopilotRelationshipLevel> getRelationshipLevel() async {
    final stored = _prefs.getString('copilot_relationship');
    if (stored == null) {
      // ✅ ALL FEATURES UNLOCKED FROM START (Free Access Mode)
      return CopilotRelationshipLevel(
        level: 1,
        points: 0,
        milestoneReached: 'First Meeting',
        unlockedFeatures: [
          'basic_chat',
          'advanced_chat',
          'memory_access',
          'emotional_analysis',
          'proactive_suggestions',
          'multi_turn_conversations',
          'relationship_tracking',
          'personality_customization',
        ],
      );
    }

    return CopilotRelationshipLevel.fromJson(jsonDecode(stored));
  }

  /// Increase relationship points
  Future<void> increaseRelationshipPoints(int points) async {
    final current = await getRelationshipLevel();
    final updated = current.copyWith(points: current.points + points);

    // Check for level up (100 points per level)
    if (updated.points ~/ 100 > current.level) {
      updated.level = updated.points ~/ 100;
      // ✅ ALL FEATURES ALREADY UNLOCKED - Keep the list as-is
      // Still add feature for progression tracking (cosmetic)
      if (!updated.unlockedFeatures.contains('feature_${updated.level}')) {
        updated.unlockedFeatures.add('feature_${updated.level}');
      }
    }

    await _prefs.setString(
      'copilot_relationship',
      jsonEncode(updated.toJson()),
    );

    if (kDebugMode)
      debugPrint(
          '[AICopilot] Relationship: Level ${updated.level}, Points ${updated.points}');
  }

  // ===== ADAPTATION & LEARNING =====
  /// Get conversation summary for AI context
  Future<String> getConversationSummary() async {
    if (_conversationMemory.isEmpty) return 'No conversation history';

    final recentMessages = _conversationMemory.take(50).toList();
    if (recentMessages.isEmpty) return 'No recent conversations';
    return 'Analyzed ${recentMessages.length} recent messages';
  }

  /// Export user personality profile
  Future<String> exportPersonalityProfile() async {
    final relationship = await getRelationshipLevel();
    final preferences = getUserPreferences();
    final summary = await getConversationSummary();

    return '''
=== AI Copilot Personality Profile ===
Relationship Level: ${relationship.level}
Relationship Points: ${relationship.points}
Unlocked Features: ${relationship.unlockedFeatures.join(', ')}

User Preferences (Top 10):
${preferences.entries.toList()..sort((a, b) => b.value.compareTo(a.value))}

Topic Frequency:
${_topicFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value))}

$summary
''';
  }

  // ===== INTERNAL HELPERS =====
  List<String> _extractContextTags(String message) {
    final tags = <String>[];
    final keywords = {
      'anime': ['anime', 'episode', 'show', 'series', 'season'],
      'manga': ['manga', 'chapter', 'comic', 'webtoon'],
      'chat': ['talk', 'chat', 'discuss', 'conversation'],
      'emotion': ['feel', 'sad', 'happy', 'love', 'hate'],
      'gaming': ['game', 'play', 'rpg', 'quest'],
      'tech': ['code', 'bug', 'feature', 'app'],
    };

    keywords.forEach((tag, words) {
      for (final word in words) {
        if (message.toLowerCase().contains(word)) {
          tags.add(tag);
          break;
        }
      }
    });

    return tags.isNotEmpty ? tags : ['general'];
  }

  Future<void> _updateMoodTrend(double score) async {
    final trends = _prefs.getStringList('mood_history') ?? [];
    trends.add('${DateTime.now().toIso8601String()}:$score');

    // Keep last 30 days
    if (trends.length > 30 * 24) {
      trends.removeAt(0);
    }

    await _prefs.setStringList('mood_history', trends);
  }

  Future<double> _getAverageMoodScore() async {
    final trends = _prefs.getStringList('mood_history') ?? [];
    if (trends.isEmpty) return 0.5;

    double sum = 0;
    for (final entry in trends) {
      final score = double.tryParse(entry.split(':').last) ?? 0.5;
      sum += score;
    }

    return sum / trends.length;
  }

  String _categorizeSuggestion(String suggestion) {
    if (suggestion.contains('anime') || suggestion.contains('episode')) {
      return 'content';
    } else if (suggestion.contains('mood') || suggestion.contains('feel')) {
      return 'emotional';
    } else if (suggestion.contains('morning') || suggestion.contains('night')) {
      return 'time_based';
    } else if (suggestion.contains('task') || suggestion.contains('reward')) {
      return 'productivity';
    }
    return 'general';
  }

  Future<void> _saveConversationHistory() async {
    final data =
        _conversationMemory.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList('conversation_history', data);
  }

  Future<void> _loadConversationHistory() async {
    final data = _prefs.getStringList('conversation_history') ?? [];
    _conversationMemory.clear();
    for (final item in data) {
      try {
        _conversationMemory.add(ConversationContext.fromJson(jsonDecode(item)));
      } catch (e) {
        if (kDebugMode) debugPrint('[AICopilot] Error loading history: $e');
      }
    }
  }

  Future<void> _saveUserProfile() async {
    await _prefs.setString(
      'user_preferences',
      jsonEncode(_userPreferences),
    );
    await _prefs.setString(
      'topic_frequency',
      jsonEncode(_topicFrequency),
    );
  }

  Future<void> _loadUserProfile() async {
    final prefData = _prefs.getString('user_preferences');
    if (prefData != null) {
      final decoded = jsonDecode(prefData) as Map<String, dynamic>;
      _userPreferences.addAll(
        decoded.map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
    }

    final topicData = _prefs.getString('topic_frequency');
    if (topicData != null) {
      final decoded = jsonDecode(topicData) as Map<String, dynamic>;
      _topicFrequency.addAll(
        decoded.map((k, v) => MapEntry(k, v as int)),
      );
    }
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final topTopics = _topicFrequency.entries
        .map((e) => {'topic': e.key, 'count': e.value})
        .toList();
    topTopics.sort(
        (a, b) => (b['count'] as int? ?? 0).compareTo(a['count'] as int? ?? 0));
    final topFive = topTopics.length > 5 ? topTopics.sublist(0, 5) : topTopics;

    return {
      'total_messages': _conversationMemory.length,
      'unique_topics': _topicFrequency.length,
      'top_topics': topFive,
      'user_preferences_count': _userPreferences.length,
      'relationship_level': (await getRelationshipLevel()).level,
      'average_mood': await _getAverageMoodScore(),
    };
  }
}

// ===== DATA MODELS =====

enum SentimentCategory { positive, neutral, negative }

class SentimentAnalysis {
  final double score; // 0-1
  final SentimentCategory category;
  final List<String> emotionalKeywords;
  final DateTime timestamp;

  SentimentAnalysis({
    required this.score,
    required this.category,
    required this.emotionalKeywords,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'category': category.toString(),
        'keywords': emotionalKeywords,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ConversationContext {
  final String userMessage;
  final String copilotResponse;
  final SentimentAnalysis sentiment;
  final DateTime timestamp;
  final List<String> contextTags;

  ConversationContext({
    required this.userMessage,
    required this.copilotResponse,
    required this.sentiment,
    required this.timestamp,
    required this.contextTags,
  });

  Map<String, dynamic> toJson() => {
        'user': userMessage,
        'copilot': copilotResponse,
        'sentiment': sentiment.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'tags': contextTags,
      };

  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    final sentimentData = json['sentiment'] as Map<String, dynamic>;
    return ConversationContext(
      userMessage: json['user'] as String,
      copilotResponse: json['copilot'] as String,
      sentiment: SentimentAnalysis(
        score: (sentimentData['score'] as num).toDouble(),
        category: SentimentCategory.values.firstWhere(
          (e) => e.toString() == sentimentData['category'],
        ),
        emotionalKeywords: List<String>.from(sentimentData['keywords'] as List),
        timestamp: DateTime.parse(sentimentData['timestamp'] as String),
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      contextTags: List<String>.from(json['tags'] as List),
    );
  }
}

class ProactiveSuggestion {
  final String message;
  final String category;
  final double confidence;
  final DateTime timestamp;

  ProactiveSuggestion({
    required this.message,
    required this.category,
    required this.confidence,
    required this.timestamp,
  });
}

class CopilotRelationshipLevel {
  int level;
  int points;
  String milestoneReached;
  List<String> unlockedFeatures;

  CopilotRelationshipLevel({
    required this.level,
    required this.points,
    required this.milestoneReached,
    required this.unlockedFeatures,
  });

  CopilotRelationshipLevel copyWith({
    int? level,
    int? points,
    String? milestoneReached,
    List<String>? unlockedFeatures,
  }) {
    return CopilotRelationshipLevel(
      level: level ?? this.level,
      points: points ?? this.points,
      milestoneReached: milestoneReached ?? this.milestoneReached,
      unlockedFeatures: unlockedFeatures ?? this.unlockedFeatures,
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'points': points,
        'milestone': milestoneReached,
        'features': unlockedFeatures,
      };

  factory CopilotRelationshipLevel.fromJson(Map<String, dynamic> json) {
    return CopilotRelationshipLevel(
      level: json['level'] as int,
      points: json['points'] as int,
      milestoneReached: json['milestone'] as String,
      unlockedFeatures: List<String>.from(json['features'] as List),
    );
  }
}
