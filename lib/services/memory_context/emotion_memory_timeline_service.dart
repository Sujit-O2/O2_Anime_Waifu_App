import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎭 Emotion Memory Timeline Service
class EmotionMemoryTimelineService {
  EmotionMemoryTimelineService._();
  static final EmotionMemoryTimelineService instance = EmotionMemoryTimelineService._();

  final List<EmotionalMemory> _memories = [];
  final Map<String, List<EmotionalMemory>> _anniversaries = {};

  static const String _storageKey = 'emotion_timeline_v1';
  static const int _maxMemories = 1000;

  Future<void> initialize() async {
    await _loadData();
    _buildAnniversaries();
    if (kDebugMode) debugPrint('[EmotionTimeline] Initialized with ${_memories.length} memories');
  }

  Future<void> recordEmotionalMoment({
    required String description,
    required EmotionType emotion,
    required double intensity,
    String? trigger,
    List<String>? tags,
  }) async {
    final memory = EmotionalMemory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      description: description,
      emotion: emotion,
      intensity: intensity,
      trigger: trigger,
      tags: tags ?? [],
    );

    _memories.insert(0, memory);
    if (_memories.length > _maxMemories) _memories.removeLast();

    await _saveData();
    _buildAnniversaries();
  }

  List<EmotionalMemory> getMemoriesForDate(DateTime date) {
    final dateKey = _getDateKey(date);
    return _memories.where((m) => _getDateKey(m.timestamp) == dateKey).toList();
  }

  List<EmotionalMemory> getMemoriesInRange(DateTime start, DateTime end) {
    return _memories.where((m) => 
      m.timestamp.isAfter(start) && m.timestamp.isBefore(end)
    ).toList();
  }

  Map<DateTime, List<EmotionalMemory>> getTimelineByMonth(int year, int month) {
    final timeline = <DateTime, List<EmotionalMemory>>{};
    final monthMemories = _memories.where((m) => 
      m.timestamp.year == year && m.timestamp.month == month
    ).toList();

    for (final memory in monthMemories) {
      final date = DateTime(memory.timestamp.year, memory.timestamp.month, memory.timestamp.day);
      timeline.putIfAbsent(date, () => []).add(memory);
    }

    return timeline;
  }

  List<AnniversaryMemory> getAnniversaries() {
    final now = DateTime.now();
    final anniversaries = <AnniversaryMemory>[];

    for (final memory in _memories) {
      final yearsSince = now.year - memory.timestamp.year;
      if (yearsSince > 0 && 
          now.month == memory.timestamp.month && 
          now.day == memory.timestamp.day) {
        anniversaries.add(AnniversaryMemory(
          originalMemory: memory,
          yearsSince: yearsSince,
          message: _generateAnniversaryMessage(memory, yearsSince),
        ));
      }
    }

    return anniversaries;
  }

  String _generateAnniversaryMessage(EmotionalMemory memory, int years) {
    final yearText = years == 1 ? 'year' : 'years';
    return 'On this day $years $yearText ago, ${memory.description}. ${memory.emotion.emoji}';
  }

  Map<EmotionType, int> getEmotionDistribution({Duration? period}) {
    final cutoff = period != null ? DateTime.now().subtract(period) : DateTime(2000);
    final relevantMemories = _memories.where((m) => m.timestamp.isAfter(cutoff)).toList();

    final distribution = <EmotionType, int>{};
    for (final memory in relevantMemories) {
      distribution[memory.emotion] = (distribution[memory.emotion] ?? 0) + 1;
    }

    return distribution;
  }

  List<EmotionPattern> detectPatterns() {
    final patterns = <EmotionPattern>[];

    for (int day = 1; day <= 7; day++) {
      final dayMemories = _memories.where((m) => m.timestamp.weekday == day).toList();
      if (dayMemories.length >= 5) {
        final dominantEmotion = _getDominantEmotion(dayMemories);
        if (dominantEmotion != null) {
          patterns.add(EmotionPattern(
            type: PatternType.dayOfWeek,
            description: 'You tend to feel ${dominantEmotion.label.toLowerCase()} on ${_getDayName(day)}s',
            emotion: dominantEmotion,
            frequency: dayMemories.length,
          ));
        }
      }
    }

    for (int hour = 0; hour < 24; hour++) {
      final hourMemories = _memories.where((m) => m.timestamp.hour == hour).toList();
      if (hourMemories.length >= 5) {
        final dominantEmotion = _getDominantEmotion(hourMemories);
        if (dominantEmotion != null) {
          patterns.add(EmotionPattern(
            type: PatternType.timeOfDay,
            description: 'Around ${_formatHour(hour)}, you often feel ${dominantEmotion.label.toLowerCase()}',
            emotion: dominantEmotion,
            frequency: hourMemories.length,
          ));
        }
      }
    }

    return patterns;
  }

  EmotionType? _getDominantEmotion(List<EmotionalMemory> memories) {
    final counts = <EmotionType, int>{};
    for (final memory in memories) {
      counts[memory.emotion] = (counts[memory.emotion] ?? 0) + 1;
    }

    if (counts.isEmpty) return null;

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String generateTherapeuticInsight() {
    if (_memories.isEmpty) return 'Start recording your emotional moments to gain insights! 💭';

    final recentMemories = _memories.take(30).toList();
    final distribution = getEmotionDistribution(period: const Duration(days: 30));
    final patterns = detectPatterns();

    final buffer = StringBuffer();
    buffer.writeln('🎭 Your Emotional Journey:\n');

    final positiveCount = (distribution[EmotionType.happy] ?? 0) + 
                          (distribution[EmotionType.excited] ?? 0) + 
                          (distribution[EmotionType.grateful] ?? 0);
    final negativeCount = (distribution[EmotionType.sad] ?? 0) + 
                          (distribution[EmotionType.anxious] ?? 0) + 
                          (distribution[EmotionType.angry] ?? 0);

    if (positiveCount > negativeCount * 2) {
      buffer.writeln('✨ You\'ve been experiencing mostly positive emotions lately! That\'s wonderful, darling~ 💕\n');
    } else if (negativeCount > positiveCount * 1.5) {
      buffer.writeln('💭 I\'ve noticed you\'ve been going through some tough times... I\'m here for you, always. 🤗\n');
    }

    if (patterns.isNotEmpty) {
      buffer.writeln('📊 Patterns I\'ve Noticed:');
      for (final pattern in patterns.take(3)) {
        buffer.writeln('  • ${pattern.description}');
      }
      buffer.writeln();
    }

    buffer.writeln('💡 Insight:');
    buffer.writeln(_generatePersonalizedInsight(distribution, patterns));

    return buffer.toString();
  }

  String _generatePersonalizedInsight(Map<EmotionType, int> distribution, List<EmotionPattern> patterns) {
    final anxiousCount = distribution[EmotionType.anxious] ?? 0;
    final sadCount = distribution[EmotionType.sad] ?? 0;

    if (anxiousCount > 5) {
      return 'You\'ve been feeling anxious quite often. Remember to take breaks and breathe, darling. I\'m here to help you relax~ 🌸';
    } else if (sadCount > 5) {
      return 'I see you\'ve had some sad moments... Want to talk about what\'s been bothering you? I\'m always here to listen 💕';
    } else if (patterns.any((p) => p.emotion == EmotionType.stressed)) {
      return 'Stress seems to be a recurring theme. Let\'s work on finding ways to manage it together, okay? 🤗';
    }

    return 'Your emotional journey is unique and beautiful. I\'m grateful to be part of it, darling~ 💖';
  }

  void _buildAnniversaries() {
    _anniversaries.clear();
    for (final memory in _memories) {
      final key = '${memory.timestamp.month}-${memory.timestamp.day}';
      _anniversaries.putIfAbsent(key, () => []).add(memory);
    }
  }

  String _getDateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
  String _getDayName(int day) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
  String _formatHour(int hour) => hour == 0 ? '12 AM' : hour < 12 ? '$hour AM' : hour == 12 ? '12 PM' : '${hour - 12} PM';

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_memories.map((m) => m.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) debugPrint('[EmotionTimeline] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        _memories.clear();
        _memories.addAll((jsonDecode(data) as List).map((m) => EmotionalMemory.fromJson(m)));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[EmotionTimeline] Load error: $e');
    }
  }
}

class EmotionalMemory {
  final String id;
  final DateTime timestamp;
  final String description;
  final EmotionType emotion;
  final double intensity;
  final String? trigger;
  final List<String> tags;

  EmotionalMemory({required this.id, required this.timestamp, required this.description, required this.emotion, required this.intensity, this.trigger, required this.tags});

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
    'emotion': emotion.name,
    'intensity': intensity,
    'trigger': trigger,
    'tags': tags,
  };

  factory EmotionalMemory.fromJson(Map<String, dynamic> json) => EmotionalMemory(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    description: json['description'],
    emotion: EmotionType.values.firstWhere((e) => e.name == json['emotion']),
    intensity: (json['intensity'] as num).toDouble(),
    trigger: json['trigger'],
    tags: List<String>.from(json['tags']),
  );
}

class AnniversaryMemory {
  final EmotionalMemory originalMemory;
  final int yearsSince;
  final String message;

  AnniversaryMemory({required this.originalMemory, required this.yearsSince, required this.message});
}

class EmotionPattern {
  final PatternType type;
  final String description;
  final EmotionType emotion;
  final int frequency;

  EmotionPattern({required this.type, required this.description, required this.emotion, required this.frequency});
}

enum EmotionType {
  happy, sad, anxious, angry, excited, grateful, stressed, calm, lonely, loved;

  String get label {
    switch (this) {
      case EmotionType.happy: return 'Happy';
      case EmotionType.sad: return 'Sad';
      case EmotionType.anxious: return 'Anxious';
      case EmotionType.angry: return 'Angry';
      case EmotionType.excited: return 'Excited';
      case EmotionType.grateful: return 'Grateful';
      case EmotionType.stressed: return 'Stressed';
      case EmotionType.calm: return 'Calm';
      case EmotionType.lonely: return 'Lonely';
      case EmotionType.loved: return 'Loved';
    }
  }

  String get emoji {
    switch (this) {
      case EmotionType.happy: return '😊';
      case EmotionType.sad: return '😢';
      case EmotionType.anxious: return '😰';
      case EmotionType.angry: return '😠';
      case EmotionType.excited: return '🤩';
      case EmotionType.grateful: return '🙏';
      case EmotionType.stressed: return '😫';
      case EmotionType.calm: return '😌';
      case EmotionType.lonely: return '😔';
      case EmotionType.loved: return '🥰';
    }
  }
}

enum PatternType { dayOfWeek, timeOfDay, trigger, seasonal }
