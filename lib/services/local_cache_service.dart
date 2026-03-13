import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

/// LocalCacheService caches the last 100 chat messages to SharedPreferences
/// so they can be restored if Firestore is unreachable.
class LocalCacheService {
  static const String _cacheKey = 'local_chat_cache_v1';
  static const int _maxMessages = 100;

  /// Save messages to local device cache.
  static Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = messages.length > _maxMessages
          ? messages.sublist(messages.length - _maxMessages)
          : messages;
      final encoded = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (e) {
      // Silently fail
    }
  }

  /// Load messages from local device cache.
  static Future<List<ChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear the local cache.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
