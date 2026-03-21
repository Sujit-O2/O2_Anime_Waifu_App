import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks watch history with position for auto-resume.
class WatchHistoryService {
  static const String _key = 'watch_history';

  static Future<List<WatchHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = raw.map((s) => WatchHistoryEntry.fromJson(jsonDecode(s))).toList();
    entries.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return entries;
  }

  /// Save or update watch progress for an episode.
  static Future<void> saveProgress({
    required String animeId,
    required String animeTitle,
    required String animeCoverUrl,
    required String episodeId,
    required int episodeNumber,
    required int positionMs,
    required int durationMs,
  }) async {
    final list = await getHistory();
    // Remove existing entry for same anime+episode
    list.removeWhere((e) => e.animeId == animeId && e.episodeId == episodeId);
    list.insert(0, WatchHistoryEntry(
      animeId: animeId, animeTitle: animeTitle, animeCoverUrl: animeCoverUrl,
      episodeId: episodeId, episodeNumber: episodeNumber,
      positionMs: positionMs, durationMs: durationMs,
      watchedAt: DateTime.now(),
    ));
    // Keep only last 100 entries
    if (list.length > 100) list.removeRange(100, list.length);
    await _save(list);
  }

  /// Get last watched position for a specific episode.
  static Future<int?> getLastPosition(String animeId, String episodeId) async {
    final list = await getHistory();
    final entry = list.cast<WatchHistoryEntry?>().firstWhere(
      (e) => e!.animeId == animeId && e.episodeId == episodeId,
      orElse: () => null,
    );
    return entry?.positionMs;
  }

  /// Get the "Continue Watching" list (most recent per anime).
  static Future<List<WatchHistoryEntry>> getContinueWatching() async {
    final list = await getHistory();
    final seen = <String>{};
    final continueList = <WatchHistoryEntry>[];
    for (final e in list) {
      if (seen.contains(e.animeId)) continue;
      // Only show if not finished (< 90% watched)
      if (e.durationMs > 0 && e.positionMs / e.durationMs < 0.9) {
        continueList.add(e);
        seen.add(e.animeId);
      }
    }
    return continueList.take(20).toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> _save(List<WatchHistoryEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

class WatchHistoryEntry {
  final String animeId;
  final String animeTitle;
  final String animeCoverUrl;
  final String episodeId;
  final int episodeNumber;
  final int positionMs;
  final int durationMs;
  final DateTime watchedAt;

  WatchHistoryEntry({
    required this.animeId, required this.animeTitle, required this.animeCoverUrl,
    required this.episodeId, required this.episodeNumber,
    required this.positionMs, required this.durationMs, required this.watchedAt,
  });

  double get progress => durationMs > 0 ? positionMs / durationMs : 0;
  String get progressText {
    final mins = positionMs ~/ 60000;
    final total = durationMs ~/ 60000;
    return '${mins}m / ${total}m';
  }

  Map<String, dynamic> toJson() => {
    'animeId': animeId, 'animeTitle': animeTitle, 'animeCoverUrl': animeCoverUrl,
    'episodeId': episodeId, 'episodeNumber': episodeNumber,
    'positionMs': positionMs, 'durationMs': durationMs,
    'watchedAt': watchedAt.toIso8601String(),
  };

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> j) => WatchHistoryEntry(
    animeId: j['animeId'] ?? '', animeTitle: j['animeTitle'] ?? '',
    animeCoverUrl: j['animeCoverUrl'] ?? '', episodeId: j['episodeId'] ?? '',
    episodeNumber: j['episodeNumber'] ?? 0, positionMs: j['positionMs'] ?? 0,
    durationMs: j['durationMs'] ?? 0,
    watchedAt: DateTime.tryParse(j['watchedAt'] ?? '') ?? DateTime.now(),
  );
}
