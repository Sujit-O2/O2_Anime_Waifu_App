import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent key-value memory for the AI assistant.
/// Facts are stored in SharedPreferences and injected into the system prompt.
class MemoryService {
  static const String _prefKey = 'assistant_memory_v1';
  static const int _maxFacts = 30;

  /// Save a key-value fact, e.g. ("my dog's name", "Bruno")
  static Future<void> saveFact(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    final Map<String, String> facts =
        raw != null ? Map<String, String>.from(jsonDecode(raw) as Map) : {};
    facts[key.trim().toLowerCase()] = value.trim();
    // Keep max facts to avoid bloating the prompt
    if (facts.length > _maxFacts) {
      final oldest = facts.keys.first;
      facts.remove(oldest);
    }
    await prefs.setString(_prefKey, jsonEncode(facts));
  }

  /// Get all stored facts as a Map
  static Future<Map<String, String>> getAllFacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  /// Get a single fact value by key, or null if not found
  static Future<String?> getFact(String key) async {
    final facts = await getAllFacts();
    return facts[key.trim().toLowerCase()];
  }

  /// Format all facts as a concise system prompt injection string
  static Future<String> buildMemoryPromptBlock() async {
    final facts = await getAllFacts();
    if (facts.isEmpty) return '';
    final lines = facts.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
    return '\n[Things you know about me that I told you before]:\n$lines\n';
  }

  /// Clear all memory
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  /// Delete a specific fact
  static Future<void> deleteFact(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    final Map<String, String> facts =
        Map<String, String>.from(jsonDecode(raw) as Map);
    facts.remove(key.trim().toLowerCase());
    await prefs.setString(_prefKey, jsonEncode(facts));
  }
}
