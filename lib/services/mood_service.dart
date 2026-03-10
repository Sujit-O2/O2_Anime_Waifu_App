import 'firestore_service.dart';

/// Tracks daily mood entries — now stored in Firestore.
class MoodService {
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

  static Future<void> saveMood(String mood) async {
    final entries = await getAll();
    entries.add({
      'mood': mood,
      'ts': DateTime.now().toIso8601String(),
    });
    // Keep last 90 entries
    final capped =
        entries.length > 90 ? entries.sublist(entries.length - 90) : entries;
    await FirestoreService().saveMoodEntries(capped);
  }

  static Future<List<Map<String, String>>> getAll() =>
      FirestoreService().loadMoodEntries();

  static Future<String?> getLatestMood() async {
    final entries = await getAll();
    return entries.isEmpty ? null : entries.last['mood'];
  }

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

  static Future<void> clearAll() => FirestoreService().clearMoodEntries();
}
