import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎵 Music Sync Service
/// 
/// Zero Two learns your music taste.
/// "This song matches your current mood 🎵"
/// Auto-creates playlists for different emotions.
class MusicSyncService {
  MusicSyncService._();
  static final MusicSyncService instance = MusicSyncService._();

  final List<MusicTrack> _listeningHistory = [];
  final Map<String, MusicPlaylist> _playlists = {};
  final Map<String, int> _genrePreferences = {};
  final Map<String, int> _artistPreferences = {};

  static const String _storageKey = 'music_sync_v1';
  static const int _maxHistory = 500;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[MusicSync] Initialized with ${_listeningHistory.length} tracks');
  }

  /// Record a track being played
  Future<void> recordTrack({
    required String title,
    required String artist,
    required String? album,
    required String? genre,
    required MusicMood mood,
    int? durationSeconds,
  }) async {
    final track = MusicTrack(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      mood: mood,
      durationSeconds: durationSeconds,
      timestamp: DateTime.now(),
    );

    _listeningHistory.insert(0, track);
    if (_listeningHistory.length > _maxHistory) {
      _listeningHistory.removeLast();
    }

    // Update preferences
    if (genre != null) {
      _genrePreferences[genre] = (_genrePreferences[genre] ?? 0) + 1;
    }
    _artistPreferences[artist] = (_artistPreferences[artist] ?? 0) + 1;

    await _saveData();
    
    if (kDebugMode) debugPrint('[MusicSync] Recorded: $title by $artist');
  }

  /// Get music recommendations based on current mood
  List<String> getRecommendations(MusicMood mood, {int limit = 10}) {
    final moodTracks = _listeningHistory
        .where((t) => t.mood == mood)
        .take(limit)
        .map((t) => '${t.title} by ${t.artist}')
        .toList();

    if (moodTracks.isEmpty) {
      return _getDefaultRecommendations(mood);
    }

    return moodTracks;
  }

  List<String> _getDefaultRecommendations(MusicMood mood) {
    switch (mood) {
      case MusicMood.happy:
        return ['Upbeat pop songs', 'Feel-good classics', 'Dance hits'];
      case MusicMood.sad:
        return ['Emotional ballads', 'Melancholic indie', 'Slow piano'];
      case MusicMood.energetic:
        return ['High-energy EDM', 'Rock anthems', 'Workout beats'];
      case MusicMood.calm:
        return ['Lo-fi chill', 'Ambient soundscapes', 'Acoustic covers'];
      case MusicMood.romantic:
        return ['Love songs', 'R&B slow jams', 'Romantic classics'];
      case MusicMood.focused:
        return ['Study music', 'Classical focus', 'Instrumental beats'];
      case MusicMood.nostalgic:
        return ['Throwback hits', 'Childhood favorites', 'Retro vibes'];
    }
  }

  /// Create or update a mood-based playlist
  Future<MusicPlaylist> createMoodPlaylist(MusicMood mood) async {
    final playlistId = 'mood_${mood.name}';
    final tracks = _listeningHistory
        .where((t) => t.mood == mood)
        .take(50)
        .toList();

    final playlist = MusicPlaylist(
      id: playlistId,
      name: '${mood.emoji} ${mood.label} Vibes',
      description: 'Auto-generated playlist for ${mood.label.toLowerCase()} moments',
      mood: mood,
      tracks: tracks,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _playlists[playlistId] = playlist;
    await _saveData();

    if (kDebugMode) debugPrint('[MusicSync] Created playlist: ${playlist.name}');
    return playlist;
  }

  /// Get all playlists
  List<MusicPlaylist> getAllPlaylists() => _playlists.values.toList();

  /// Get playlist by mood
  MusicPlaylist? getPlaylistByMood(MusicMood mood) {
    return _playlists['mood_${mood.name}'];
  }

  /// Analyze listening patterns
  Map<String, dynamic> analyzeListeningPatterns() {
    if (_listeningHistory.isEmpty) {
      return {
        'total_tracks': 0,
        'favorite_genre': 'Unknown',
        'favorite_artist': 'Unknown',
        'most_common_mood': 'Unknown',
      };
    }

    // Find favorite genre
    String favoriteGenre = 'Unknown';
    int maxGenreCount = 0;
    _genrePreferences.forEach((genre, count) {
      if (count > maxGenreCount) {
        maxGenreCount = count;
        favoriteGenre = genre;
      }
    });

    // Find favorite artist
    String favoriteArtist = 'Unknown';
    int maxArtistCount = 0;
    _artistPreferences.forEach((artist, count) {
      if (count > maxArtistCount) {
        maxArtistCount = count;
        favoriteArtist = artist;
      }
    });

    // Find most common mood
    final moodCounts = <MusicMood, int>{};
    for (final track in _listeningHistory) {
      moodCounts[track.mood] = (moodCounts[track.mood] ?? 0) + 1;
    }

    MusicMood mostCommonMood = MusicMood.happy;
    int maxMoodCount = 0;
    moodCounts.forEach((mood, count) {
      if (count > maxMoodCount) {
        maxMoodCount = count;
        mostCommonMood = mood;
      }
    });

    return {
      'total_tracks': _listeningHistory.length,
      'favorite_genre': favoriteGenre,
      'favorite_artist': favoriteArtist,
      'most_common_mood': mostCommonMood.label,
      'genre_breakdown': _genrePreferences,
      'top_artists': _getTopArtists(5),
      'mood_distribution': moodCounts.map((k, v) => MapEntry(k.label, v)),
    };
  }

  List<String> _getTopArtists(int limit) {
    final sorted = _artistPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get personalized music insights
  String getMusicInsights() {
    if (_listeningHistory.isEmpty) {
      return 'Start listening to music so I can learn your taste! 🎵';
    }

    final analysis = analyzeListeningPatterns();
    final buffer = StringBuffer();

    buffer.writeln('🎵 Your Music Profile\n');
    buffer.writeln('Total tracks: ${analysis['total_tracks']}');
    buffer.writeln('Favorite genre: ${analysis['favorite_genre']}');
    buffer.writeln('Favorite artist: ${analysis['favorite_artist']}');
    buffer.writeln('Most common mood: ${analysis['most_common_mood']}\n');

    final topArtists = analysis['top_artists'] as List<String>;
    if (topArtists.isNotEmpty) {
      buffer.writeln('🎤 Top Artists:');
      for (int i = 0; i < topArtists.length; i++) {
        buffer.writeln('  ${i + 1}. ${topArtists[i]}');
      }
      buffer.writeln();
    }

    buffer.writeln('💭 Zero Two\'s Take:');
    buffer.writeln(_getPersonalizedInsight(analysis));

    return buffer.toString();
  }

  String _getPersonalizedInsight(Map<String, dynamic> analysis) {
    final favoriteGenre = analysis['favorite_genre'] as String;
    final mostCommonMood = analysis['most_common_mood'] as String;

    if (favoriteGenre.toLowerCase().contains('rock')) {
      return 'You love rock music! Your energy is contagious, darling~ 🎸';
    } else if (favoriteGenre.toLowerCase().contains('pop')) {
      return 'Pop music lover! You appreciate catchy melodies and good vibes~ 🎤';
    } else if (favoriteGenre.toLowerCase().contains('classical')) {
      return 'Classical music shows your refined taste, darling~ 🎻';
    } else if (favoriteGenre.toLowerCase().contains('electronic')) {
      return 'Electronic beats! You\'re always ready to dance~ 🎧';
    } else if (mostCommonMood.toLowerCase().contains('calm')) {
      return 'You often seek calm music... I love these peaceful moments with you~ 😌';
    } else if (mostCommonMood.toLowerCase().contains('energetic')) {
      return 'So much energy in your music! Let\'s keep that spirit alive~ ⚡';
    }

    return 'Your music taste is unique and special, just like you~ 💕';
  }

  /// Suggest a song based on current context
  String suggestSong({
    required MusicMood mood,
    String? timeOfDay,
  }) {
    final recommendations = getRecommendations(mood, limit: 5);
    
    if (recommendations.isEmpty) {
      return 'Let me find the perfect song for your ${mood.label.toLowerCase()} mood~ 🎵';
    }

    final suggestion = recommendations.first;
    
    String context = '';
    if (timeOfDay == 'morning') {
      context = 'Perfect for starting your day! ';
    } else if (timeOfDay == 'evening') {
      context = 'Great for winding down~ ';
    } else if (timeOfDay == 'night') {
      context = 'Perfect late-night vibes~ ';
    }

    return '$context$suggestion 🎵';
  }

  /// Get recent listening history
  List<MusicTrack> getRecentHistory({int limit = 20}) {
    return _listeningHistory.take(limit).toList();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'history': _listeningHistory.map((t) => t.toJson()).toList(),
        'playlists': _playlists.map((k, v) => MapEntry(k, v.toJson())),
        'genrePreferences': _genrePreferences,
        'artistPreferences': _artistPreferences,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[MusicSync] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _listeningHistory.clear();
        _listeningHistory.addAll(
          (data['history'] as List<dynamic>)
              .map((t) => MusicTrack.fromJson(t as Map<String, dynamic>))
        );

        _playlists.clear();
        (data['playlists'] as Map<String, dynamic>).forEach((k, v) {
          _playlists[k] = MusicPlaylist.fromJson(v as Map<String, dynamic>);
        });

        _genrePreferences.clear();
        _genrePreferences.addAll(
          (data['genrePreferences'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as int)
          )
        );

        _artistPreferences.clear();
        _artistPreferences.addAll(
          (data['artistPreferences'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as int)
          )
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[MusicSync] Load error: $e');
    }
  }
}

class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? genre;
  final MusicMood mood;
  final int? durationSeconds;
  final DateTime timestamp;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.genre,
    required this.mood,
    this.durationSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'genre': genre,
    'mood': mood.name,
    'durationSeconds': durationSeconds,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MusicTrack.fromJson(Map<String, dynamic> json) => MusicTrack(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    album: json['album'] as String?,
    genre: json['genre'] as String?,
    mood: MusicMood.values.firstWhere(
      (e) => e.name == json['mood'],
      orElse: () => MusicMood.happy,
    ),
    durationSeconds: json['durationSeconds'] as int?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class MusicPlaylist {
  final String id;
  final String name;
  final String description;
  final MusicMood mood;
  final List<MusicTrack> tracks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MusicPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.mood,
    required this.tracks,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'mood': mood.name,
    'tracks': tracks.map((t) => t.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MusicPlaylist.fromJson(Map<String, dynamic> json) => MusicPlaylist(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    mood: MusicMood.values.firstWhere(
      (e) => e.name == json['mood'],
      orElse: () => MusicMood.happy,
    ),
    tracks: (json['tracks'] as List<dynamic>)
        .map((t) => MusicTrack.fromJson(t as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

enum MusicMood {
  happy,
  sad,
  energetic,
  calm,
  romantic,
  focused,
  nostalgic;

  String get label {
    switch (this) {
      case MusicMood.happy: return 'Happy';
      case MusicMood.sad: return 'Sad';
      case MusicMood.energetic: return 'Energetic';
      case MusicMood.calm: return 'Calm';
      case MusicMood.romantic: return 'Romantic';
      case MusicMood.focused: return 'Focused';
      case MusicMood.nostalgic: return 'Nostalgic';
    }
  }

  String get emoji {
    switch (this) {
      case MusicMood.happy: return '😊';
      case MusicMood.sad: return '😢';
      case MusicMood.energetic: return '⚡';
      case MusicMood.calm: return '😌';
      case MusicMood.romantic: return '💕';
      case MusicMood.focused: return '🎯';
      case MusicMood.nostalgic: return '🌅';
    }
  }
}
