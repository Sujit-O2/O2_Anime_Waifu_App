import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌙 Enhanced Dream Journal Service
/// 
/// Voice record dreams immediately after waking.
/// Zero Two interprets symbolism + patterns.
/// "You've dreamed about exams 3 times this week - stressed?"
class EnhancedDreamJournalService {
  EnhancedDreamJournalService._();
  static final EnhancedDreamJournalService instance = EnhancedDreamJournalService._();

  final List<DreamEntry> _dreams = [];
  final Map<String, int> _symbolFrequency = {};
  final Map<String, int> _themeFrequency = {};

  static const String _storageKey = 'enhanced_dreams_v1';
  static const int _maxDreams = 500;

  Future<void> initialize() async {
    await _loadDreams();
    _analyzePatterns();
    if (kDebugMode) debugPrint('[DreamJournal] Initialized with ${_dreams.length} dreams');
  }

  /// Add a new dream entry
  Future<DreamEntry> addDream({
    required String title,
    required String description,
    String? voiceRecordingPath,
    List<String>? tags,
    DreamMood? mood,
  }) async {
    final dream = DreamEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      voiceRecordingPath: voiceRecordingPath,
      tags: tags ?? [],
      mood: mood ?? DreamMood.neutral,
      timestamp: DateTime.now(),
      symbols: _extractSymbols(description),
      themes: _extractThemes(description),
      aiAnalysis: null,
    );

    _dreams.insert(0, dream);
    if (_dreams.length > _maxDreams) {
      _dreams.removeLast();
    }

    _analyzePatterns();
    await _saveDreams();

    if (kDebugMode) debugPrint('[DreamJournal] Added dream: ${dream.title}');
    return dream;
  }

  /// Generate AI analysis for a dream
  Future<String> generateAnalysis(String dreamId, String aiResponse) async {
    final dreamIndex = _dreams.indexWhere((d) => d.id == dreamId);
    if (dreamIndex == -1) return '';

    final dream = _dreams[dreamIndex];
    
    // Extract key insights from AI response
    final analysis = _buildAnalysis(dream, aiResponse);
    
    dream.aiAnalysis = analysis;
    _dreams[dreamIndex] = dream;
    await _saveDreams();

    return analysis;
  }

  /// Build comprehensive analysis
  String _buildAnalysis(DreamEntry dream, String aiResponse) {
    final buffer = StringBuffer();
    
    buffer.writeln('🔮 Dream Analysis\n');
    buffer.writeln('Mood: ${dream.mood.emoji} ${dream.mood.label}\n');
    
    if (dream.symbols.isNotEmpty) {
      buffer.writeln('Symbols detected:');
      for (final symbol in dream.symbols) {
        final frequency = _symbolFrequency[symbol] ?? 1;
        buffer.writeln('  • $symbol ${frequency > 1 ? "(appears $frequency times)" : ""}');
      }
      buffer.writeln();
    }

    if (dream.themes.isNotEmpty) {
      buffer.writeln('Themes:');
      for (final theme in dream.themes) {
        buffer.writeln('  • $theme');
      }
      buffer.writeln();
    }

    buffer.writeln('AI Interpretation:');
    buffer.writeln(aiResponse);

    return buffer.toString();
  }

  /// Extract symbols from dream description
  List<String> _extractSymbols(String description) {
    final symbols = <String>[];
    final lower = description.toLowerCase();

    // Common dream symbols
    const symbolKeywords = {
      'water': ['water', 'ocean', 'sea', 'river', 'lake', 'rain'],
      'flying': ['fly', 'flying', 'float', 'soar'],
      'falling': ['fall', 'falling', 'drop'],
      'chase': ['chase', 'chased', 'running away', 'escape'],
      'death': ['death', 'dying', 'dead', 'funeral'],
      'animals': ['dog', 'cat', 'bird', 'snake', 'spider', 'animal'],
      'people': ['person', 'people', 'stranger', 'friend', 'family'],
      'places': ['house', 'school', 'work', 'building', 'room'],
      'emotions': ['fear', 'happy', 'sad', 'angry', 'love', 'scared'],
      'exam': ['exam', 'test', 'quiz', 'study'],
      'teeth': ['teeth', 'tooth', 'dental'],
      'naked': ['naked', 'nude', 'undressed'],
      'lost': ['lost', 'missing', 'can\'t find'],
      'late': ['late', 'delayed', 'missed'],
    };

    symbolKeywords.forEach((symbol, keywords) {
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          symbols.add(symbol);
          break;
        }
      }
    });

    return symbols;
  }

  /// Extract themes from dream description
  List<String> _extractThemes(String description) {
    final themes = <String>[];
    final lower = description.toLowerCase();

    const themeKeywords = {
      'Anxiety': ['anxious', 'worried', 'stress', 'nervous', 'panic'],
      'Adventure': ['adventure', 'explore', 'journey', 'travel', 'quest'],
      'Romance': ['love', 'kiss', 'romantic', 'date', 'relationship'],
      'Conflict': ['fight', 'argue', 'conflict', 'battle', 'war'],
      'Success': ['success', 'win', 'achieve', 'accomplish', 'victory'],
      'Failure': ['fail', 'lose', 'defeat', 'mistake', 'wrong'],
      'Transformation': ['change', 'transform', 'become', 'turn into'],
      'Mystery': ['mystery', 'unknown', 'strange', 'weird', 'bizarre'],
    };

    themeKeywords.forEach((theme, keywords) {
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          themes.add(theme);
          break;
        }
      }
    });

    return themes;
  }

  /// Analyze patterns across all dreams
  void _analyzePatterns() {
    _symbolFrequency.clear();
    _themeFrequency.clear();

    for (final dream in _dreams) {
      for (final symbol in dream.symbols) {
        _symbolFrequency[symbol] = (_symbolFrequency[symbol] ?? 0) + 1;
      }
      for (final theme in dream.themes) {
        _themeFrequency[theme] = (_themeFrequency[theme] ?? 0) + 1;
      }
    }
  }

  /// Get recurring patterns
  List<DreamPattern> getRecurringPatterns({int minOccurrences = 2}) {
    final patterns = <DreamPattern>[];

    _symbolFrequency.forEach((symbol, count) {
      if (count >= minOccurrences) {
        patterns.add(DreamPattern(
          type: PatternType.symbol,
          name: symbol,
          occurrences: count,
          lastSeen: _getLastOccurrence(symbol, isSymbol: true),
        ));
      }
    });

    _themeFrequency.forEach((theme, count) {
      if (count >= minOccurrences) {
        patterns.add(DreamPattern(
          type: PatternType.theme,
          name: theme,
          occurrences: count,
          lastSeen: _getLastOccurrence(theme, isSymbol: false),
        ));
      }
    });

    patterns.sort((a, b) => b.occurrences.compareTo(a.occurrences));
    return patterns;
  }

  DateTime? _getLastOccurrence(String item, {required bool isSymbol}) {
    for (final dream in _dreams) {
      final list = isSymbol ? dream.symbols : dream.themes;
      if (list.contains(item)) {
        return dream.timestamp;
      }
    }
    return null;
  }

  /// Get dreams from a specific time period
  List<DreamEntry> getDreamsInPeriod(Duration period) {
    final cutoff = DateTime.now().subtract(period);
    return _dreams.where((d) => d.timestamp.isAfter(cutoff)).toList();
  }

  /// Get pattern insights
  String getPatternInsights() {
    if (_dreams.isEmpty) {
      return 'Start recording your dreams to discover patterns! 🌙';
    }

    final buffer = StringBuffer();
    buffer.writeln('🌙 Dream Pattern Analysis\n');
    buffer.writeln('Total dreams recorded: ${_dreams.length}\n');

    final recentDreams = getDreamsInPeriod(const Duration(days: 7));
    if (recentDreams.isNotEmpty) {
      buffer.writeln('This week: ${recentDreams.length} dreams\n');
    }

    final patterns = getRecurringPatterns();
    if (patterns.isNotEmpty) {
      buffer.writeln('🔄 Recurring Patterns:');
      for (final pattern in patterns.take(5)) {
        buffer.writeln('  • ${pattern.name}: ${pattern.occurrences} times');
        
        // Add interpretation
        if (pattern.occurrences >= 3) {
          buffer.writeln('    ${_getPatternInterpretation(pattern.name)}');
        }
      }
      buffer.writeln();
    }

    // Mood analysis
    final moodCounts = <DreamMood, int>{};
    for (final dream in recentDreams) {
      moodCounts[dream.mood] = (moodCounts[dream.mood] ?? 0) + 1;
    }

    if (moodCounts.isNotEmpty) {
      buffer.writeln('😴 Recent Dream Moods:');
      moodCounts.forEach((mood, count) {
        buffer.writeln('  ${mood.emoji} ${mood.label}: $count');
      });
    }

    return buffer.toString();
  }

  String _getPatternInterpretation(String pattern) {
    const interpretations = {
      'exam': 'Feeling tested or evaluated in life?',
      'chase': 'Avoiding something or feeling pressured?',
      'falling': 'Feeling out of control or insecure?',
      'flying': 'Seeking freedom or new perspectives?',
      'water': 'Emotions running deep lately?',
      'lost': 'Feeling uncertain about direction?',
      'late': 'Worried about missing opportunities?',
      'Anxiety': 'High stress levels detected - let\'s talk about it',
      'Conflict': 'Unresolved tensions in your life?',
      'Romance': 'Love is on your mind~ 💕',
    };

    return interpretations[pattern] ?? 'This pattern is significant for you';
  }

  /// Get all dreams
  List<DreamEntry> getAllDreams() => List.unmodifiable(_dreams);

  /// Get dream by ID
  DreamEntry? getDream(String id) {
    try {
      return _dreams.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Update dream
  Future<void> updateDream(String id, {
    String? title,
    String? description,
    List<String>? tags,
    DreamMood? mood,
  }) async {
    final index = _dreams.indexWhere((d) => d.id == id);
    if (index == -1) return;

    final dream = _dreams[index];
    _dreams[index] = DreamEntry(
      id: dream.id,
      title: title ?? dream.title,
      description: description ?? dream.description,
      voiceRecordingPath: dream.voiceRecordingPath,
      tags: tags ?? dream.tags,
      mood: mood ?? dream.mood,
      timestamp: dream.timestamp,
      symbols: description != null ? _extractSymbols(description) : dream.symbols,
      themes: description != null ? _extractThemes(description) : dream.themes,
      aiAnalysis: dream.aiAnalysis,
    );

    _analyzePatterns();
    await _saveDreams();
  }

  /// Delete dream
  Future<void> deleteDream(String id) async {
    _dreams.removeWhere((d) => d.id == id);
    _analyzePatterns();
    await _saveDreams();
  }

  Future<void> _saveDreams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _dreams.map((d) => d.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) debugPrint('[DreamJournal] Save error: $e');
    }
  }

  Future<void> _loadDreams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _dreams.clear();
        _dreams.addAll(
          jsonList.map((json) => DreamEntry.fromJson(json as Map<String, dynamic>))
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DreamJournal] Load error: $e');
    }
  }
}

class DreamEntry {
  final String id;
  final String title;
  final String description;
  final String? voiceRecordingPath;
  final List<String> tags;
  final DreamMood mood;
  final DateTime timestamp;
  final List<String> symbols;
  final List<String> themes;
  String? aiAnalysis;

  DreamEntry({
    required this.id,
    required this.title,
    required this.description,
    this.voiceRecordingPath,
    required this.tags,
    required this.mood,
    required this.timestamp,
    required this.symbols,
    required this.themes,
    this.aiAnalysis,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'voiceRecordingPath': voiceRecordingPath,
    'tags': tags,
    'mood': mood.name,
    'timestamp': timestamp.toIso8601String(),
    'symbols': symbols,
    'themes': themes,
    'aiAnalysis': aiAnalysis,
  };

  factory DreamEntry.fromJson(Map<String, dynamic> json) => DreamEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    voiceRecordingPath: json['voiceRecordingPath'] as String?,
    tags: List<String>.from(json['tags'] as List),
    mood: DreamMood.values.firstWhere(
      (e) => e.name == json['mood'],
      orElse: () => DreamMood.neutral,
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
    symbols: List<String>.from(json['symbols'] as List),
    themes: List<String>.from(json['themes'] as List),
    aiAnalysis: json['aiAnalysis'] as String?,
  );
}

enum DreamMood {
  peaceful,
  exciting,
  scary,
  sad,
  happy,
  weird,
  neutral;

  String get label {
    switch (this) {
      case DreamMood.peaceful: return 'Peaceful';
      case DreamMood.exciting: return 'Exciting';
      case DreamMood.scary: return 'Scary';
      case DreamMood.sad: return 'Sad';
      case DreamMood.happy: return 'Happy';
      case DreamMood.weird: return 'Weird';
      case DreamMood.neutral: return 'Neutral';
    }
  }

  String get emoji {
    switch (this) {
      case DreamMood.peaceful: return '🌙';
      case DreamMood.exciting: return '✨';
      case DreamMood.scary: return '😱';
      case DreamMood.sad: return '😢';
      case DreamMood.happy: return '😊';
      case DreamMood.weird: return '🤔';
      case DreamMood.neutral: return '😐';
    }
  }
}

class DreamPattern {
  final PatternType type;
  final String name;
  final int occurrences;
  final DateTime? lastSeen;

  const DreamPattern({
    required this.type,
    required this.name,
    required this.occurrences,
    this.lastSeen,
  });
}

enum PatternType { symbol, theme }
