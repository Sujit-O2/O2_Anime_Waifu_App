import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎯 Smart Habit Tracker Service
/// 
/// Zero Two helps you build better habits with AI coaching.
/// Track streaks, get personalized reminders, and unlock achievements.
class SmartHabitTrackerService {
  SmartHabitTrackerService._();
  static final SmartHabitTrackerService instance = SmartHabitTrackerService._();

  final List<Habit> _habits = [];
  final List<HabitCompletion> _completions = [];
  final Map<String, int> _streaks = {};

  static const String _storageKey = 'smart_habits_v1';
  static const int _maxCompletions = 5000;

  Future<void> initialize() async {
    await _loadData();
    _calculateStreaks();
    if (kDebugMode) debugPrint('[SmartHabits] Initialized with ${_habits.length} habits');
  }

  Future<Habit> createHabit({
    required String name,
    required String description,
    required HabitCategory category,
    required HabitDifficulty difficulty,
    required List<int> targetDays,
    int? targetTimeHour,
    String? reminderMessage,
    int pointsReward = 10,
  }) async {
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      category: category,
      difficulty: difficulty,
      targetDays: targetDays,
      targetTimeHour: targetTimeHour,
      reminderMessage: reminderMessage,
      pointsReward: pointsReward,
      currentStreak: 0,
      longestStreak: 0,
      totalCompletions: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    _habits.add(habit);
    _streaks[habit.id] = 0;
    await _saveData();

    if (kDebugMode) debugPrint('[SmartHabits] Created: $name');
    return habit;
  }

  Future<HabitCompletionResult> completeHabit(String habitId) async {
    final habitIndex = _habits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) {
      return HabitCompletionResult(
        success: false,
        message: 'Habit not found',
        pointsEarned: 0,
        newStreak: 0,
      );
    }

    final habit = _habits[habitIndex];
    final today = DateTime.now();
    final todayKey = _getDateKey(today);

    if (_completions.any((c) => c.habitId == habitId && _getDateKey(c.timestamp) == todayKey)) {
      return HabitCompletionResult(
        success: false,
        message: 'Already completed today!',
        pointsEarned: 0,
        newStreak: habit.currentStreak,
      );
    }

    final completion = HabitCompletion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      habitId: habitId,
      timestamp: today,
      mood: null,
      note: null,
    );

    _completions.insert(0, completion);
    if (_completions.length > _maxCompletions) {
      _completions.removeLast();
    }

    habit.totalCompletions++;
    habit.lastCompletedAt = today;

    final newStreak = _calculateHabitStreak(habitId);
    habit.currentStreak = newStreak;
    if (newStreak > habit.longestStreak) {
      habit.longestStreak = newStreak;
    }

    _habits[habitIndex] = habit;
    _streaks[habitId] = newStreak;

    int bonusPoints = 0;
    if (newStreak >= 7) bonusPoints = 5;
    if (newStreak >= 30) bonusPoints = 20;
    if (newStreak >= 100) bonusPoints = 50;

    final totalPoints = habit.pointsReward + bonusPoints;

    await _saveData();

    return HabitCompletionResult(
      success: true,
      message: _getCompletionMessage(habit, newStreak),
      pointsEarned: totalPoints,
      newStreak: newStreak,
      bonusPoints: bonusPoints,
      achievementUnlocked: _checkAchievements(habit, newStreak),
    );
  }

  String _getCompletionMessage(Habit habit, int streak) {
    if (streak == 1) return 'Great start, darling! Keep it up~ 💪';
    if (streak == 7) return 'One week streak! You\'re amazing~ 🔥';
    if (streak == 30) return '30 days! This is becoming a real habit~ ⭐';
    if (streak == 100) return '100 DAYS! You\'re unstoppable, darling! 🏆';
    if (streak % 10 == 0) return '$streak days! I\'m so proud of you~ 💕';
    return 'Day $streak! Keep going, darling~ ✨';
  }

  String? _checkAchievements(Habit habit, int streak) {
    if (streak == 7) return '🔥 Week Warrior';
    if (streak == 30) return '⭐ Monthly Master';
    if (streak == 100) return '🏆 Century Champion';
    if (habit.totalCompletions == 50) return '💯 Half Century';
    if (habit.totalCompletions == 365) return '🎯 Year Long Dedication';
    return null;
  }

  int _calculateHabitStreak(String habitId) {
    final completions = _completions
        .where((c) => c.habitId == habitId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (completions.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final dateKey = _getDateKey(checkDate);
      final hasCompletion = completions.any((c) => _getDateKey(c.timestamp) == dateKey);

      if (hasCompletion) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        if (i == 0 && checkDate.day == DateTime.now().day) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }

    return streak;
  }

  void _calculateStreaks() {
    for (final habit in _habits) {
      _streaks[habit.id] = _calculateHabitStreak(habit.id);
      habit.currentStreak = _streaks[habit.id]!;
    }
  }

  List<Habit> getHabitsDueToday() {
    final today = DateTime.now();
    final weekday = today.weekday;

    return _habits.where((h) {
      if (!h.isActive) return false;
      if (!h.targetDays.contains(weekday)) return false;

      final todayKey = _getDateKey(today);
      final completed = _completions.any(
        (c) => c.habitId == h.id && _getDateKey(c.timestamp) == todayKey
      );

      return !completed;
    }).toList();
  }

  Map<DateTime, bool> getCompletionCalendar(String habitId, {int days = 90}) {
    final calendar = <DateTime, bool>{};
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      
      final completed = _completions.any(
        (c) => c.habitId == habitId && _getDateKey(c.timestamp) == dateKey
      );

      calendar[DateTime(date.year, date.month, date.day)] = completed;
    }

    return calendar;
  }

  String getAICoachingMessage(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => _habits.first);
    final streak = habit.currentStreak;
    final completions = _completions.where((c) => c.habitId == habitId).length;

    if (streak == 0 && completions == 0) {
      return 'Let\'s start this journey together, darling! The first step is always the hardest~ 💕';
    } else if (streak == 0 && completions > 0) {
      return 'You\'ve done this before! Let\'s rebuild that momentum~ 💪';
    } else if (streak < 7) {
      return 'You\'re building momentum! Each day makes it easier~ ✨';
    } else if (streak < 30) {
      return 'This is becoming a real habit! Your consistency is impressive~ 🌟';
    } else if (streak < 100) {
      return 'You\'re a habit master! This is part of who you are now~ 🏆';
    } else {
      return 'Legendary dedication! You inspire me, darling~ 👑';
    }
  }

  Map<String, dynamic> getWeeklyReport() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weekCompletions = _completions.where(
      (c) => c.timestamp.isAfter(weekAgo)
    ).toList();

    final habitCompletionCounts = <String, int>{};
    for (final completion in weekCompletions) {
      habitCompletionCounts[completion.habitId] = 
          (habitCompletionCounts[completion.habitId] ?? 0) + 1;
    }

    final activeHabits = _habits.where((h) => h.isActive).length;
    final expectedCompletions = activeHabits * 7;
    final actualCompletions = weekCompletions.length;
    final completionRate = expectedCompletions > 0 
        ? (actualCompletions / expectedCompletions * 100).round()
        : 0;

    String? bestHabit;
    int maxCompletions = 0;
    habitCompletionCounts.forEach((habitId, count) {
      if (count > maxCompletions) {
        maxCompletions = count;
        final habit = _habits.firstWhere((h) => h.id == habitId);
        bestHabit = habit.name;
      }
    });

    return {
      'total_completions': actualCompletions,
      'completion_rate': completionRate,
      'best_habit': bestHabit,
      'best_habit_completions': maxCompletions,
      'active_habits': activeHabits,
      'total_points_earned': actualCompletions * 10,
    };
  }

  List<Habit> getAllHabits() => List.unmodifiable(_habits);

  Habit? getHabit(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    _completions.removeWhere((c) => c.habitId == id);
    _streaks.remove(id);
    await _saveData();
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'habits': _habits.map((h) => h.toJson()).toList(),
        'completions': _completions.map((c) => c.toJson()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[SmartHabits] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _habits.clear();
        _habits.addAll(
          (data['habits'] as List<dynamic>)
              .map((h) => Habit.fromJson(h as Map<String, dynamic>))
        );

        _completions.clear();
        _completions.addAll(
          (data['completions'] as List<dynamic>)
              .map((c) => HabitCompletion.fromJson(c as Map<String, dynamic>))
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SmartHabits] Load error: $e');
    }
  }
}

class Habit {
  final String id;
  final String name;
  final String description;
  final HabitCategory category;
  final HabitDifficulty difficulty;
  final List<int> targetDays;
  final int? targetTimeHour;
  final String? reminderMessage;
  final int pointsReward;
  int currentStreak;
  int longestStreak;
  int totalCompletions;
  final bool isActive;
  final DateTime createdAt;
  DateTime? lastCompletedAt;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.targetDays,
    this.targetTimeHour,
    this.reminderMessage,
    required this.pointsReward,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.isActive,
    required this.createdAt,
    this.lastCompletedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'difficulty': difficulty.name,
    'targetDays': targetDays,
    'targetTimeHour': targetTimeHour,
    'reminderMessage': reminderMessage,
    'pointsReward': pointsReward,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'totalCompletions': totalCompletions,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'lastCompletedAt': lastCompletedAt?.toIso8601String(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    category: HabitCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => HabitCategory.other,
    ),
    difficulty: HabitDifficulty.values.firstWhere(
      (e) => e.name == json['difficulty'],
      orElse: () => HabitDifficulty.medium,
    ),
    targetDays: List<int>.from(json['targetDays'] as List),
    targetTimeHour: json['targetTimeHour'] as int?,
    reminderMessage: json['reminderMessage'] as String?,
    pointsReward: json['pointsReward'] as int,
    currentStreak: json['currentStreak'] as int,
    longestStreak: json['longestStreak'] as int,
    totalCompletions: json['totalCompletions'] as int,
    isActive: json['isActive'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastCompletedAt: json['lastCompletedAt'] != null
        ? DateTime.parse(json['lastCompletedAt'] as String)
        : null,
  );
}

class HabitCompletion {
  final String id;
  final String habitId;
  final DateTime timestamp;
  final String? mood;
  final String? note;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.timestamp,
    this.mood,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'habitId': habitId,
    'timestamp': timestamp.toIso8601String(),
    'mood': mood,
    'note': note,
  };

  factory HabitCompletion.fromJson(Map<String, dynamic> json) => HabitCompletion(
    id: json['id'] as String,
    habitId: json['habitId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    mood: json['mood'] as String?,
    note: json['note'] as String?,
  );
}

class HabitCompletionResult {
  final bool success;
  final String message;
  final int pointsEarned;
  final int newStreak;
  final int bonusPoints;
  final String? achievementUnlocked;

  const HabitCompletionResult({
    required this.success,
    required this.message,
    required this.pointsEarned,
    required this.newStreak,
    this.bonusPoints = 0,
    this.achievementUnlocked,
  });
}

enum HabitCategory {
  health,
  fitness,
  productivity,
  learning,
  social,
  mindfulness,
  creativity,
  finance,
  other;

  String get label {
    switch (this) {
      case HabitCategory.health: return 'Health';
      case HabitCategory.fitness: return 'Fitness';
      case HabitCategory.productivity: return 'Productivity';
      case HabitCategory.learning: return 'Learning';
      case HabitCategory.social: return 'Social';
      case HabitCategory.mindfulness: return 'Mindfulness';
      case HabitCategory.creativity: return 'Creativity';
      case HabitCategory.finance: return 'Finance';
      case HabitCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case HabitCategory.health: return '🏥';
      case HabitCategory.fitness: return '💪';
      case HabitCategory.productivity: return '📊';
      case HabitCategory.learning: return '📚';
      case HabitCategory.social: return '👥';
      case HabitCategory.mindfulness: return '🧘';
      case HabitCategory.creativity: return '🎨';
      case HabitCategory.finance: return '💰';
      case HabitCategory.other: return '⭐';
    }
  }
}

enum HabitDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case HabitDifficulty.easy: return 'Easy';
      case HabitDifficulty.medium: return 'Medium';
      case HabitDifficulty.hard: return 'Hard';
    }
  }

  int get pointsMultiplier {
    switch (this) {
      case HabitDifficulty.easy: return 1;
      case HabitDifficulty.medium: return 2;
      case HabitDifficulty.hard: return 3;
    }
  }
}
