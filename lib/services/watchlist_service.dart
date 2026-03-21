import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified watchlist for both anime and manga.
/// Stores locally in SharedPrefs, can sync to Firestore later.
class WatchlistService {
  static const String _animeKey = 'watchlist_anime';
  static const String _mangaKey = 'watchlist_manga';

  // ── Anime Watchlist ──

  static Future<List<WatchlistItem>> getAnimeWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_animeKey) ?? [];
    return raw.map((s) => WatchlistItem.fromJson(jsonDecode(s))).toList();
  }

  static Future<void> addAnime(WatchlistItem item) async {
    final list = await getAnimeWatchlist();
    if (list.any((e) => e.id == item.id)) return; // Already exists
    list.insert(0, item);
    await _saveAnimeList(list);
  }

  static Future<void> removeAnime(String id) async {
    final list = await getAnimeWatchlist();
    list.removeWhere((e) => e.id == id);
    await _saveAnimeList(list);
  }

  static Future<bool> isAnimeFavorited(String id) async {
    final list = await getAnimeWatchlist();
    return list.any((e) => e.id == id);
  }

  static Future<void> _saveAnimeList(List<WatchlistItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _animeKey,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  // ── Manga Watchlist ──

  static Future<List<WatchlistItem>> getMangaWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_mangaKey) ?? [];
    return raw.map((s) => WatchlistItem.fromJson(jsonDecode(s))).toList();
  }

  static Future<void> addManga(WatchlistItem item) async {
    final list = await getMangaWatchlist();
    if (list.any((e) => e.id == item.id)) return;
    list.insert(0, item);
    await _saveMangaList(list);
  }

  static Future<void> removeManga(String id) async {
    final list = await getMangaWatchlist();
    list.removeWhere((e) => e.id == id);
    await _saveMangaList(list);
  }

  static Future<bool> isMangaFavorited(String id) async {
    final list = await getMangaWatchlist();
    return list.any((e) => e.id == id);
  }

  static Future<void> _saveMangaList(List<WatchlistItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _mangaKey,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

/// A single item in the watchlist (works for both anime and manga).
class WatchlistItem {
  final String id;
  final String title;
  final String coverUrl;
  final String type; // 'anime' or 'manga'
  final DateTime addedAt;

  WatchlistItem({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.type,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'coverUrl': coverUrl,
    'type': type, 'addedAt': addedAt.toIso8601String(),
  };

  factory WatchlistItem.fromJson(Map<String, dynamic> j) => WatchlistItem(
    id: j['id'] ?? '', title: j['title'] ?? '',
    coverUrl: j['coverUrl'] ?? '', type: j['type'] ?? 'anime',
    addedAt: DateTime.tryParse(j['addedAt'] ?? '') ?? DateTime.now(),
  );
}
