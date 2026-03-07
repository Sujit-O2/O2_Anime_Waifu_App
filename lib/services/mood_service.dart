import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily mood entries for the AI to reference.
class MoodService {
  static const _key = 'mood_tracker_v1';

  static const List<String> moods = [
    '😄 Happy',
    '😊 Good',
    '😐 Neutral',
    '😔 Sad',
    '😤 Frustrated',
    '😴 Tired',
    '💪 Motivated',
    '😰 Anxious',
  ];

  /// Save mood entry with timestamp
  static Future<void> saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final List<Map<String, String>> entries = raw != null
        ? List<Map<String, String>>.from((jsonDecode(raw) as List)
            .map((e) => Map<String, String>.from(e as Map)))
        : [];
    entries.add({
      'mood': mood,
      'ts': DateTime.now().toIso8601String(),
    });
    // Keep last 90 entries
    if (entries.length > 90) entries.removeRange(0, entries.length - 90);
    await prefs.setString(_key, jsonEncode(entries));
  }

  /// Get all mood entries
  static Future<List<Map<String, String>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    return List<Map<String, String>>.from((jsonDecode(raw) as List)
        .map((e) => Map<String, String>.from(e as Map)));
  }

  /// Get most recent mood
  static Future<String?> getLatestMood() async {
    final entries = await getAll();
    if (entries.isEmpty) return null;
    return entries.last['mood'];
  }

  /// Get mood summary string for AI context
  static Future<String> buildMoodContext() async {
    final entries = await getAll();
    if (entries.isEmpty) return '';
    final recent = entries.reversed.take(7).toList();
    final lines = recent
        .map((e) {
          final ts = DateTime.tryParse(e['ts'] ?? '') ?? DateTime.now();
          return '${ts.month}/${ts.day}: ${e['mood']}';
        })
        .toList()
        .reversed
        .join(', ');
    return '\n[Mood history (last 7 days)]: $lines\n';
  }

  /// Clear all mood history
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
