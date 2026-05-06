import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Stores per-game: level, bestScore, totalGamesPlayed
class GameProgressDB {
  GameProgressDB._();
  static final GameProgressDB instance = GameProgressDB._();
  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'game_progress.db');
    return openDatabase(path, version: 1, onCreate: (db, _) {
      return db.execute('''
        CREATE TABLE progress (
          gameId TEXT PRIMARY KEY,
          level INTEGER NOT NULL DEFAULT 1,
          bestScore INTEGER NOT NULL DEFAULT 0,
          totalPlayed INTEGER NOT NULL DEFAULT 0
        )
      ''');
    });
  }

  Future<Map<String, dynamic>> load(String gameId) async {
    final d = await db;
    final rows = await d.query('progress', where: 'gameId = ?', whereArgs: [gameId]);
    if (rows.isEmpty) return {'level': 1, 'bestScore': 0, 'totalPlayed': 0};
    return rows.first;
  }

  Future<void> save(String gameId, {required int level, required int bestScore, required int totalPlayed}) async {
    final d = await db;
    await d.insert('progress', {
      'gameId': gameId,
      'level': level,
      'bestScore': bestScore,
      'totalPlayed': totalPlayed,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBestScore(String gameId, int score) async {
    final current = await load(gameId);
    final best = current['bestScore'] as int;
    final level = current['level'] as int;
    final played = (current['totalPlayed'] as int) + 1;
    await save(gameId, level: level, bestScore: score > best ? score : best, totalPlayed: played);
  }

  Future<void> updateLevel(String gameId, int newLevel) async {
    final current = await load(gameId);
    await save(gameId,
      level: newLevel,
      bestScore: current['bestScore'] as int,
      totalPlayed: current['totalPlayed'] as int,
    );
  }

  Future<Map<String, Map<String, dynamic>>> loadAll(List<String> gameIds) async {
    final result = <String, Map<String, dynamic>>{};
    for (final id in gameIds) {
      result[id] = await load(id);
    }
    return result;
  }
}
