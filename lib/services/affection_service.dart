import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_widget_service.dart';

/// Manages the affection/relationship system with the AI Companion
class AffectionService extends ChangeNotifier {
  static const String _keyAffection = 'affection_points';
  static const String _keyLastInteraction = 'last_interaction_time';

  // Singleton pattern
  static final AffectionService instance = AffectionService._internal();

  SharedPreferences? _prefs;
  int _affectionPoints = 0;
  DateTime? _lastInteractionTime;

  int get points => _affectionPoints;

  static const String _keyStreak = 'daily_login_streak';
  static const String _keyLastStreakDate = 'last_streak_date';

  int _streakDays = 0;
  int get streakDays => _streakDays;

  // Stream to notify UI when a daily bonus is awarded
  final _bonusStreamController = StreamController<int>.broadcast();
  Stream<int> get onDailyLoginBonus => _bonusStreamController.stream;

  AffectionService._internal() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _affectionPoints =
        _prefs?.getInt(_keyAffection) ?? 100; // Start with 100 points
    _streakDays = _prefs?.getInt(_keyStreak) ?? 0;
    final lastTimeMs = _prefs?.getInt(_keyLastInteraction);
    if (lastTimeMs != null) {
      _lastInteractionTime = DateTime.fromMillisecondsSinceEpoch(lastTimeMs);
    }

    // Check for daily decay if ignored
    _applyDecayIfNeeded();
    await HomeWidgetService
        .updateAffectionWidget(); // Call after initial affection is set and decay applied
    notifyListeners();
  }

  /// Calculates the current relationship level name based on points
  String get levelName {
    if (_affectionPoints < 50) return "Newlyweds 💍";
    if (_affectionPoints < 200) return "Honeymooners 🥂";
    if (_affectionPoints < 500) return "Sweet Spouses 💕";
    if (_affectionPoints < 900) return "Soulmates 💖";
    if (_affectionPoints < 1500) return "Eternal Partners 💞";
    if (_affectionPoints < 2500) return "Beloved Husband 👑";
    return "Bound by Fate ♾️";
  }

  /// Calculates progress to the next level (0.0 to 1.0)
  double get levelProgress {
    if (_affectionPoints < 50) return _affectionPoints / 50;
    if (_affectionPoints < 200) return (_affectionPoints - 50) / 150;
    if (_affectionPoints < 500) return (_affectionPoints - 200) / 300;
    if (_affectionPoints < 900) return (_affectionPoints - 500) / 400;
    if (_affectionPoints < 1500) return (_affectionPoints - 900) / 600;
    if (_affectionPoints < 2500) return (_affectionPoints - 1500) / 1000;
    return 1.0; // Max level
  }

  /// Get color associated with current affection level
  Color get levelColor {
    if (_affectionPoints < 50) return Colors.grey;
    if (_affectionPoints < 200) return Colors.blueGrey;
    if (_affectionPoints < 500) return Colors.lightBlueAccent;
    if (_affectionPoints < 900) return Colors.purpleAccent;
    if (_affectionPoints < 1500) return Colors.pinkAccent;
    if (_affectionPoints < 2500) return Colors.redAccent;
    return Colors.amber;
  }

  /// Add points (e.g., from positive interaction or completing a quest)
  Future<void> addPoints(int amount) async {
    _affectionPoints += amount;
    _updateLastInteraction();
    await _save();
    await HomeWidgetService.updateAffectionWidget();
    notifyListeners();
  }

  /// Remove points (e.g., from ignoring or negative interaction)
  Future<void> removePoints(int amount) async {
    _affectionPoints -= amount;
    if (_affectionPoints < 0) _affectionPoints = 0;
    await _save();
    await HomeWidgetService.updateAffectionWidget();
    notifyListeners();
  }

  /// Records that the user interacted with the app today
  Future<void> recordInteraction() async {
    // Check daily streak before updating interaction time
    _checkDailyStreak();

    // Made async to await _save()
    _updateLastInteraction();
    await _save();
    await HomeWidgetService.updateAffectionWidget();
  }

  void _checkDailyStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastStreakMs = _prefs?.getInt(_keyLastStreakDate);
    if (lastStreakMs != null) {
      final lastStreak = DateTime.fromMillisecondsSinceEpoch(lastStreakMs);
      final diff = today.difference(lastStreak).inDays;

      if (diff == 1) {
        // Consecutive day
        _streakDays++;
        _grantDailyBonus(today);
      } else if (diff > 1) {
        // Streak broken
        _streakDays = 1;
        _grantDailyBonus(today);
      }
      // If diff == 0, already claimed today.
    } else {
      // First time ever
      _streakDays = 1;
      _grantDailyBonus(today);
    }
  }

  void _grantDailyBonus(DateTime today) {
    _prefs?.setInt(_keyLastStreakDate, today.millisecondsSinceEpoch);
    _prefs?.setInt(_keyStreak, _streakDays);

    // Calculate bonus: base 5 + 2 for every streak day (capped at 25)
    int bonus = 5 + (_streakDays * 2);
    if (bonus > 25) bonus = 25;

    _affectionPoints += bonus;
    _bonusStreamController.add(bonus); // Notify UI
    notifyListeners();
  }

  void _updateLastInteraction() {
    _lastInteractionTime = DateTime.now();
    _prefs?.setInt(
        _keyLastInteraction, _lastInteractionTime!.millisecondsSinceEpoch);
  }

  /// If the user hasn't interacted in more than 48 hours, decay affection.
  Future<void> _applyDecayIfNeeded() async {
    // Made async to await _save() and HomeWidgetService
    if (_lastInteractionTime == null) return;
    final now = DateTime.now();
    final difference = now.difference(_lastInteractionTime!);

    // Decay 10 points for every full day after the first 2 days of inactivity
    if (difference.inDays > 2) {
      final decayDays = difference.inDays - 2;
      _affectionPoints -= (decayDays * 10);
      if (_affectionPoints < 0) _affectionPoints = 0;

      // Update interaction time so we don't decay again until another day passes
      _updateLastInteraction();

      // Also reset streak since it's definitely broken
      _streakDays = 0;
      _prefs?.setInt(_keyStreak, 0);

      await _save(); // Save after decay
      await HomeWidgetService
          .updateAffectionWidget(); // Update widget after decay
    }
  }

  Future<void> _save() async {
    await _prefs?.setInt(_keyAffection, _affectionPoints);
  }
}
