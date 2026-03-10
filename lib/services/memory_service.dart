import 'firestore_service.dart';

/// Persistent key-value memory for the AI assistant.
/// Facts stored in Firestore — survives reinstalls, syncs across devices.
class MemoryService {
  static const int _maxFacts = 30;

  static Future<void> saveFact(String key, String value) async {
    final facts = await getAllFacts();
    facts[key.trim().toLowerCase()] = value.trim();
    if (facts.length > _maxFacts) {
      facts.remove(facts.keys.first);
    }
    await FirestoreService().saveMemoryFacts(facts);
    // Achievement: first fact saved
    await FirestoreService().unlockAchievement('first_memory_saved');
  }

  static Future<Map<String, String>> getAllFacts() =>
      FirestoreService().loadMemoryFacts();

  static Future<String?> getFact(String key) async {
    final facts = await getAllFacts();
    return facts[key.trim().toLowerCase()];
  }

  static Future<String> buildMemoryPromptBlock() async {
    final facts = await getAllFacts();
    if (facts.isEmpty) return '';
    final lines = facts.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
    return '\n[Things you know about me that I told you before]:\n$lines\n';
  }

  static Future<void> clearAll() => FirestoreService().clearMemoryFacts();

  static Future<void> deleteFact(String key) async {
    final facts = await getAllFacts();
    facts.remove(key.trim().toLowerCase());
    await FirestoreService().saveMemoryFacts(facts);
  }
}
