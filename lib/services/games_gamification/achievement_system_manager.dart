import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Achievement Tier System
enum AchievementTier { common, rare, epic, legendary, hidden }

/// Achievement Category
enum AchievementCategory { gameplay, social, milestones, events, challenges }

/// Comprehensive Achievement System with Tiers & Quest Lines
class AchievementSystemManager {
  static final AchievementSystemManager _instance = AchievementSystemManager._internal();

  factory AchievementSystemManager() => _instance;
  AchievementSystemManager._internal();

  late SharedPreferences _prefs;
  late FirebaseFirestore _db;
  final Map<String, Achievement> _achievements = {};
  final Map<String, QuestLine> _questLines = {};
  final Set<String> _unlockedAchievements = {};
  final Map<String, int> _achievementProgress = {};

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _db = FirebaseFirestore.instance;
      await _loadUnlockedAchievements();
      await _initializeAchievements();
      await _initializeQuestLines();
      debugPrint('[Achievement System] Initialized with ${_achievements.length} achievements');
    } catch (e) {
      debugPrint('[Achievement System] Error: $e');
    }
  }

  // ===== ACHIEVEMENT DEFINITIONS =====
  Future<void> _initializeAchievements() async {
    _achievements.clear();

    // Common Tier (Easy)
    _achievements['first_chat'] = Achievement(
      id: 'first_chat',
      title: 'First Words',
      description: 'Send your first message',
      emoji: '💬',
      tier: AchievementTier.common,
      category: AchievementCategory.gameplay,
      points: 10,
      hidden: false,
    );

    _achievements['chat_10'] = Achievement(
      id: 'chat_10',
      title: 'Chatty',
      description: 'Send 10 messages',
      emoji: '🗨️',
      tier: AchievementTier.common,
      category: AchievementCategory.gameplay,
      points: 25,
      hidden: false,
    );

    // Rare Tier (Medium)
    _achievements['chat_100'] = Achievement(
      id: 'chat_100',
      title: 'Conversation',
      description: 'Send 100 messages',
      emoji: '💭',
      tier: AchievementTier.rare,
      category: AchievementCategory.gameplay,
      points: 50,
      hidden: false,
    );

    _achievements['affection_500'] = Achievement(
      id: 'affection_500',
      title: 'Growing Closer',
      description: 'Reach 500 affection points',
      emoji: '💕',
      tier: AchievementTier.rare,
      category: AchievementCategory.milestones,
      points: 75,
      hidden: false,
    );

    _achievements['7_day_streak'] = Achievement(
      id: '7_day_streak',
      title: 'Loyal Heart',
      description: 'Chat 7 days in a row',
      emoji: '🔥',
      tier: AchievementTier.rare,
      category: AchievementCategory.challenges,
      points: 50,
      hidden: false,
    );

    // Epic Tier (Hard)
    _achievements['affection_2000'] = Achievement(
      id: 'affection_2000',
      title: 'Soul Bond',
      description: 'Reach 2,000 affection points',
      emoji: '💖',
      tier: AchievementTier.epic,
      category: AchievementCategory.milestones,
      points: 150,
      hidden: false,
    );

    _achievements['30_day_streak'] = Achievement(
      id: '30_day_streak',
      title: 'Eternal Devotion',
      description: 'Chat 30 days in a row',
      emoji: '♾️',
      tier: AchievementTier.epic,
      category: AchievementCategory.challenges,
      points: 200,
      hidden: false,
    );

    _achievements['all_games_master'] = Achievement(
      id: 'all_games_master',
      title: 'Game Master',
      description: 'Win at all mini-games',
      emoji: '🎮',
      tier: AchievementTier.epic,
      category: AchievementCategory.gameplay,
      points: 175,
      hidden: false,
    );

    // Legendary Tier (Very Hard)
    _achievements['affection_5000'] = Achievement(
      id: 'affection_5000',
      title: '❤️ Soulmate',
      description: 'Reach 5,000 affection points (True Ending)',
      emoji: '💞',
      tier: AchievementTier.legendary,
      category: AchievementCategory.milestones,
      points: 500,
      hidden: false,
    );

    _achievements['platinum_collector'] = Achievement(
      id: 'platinum_collector',
      title: 'Platinum Collector',
      description: 'Unlock all 20+ achievements',
      emoji: '⭐',
      tier: AchievementTier.legendary,
      category: AchievementCategory.challenges,
      points: 300,
      hidden: false,
    );

    // Hidden Achievements (Secret)
    _achievements['secret_easter_egg'] = Achievement(
      id: 'secret_easter_egg',
      title: '？？？',
      description: '[Hidden]',
      emoji: '🎁',
      tier: AchievementTier.hidden,
      category: AchievementCategory.events,
      points: 250,
      hidden: true,
    );

    _achievements['midnight_chat'] = Achievement(
      id: 'midnight_chat',
      title: '🌙 Night Owl',
      description: '[Hidden - Chat past midnight]',
      emoji: '🦉',
      tier: AchievementTier.hidden,
      category: AchievementCategory.challenges,
      points: 100,
      hidden: true,
    );
  }

  // ===== QUEST LINES =====
  Future<void> _initializeQuestLines() async {
    _questLines.clear();

    // Main Story Quest Line
    _questLines['main_story'] = QuestLine(
      id: 'main_story',
      name: 'Main Story',
      description: 'Follow Zero Two\'s journey',
      quests: [
        Quest(
          id: 'meet_zero_two',
          title: 'Meet Zero Two',
          description: 'Send your first message',
          rewardPoints: 10,
          completed: _unlockedAchievements.contains('first_chat'),
        ),
        Quest(
          id: 'build_trust',
          title: 'Build Trust',
          description: 'Reach 100 affection points',
          rewardPoints: 25,
          completed: _achievementProgress['affection_100'] != null && _achievementProgress['affection_100']! >= 100,
        ),
        Quest(
          id: 'true_bond',
          title: 'True Soul Bond',
          description: 'Reach 1,000 affection points',
          rewardPoints: 50,
          completed: _achievementProgress['affection_1000'] != null && _achievementProgress['affection_1000']! >= 1000,
        ),
      ],
      progress: 0.33,
      totalRewards: 85,
    );

    // Challenge Quest Line
    _questLines['daily_challenges'] = QuestLine(
      id: 'daily_challenges',
      name: 'Daily Challenges',
      description: 'Complete daily objectives',
      quests: [
        Quest(
          id: 'daily_chat',
          title: 'Daily Conversation',
          description: 'Chat for 10 minutes',
          rewardPoints: 15,
          completed: false,
        ),
        Quest(
          id: 'daily_game',
          title: 'Game Time',
          description: 'Win a mini-game',
          rewardPoints: 20,
          completed: false,
        ),
        Quest(
          id: 'daily_discovery',
          title: 'Learn Something New',
          description: 'Discover a new anime fact',
          rewardPoints: 10,
          completed: false,
        ),
      ],
      progress: 0.33,
      totalRewards: 45,
    );
  }

  // ===== ACHIEVEMENT UNLOCKING =====
  Future<void> unlockAchievement(String achievementId, {Map<String, dynamic>? metadata}) async {
    if (!_achievements.containsKey(achievementId) || _unlockedAchievements.contains(achievementId)) {
      return;
    }

    try {
      _unlockedAchievements.add(achievementId);
      final achievement = _achievements[achievementId]!;

      // Save locally
      final list = _unlockedAchievements.toList();
      await _prefs.setStringList('unlocked_achievements', list);

      // Save to Firestore
      await _db.collection('achievements').doc(achievementId).set({
        'unlockedAt': DateTime.now().toIso8601String(),
        'tier': achievement.tier.toString(),
        'category': achievement.category.toString(),
        'points': achievement.points,
        'metadata': metadata ?? {},
      }, SetOptions(merge: true));

      debugPrint('✅ Achievement unlocked: ${achievement.title}');
    } catch (e) {
      debugPrint('[Achievement System] Unlock error: $e');
    }
  }

  // ===== PROGRESS TRACKING =====
  Future<void> updateProgress(String achievementId, int progress) async {
    _achievementProgress[achievementId] = progress;
    await _prefs.setString(
      'achievement_progress:$achievementId',
      jsonEncode({'progress': progress, 'updatedAt': DateTime.now().toIso8601String()}),
    );
  }

  int getProgress(String achievementId) => _achievementProgress[achievementId] ?? 0;

  // ===== GETTERS =====
  Achievement? getAchievement(String id) => _achievements[id];

  List<Achievement> getAchievementsByTier(AchievementTier tier) =>
      _achievements.values.where((a) => a.tier == tier).toList();

  List<Achievement> getAchievementsByCategory(AchievementCategory category) =>
      _achievements.values.where((a) => a.category == category).toList();

  List<Achievement> getUnlockedAchievements() =>
      _achievements.values.where((a) => _unlockedAchievements.contains(a.id)).toList();

  int getTotalPoints() => getUnlockedAchievements().fold(0, (total, a) => total + a.points);

  int getUnlockedCount() => _unlockedAchievements.length;

  int getTotalCount() => _achievements.length;

  double getCompletionPercentage() => (getUnlockedCount() / getTotalCount() * 100);

  QuestLine? getQuestLine(String id) => _questLines[id];

  List<QuestLine> getAllQuestLines() => _questLines.values.toList();

  // ===== PERSISTENCE =====
  Future<void> _loadUnlockedAchievements() async {
    final stored = _prefs.getStringList('unlocked_achievements') ?? [];
    _unlockedAchievements.addAll(stored);
  }

  Future<Map<String, dynamic>> exportAchievements() async {
    return {
      'unlockedCount': getUnlockedCount(),
      'totalCount': getTotalCount(),
      'completionPercentage': getCompletionPercentage(),
      'totalPoints': getTotalPoints(),
      'achievements': getUnlockedAchievements().map((a) => {'id': a.id, 'title': a.title, 'tier': a.tier.toString()}).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}

// ===== DATA MODELS =====

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementTier tier;
  final AchievementCategory category;
  final int points;
  final bool hidden;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.category,
    required this.points,
    required this.hidden,
  });

  String get tierColor {
    switch (tier) {
      case AchievementTier.common:
        return '⚪';
      case AchievementTier.rare:
        return '🔵';
      case AchievementTier.epic:
        return '🟣';
      case AchievementTier.legendary:
        return '🟡';
      case AchievementTier.hidden:
        return '❓';
    }
  }
}

class QuestLine {
  final String id;
  final String name;
  final String description;
  final List<Quest> quests;
  final double progress;
  final int totalRewards;

  QuestLine({
    required this.id,
    required this.name,
    required this.description,
    required this.quests,
    required this.progress,
    required this.totalRewards,
  });

  int getCompletedCount() => quests.where((q) => q.completed).length;

  int getTotalCount() => quests.length;
}

class Quest {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  bool completed;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    this.completed = false,
  });
}


