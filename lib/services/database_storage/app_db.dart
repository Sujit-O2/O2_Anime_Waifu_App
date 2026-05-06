import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Universal SQLite service for the entire app.
///
/// Tables:
///   kv          — generic key-value store (String value, JSON-serialisable)
///   feature_stats — per-feature: usageCount, lastUsed, streakDays, bestScore, level, totalPlayed
///
/// Usage:
///   // Read
///   final val = await AppDB.instance.get('habit_water_count', defaultValue: '0');
///   // Write
///   await AppDB.instance.set('habit_water_count', '5');
///   // Feature stats
///   await AppDB.instance.recordUsage('pomodoro');
///   final stats = await AppDB.instance.featureStats('pomodoro');
///   await AppDB.instance.saveFeatureStats('quiz', level: 3, bestScore: 120, totalPlayed: 10);
class AppDB {
  AppDB._();
  static final AppDB instance = AppDB._();
  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'app_universal.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE kv (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE feature_stats (
            featureId   TEXT PRIMARY KEY,
            usageCount  INTEGER NOT NULL DEFAULT 0,
            lastUsed    INTEGER NOT NULL DEFAULT 0,
            streakDays  INTEGER NOT NULL DEFAULT 0,
            bestScore   INTEGER NOT NULL DEFAULT 0,
            level       INTEGER NOT NULL DEFAULT 1,
            totalPlayed INTEGER NOT NULL DEFAULT 0,
            extraJson   TEXT    NOT NULL DEFAULT '{}'
          )
        ''');
      },
    );
  }

  // ── Key-Value ─────────────────────────────────────────────────────────────

  Future<String?> get(String key, {String? defaultValue}) async {
    final db = await _database;
    final rows = await db.query('kv', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return defaultValue;
    return rows.first['value'] as String;
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final v = await get(key, defaultValue: defaultValue.toString());
    return int.tryParse(v ?? '') ?? defaultValue;
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final v = await get(key, defaultValue: defaultValue ? '1' : '0');
    return v == '1';
  }

  Future<List<dynamic>> getList(String key) async {
    final v = await get(key, defaultValue: '[]');
    try { return jsonDecode(v!) as List; } catch (_) { return []; }
  }

  Future<Map<String, dynamic>> getMap(String key) async {
    final v = await get(key, defaultValue: '{}');
    try { return jsonDecode(v!) as Map<String, dynamic>; } catch (_) { return {}; }
  }

  Future<void> set(String key, String value) async {
    final db = await _database;
    await db.insert('kv', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setInt(String key, int value) => set(key, value.toString());
  Future<void> setBool(String key, bool value) => set(key, value ? '1' : '0');
  Future<void> setList(String key, List<dynamic> value) => set(key, jsonEncode(value));
  Future<void> setMap(String key, Map<String, dynamic> value) => set(key, jsonEncode(value));

  Future<void> delete(String key) async {
    final db = await _database;
    await db.delete('kv', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> increment(String key, {int by = 1}) async {
    final current = await getInt(key);
    await setInt(key, current + by);
  }

  // ── Feature Stats ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> featureStats(String featureId) async {
    final db = await _database;
    final rows = await db.query('feature_stats',
        where: 'featureId = ?', whereArgs: [featureId]);
    if (rows.isEmpty) {
      return {
        'featureId': featureId,
        'usageCount': 0,
        'lastUsed': 0,
        'streakDays': 0,
        'bestScore': 0,
        'level': 1,
        'totalPlayed': 0,
        'extraJson': <String, dynamic>{},
      };
    }
    final row = Map<String, dynamic>.from(rows.first);
    try {
      row['extraJson'] = jsonDecode(row['extraJson'] as String? ?? '{}');
    } catch (_) {
      row['extraJson'] = <String, dynamic>{};
    }
    return row;
  }

  Future<void> saveFeatureStats(
    String featureId, {
    int? level,
    int? bestScore,
    int? totalPlayed,
    int? streakDays,
    Map<String, dynamic>? extra,
  }) async {
    final current = await featureStats(featureId);
    final db = await _database;
    await db.insert('feature_stats', {
      'featureId': featureId,
      'usageCount': (current['usageCount'] as int? ?? 0),
      'lastUsed': DateTime.now().millisecondsSinceEpoch,
      'streakDays': streakDays ?? (current['streakDays'] as int? ?? 0),
      'bestScore': bestScore ?? (current['bestScore'] as int? ?? 0),
      'level': level ?? (current['level'] as int? ?? 1),
      'totalPlayed': totalPlayed ?? (current['totalPlayed'] as int? ?? 0),
      'extraJson': jsonEncode(extra ?? (current['extraJson'] as Map? ?? {})),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Call on every screen open — increments usageCount, updates lastUsed, updates streak.
  Future<void> recordUsage(String featureId) async {
    final current = await featureStats(featureId);
    final lastUsed = current['lastUsed'] as int? ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastUsed);
    final today = DateTime.now();
    final daysSinceLast = today.difference(lastDate).inDays;
    int streak = current['streakDays'] as int? ?? 0;
    if (daysSinceLast == 1) streak++;
    else if (daysSinceLast > 1) streak = 1;
    // same day: keep streak

    final db = await _database;
    await db.insert('feature_stats', {
      'featureId': featureId,
      'usageCount': (current['usageCount'] as int? ?? 0) + 1,
      'lastUsed': now,
      'streakDays': streak,
      'bestScore': current['bestScore'] as int? ?? 0,
      'level': current['level'] as int? ?? 1,
      'totalPlayed': current['totalPlayed'] as int? ?? 0,
      'extraJson': jsonEncode(current['extraJson'] ?? {}),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> usageCount(String featureId) async {
    final s = await featureStats(featureId);
    return s['usageCount'] as int? ?? 0;
  }

  Future<int> streakDays(String featureId) async {
    final s = await featureStats(featureId);
    return s['streakDays'] as int? ?? 0;
  }

  /// Returns all feature stats sorted by usageCount desc — useful for dashboards.
  Future<List<Map<String, dynamic>>> allFeatureStats() async {
    final db = await _database;
    final rows = await db.query('feature_stats', orderBy: 'usageCount DESC');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      try { m['extraJson'] = jsonDecode(m['extraJson'] as String? ?? '{}'); } catch (_) {}
      return m;
    }).toList();
  }

  Future<void> resetFeature(String featureId) async {
    final db = await _database;
    await db.delete('feature_stats', where: 'featureId = ?', whereArgs: [featureId]);
  }
}
