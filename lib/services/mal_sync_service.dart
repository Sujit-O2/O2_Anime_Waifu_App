import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// MyAnimeList Sync — OAuth2 login + watch history sync.
/// Note: Requires a MAL API Client ID registered at myanimelist.net/apiconfig.
class MalSyncService {
  static const String _clientIdKey = 'mal_client_id';
  static const String _tokenKey = 'mal_access_token';
  static const String _refreshTokenKey = 'mal_refresh_token';
  static const String _malStatusKey = 'mal_sync_enabled';

  static const String _malApiBase = 'https://api.myanimelist.net/v2';

  /// Check if MAL sync is configured.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_malStatusKey) ?? false;
  }

  /// Save MAL API Client ID.
  static Future<void> setClientId(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clientIdKey, clientId);
  }

  /// Get stored Client ID.
  static Future<String?> getClientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clientIdKey);
  }

  /// Save access token from OAuth2 flow.
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setBool(_malStatusKey, true);
  }

  /// Get access token.
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Logout / disconnect MAL.
  static Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.setBool(_malStatusKey, false);
  }

  /// Get the user's MAL anime list.
  static Future<List<MalAnimeEntry>> getMyList({int limit = 50}) async {
    final token = await getAccessToken();
    if (token == null) return [];

    try {
      final resp = await http.get(
        Uri.parse('$_malApiBase/users/@me/animelist?fields=list_status&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'AnimeWaifuApp/3.0',
        },
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];

      return data.map((e) {
        final entry = e as Map<String, dynamic>;
        final node = entry['node'] as Map<String, dynamic>? ?? {};
        final listStatus = entry['list_status'] as Map<String, dynamic>? ?? {};
        return MalAnimeEntry(
          malId: node['id'] as int? ?? 0,
          title: node['title'] as String? ?? '',
          coverUrl: (node['main_picture'] as Map<String, dynamic>?)?['large'] ?? '',
          status: listStatus['status'] as String? ?? '',
          episodesWatched: listStatus['num_episodes_watched'] as int? ?? 0,
          score: listStatus['score'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('MAL list fetch failed: $e');
      return [];
    }
  }

  /// Update anime status on MAL.
  static Future<bool> updateAnimeStatus({
    required int malId,
    required String status, // 'watching', 'completed', 'plan_to_watch', etc.
    int? episodesWatched,
    int? score,
  }) async {
    final token = await getAccessToken();
    if (token == null) return false;

    try {
      final body = <String, String>{
        'status': status,
      };
      if (episodesWatched != null) body['num_watched_episodes'] = '$episodesWatched';
      if (score != null) body['score'] = '$score';

      final resp = await http.patch(
        Uri.parse('$_malApiBase/anime/$malId/my_list_status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'AnimeWaifuApp/3.0',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('MAL update failed: $e');
      return false;
    }
  }

  /// Get OAuth2 authorization URL.
  static Future<String?> getAuthUrl() async {
    final clientId = await getClientId();
    if (clientId == null || clientId.isEmpty) return null;
    return 'https://myanimelist.net/v1/oauth2/authorize'
        '?response_type=code&client_id=$clientId'
        '&code_challenge=anime_waifu_challenge_string'
        '&code_challenge_method=plain';
  }

  /// Exchange authorization code for tokens.
  static Future<bool> exchangeCode(String code) async {
    final clientId = await getClientId();
    if (clientId == null) return false;

    try {
      final resp = await http.post(
        Uri.parse('https://myanimelist.net/v1/oauth2/token'),
        body: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'code_verifier': 'anime_waifu_challenge_string',
        },
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        await saveTokens(
          json['access_token'] as String,
          json['refresh_token'] as String? ?? '',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Token exchange failed: $e');
    }
    return false;
  }
}

class MalAnimeEntry {
  final int malId;
  final String title;
  final String coverUrl;
  final String status;
  final int episodesWatched;
  final int score;

  MalAnimeEntry({required this.malId, required this.title,
    required this.coverUrl, required this.status,
    required this.episodesWatched, required this.score});
}
