import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FeatureSyncService — Syncs SharedPreferences data to Firebase Firestore
///
/// Provides a generic sync layer so any feature that saves to SharedPreferences
/// can also persist data to the cloud. Handles:
///   • upload(key) — saves a SharedPreferences key to Firestore
///   • download(key) — restores a SharedPreferences key from Firestore
///   • syncAll()    — batch sync all tracked keys
///   • enableAutoSync() — auto-sync on every save
///
/// Firestore path: users/{uid}/feature_data/{key}
/// ─────────────────────────────────────────────────────────────────────────────
class FeatureSyncService {
  static final FeatureSyncService instance = FeatureSyncService._();
  FeatureSyncService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _initialized = false;

  /// All SharedPreferences keys that should be synced to cloud.
  static const List<String> syncKeys = [
    // Settings
    'wake_word_enabled', 'idle_timer_enabled', 'idle_duration_seconds',
    'proactive_enabled', 'proactive_interval_seconds', 'proactive_random_enabled',
    'voice_model', 'dual_voice_enabled_v1', 'dual_voice_secondary_v1',
    'lite_mode_enabled_v1', 'app_lock_enabled', 'app_theme_index',
    'flutter.advanced_memory_limit', 'flutter.advanced_debug_logs',
    'flutter.advanced_strict_wake', 'flutter.theme_accent_color',

    // Feature data
    'goals_data', 'thought_capture', 'habit_tracker_data', 'notes_data',
    'bucket_list_data', 'mood_tracker_data', 'gratitude_journal',
    'dream_journal_data', 'daily_affirmations_data', 'countdown_timers',
    'workout_planner_data', 'budget_tracker_data', 'medication_reminders',
    'study_timer_data', 'pomodoro_data', 'daily_challenge_progress',
    'pinned_clips', 'spinner_options', 'draw_lots_data',
    'secret_notes_data', 'scheduled_msg_data', 'episode_alerts_data',
    'parking_spot_data', 'password_gen_history',

    // Persona
    'selected_persona', 'persona_prompt',
  ];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('FeatureSyncService.init: $e');
    }
  }

  /// Upload a single SharedPreferences key to Firestore.
  Future<void> upload(String key) async {
    if (_uid == null) return;
    await init();
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = _readPref(prefs, key);
      if (value == null) return;

      await _db
          .collection('users')
          .doc(_uid!)
          .collection('feature_data')
          .doc(key)
          .set({
        'value': jsonEncode(value),
        'type': value.runtimeType.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('FeatureSyncService.upload($key): $e');
    }
  }

  /// Download a single key from Firestore and write to SharedPreferences.
  Future<void> download(String key) async {
    if (_uid == null) return;
    await init();
    try {
      final snap = await _db
          .collection('users')
          .doc(_uid!)
          .collection('feature_data')
          .doc(key)
          .get();

      if (!snap.exists) return;
      final data = snap.data()!;
      final rawValue = data['value'] as String?;
      final type = data['type'] as String? ?? 'String';
      if (rawValue == null) return;

      final decoded = jsonDecode(rawValue);
      final prefs = await SharedPreferences.getInstance();
      _writePref(prefs, key, decoded, type);
    } catch (e) {
      if (kDebugMode) debugPrint('FeatureSyncService.download($key): $e');
    }
  }

  /// Sync ALL tracked keys — upload to cloud.
  Future<void> uploadAll() async {
    if (_uid == null) return;
    await init();
    try {
      final prefs = await SharedPreferences.getInstance();
      final batch = _db.batch();
      final col = _db.collection('users').doc(_uid!).collection('feature_data');

      for (final key in syncKeys) {
        final value = _readPref(prefs, key);
        if (value != null) {
          batch.set(col.doc(key), {
            'value': jsonEncode(value),
            'type': value.runtimeType.toString(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
      if (kDebugMode) debugPrint('FeatureSyncService: uploaded ${syncKeys.length} keys');
    } catch (e) {
      if (kDebugMode) debugPrint('FeatureSyncService.uploadAll: $e');
    }
  }

  /// Download ALL tracked keys from cloud.
  Future<void> downloadAll() async {
    if (_uid == null) return;
    await init();
    try {
      final prefs = await SharedPreferences.getInstance();
      final col = _db.collection('users').doc(_uid!).collection('feature_data');

      for (final key in syncKeys) {
        try {
          final snap = await col.doc(key).get();
          if (!snap.exists) continue;
          final data = snap.data()!;
          final rawValue = data['value'] as String?;
          final type = data['type'] as String? ?? 'String';
          if (rawValue == null) continue;
          final decoded = jsonDecode(rawValue);
          _writePref(prefs, key, decoded, type);
        } catch (e) {
          if (kDebugMode) debugPrint('FeatureSyncService.downloadAll($key): $e');
        }
      }
      if (kDebugMode) debugPrint('FeatureSyncService: downloaded all keys');
    } catch (e) {
      if (kDebugMode) debugPrint('FeatureSyncService.downloadAll: $e');
    }
  }

  /// Save to SharedPreferences AND upload to cloud in one call.
  Future<void> saveAndSync(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
    // Fire-and-forget cloud upload
    upload(key);
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  dynamic _readPref(SharedPreferences prefs, String key) {
    return prefs.get(key);
  }

  void _writePref(SharedPreferences prefs, String key, dynamic value, String type) {
    if (value is String) {
      prefs.setString(key, value);
    } else if (value is int) {
      prefs.setInt(key, value);
    } else if (value is double) {
      prefs.setDouble(key, value);
    } else if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is num) {
      // JSON decodes ints as nums sometimes
      if (type.contains('int')) {
        prefs.setInt(key, value.toInt());
      } else {
        prefs.setDouble(key, value.toDouble());
      }
    }
  }
}


