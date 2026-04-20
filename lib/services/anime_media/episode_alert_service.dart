import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Episode Alert Service — checks for new episodes of followed anime.
/// Uses Jikan API to poll for newly aired episodes.
class EpisodeAlertService {
  static const String _followedKey = 'episode_alerts_followed';
  static const String _lastCheckKey = 'episode_alerts_last_check';
  static const String _alertsKey = 'episode_alerts_pending';

  /// Follow an anime for new episode alerts.
  static Future<void> followAnime(FollowedAnime anime) async {
    final list = await getFollowedAnime();
    if (list.any((e) => e.malId == anime.malId)) return;
    list.add(anime);
    await _saveFollowed(list);
  }

  /// Unfollow an anime.
  static Future<void> unfollowAnime(int malId) async {
    final list = await getFollowedAnime();
    list.removeWhere((e) => e.malId == malId);
    await _saveFollowed(list);
  }

  /// Check if an anime is being followed.
  static Future<bool> isFollowed(int malId) async {
    final list = await getFollowedAnime();
    return list.any((e) => e.malId == malId);
  }

  /// Get all followed anime.
  static Future<List<FollowedAnime>> getFollowedAnime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_followedKey) ?? [];
    return raw.map((s) => FollowedAnime.fromJson(jsonDecode(s))).toList();
  }

  /// Check for new episodes (call periodically or on app launch).
  static Future<List<EpisodeAlert>> checkForNewEpisodes() async {
    final followed = await getFollowedAnime();
    if (followed.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final alerts = <EpisodeAlert>[];

    for (final anime in followed) {
      try {
        final resp = await http.get(
          Uri.parse('https://api.jikan.moe/v4/anime/${anime.malId}'),
          headers: {'User-Agent': 'AnimeWaifuApp/3.0'},
        ).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body)['data'] as Map<String, dynamic>? ?? {};
          final currentEps = data['episodes'] as int? ?? 0;
          final status = data['status'] as String? ?? '';

          if (currentEps > anime.lastKnownEpisode) {
            alerts.add(EpisodeAlert(
              malId: anime.malId,
              title: anime.title,
              coverUrl: anime.coverUrl,
              newEpisode: currentEps,
              previousEpisode: anime.lastKnownEpisode,
            ));

            // Update the last known episode count
            anime.lastKnownEpisode = currentEps;
          }

          // Update airing status
          anime.isAiring = status == 'Currently Airing';
        }

        // Rate limiting
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (e) {
        debugPrint('Alert check failed for ${anime.title}: $e');
      }
    }

    // Save updated followed list and alerts
    await _saveFollowed(followed);
    if (alerts.isNotEmpty) {
      await _saveAlerts(alerts);
    }

    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());

    return alerts;
  }

  /// Get pending alerts (not yet seen by user).
  static Future<List<EpisodeAlert>> getPendingAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_alertsKey) ?? [];
    return raw.map((s) => EpisodeAlert.fromJson(jsonDecode(s))).toList();
  }

  /// Clear all pending alerts.
  static Future<void> clearAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alertsKey);
  }

  /// Get last check timestamp.
  static Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastCheckKey);
    return str != null ? DateTime.tryParse(str) : null;
  }

  static Future<void> _saveFollowed(List<FollowedAnime> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _followedKey,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> _saveAlerts(List<EpisodeAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_alertsKey) ?? [];
    final all = [...existing, ...alerts.map((a) => jsonEncode(a.toJson()))];
    await prefs.setStringList(_alertsKey, all);
  }
}

class FollowedAnime {
  final int malId;
  final String title;
  final String coverUrl;
  int lastKnownEpisode;
  bool isAiring;

  FollowedAnime({
    required this.malId, required this.title, required this.coverUrl,
    required this.lastKnownEpisode, this.isAiring = true,
  });

  Map<String, dynamic> toJson() => {
    'malId': malId, 'title': title, 'coverUrl': coverUrl,
    'lastKnownEpisode': lastKnownEpisode, 'isAiring': isAiring,
  };

  factory FollowedAnime.fromJson(Map<String, dynamic> j) => FollowedAnime(
    malId: j['malId'] ?? 0, title: j['title'] ?? '', coverUrl: j['coverUrl'] ?? '',
    lastKnownEpisode: j['lastKnownEpisode'] ?? 0, isAiring: j['isAiring'] ?? true,
  );
}

class EpisodeAlert {
  final int malId;
  final String title;
  final String coverUrl;
  final int newEpisode;
  final int previousEpisode;
  final DateTime createdAt;

  EpisodeAlert({
    required this.malId, required this.title, required this.coverUrl,
    required this.newEpisode, required this.previousEpisode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'malId': malId, 'title': title, 'coverUrl': coverUrl,
    'newEpisode': newEpisode, 'previousEpisode': previousEpisode,
    'createdAt': createdAt.toIso8601String(),
  };

  factory EpisodeAlert.fromJson(Map<String, dynamic> j) => EpisodeAlert(
    malId: j['malId'] ?? 0, title: j['title'] ?? '', coverUrl: j['coverUrl'] ?? '',
    newEpisode: j['newEpisode'] ?? 0, previousEpisode: j['previousEpisode'] ?? 0,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}


