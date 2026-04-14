import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/database_storage/firestore_service.dart';
import 'package:anime_waifu/services/utilities_core/home_widget_service.dart';

/// Manages the affection/relationship system.
/// Data is cached locally and merged with Firestore on sign-in.
class AffectionService extends ChangeNotifier {
  static final AffectionService instance = AffectionService._internal();

  static const _pointsKey = 'affectionPoints';
  static const _streakKey = 'affectionStreakDays';
  static const _lastInteractionKey = 'affectionLastInteractionMs';
  static const _lastStreakKey = 'affectionLastStreakDateMs';
  static const _legacyOwnerKey = 'affectionLegacyOwnerUid';

  int _affectionPoints = 0;
  int _streakDays = 0;
  DateTime? _lastInteractionTime;
  int _lastStreakDateMs = 0;

  final _bonusStreamController = StreamController<int>.broadcast();
  late final StreamSubscription<User?> _authSubscription;

  Future<void> _operationQueue = Future<void>.value();

  int get points => _affectionPoints;
  int get streakDays => _streakDays;
  Stream<int> get onDailyLoginBonus => _bonusStreamController.stream;

  AffectionService._internal() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      unawaited(_enqueue(() => _reloadForUser(user)));
    });
    unawaited(_enqueue(() => _reloadForUser(FirebaseAuth.instance.currentUser)));
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _bonusStreamController.close();
    super.dispose();
  }

  String get levelName {
    if (_affectionPoints < 50) return 'Newlyweds 💍';
    if (_affectionPoints < 200) return 'Honeymooners 🥂';
    if (_affectionPoints < 500) return 'Sweet Spouses 💕';
    if (_affectionPoints < 900) return 'Soulmates 💖';
    if (_affectionPoints < 1500) return 'Eternal Partners 💞';
    if (_affectionPoints < 2500) return 'Beloved Husband 👑';
    return 'Bound by Fate ♾️';
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

  Future<void> addPoints(int amount) {
    return _enqueue(() async {
      _affectionPoints += amount;
      _updateLastInteraction();
      await _saveCurrentState();
      await _checkAchievements();
      await HomeWidgetService.updateAffectionWidget();
      notifyListeners();
    });
  }

  Future<void> removePoints(int amount) {
    return _enqueue(() async {
      _affectionPoints = (_affectionPoints - amount).clamp(0, 99999);
      _updateLastInteraction();
      await _saveCurrentState();
      await HomeWidgetService.updateAffectionWidget();
      notifyListeners();
    });
  }

  Future<void> recordInteraction() {
    return _enqueue(() async {
      _checkDailyStreak();
      _updateLastInteraction();
      await _saveCurrentState();
      await HomeWidgetService.updateAffectionWidget();
      notifyListeners();
    });
  }

  Future<void> _reloadForUser(User? user) async {
    final prefs = await SharedPreferences.getInstance();
    final local = _readLocalSnapshot(prefs, user?.uid);

    var resolved = local;
    var shouldPushCloud = false;

    if (user != null) {
      final cloudData = await FirestoreService().loadAffection();
      final cloud = _AffectionSnapshot.fromCloud(cloudData);
      resolved = _resolveSnapshot(local, cloud);
      shouldPushCloud = cloudData.isEmpty || !resolved.sameAs(cloud);
    }

    _applySnapshot(resolved);
    await _writeLocalSnapshot(prefs, user?.uid, resolved);

    if (user != null && shouldPushCloud) {
      await _pushSnapshot(resolved);
    }

    await _applyDecayIfNeeded();
    await HomeWidgetService.updateAffectionWidget();
    notifyListeners();
  }

  Future<void> _applyDecayIfNeeded() async {
    if (_lastInteractionTime == null) return;
    final diff = DateTime.now().difference(_lastInteractionTime!);
    if (diff.inDays > 2) {
      _affectionPoints = (_affectionPoints - (diff.inDays - 2) * 10).clamp(
        0,
        99999,
      );
      _streakDays = 0;
      _updateLastInteraction();
      await _saveCurrentState();
    }
  }

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
    final bonus = (5 + (_streakDays * 2)).clamp(0, 25);
    _affectionPoints += bonus;
    _bonusStreamController.add(bonus);
  }

  void _updateLastInteraction() {
    _lastInteractionTime = DateTime.now();
  }

  Future<void> _checkAchievements() async {
    final fs = FirestoreService();
    if (_affectionPoints >= 100) await fs.unlockAchievement('first_100_pts');
    if (_affectionPoints >= 500) await fs.unlockAchievement('500_pts');
    if (_affectionPoints >= 1000) await fs.unlockAchievement('1000_pts');
    if (_streakDays >= 7) await fs.unlockAchievement('7_day_streak');
    if (_streakDays >= 30) await fs.unlockAchievement('30_day_streak');
  }

  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = _AffectionSnapshot(
      points: _affectionPoints,
      streakDays: _streakDays,
      lastInteractionMs:
          _lastInteractionTime?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      lastStreakDateMs: _lastStreakDateMs,
    );

    await _writeLocalSnapshot(prefs, FirebaseAuth.instance.currentUser?.uid, snapshot);

    if (FirestoreService().isSignedIn) {
      await _pushSnapshot(snapshot);
    }
  }

  Future<void> _pushSnapshot(_AffectionSnapshot snapshot) {
    return FirestoreService().saveAffection(
      points: snapshot.points,
      streakDays: snapshot.streakDays,
      lastInteractionMs: snapshot.lastInteractionMs,
      lastStreakDateMs: snapshot.lastStreakDateMs,
      levelName: levelName,
      levelProgress: levelProgress,
    );
  }

  _AffectionSnapshot _resolveSnapshot(
    _AffectionSnapshot local,
    _AffectionSnapshot cloud,
  ) {
    if (!local.hasData && !cloud.hasData) {
      return const _AffectionSnapshot();
    }
    if (!cloud.hasData) return local;
    if (!local.hasData) return cloud;
    return cloud.freshnessMs >= local.freshnessMs ? cloud : local;
  }

  void _applySnapshot(_AffectionSnapshot snapshot) {
    _affectionPoints = snapshot.points;
    _streakDays = snapshot.streakDays;
    _lastStreakDateMs = snapshot.lastStreakDateMs;
    _lastInteractionTime = snapshot.lastInteractionMs == 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(snapshot.lastInteractionMs);
  }

  _AffectionSnapshot _readLocalSnapshot(SharedPreferences prefs, String? uid) {
    int? readValue(String key) {
      if (uid != null) {
        final scoped = prefs.getInt(_scopedKey(uid, key));
        if (scoped != null) return scoped;
        final legacyOwner = prefs.getString(_legacyOwnerKey);
        if (legacyOwner != null && legacyOwner != uid) {
          return null;
        }
      } else {
        final guest = prefs.getInt(_guestKey(key));
        if (guest != null) return guest;
      }
      return prefs.getInt(key);
    }

    return _AffectionSnapshot(
      points: readValue(_pointsKey) ?? 0,
      streakDays: readValue(_streakKey) ?? 0,
      lastInteractionMs: readValue(_lastInteractionKey) ?? 0,
      lastStreakDateMs: readValue(_lastStreakKey) ?? 0,
    ).normalized;
  }

  Future<void> _writeLocalSnapshot(
    SharedPreferences prefs,
    String? uid,
    _AffectionSnapshot snapshot,
  ) async {
    final pointsKey = uid == null ? _guestKey(_pointsKey) : _scopedKey(uid, _pointsKey);
    final streakKey = uid == null ? _guestKey(_streakKey) : _scopedKey(uid, _streakKey);
    final interactionKey = uid == null
        ? _guestKey(_lastInteractionKey)
        : _scopedKey(uid, _lastInteractionKey);
    final lastStreakKey = uid == null
        ? _guestKey(_lastStreakKey)
        : _scopedKey(uid, _lastStreakKey);

    final keys = <String, int>{
      pointsKey: snapshot.points,
      streakKey: snapshot.streakDays,
      interactionKey: snapshot.lastInteractionMs,
      lastStreakKey: snapshot.lastStreakDateMs,
    };

    for (final entry in keys.entries) {
      await prefs.setInt(entry.key, entry.value);
    }

    // Keep legacy keys mirrored so older code and migrations stay stable.
    await prefs.setInt(_pointsKey, snapshot.points);
    await prefs.setInt(_streakKey, snapshot.streakDays);
    await prefs.setInt(_lastInteractionKey, snapshot.lastInteractionMs);
    await prefs.setInt(_lastStreakKey, snapshot.lastStreakDateMs);
    if (uid != null) {
      await prefs.setString(_legacyOwnerKey, uid);
    }
  }

  String _scopedKey(String uid, String key) => 'affection.$uid.$key';
  String _guestKey(String key) => 'affection.guest.$key';

  Future<void> _enqueue(Future<void> Function() operation) {
    final future = _operationQueue.then((_) => operation());
    _operationQueue = future.catchError((Object error, StackTrace stackTrace) {
      debugPrint('AffectionService error: $error');
    });
    return future;
  }
}

class _AffectionSnapshot {
  final int points;
  final int streakDays;
  final int lastInteractionMs;
  final int lastStreakDateMs;

  const _AffectionSnapshot({
    this.points = 0,
    this.streakDays = 0,
    this.lastInteractionMs = 0,
    this.lastStreakDateMs = 0,
  });

  factory _AffectionSnapshot.fromCloud(Map<String, dynamic> data) {
    return _AffectionSnapshot(
      points: data['points'] as int? ?? 0,
      streakDays: data['streakDays'] as int? ?? 0,
      lastInteractionMs: data['lastInteractionMs'] as int? ?? 0,
      lastStreakDateMs: data['lastStreakDateMs'] as int? ?? 0,
    ).normalized;
  }

  _AffectionSnapshot get normalized {
    if (points == 100 &&
        streakDays == 0 &&
        lastInteractionMs == 0 &&
        lastStreakDateMs == 0) {
      return const _AffectionSnapshot();
    }
    return this;
  }

  bool get hasData =>
      points > 0 ||
      streakDays > 0 ||
      lastInteractionMs > 0 ||
      lastStreakDateMs > 0;

  int get freshnessMs =>
      lastInteractionMs > 0 ? lastInteractionMs : lastStreakDateMs;

  bool sameAs(_AffectionSnapshot other) {
    return points == other.points &&
        streakDays == other.streakDays &&
        lastInteractionMs == other.lastInteractionMs &&
        lastStreakDateMs == other.lastStreakDateMs;
  }
}


