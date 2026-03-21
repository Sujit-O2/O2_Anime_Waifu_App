import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';
import 'home_widget_service.dart';

/// Manages the affection/relationship system.
/// All data persisted locally with SharedPreferences and synced to Firestore.
class AffectionService extends ChangeNotifier {
  static final AffectionService instance = AffectionService._internal();

  int _affectionPoints = 0;
  int _streakDays = 0;
  DateTime? _lastInteractionTime;
  int _lastStreakDateMs = 0;

  int get points => _affectionPoints;
  int get streakDays => _streakDays;

  final _bonusStreamController = StreamController<int>.broadcast();
  Stream<int> get onDailyLoginBonus => _bonusStreamController.stream;

  AffectionService._internal() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Default local
    _affectionPoints = prefs.getInt('affectionPoints') ?? 100;
    _streakDays = prefs.getInt('affectionStreakDays') ?? 0;
    _lastStreakDateMs = prefs.getInt('affectionLastStreakDateMs') ?? 0;
    final localLastMs = prefs.getInt('affectionLastInteractionMs');
    if (localLastMs != null) {
      _lastInteractionTime = DateTime.fromMillisecondsSinceEpoch(localLastMs);
    }

    try {
      if (FirestoreService().isSignedIn) {
        final data = await FirestoreService().loadAffection();
        if (data.isNotEmpty) {
          final cloudPoints = data['points'] as int? ?? 100;
          final cloudStreak = data['streakDays'] as int? ?? 0;
          final cloudStreakMs = data['lastStreakDateMs'] as int? ?? 0;
          final cloudLastMs = data['lastInteractionMs'] as int?;

          // Use cloud data if it is newer or if local is basically empty
          if (cloudLastMs != null && (localLastMs == null || cloudLastMs >= localLastMs)) {
            _affectionPoints = cloudPoints;
            _streakDays = cloudStreak;
            _lastStreakDateMs = cloudStreakMs;
            _lastInteractionTime = DateTime.fromMillisecondsSinceEpoch(cloudLastMs);
            
            // Mirror securely to local
            await prefs.setInt('affectionPoints', _affectionPoints);
            await prefs.setInt('affectionStreakDays', _streakDays);
            await prefs.setInt('affectionLastInteractionMs', cloudLastMs);
            await prefs.setInt('affectionLastStreakDateMs', _lastStreakDateMs);
          }
        }
      }
    } catch (_) {
      // Offline or permission denied, stick to local variables loaded above
    }

    _applyDecayIfNeeded();
    await HomeWidgetService.updateAffectionWidget();
    notifyListeners();
  }

  // ── Level logic (unchanged) ───────────────────────────────────────────────

  String get levelName {
    if (_affectionPoints < 50) return "Newlyweds 💍";
    if (_affectionPoints < 200) return "Honeymooners 🥂";
    if (_affectionPoints < 500) return "Sweet Spouses 💕";
    if (_affectionPoints < 900) return "Soulmates 💖";
    if (_affectionPoints < 1500) return "Eternal Partners 💞";
    if (_affectionPoints < 2500) return "Beloved Husband 👑";
    return "Bound by Fate ♾️";
  }

  double get levelProgress {
    if (_affectionPoints < 50) return _affectionPoints / 50;
    if (_affectionPoints < 200) return (_affectionPoints - 50) / 150;
    if (_affectionPoints < 500) return (_affectionPoints - 200) / 300;
    if (_affectionPoints < 900) return (_affectionPoints - 500) / 400;
    if (_affectionPoints < 1500) return (_affectionPoints - 900) / 600;
    if (_affectionPoints < 2500) return (_affectionPoints - 1500) / 1000;
    return 1.0;
  }

  Color get levelColor {
    if (_affectionPoints < 50) return Colors.grey;
    if (_affectionPoints < 200) return Colors.blueGrey;
    if (_affectionPoints < 500) return Colors.lightBlueAccent;
    if (_affectionPoints < 900) return Colors.purpleAccent;
    if (_affectionPoints < 1500) return Colors.pinkAccent;
    if (_affectionPoints < 2500) return Colors.redAccent;
    return Colors.amber;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> addPoints(int amount) async {
    _affectionPoints += amount;
    _updateLastInteraction();
    await _save();
    await _checkAchievements();
    await HomeWidgetService.updateAffectionWidget();
    notifyListeners();
  }

  Future<void> removePoints(int amount) async {
    _affectionPoints = (_affectionPoints - amount).clamp(0, 99999);
    await _save();
    await HomeWidgetService.updateAffectionWidget();
    notifyListeners();
  }

  Future<void> recordInteraction() async {
    _checkDailyStreak();
    _updateLastInteraction();
    await _save();
    await HomeWidgetService.updateAffectionWidget();
  }

  // ── Streak logic ──────────────────────────────────────────────────────────

  void _checkDailyStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastStreakDateMs != 0) {
      final lastStreak = DateTime.fromMillisecondsSinceEpoch(_lastStreakDateMs);
      final diff = today.difference(lastStreak).inDays;
      if (diff == 1) {
        _streakDays++;
        _grantDailyBonus(today);
      } else if (diff > 1) {
        _streakDays = 1;
        _grantDailyBonus(today);
      }
    } else {
      _streakDays = 1;
      _grantDailyBonus(today);
    }
  }

  void _grantDailyBonus(DateTime today) {
    _lastStreakDateMs = today.millisecondsSinceEpoch;
    int bonus = (5 + (_streakDays * 2)).clamp(0, 25);
    _affectionPoints += bonus;
    _bonusStreamController.add(bonus);
    notifyListeners();
  }

  void _updateLastInteraction() {
    _lastInteractionTime = DateTime.now();
  }

  Future<void> _applyDecayIfNeeded() async {
    if (_lastInteractionTime == null) return;
    final diff = DateTime.now().difference(_lastInteractionTime!);
    if (diff.inDays > 2) {
      _affectionPoints =
          (_affectionPoints - (diff.inDays - 2) * 10).clamp(0, 99999);
      _streakDays = 0;
      _updateLastInteraction();
      await _save();
      await HomeWidgetService.updateAffectionWidget();
    }
  }

  /// Check & unlock milestone achievements
  Future<void> _checkAchievements() async {
    final fs = FirestoreService();
    if (_affectionPoints >= 100) await fs.unlockAchievement('first_100_pts');
    if (_affectionPoints >= 500) await fs.unlockAchievement('500_pts');
    if (_affectionPoints >= 1000) await fs.unlockAchievement('1000_pts');
    if (_streakDays >= 7) await fs.unlockAchievement('7_day_streak');
    if (_streakDays >= 30) await fs.unlockAchievement('30_day_streak');
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('affectionPoints', _affectionPoints);
    await prefs.setInt('affectionStreakDays', _streakDays);
    await prefs.setInt('affectionLastInteractionMs',
        _lastInteractionTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt('affectionLastStreakDateMs', _lastStreakDateMs);

    // Sync to cloud (may fail if unauthenticated, but local is now safe)
    await FirestoreService().saveAffection(
      points: _affectionPoints,
      streakDays: _streakDays,
      lastInteractionMs: _lastInteractionTime?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      lastStreakDateMs: _lastStreakDateMs,
    );
  }
}
