import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Advanced Personalization Engine
/// AI-driven personalization, dynamic UI, predictive content
class AdvancedPersonalizationEngine {
  static final AdvancedPersonalizationEngine _instance = AdvancedPersonalizationEngine._internal();

  factory AdvancedPersonalizationEngine() {
    return _instance;
  }

  AdvancedPersonalizationEngine._internal();

  late SharedPreferences _prefs;
  late PersonalizationProfile _profile;
  final Map<String, InteractionPattern> _patterns = {};
  final List<String> _predictedInterests = [];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProfile();
    await _analyzePatterns();
    debugPrint('[Personalization] Service initialized');
  }

  // ===== PERSONALIZATION PROFILE =====
  /// Get personalization profile
  Future<PersonalizationProfile> getProfile() async {
    return _profile;
  }

  /// Update personalization based on interaction
  Future<void> recordInteraction({
    required String contentType, // 'anime', 'character', 'theme', 'feature'
    required String contentId,
    required String action, // 'view', 'like', 'share', 'complete'
    required int duration, // time spent in seconds
  }) async {
    final key = '$contentType:$contentId';
    final pattern = _patterns[key] ?? InteractionPattern(
      contentType: contentType,
      contentId: contentId,
      interactionCount: 0,
      totalTimeSpent: 0,
      lastInteracted: DateTime.now(),
      engagement: 0.5,
    );

    pattern.interactionCount++;
    pattern.totalTimeSpent += duration;
    pattern.lastInteracted = DateTime.now();
    pattern.engagement = _calculateEngagement(pattern);

    _patterns[key] = pattern;
    await _savePatterns();

    // Update profile
    await _updateProfile();
  }

  // ===== DYNAMIC UI PERSONALIZATION =====
  /// Get personalized UI configuration
  Future<UIConfiguration> getPersonalizedUI() async {
    return UIConfiguration(
      preferenceLayout: _profile.preferredLayout,
      colorScheme: _profile.preferredColorScheme,
      animationIntensity: _profile.animationPreference,
      contentOrder: _generateContentOrder(),
      hiddenFeatures: _profile.hiddenFeatures,
      pinnedItems: _profile.pinnedItems,
    );
  }

  /// Get color scheme preference
  Future<String> getPreferredColorScheme() async {
    return _profile.preferredColorScheme;
  }

  /// Set color scheme preference
  Future<void> setColorScheme(String scheme) async {
    _profile.preferredColorScheme = scheme;
    await _saveProfile();
  }

  /// Get animation intensity preference
  Future<double> getAnimationIntensity() async {
    return _profile.animationPreference;
  }

  /// Customize layout
  Future<void> customizeLayout(String layout) async {
    _profile.preferredLayout = layout;
    await _saveProfile();
  }

  // ===== CONTENT PREDICTION =====
  /// Predict next content user will be interested in
  Future<List<String>> predictNextContent({int count = 10}) async {
    // Analyze patterns to predict
    final sorted = _patterns.values.toList()
      ..sort((a, b) => b.engagement.compareTo(a.engagement));

    final predictions = <String>[];
    final predicted = <String>{};

    // Recommend similar content based on top interests
    for (final pattern in sorted.take(5)) {
      // In real implementation, would query backend for similar content
      final similar = await _findSimilarContent(pattern.contentType, pattern.contentId);
      for (final item in similar) {
        if (!predicted.contains(item) && predictions.length < count) {
          predictions.add(item);
          predicted.add(item);
        }
      }
    }

    _predictedInterests.clear();
    _predictedInterests.addAll(predictions);
    return predictions;
  }

  /// Get recommended anime for user
  Future<List<String>> getRecommendedAnime({int count = 5}) async {
    final predictions = await predictNextContent(count: count);
    return predictions;
  }

  /// Get trending content matching user preferences
  Future<List<String>> getTrendingForYou() async {
    final interests = _profile.topInterests;
    return [
      'Trending in ${interests.isNotEmpty ? interests.first : 'Anime'}',
      'Top rated this week',
      'New releases you might like',
    ];
  }

  // ===== ADAPTIVE BEHAVIOR =====
  /// Get adaptive recommendation message
  Future<String> getAdaptiveMessage(String messageType) async {
    final baseMsg = _getBaseMessage(messageType);
    
    // Personalize based on profile
    if (_profile.topInterests.isNotEmpty) {
      return baseMsg.replaceFirst('{interest}', _profile.topInterests.first);
    }
    return baseMsg;
  }

  /// Predict user availability
  Future<String> predictUserAvailability() async {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 9) return 'morning';
    if (hour >= 9 && hour < 18) return 'daytime';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'late_night';
  }

  /// Get time-appropriate suggestion
  Future<String> getTimeAppropriateContent() async {
    final availability = await predictUserAvailability();
    
    switch (availability) {
      case 'morning':
        return 'Start your day with an inspiring anime episode! 🌅';
      case 'daytime':
        return 'Quick break? Try this short anime scene! ⚡';
      case 'evening':
        return 'Wind down with your favorite anime 🌙';
      case 'late_night':
        return 'Night owl? Let\'s watch something engaging! 🌟';
      default:
        return 'Want to watch something now?';
    }
  }

  // ===== BEHAVIOR ANALYSIS =====
  /// Analyze user behavior patterns
  Future<BehaviorAnalysis> analyzeBehavior() async {
    if (_patterns.isEmpty) {
      return BehaviorAnalysis(
        avgSessionDuration: 0,
        mostActiveTime: 'unknown',
        preferredContentType: 'unknown',
        engagementScore: 0.5,
        loyaltyScore: 0.0,
      );
    }

    final avgDuration = _patterns.values.fold<int>(0, (a, b) => a + b.totalTimeSpent) ~/ _patterns.length;
    final byType = <String, double>{};
    
    for (final pattern in _patterns.values) {
      byType[pattern.contentType] = (byType[pattern.contentType] ?? 0) + pattern.engagement;
    }

    final preferredType = byType.entries.isNotEmpty
        ? byType.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'unknown';

    final avgEngagement = _patterns.values.fold<double>(0, (a, b) => a + b.engagement) / _patterns.length;

    return BehaviorAnalysis(
      avgSessionDuration: avgDuration,
      mostActiveTime: await predictUserAvailability(),
      preferredContentType: preferredType,
      engagementScore: avgEngagement,
      loyaltyScore: (_patterns.length / 100).clamp(0.0, 1.0),
    );
  }

  // ===== PERSONALIZATION STATISTICS =====
  Future<String> generatePersonalizationReport() async {
    final analysis = await analyzeBehavior();
    final topInterests = _profile.topInterests.take(5);
    final predictions = await predictNextContent(count: 5);

    return '''
=== PERSONALIZATION REPORT ===
Generated: ${DateTime.now()}

BEHAVIOR PROFILE:
- Avg Session Duration: ${analysis.avgSessionDuration} seconds
- Most Active: ${analysis.mostActiveTime}
- Preferred Content: ${analysis.preferredContentType}
- Engagement Score: ${(analysis.engagementScore * 100).toStringAsFixed(1)}%
- Loyalty Score: ${(analysis.loyaltyScore * 100).toStringAsFixed(1)}%

TOP INTERESTS:
${topInterests.map((i) => '- $i').join('\n')}

PREDICTED NEXT INTERESTS:
${predictions.take(5).map((p) => '- $p').join('\n')}

UI PREFERENCES:
- Layout: ${_profile.preferredLayout}
- Color Scheme: ${_profile.preferredColorScheme}
- Animation Intensity: ${(_profile.animationPreference * 100).toStringAsFixed(0)}%

PERSONALIZATION FEATURES ENABLED:
${_profile.enabledFeatures.map((f) => '✓ $f').join('\n')}
''';
  }

  // ===== INTERNAL HELPERS =====
  double _calculateEngagement(InteractionPattern pattern) {
    // Simple engagement formula
    final interactionScore = (pattern.interactionCount / 10).clamp(0.0, 1.0);
    final durationScore = (pattern.totalTimeSpent / 3600).clamp(0.0, 1.0);
    return (interactionScore * 0.6 + durationScore * 0.4).clamp(0.0, 1.0);
  }

  Future<void> _updateProfile() async {
    // Recalculate top interests
    final sorted = _patterns.values.toList()
      ..sort((a, b) => b.engagement.compareTo(a.engagement));

    _profile.topInterests = sorted.take(5).map((p) => p.contentId).toList();
    await _saveProfile();
  }

  Future<List<String>> _findSimilarContent(String type, String id) async {
    // In real implementation, would query backend
    return ['similar_$type:$id:1', 'similar_$type:$id:2', 'similar_$type:$id:3'];
  }

  List<String> _generateContentOrder() {
    // Return content order based on preferences
    return _profile.topInterests;
  }

  String _getBaseMessage(String type) {
    switch (type) {
      case 'greeting':
        return 'Welcome back! Ready to explore {interest}?';
      case 'suggestion':
        return 'Based on your interests, try this {interest}!';
      default:
        return 'Excited to see you! 🌟';
    }
  }

  Future<void> _analyzePatterns() async {
    // Analyze stored patterns to extract insights
    if (_patterns.isNotEmpty) {
      final sorted = _patterns.values.toList()
        ..sort((a, b) => b.engagement.compareTo(a.engagement));
      
      _profile.topInterests = sorted.take(5).map((p) => p.contentId).toList();
    }
  }

  Future<void> _saveProfile() async {
    await _prefs.setString('personalization_profile', jsonEncode(_profile.toJson()));
  }

  Future<void> _loadProfile() async {
    final stored = _prefs.getString('personalization_profile');
    if (stored != null) {
      try {
        _profile = PersonalizationProfile.fromJson(jsonDecode(stored));
      } catch (e) {
        _profile = PersonalizationProfile.default_();
      }
    } else {
      _profile = PersonalizationProfile.default_();
    }
  }

  Future<void> _savePatterns() async {
    final data = _patterns.entries
        .map((e) => jsonEncode({
          'key': e.key,
          'value': e.value.toJson(),
        }))
        .toList();
    await _prefs.setStringList('interaction_patterns', data);
  }
}

// ===== DATA MODELS =====

class PersonalizationProfile {
  String preferredLayout;
  String preferredColorScheme;
  double animationPreference;
  List<String> topInterests;
  List<String> hiddenFeatures;
  List<String> pinnedItems;
  List<String> enabledFeatures;

  PersonalizationProfile({
    required this.preferredLayout,
    required this.preferredColorScheme,
    required this.animationPreference,
    required this.topInterests,
    required this.hiddenFeatures,
    required this.pinnedItems,
    required this.enabledFeatures,
  });

  factory PersonalizationProfile.default_() {
    return PersonalizationProfile(
      preferredLayout: 'standard',
      preferredColorScheme: 'dark',
      animationPreference: 0.8,
      topInterests: [],
      hiddenFeatures: [],
      pinnedItems: [],
      enabledFeatures: ['recommendations', 'adaptive_ui', 'predictive_content'],
    );
  }

  Map<String, dynamic> toJson() => {
    'layout': preferredLayout,
    'colorScheme': preferredColorScheme,
    'animation': animationPreference,
    'interests': topInterests,
    'hidden': hiddenFeatures,
    'pinned': pinnedItems,
    'enabled': enabledFeatures,
  };

  factory PersonalizationProfile.fromJson(Map<String, dynamic> json) {
    return PersonalizationProfile(
      preferredLayout: json['layout'] as String? ?? 'standard',
      preferredColorScheme: json['colorScheme'] as String? ?? 'dark',
      animationPreference: (json['animation'] as num?)?.toDouble() ?? 0.8,
      topInterests: List<String>.from(json['interests'] as List? ?? []),
      hiddenFeatures: List<String>.from(json['hidden'] as List? ?? []),
      pinnedItems: List<String>.from(json['pinned'] as List? ?? []),
      enabledFeatures: List<String>.from(json['enabled'] as List? ?? []),
    );
  }
}

class InteractionPattern {
  final String contentType;
  final String contentId;
  int interactionCount;
  int totalTimeSpent;
  DateTime lastInteracted;
  double engagement;

  InteractionPattern({
    required this.contentType,
    required this.contentId,
    required this.interactionCount,
    required this.totalTimeSpent,
    required this.lastInteracted,
    required this.engagement,
  });

  Map<String, dynamic> toJson() => {
    'contentType': contentType,
    'contentId': contentId,
    'interactions': interactionCount,
    'timeSpent': totalTimeSpent,
    'lastInteracted': lastInteracted.toIso8601String(),
    'engagement': engagement,
  };

  factory InteractionPattern.fromJson(Map<String, dynamic> json) {
    return InteractionPattern(
      contentType: json['contentType'] as String,
      contentId: json['contentId'] as String,
      interactionCount: json['interactions'] as int? ?? 0,
      totalTimeSpent: json['timeSpent'] as int? ?? 0,
      lastInteracted: DateTime.parse(json['lastInteracted'] as String? ?? DateTime.now().toIso8601String()),
      engagement: (json['engagement'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class UIConfiguration {
  final String preferenceLayout;
  final String colorScheme;
  final double animationIntensity;
  final List<String> contentOrder;
  final List<String> hiddenFeatures;
  final List<String> pinnedItems;

  UIConfiguration({
    required this.preferenceLayout,
    required this.colorScheme,
    required this.animationIntensity,
    required this.contentOrder,
    required this.hiddenFeatures,
    required this.pinnedItems,
  });
}

class BehaviorAnalysis {
  final int avgSessionDuration;
  final String mostActiveTime;
  final String preferredContentType;
  final double engagementScore;
  final double loyaltyScore;

  BehaviorAnalysis({
    required this.avgSessionDuration,
    required this.mostActiveTime,
    required this.preferredContentType,
    required this.engagementScore,
    required this.loyaltyScore,
  });
}


