import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌟 Achievement & Milestone System
class AchievementSystemService {
  AchievementSystemService._();
  static final AchievementSystemService instance = AchievementSystemService._();

  final Map<String, Achievement> _achievements = {};
  final List<String> _unlockedIds = [];
  int _totalPoints = 0;

  Future<void> initialize() async {
    _initializeAchievements();
    await _loadProgress();
    if (kDebugMode) debugPrint('[Achievements] ${_unlockedIds.length}/${_achievements.length} unlocked');
  }

  void _initializeAchievements() {
    _achievements['first_message'] = Achievement(id: 'first_message', title: 'First Words', description: 'Send your first message', points: 10, icon: '💬');
    _achievements['100_messages'] = Achievement(id: '100_messages', title: 'Chatty', description: 'Send 100 messages', points: 50, icon: '💯');
    _achievements['1000_messages'] = Achievement(id: '1000_messages', title: 'Conversationalist', description: 'Send 1000 messages', points: 200, icon: '🗣️');
    _achievements['week_streak'] = Achievement(id: 'week_streak', title: 'Week Together', description: 'Talk for 7 days straight', points: 50, icon: '🔥');
    _achievements['month_streak'] = Achievement(id: 'month_streak', title: 'Monthly Devotion', description: '30 day streak', points: 150, icon: '⭐');
    _achievements['affection_1000'] = Achievement(id: 'affection_1000', title: 'Beloved', description: 'Reach 1000 affection points', points: 100, icon: '💖');
    _achievements['affection_5000'] = Achievement(id: 'affection_5000', title: 'Soulmate', description: 'Reach 5000 affection points', points: 500, icon: '👑');
  }

  Future<UnlockResult?> checkAndUnlock(String achievementId) async {
    if (_unlockedIds.contains(achievementId)) return null;
    final achievement = _achievements[achievementId];
    if (achievement == null) return null;

    _unlockedIds.add(achievementId);
    _totalPoints += achievement.points;
    await _saveProgress();

    return UnlockResult(achievement: achievement, totalPoints: _totalPoints);
  }

  List<Achievement> getAllAchievements() => _achievements.values.toList();
  double getCompletionPercentage() => (_unlockedIds.length / _achievements.length) * 100;
  int getTotalPoints() => _totalPoints;

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlocked_achievements', _unlockedIds);
    await prefs.setInt('achievement_points', _totalPoints);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _unlockedIds.addAll(prefs.getStringList('unlocked_achievements') ?? []);
    _totalPoints = prefs.getInt('achievement_points') ?? 0;
  }
}

class Achievement {
  final String id, title, description, icon;
  final int points;
  Achievement({required this.id, required this.title, required this.description, required this.points, required this.icon});
}

class UnlockResult {
  final Achievement achievement;
  final int totalPoints;
  UnlockResult({required this.achievement, required this.totalPoints});
}
