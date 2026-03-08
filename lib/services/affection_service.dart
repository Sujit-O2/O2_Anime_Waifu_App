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

  AffectionService._internal() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _affectionPoints =
        _prefs?.getInt(_keyAffection) ?? 100; // Start with 100 points
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
    if (_affectionPoints < 50) return "Stranger";
    if (_affectionPoints < 150) return "Acquaintance";
    if (_affectionPoints < 300) return "Friend";
    if (_affectionPoints < 600) return "Close Friend";
    if (_affectionPoints < 1000) return "Darling";
    return "Soulmate";
  }

  /// Calculates progress to the next level (0.0 to 1.0)
  double get levelProgress {
    if (_affectionPoints < 50) return _affectionPoints / 50;
    if (_affectionPoints < 150) return (_affectionPoints - 50) / 100;
    if (_affectionPoints < 300) return (_affectionPoints - 150) / 150;
    if (_affectionPoints < 600) return (_affectionPoints - 300) / 300;
    if (_affectionPoints < 1000) return (_affectionPoints - 600) / 400;
    return 1.0; // Max level
  }

  /// Get color associated with current affection level
  Color get levelColor {
    if (_affectionPoints < 50) return Colors.grey;
    if (_affectionPoints < 150) return Colors.blueAccent;
    if (_affectionPoints < 300) return Colors.greenAccent;
    if (_affectionPoints < 600) return Colors.amberAccent;
    if (_affectionPoints < 1000) return Colors.pinkAccent;
    return Colors.redAccent;
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
    // Made async to await _save()
    _updateLastInteraction();
    await _save();
    await HomeWidgetService.updateAffectionWidget();
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
      await _save(); // Save after decay
      await HomeWidgetService
          .updateAffectionWidget(); // Update widget after decay
    }
  }

  Future<void> _save() async {
    await _prefs?.setInt(_keyAffection, _affectionPoints);
  }
}
