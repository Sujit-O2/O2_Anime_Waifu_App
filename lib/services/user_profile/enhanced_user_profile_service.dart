import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced User Profile Service
/// Advanced personalization, AI persona training, preference learning
class EnhancedUserProfileService {
  static final EnhancedUserProfileService _instance = EnhancedUserProfileService._internal();

  factory EnhancedUserProfileService() {
    return _instance;
  }

  EnhancedUserProfileService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;
  late UserProfile _profile;
  final Map<String, PersonaTraits> _personaTraining = {};
  final Map<String, double> _behaviorPatterns = {};

  // ===== PROFILE MANAGEMENT =====
  Future<UserProfile> getProfile() async {
    return _profile;
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
    String? favoriteAnime,
    DateTime? joinDate,
  }) async {
    _profile.name = name ?? _profile.name;
    _profile.bio = bio ?? _profile.bio;
    _profile.avatarUrl = avatarUrl ?? _profile.avatarUrl;
    _profile.favoriteAnime = favoriteAnime ?? _profile.favoriteAnime;
    _profile.joinDate = joinDate ?? _profile.joinDate;
    _profile.lastUpdated = DateTime.now();

    await _saveProfile();
    if (kDebugMode) debugPrint('[UserProfile] Profile updated');
  }

  // ===== AI PERSONA TRAINING =====
  /// Record user interaction for persona learning
  Future<void> recordInteraction({
    required String category, // 'communication', 'preference', 'behavior'
    required String action,
    required double value, // 0-1 scale
    required String context,
  }) async {
    final trait = PersonaTraits(
      category: category,
      action: action,
      value: value,
      context: context,
      timestamp: DateTime.now(),
      weight: 1.0,
    );

    final key = '$category:$action';
    _personaTraining[key] = trait;

    // Update aggregated behavior patterns
    _behaviorPatterns[action] = (_behaviorPatterns[action] ?? 0.5) * 0.8 + value * 0.2;

    await _savePersonaTraining();
    if (kDebugMode) debugPrint('[UserProfile] Recorded: $category -> $action ($value)');
  }

  /// Get trained persona traits
  Future<Map<String, PersonaTraits>> getPersonaTraits() async {
    return Map.from(_personaTraining);
  }

  /// Get dominant personality characteristics
  Future<PersonalityProfile> generatePersonalityProfile() async {
    if (_personaTraining.isEmpty) {
      return PersonalityProfile.default_();
    }

    final traits = await getPersonaTraits();
    double communication = 0, preference = 0, behavior = 0;
    int commCount = 0, prefCount = 0, behavCount = 0;

    for (final trait in traits.values) {
      switch (trait.category) {
        case 'communication':
          communication += trait.value;
          commCount++;
          break;
        case 'preference':
          preference += trait.value;
          prefCount++;
          break;
        case 'behavior':
          behavior += trait.value;
          behavCount++;
          break;
      }
    }

    return PersonalityProfile(
      communicationStyle: commCount > 0 ? communication / commCount : 0.5,
      preferencePattern: prefCount > 0 ? preference / prefCount : 0.5,
      behaviorPattern: behavCount > 0 ? behavior / behavCount : 0.5,
      dominantTrait: _getDominantTrait(),
      matchedTypes: _analyzePersonalityType(),
    );
  }

  // ===== PREFERENCE LEARNING =====
  /// Record preference learning
  Future<void> learnPreference({
    required String category,
    required String item,
    required double score, // 0-1, higher = more preferred
  }) async {
    final key = '$category:$item';
    _profile.preferences[key] = score;
    _profile.lastUpdated = DateTime.now();

    // Also record as behavior pattern
    _behaviorPatterns[item] = score;

    await _saveProfile();
    if (kDebugMode) debugPrint('[UserProfile] Learned preference: $category -> $item ($score)');
  }

  /// Get recommendations based on learned preferences
  Future<List<String>> getRecommendations({
    required String category,
    int count = 5,
  }) async {
    final categoryPrefs = _profile.preferences.entries
        .where((e) => e.key.startsWith('$category:'))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return categoryPrefs
        .take(count)
        .map((e) => e.key.replaceFirst('$category:', ''))
        .toList();
  }

  // ===== ADAPTIVE BEHAVIOR =====
  /// Get user's current mood/state
  Future<String> getCurrentState() async {
    final avgMood = _profile.moodHistory.isNotEmpty
        ? _profile.moodHistory.values.fold<double>(0, (a, b) => a + b) / _profile.moodHistory.length
        : 0.5;

    if (avgMood > 0.7) return 'happy';
    if (avgMood > 0.5) return 'neutral';
    return 'sad';
  }

  /// Update user mood
  Future<void> updateMood(double mood) async {
    // 0-1 scale, 0=sad, 1=happy
    _profile.moodHistory[DateTime.now().toString()] = mood;
    
    // Keep last 30 moods
    if (_profile.moodHistory.length > 30) {
      _profile.moodHistory.remove(_profile.moodHistory.keys.first);
    }

    await _saveProfile();
    if (kDebugMode) debugPrint('[UserProfile] Mood updated: $mood');
  }

  /// Get mood trend
  Future<MoodTrend> getMoodTrend() async {
    if (_profile.moodHistory.isEmpty) {
      return MoodTrend(
        average: 0.5,
        trend: 'stable',
        recentMoods: [],
      );
    }

    final moods = _profile.moodHistory.values.toList();
    final average = moods.fold<double>(0, (a, b) => a + b) / moods.length;
    
    String trend = 'stable';
    if (moods.length > 5) {
      final recent = moods.sublist(moods.length - 5);
      final avgRecent = recent.fold<double>(0, (a, b) => a + b) / recent.length;
      if (avgRecent > average + 0.1) {
        trend = 'improving';
      } else if (avgRecent < average - 0.1) {
        trend = 'declining';
      }
    }

    return MoodTrend(
      average: average,
      trend: trend,
      recentMoods: moods.sublist(moods.length - 5).toList(),
    );
  }

  // ===== ACTIVITY TRACKING =====
  /// Record activity
  Future<void> recordActivity(String activity, {Map<String, dynamic>? metadata}) async {
    _profile.activityLog.add(
      ActivityRecord(
        activity: activity,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      ),
    );

    // Keep last 1000 activities
    if (_profile.activityLog.length > 1000) {
      _profile.activityLog.removeAt(0);
    }

    await _saveProfile();
  }

  /// Get activity statistics
  Future<ActivityStats> getActivityStats() async {
    final stats = <String, int>{};
    
    for (final record in _profile.activityLog) {
      stats[record.activity] = (stats[record.activity] ?? 0) + 1;
    }

    stats.entries.toList().sort((a, b) => b.value.compareTo(a.value));

    return ActivityStats(
      totalActivities: _profile.activityLog.length,
      uniqueActivities: stats.length,
      topActivities: stats.entries.take(5).map((e) => e.key).toList(),
      activityBreakdown: stats,
    );
  }

  // ===== ACHIEVEMENT TRACKING =====
  /// Unlock achievement
  Future<void> unlockAchievement(String id, String title, String description) async {
    final achievement = Achievement(
      id: id,
      title: title,
      description: description,
      unlockedAt: DateTime.now(),
      rarity: _calculateRarity(),
    );

    _profile.achievements.add(achievement);
    if (kDebugMode) debugPrint('[UserProfile] Achievement unlocked: $title');
  }

  Future<List<Achievement>> getAchievements() async {
    return _profile.achievements;
  }

  /// Get achievement progress
  Future<String> getAchievementProgress() async {
    return 'Achievements: ${_profile.achievements.length} unlocked';
  }

  // ===== STATISTICS =====
  Future<UserStatistics> generateStatistics() async {
    final personalityProfile = await generatePersonalityProfile();
    final activityStats = await getActivityStats();
    final moodTrend = await getMoodTrend();

    return UserStatistics(
      profileAge: DateTime.now().difference(_profile.joinDate),
      totalActivities: activityStats.totalActivities,
      achievementsCount: _profile.achievements.length,
      personalityProfile: personalityProfile,
      moodAverage: moodTrend.average,
      moodTrend: moodTrend.trend,
      topInterests: await getRecommendations(category: 'anime', count: 3),
      generatedAt: DateTime.now(),
    );
  }

  /// Export user data
  Future<String> exportUserData() async {
    final stats = await generateStatistics();
    final personalityProfile = await generatePersonalityProfile();

    return '''
=== USER PROFILE EXPORT ===
Generated: ${DateTime.now()}

BASIC INFO:
- Name: ${_profile.name}
- Bio: ${_profile.bio}
- Member Since: ${_profile.joinDate}
- Favorite Anime: ${_profile.favoriteAnime}

PERSONALITY:
- Communication Style: ${personalityProfile.communicationStyle.toStringAsFixed(2)}
- Preference Pattern: ${personalityProfile.preferencePattern.toStringAsFixed(2)}
- Behavior Pattern: ${personalityProfile.behaviorPattern.toStringAsFixed(2)}
- Dominant Trait: ${personalityProfile.dominantTrait}
- Personality Types: ${personalityProfile.matchedTypes.join(', ')}

MOOD:
- Average Mood: ${stats.moodAverage.toStringAsFixed(2)}
- Trend: ${stats.moodTrend}

ACTIVITY:
- Total Activities: ${stats.totalActivities}
- Achievements: ${stats.achievementsCount}
- Top Interests: ${stats.topInterests.join(', ')}

ACCOUNT AGE:
- Days: ${stats.profileAge.inDays}
- Duration: ${stats.profileAge.inDays ~/ 365} years, ${(stats.profileAge.inDays % 365) ~/ 30} months
''';
  }

  // ===== INTERNAL HELPERS =====
  String _getDominantTrait() {
    if (_personaTraining.isEmpty) return 'balanced';
    
    final traits = _personaTraining.values.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return traits.first.action;
  }

  List<String> _analyzePersonalityType() {
    final types = <String>[];
    final comm = _personaTraining.values
        .where((t) => t.category == 'communication')
        .fold<double>(0, (a, b) => a + b.value) / 3;

    if (comm > 0.6) types.add('Communicative');
    if (comm < 0.4) types.add('Reserved');
    
    types.add('Analytical');
    return types;
  }

  String _calculateRarity() {
    final random = DateTime.now().millisecond % 100;
    if (random < 20) return 'common';
    if (random < 50) return 'uncommon';
    if (random < 75) return 'rare';
    if (random < 90) return 'epic';
    return 'mythic';
  }

  Future<void> _saveProfile() async {
    await _prefs.setString('user_profile', jsonEncode(_profile.toJson()));
  }

  Future<void> _loadProfile() async {
    final stored = _prefs.getString('user_profile');
    if (stored != null) {
      try {
        _profile = UserProfile.fromJson(jsonDecode(stored));
      } catch (e) {
        _profile = UserProfile.empty();
      }
    } else {
      _profile = UserProfile.empty();
    }
  }

  Future<void> _savePersonaTraining() async {
    final data = _personaTraining.entries
        .map((e) => jsonEncode({
          'key': e.key,
          'value': e.value.toJson(),
        }))
        .toList();
    await _prefs.setStringList('persona_training', data);
  }

  Future<void> _loadPersonaTraining() async {
    // Placeholder for persona training load
    if (!_initialized) return;
    final data = _prefs.getStringList('persona_training') ?? [];
    for (final item in data) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final trait = PersonaTraits.fromJson(decoded['value'] as Map<String, dynamic>);
        _personaTraining[decoded['key'] as String] = trait;
      } catch (e) {
        if (kDebugMode) debugPrint('[UserProfile] Error loading persona: $e');
      }
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _prefs = await SharedPreferences.getInstance();
    await _loadProfile();
    await _loadPersonaTraining();
  }
}

// ===== DATA MODELS =====

class UserProfile {
  String name;
  String bio;
  String? avatarUrl;
  String? favoriteAnime;
  DateTime joinDate;
  DateTime lastUpdated;
  Map<String, double> preferences; // category:item -> score
  Map<String, double> moodHistory; // timestamp -> mood
  List<ActivityRecord> activityLog;
  List<Achievement> achievements;

  UserProfile({
    required this.name,
    required this.bio,
    this.avatarUrl,
    this.favoriteAnime,
    required this.joinDate,
    required this.lastUpdated,
    required this.preferences,
    required this.moodHistory,
    required this.activityLog,
    required this.achievements,
  });

  factory UserProfile.empty() {
    return UserProfile(
      name: 'User',
      bio: '',
      joinDate: DateTime.now(),
      lastUpdated: DateTime.now(),
      preferences: {},
      moodHistory: {},
      activityLog: [],
      achievements: [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'bio': bio,
    'avatar': avatarUrl,
    'favorite': favoriteAnime,
    'joinDate': joinDate.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'preferences': preferences,
    'moods': moodHistory,
    'activities': activityLog.map((a) => a.toJson()).toList(),
    'achievements': achievements.map((a) => a.toJson()).toList(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'User',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar'] as String?,
      favoriteAnime: json['favorite'] as String?,
      joinDate: DateTime.parse(json['joinDate'] as String? ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String? ?? DateTime.now().toIso8601String()),
      preferences: Map<String, double>.from((json['preferences'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ?? {}),
      moodHistory: Map<String, double>.from((json['moods'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ?? {}),
      activityLog: ((json['activities'] as List?) ?? [])
          .map((a) => ActivityRecord.fromJson(a as Map<String, dynamic>))
          .toList(),
      achievements: ((json['achievements'] as List?) ?? [])
          .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PersonaTraits {
  final String category;
  final String action;
  final double value;
  final String context;
  final DateTime timestamp;
  double weight;

  PersonaTraits({
    required this.category,
    required this.action,
    required this.value,
    required this.context,
    required this.timestamp,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'action': action,
    'value': value,
    'context': context,
    'timestamp': timestamp.toIso8601String(),
    'weight': weight,
  };

  factory PersonaTraits.fromJson(Map<String, dynamic> json) {
    return PersonaTraits(
      category: json['category'] as String,
      action: json['action'] as String,
      value: (json['value'] as num).toDouble(),
      context: json['context'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      weight: (json['weight'] as num).toDouble(),
    );
  }
}

class PersonalityProfile {
  final double communicationStyle;
  final double preferencePattern;
  final double behaviorPattern;
  final String dominantTrait;
  final List<String> matchedTypes;

  PersonalityProfile({
    required this.communicationStyle,
    required this.preferencePattern,
    required this.behaviorPattern,
    required this.dominantTrait,
    required this.matchedTypes,
  });

  factory PersonalityProfile.default_() {
    return PersonalityProfile(
      communicationStyle: 0.5,
      preferencePattern: 0.5,
      behaviorPattern: 0.5,
      dominantTrait: 'balanced',
      matchedTypes: ['Neutral', 'Observant'],
    );
  }
}

class MoodTrend {
  final double average;
  final String trend; // improving, stable, declining
  final List<double> recentMoods;

  MoodTrend({
    required this.average,
    required this.trend,
    required this.recentMoods,
  });
}

class ActivityRecord {
  final String activity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ActivityRecord({
    required this.activity,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'activity': activity,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      activity: json['activity'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final DateTime unlockedAt;
  final String rarity;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockedAt,
    required this.rarity,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'unlockedAt': unlockedAt.toIso8601String(),
    'rarity': rarity,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      rarity: json['rarity'] as String,
    );
  }
}

class ActivityStats {
  final int totalActivities;
  final int uniqueActivities;
  final List<String> topActivities;
  final Map<String, int> activityBreakdown;

  ActivityStats({
    required this.totalActivities,
    required this.uniqueActivities,
    required this.topActivities,
    required this.activityBreakdown,
  });
}

class UserStatistics {
  final Duration profileAge;
  final int totalActivities;
  final int achievementsCount;
  final PersonalityProfile personalityProfile;
  final double moodAverage;
  final String moodTrend;
  final List<String> topInterests;
  final DateTime generatedAt;

  UserStatistics({
    required this.profileAge,
    required this.totalActivities,
    required this.achievementsCount,
    required this.personalityProfile,
    required this.moodAverage,
    required this.moodTrend,
    required this.topInterests,
    required this.generatedAt,
  });
}


