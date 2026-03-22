import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/models/waifu_mood.dart';

/// Rolling sentiment analysis to adjust TTS tone.
class MoodEntry {
  final WaifuMood mood;
  final double sentiment;
  final DateTime timestamp;

  MoodEntry({
    required this.mood,
    required this.sentiment,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'mood': mood.name,
        'sentiment': sentiment,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        mood: WaifuMood.values.firstWhere(
          (e) => e.name == json['mood'],
          orElse: () => WaifuMood.neutral,
        ),
        sentiment: (json['sentiment'] as num?)?.toDouble() ?? 0.5,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class MoodService {
  final List<MoodEntry> _entries = [];
  static const int _windowSize = 10;

  double get averageSentiment {
    if (_entries.isEmpty) return 0.5;
    final recent = _entries.length > _windowSize
        ? _entries.sublist(_entries.length - _windowSize)
        : _entries;
    return recent.map((e) => e.sentiment).reduce((a, b) => a + b) /
        recent.length;
  }

  WaifuMood get dominantMood {
    if (_entries.isEmpty) return WaifuMood.neutral;
    final recent = _entries.length > _windowSize
        ? _entries.sublist(_entries.length - _windowSize)
        : _entries;
    final counts = <WaifuMood, int>{};
    for (final entry in recent) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('mood_entries');
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      _entries.clear();
      _entries.addAll(
          decoded.map((e) => MoodEntry.fromJson(e as Map<String, dynamic>)));
    }
  }

  void recordMood(WaifuMood mood, double sentiment) {
    _entries.add(MoodEntry(
      mood: mood,
      sentiment: sentiment,
      timestamp: DateTime.now(),
    ));
    if (_entries.length > 100) _entries.removeAt(0);
    _persist();
  }

  String toContextString() =>
      '[Mood Trend] Average sentiment: ${averageSentiment.toStringAsFixed(2)} | Dominant: ${dominantMood.displayName}';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mood_entries',
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }
}
