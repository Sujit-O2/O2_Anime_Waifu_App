import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

/// Opens Spotify or the default music player using Android intents.
class MusicService {
  /// Tries to start Spotify with the given search query.
  /// Falls back to opening the default music app.
  static Future<String> playMusic(String query) async {
    if (!Platform.isAndroid) return "Music integration is Android only.";
    try {
      // Try Spotify first via Uri
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'spotify:search:${Uri.encodeComponent(query)}',
        package: 'com.spotify.music',
      );
      await intent.launch();
      return "🎵 Opening Spotify to search: **$query**";
    } catch (e) {
      debugPrint('Spotify intent failed: $e');
      // Fallback: open generic music player
      try {
        final fallback = AndroidIntent(
          action: 'android.intent.action.MUSIC_PLAYER',
        );
        await fallback.launch();
        return "🎵 Opened your music player! (Spotify not found, try installing it)";
      } catch (e2) {
        debugPrint('Music fallback failed: $e2');
        return "❌ Couldn't open a music player. Do you have Spotify or a music app installed?";
      }
    }
  }
}
