import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enhanced memory service that persists key-value user facts
/// to Firestore under users/{uid}/memory_facts.
///
/// Call [buildMemoryBlock] to get an injectable string for the AI system prompt.
class EnhancedMemoryService {
  static final EnhancedMemoryService instance = EnhancedMemoryService._();
  EnhancedMemoryService._();

  static const int _maxFacts = 30;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('memory_facts');
  }

  /// Saves a key-value fact. Overwrites existing fact with same key.
  Future<void> saveFact(String key, String value) async {
    try {
      final col = _col;
      if (col == null) return;
      await col.doc(_sanitize(key)).set({
        'key': key,
        'value': value,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Recalls a specific fact by key. Returns null if not found.
  Future<String?> recallFact(String key) async {
    try {
      final col = _col;
      if (col == null) return null;
      final doc = await col.doc(_sanitize(key)).get();
      if (!doc.exists) return null;
      return doc.data()?['value'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Returns all stored facts as a map.
  Future<Map<String, String>> recallAll() async {
    try {
      final col = _col;
      if (col == null) return {};
      final snap = await col.orderBy('savedAt', descending: false).limit(_maxFacts).get();
      final result = <String, String>{};
      for (final doc in snap.docs) {
        final key = doc.data()['key'] as String?;
        final val = doc.data()['value'] as String?;
        if (key != null && val != null) result[key] = val;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Deletes a specific fact.
  Future<void> deleteFact(String key) async {
    try {
      await _col?.doc(_sanitize(key)).delete();
    } catch (_) {}
  }

  /// Clears all facts.
  Future<void> clearAll() async {
    try {
      final col = _col;
      if (col == null) return;
      final snap = await col.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Returns a compact block of text to inject into the AI system prompt.
  /// E.g. "// User memory:\n- Name: Sujit\n- Likes: Anime"
  Future<String> buildMemoryBlock() async {
    try {
      final facts = await recallAll();
      if (facts.isEmpty) return '';
      final lines = facts.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
      return '// User facts (remember these):\n$lines\n';
    } catch (_) {
      return '';
    }
  }

  /// Parses MEMORY_SAVE action output from the AI into Firestore.
  Future<void> handleMemorySave(String key, String value) async {
    await saveFact(key, value);
  }

  /// Returns a human-readable summary of all memories as JSON string.
  Future<String> exportAsJson() async {
    final facts = await recallAll();
    return jsonEncode(facts);
  }

  String _sanitize(String key) => key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
}
