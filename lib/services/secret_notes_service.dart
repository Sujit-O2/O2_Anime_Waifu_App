import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple XOR-obfuscated secret notes stored in SharedPreferences.
class SecretNotesService {
  static const _notesKey = 'secret_notes_v1';
  static const _pinKey = 'secret_notes_pin_v1';
  static const int _xorKey = 0x5A; // simple obfuscation

  static String _obfuscate(String text) {
    return base64Encode(text.codeUnits.map((c) => c ^ _xorKey).toList());
  }

  static String _deobfuscate(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      return String.fromCharCodes(bytes.map((b) => b ^ _xorKey));
    } catch (_) {
      return encoded;
    }
  }

  // ── PIN ──────────────────────────────────────────────────────────────────

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _obfuscate(pin));
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    if (stored == null) return true; // no PIN set
    return _deobfuscate(stored) == pin;
  }

  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, String>>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = _deobfuscate(raw);
      return List<Map<String, String>>.from((jsonDecode(decoded) as List)
          .map((e) => Map<String, String>.from(e as Map)));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveNote(String title, String content) async {
    final notes = await getAllNotes();
    notes.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'content': content,
      'ts': DateTime.now().toIso8601String(),
    });
    await _persist(notes);
  }

  static Future<void> deleteNote(String id) async {
    final notes = await getAllNotes();
    notes.removeWhere((n) => n['id'] == id);
    await _persist(notes);
  }

  static Future<void> _persist(List<Map<String, String>> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notesKey, _obfuscate(jsonEncode(notes)));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notesKey);
  }
}
