import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// MyAnimeList Sync using Jikan API.
/// Requires NO API Key or OAuth login — just a username!
class MalSyncService {
  static const String _usernameKey = 'mal_username';
  static const String _malStatusKey = 'mal_sync_enabled';

  /// Check if MAL sync is configured.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_malStatusKey) ?? false;
  }

  /// Save MAL Username.
  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username.trim());
    await prefs.setBool(_malStatusKey, username.trim().isNotEmpty);
  }

  /// Get stored Username.
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// Logout / disconnect MAL.
  static Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.setBool(_malStatusKey, false);
  }

  /// Get the user's MAL anime list via Jikan API v4.
  static Future<List<MalAnimeEntry>> getMyList({int limit = 50}) async {
    final username = await getUsername();
    if (username == null || username.isEmpty) return [];

    try {
      final resp = await http.get(
        Uri.parse('https://api.jikan.moe/v4/users/$username/animelist'),
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];

      return data.take(limit).map((e) {
        final entry = e as Map<String, dynamic>;
        final anime = entry['anime'] as Map<String, dynamic>? ?? {};
        final images = anime['images'] as Map<String, dynamic>? ?? {};
        final jpg = images['jpg'] as Map<String, dynamic>? ?? {};
        
        // Map Jikan status int to MAL string
        String statusStr = 'Unknown';
        final statusCode = entry['watching_status'] as int? ?? 0;
        switch (statusCode) {
          case 1: statusStr = 'watching'; break;
          case 2: statusStr = 'completed'; break;
          case 3: statusStr = 'on_hold'; break;
          case 4: statusStr = 'dropped'; break;
          case 6: statusStr = 'plan_to_watch'; break;
        }

        return MalAnimeEntry(
          malId: anime['mal_id'] as int? ?? 0,
          title: anime['title'] as String? ?? 'Unknown Anime',
          coverUrl: jpg['large_image_url'] ?? jpg['image_url'] ?? '',
          status: statusStr,
          episodesWatched: entry['episodes_watched'] as int? ?? 0,
          score: entry['score'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('MAL list fetch failed: $e');
      return [];
    }
  }
}

class MalAnimeEntry {
  final int malId;
  final String title;
  final String coverUrl;
  final String status;
  final int episodesWatched;
  final int score;

  MalAnimeEntry({
    required this.malId,
    required this.title,
    required this.coverUrl,
    required this.status,
    required this.episodesWatched,
    required this.score,
  });
}
