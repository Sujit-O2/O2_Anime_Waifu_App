import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 🎵 Spotify Integration Service
/// 
/// Real Spotify API integration for Zero Two.
/// Auto-detects currently playing songs, creates playlists, and syncs with MusicSyncService.
/// 
/// Features:
/// - OAuth2 authentication with Spotify
/// - Real-time "Now Playing" detection
/// - Auto-create mood-based playlists on Spotify
/// - Sync listening history with Zero Two's memory
/// - Smart recommendations based on your actual Spotify data
class SpotifyIntegrationService {
  SpotifyIntegrationService._();
  static final SpotifyIntegrationService instance = SpotifyIntegrationService._();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  Timer? _nowPlayingPoller;
  
  String? _currentTrackId;
  bool _isAuthenticated = false;

  static const String _storageKey = 'spotify_auth_v1';
  static const String _baseUrl = 'https://api.spotify.com/v1';
  
  // Replace with your Spotify app credentials
  static const String _clientId = 'YOUR_SPOTIFY_CLIENT_ID';
  static const String _clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
  static const String _redirectUri = 'com.zerotwo.waifu://callback';

  bool get isAuthenticated => _isAuthenticated;
  String? get currentTrackId => _currentTrackId;

  Future<void> initialize() async {
    await _loadTokens();
    
    if (_isAuthenticated && _tokenExpiry != null) {
      if (DateTime.now().isAfter(_tokenExpiry!)) {
        await _refreshAccessToken();
      }
      startNowPlayingMonitor();
    }
    
    if (kDebugMode) debugPrint('[Spotify] Initialized (authenticated: $_isAuthenticated)');
  }

  /// Start OAuth2 authentication flow
  String getAuthUrl() {
    final scopes = [
      'user-read-currently-playing',
      'user-read-playback-state',
      'user-top-read',
      'playlist-modify-public',
      'playlist-modify-private',
      'user-library-read',
    ].join('%20');

    return 'https://accounts.spotify.com/authorize?'
        'client_id=$_clientId&'
        'response_type=code&'
        'redirect_uri=$_redirectUri&'
        'scope=$scopes';
  }

  /// Exchange authorization code for access token
  Future<bool> authenticate(String authCode) async {
    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': authCode,
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        _isAuthenticated = true;

        await _saveTokens();
        startNowPlayingMonitor();

        if (kDebugMode) debugPrint('[Spotify] Authentication successful');
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Auth error: $e');
    }
    return false;
  }

  /// Refresh access token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));

        await _saveTokens();
        if (kDebugMode) debugPrint('[Spotify] Token refreshed');
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Refresh error: $e');
    }
    return false;
  }

  /// Start monitoring currently playing track
  void startNowPlayingMonitor() {
    _nowPlayingPoller?.cancel();
    _nowPlayingPoller = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkNowPlaying();
    });
    if (kDebugMode) debugPrint('[Spotify] Now playing monitor started');
  }

  /// Stop monitoring
  void stopNowPlayingMonitor() {
    _nowPlayingPoller?.cancel();
    if (kDebugMode) debugPrint('[Spotify] Now playing monitor stopped');
  }

  /// Check currently playing track
  Future<SpotifyTrack?> _checkNowPlaying() async {
    if (!_isAuthenticated || _accessToken == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me/player/currently-playing'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['item'] != null) {
          final track = SpotifyTrack.fromJson(data['item']);
          
          // Only trigger if track changed
          if (track.id != _currentTrackId) {
            _currentTrackId = track.id;
            onTrackChanged?.call(track);
            
            if (kDebugMode) debugPrint('[Spotify] Now playing: ${track.name} by ${track.artist}');
          }
          
          return track;
        }
      } else if (response.statusCode == 401) {
        // Token expired, refresh it
        await _refreshAccessToken();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Now playing error: $e');
    }
    return null;
  }

  /// Get user's top tracks
  Future<List<SpotifyTrack>> getTopTracks({
    String timeRange = 'medium_term', // short_term, medium_term, long_term
    int limit = 20,
  }) async {
    if (!_isAuthenticated || _accessToken == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me/top/tracks?time_range=$timeRange&limit=$limit'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        return items.map((item) => SpotifyTrack.fromJson(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Top tracks error: $e');
    }
    return [];
  }

  /// Get user's top artists
  Future<List<SpotifyArtist>> getTopArtists({
    String timeRange = 'medium_term',
    int limit = 20,
  }) async {
    if (!_isAuthenticated || _accessToken == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me/top/artists?time_range=$timeRange&limit=$limit'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        return items.map((item) => SpotifyArtist.fromJson(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Top artists error: $e');
    }
    return [];
  }

  /// Create a playlist on Spotify
  Future<String?> createPlaylist({
    required String name,
    required String description,
    required List<String> trackUris,
  }) async {
    if (!_isAuthenticated || _accessToken == null) return null;

    try {
      // Get user ID first
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (userResponse.statusCode != 200) return null;

      final userId = jsonDecode(userResponse.body)['id'];

      // Create playlist
      final createResponse = await http.post(
        Uri.parse('$_baseUrl/users/$userId/playlists'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'public': false,
        }),
      );

      if (createResponse.statusCode == 201) {
        final playlistId = jsonDecode(createResponse.body)['id'];

        // Add tracks to playlist
        if (trackUris.isNotEmpty) {
          await http.post(
            Uri.parse('$_baseUrl/playlists/$playlistId/tracks'),
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'uris': trackUris}),
          );
        }

        if (kDebugMode) debugPrint('[Spotify] Created playlist: $name');
        return playlistId;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Create playlist error: $e');
    }
    return null;
  }

  /// Get recommendations based on seed tracks/artists
  Future<List<SpotifyTrack>> getRecommendations({
    List<String>? seedTracks,
    List<String>? seedArtists,
    List<String>? seedGenres,
    int limit = 20,
  }) async {
    if (!_isAuthenticated || _accessToken == null) return [];

    final params = <String, String>{
      'limit': limit.toString(),
    };

    if (seedTracks != null && seedTracks.isNotEmpty) {
      params['seed_tracks'] = seedTracks.take(5).join(',');
    }
    if (seedArtists != null && seedArtists.isNotEmpty) {
      params['seed_artists'] = seedArtists.take(5).join(',');
    }
    if (seedGenres != null && seedGenres.isNotEmpty) {
      params['seed_genres'] = seedGenres.take(5).join(',');
    }

    try {
      final uri = Uri.parse('$_baseUrl/recommendations').replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracks = data['tracks'] as List;
        return tracks.map((track) => SpotifyTrack.fromJson(track)).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Recommendations error: $e');
    }
    return [];
  }

  /// Search for tracks
  Future<List<SpotifyTrack>> searchTracks(String query, {int limit = 20}) async {
    if (!_isAuthenticated || _accessToken == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}&type=track&limit=$limit'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['tracks']['items'] as List;
        return items.map((item) => SpotifyTrack.fromJson(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Search error: $e');
    }
    return [];
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _isAuthenticated = false;
    _currentTrackId = null;

    stopNowPlayingMonitor();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    if (kDebugMode) debugPrint('[Spotify] Logged out');
  }

  Future<void> _saveTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode({
        'accessToken': _accessToken,
        'refreshToken': _refreshToken,
        'tokenExpiry': _tokenExpiry?.toIso8601String(),
      }));
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Save tokens error: $e');
    }
  }

  Future<void> _loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _tokenExpiry = data['tokenExpiry'] != null
            ? DateTime.parse(data['tokenExpiry'])
            : null;
        _isAuthenticated = _accessToken != null && _refreshToken != null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Spotify] Load tokens error: $e');
    }
  }

  /// Callback when track changes
  void Function(SpotifyTrack track)? onTrackChanged;

  void dispose() {
    stopNowPlayingMonitor();
  }
}

class SpotifyTrack {
  final String id;
  final String name;
  final String artist;
  final String? album;
  final String? albumArt;
  final int durationMs;
  final String uri;
  final List<String> genres;

  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    this.album,
    this.albumArt,
    required this.durationMs,
    required this.uri,
    required this.genres,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List;
    final artistName = artists.isNotEmpty ? artists[0]['name'] : 'Unknown';

    final album = json['album'];
    final albumName = album?['name'];
    final images = album?['images'] as List?;
    final albumArt = images != null && images.isNotEmpty ? images[0]['url'] : null;

    return SpotifyTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      artist: artistName,
      album: albumName,
      albumArt: albumArt,
      durationMs: json['duration_ms'] ?? 0,
      uri: json['uri'] ?? '',
      genres: [], // Genres not available in track object
    );
  }
}

class SpotifyArtist {
  final String id;
  final String name;
  final List<String> genres;
  final String? imageUrl;
  final int popularity;

  const SpotifyArtist({
    required this.id,
    required this.name,
    required this.genres,
    this.imageUrl,
    required this.popularity,
  });

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty ? images[0]['url'] : null;

    return SpotifyArtist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      genres: List<String>.from(json['genres'] ?? []),
      imageUrl: imageUrl,
      popularity: json['popularity'] ?? 0,
    );
  }
}
