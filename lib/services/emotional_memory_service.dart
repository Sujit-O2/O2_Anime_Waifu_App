import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/models/waifu_mood.dart';

/// Emotional event log with mood-tagged memories.
class EmotionalMemory {
  final String content;
  final WaifuMood mood;
  final DateTime timestamp;
  final double intensity;

  EmotionalMemory({
    required this.content,
    required this.mood,
    required this.timestamp,
    this.intensity = 0.5,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'mood': mood.name,
        'timestamp': timestamp.toIso8601String(),
        'intensity': intensity,
      };

  factory EmotionalMemory.fromJson(Map<String, dynamic> json) =>
      EmotionalMemory(
        content: json['content'] as String,
        mood: WaifuMood.values.firstWhere(
          (e) => e.name == json['mood'],
          orElse: () => WaifuMood.neutral,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        intensity: (json['intensity'] as num?)?.toDouble() ?? 0.5,
      );
}

class EmotionalMemoryService {
  static const int _maxMemories = 100;
  final List<EmotionalMemory> _memories = [];

  List<EmotionalMemory> get memories => List.unmodifiable(_memories);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('emotional_memories');
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      _memories.clear();
      _memories.addAll(
        decoded
            .map((e) => EmotionalMemory.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  void addMemory(String content, WaifuMood mood, {double intensity = 0.5}) {
    _memories.add(EmotionalMemory(
      content: content,
      mood: mood,
      timestamp: DateTime.now(),
      intensity: intensity,
    ));
    if (_memories.length > _maxMemories) {
      _memories.removeAt(0);
    }
    _persist();
  }

  List<EmotionalMemory> getMemoriesByMood(WaifuMood mood) {
    return _memories.where((m) => m.mood == mood).toList();
  }

  List<EmotionalMemory> getRecentMemories({int count = 5}) {
    final sorted = List<EmotionalMemory>.from(_memories)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(count).toList();
  }

  String toContextString() {
    final recent = getRecentMemories(count: 3);
    if (recent.isEmpty) return '';
    return '[Emotional Memories]\n${recent.map((m) => '- ${m.mood.displayName}: ${m.content}').join('\n')}';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'emotional_memories',
      jsonEncode(_memories.map((m) => m.toJson()).toList()),
    );
  }
}
