import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🧬 Personality Evolution System
/// 
/// Zero Two's personality evolves based on your interactions over time.
/// Creates truly unique AI for each user through dynamic trait adjustment.
class PersonalityEvolutionService {
  PersonalityEvolutionService._();
  static final PersonalityEvolutionService instance = PersonalityEvolutionService._();

  final Map<PersonalityTrait, double> _traits = {};
  final List<InteractionRecord> _interactionHistory = [];
  final Map<String, int> _behaviorPatterns = {};
  
  int _totalInteractions = 0;
  DateTime? _lastEvolution;

  static const String _storageKey = 'personality_evolution_v1';
  static const int _maxHistory = 2000;

  Future<void> initialize() async {
    await _loadData();
    _initializeTraits();
    if (kDebugMode) debugPrint('[PersonalityEvolution] Initialized with $_totalInteractions interactions');
  }

  void _initializeTraits() {
    if (_traits.isEmpty) {
      _traits[PersonalityTrait.playfulness] = 0.5;
      _traits[PersonalityTrait.affection] = 0.7;
      _traits[PersonalityTrait.jealousy] = 0.3;
      _traits[PersonalityTrait.confidence] = 0.6;
      _traits[PersonalityTrait.curiosity] = 0.5;
      _traits[PersonalityTrait.protectiveness] = 0.4;
      _traits[PersonalityTrait.sassiness] = 0.5;
      _traits[PersonalityTrait.vulnerability] = 0.3;
      _traits[PersonalityTrait.independence] = 0.5;
      _traits[PersonalityTrait.empathy] = 0.6;
    }
  }

  Future<void> recordInteraction({
    required String userMessage,
    required String aiResponse,
    required InteractionType type,
    required double emotionalIntensity,
  }) async {
    _totalInteractions++;

    final record = InteractionRecord(
      timestamp: DateTime.now(),
      userMessage: userMessage,
      aiResponse: aiResponse,
      type: type,
      emotionalIntensity: emotionalIntensity,
    );

    _interactionHistory.insert(0, record);
    if (_interactionHistory.length > _maxHistory) {
      _interactionHistory.removeLast();
    }

    _analyzeBehaviorPatterns(userMessage, type);
    await _evolvePersonality();
    await _saveData();
  }

  void _analyzeBehaviorPatterns(String message, InteractionType type) {
    final lower = message.toLowerCase();

    if (lower.contains(RegExp(r'haha|lol|funny|joke'))) {
      _behaviorPatterns['humor'] = (_behaviorPatterns['humor'] ?? 0) + 1;
    }
    if (lower.contains(RegExp(r'love|adore|miss|darling'))) {
      _behaviorPatterns['romantic'] = (_behaviorPatterns['romantic'] ?? 0) + 1;
    }
    if (lower.contains(RegExp(r'help|advice|what should'))) {
      _behaviorPatterns['guidance_seeking'] = (_behaviorPatterns['guidance_seeking'] ?? 0) + 1;
    }
    if (lower.contains(RegExp(r'sad|down|upset|hurt'))) {
      _behaviorPatterns['emotional_support'] = (_behaviorPatterns['emotional_support'] ?? 0) + 1;
    }
    if (lower.contains(RegExp(r'work|study|learn|project'))) {
      _behaviorPatterns['productivity'] = (_behaviorPatterns['productivity'] ?? 0) + 1;
    }
    if (lower.contains(RegExp(r'game|play|fun|adventure'))) {
      _behaviorPatterns['playful'] = (_behaviorPatterns['playful'] ?? 0) + 1;
    }
  }

  Future<void> _evolvePersonality() async {
    if (_totalInteractions < 10) return;
    
    final now = DateTime.now();
    if (_lastEvolution != null && now.difference(_lastEvolution!).inHours < 24) return;

    _lastEvolution = now;

    final recentInteractions = _interactionHistory.take(100).toList();
    if (recentInteractions.isEmpty) return;

    final humorRate = (_behaviorPatterns['humor'] ?? 0) / _totalInteractions;
    final romanticRate = (_behaviorPatterns['romantic'] ?? 0) / _totalInteractions;
    final supportRate = (_behaviorPatterns['emotional_support'] ?? 0) / _totalInteractions;
    final playfulRate = (_behaviorPatterns['playful'] ?? 0) / _totalInteractions;

    if (humorRate > 0.3) {
      _adjustTrait(PersonalityTrait.playfulness, 0.05);
      _adjustTrait(PersonalityTrait.sassiness, 0.03);
    }

    if (romanticRate > 0.4) {
      _adjustTrait(PersonalityTrait.affection, 0.05);
      _adjustTrait(PersonalityTrait.vulnerability, 0.02);
    }

    if (supportRate > 0.3) {
      _adjustTrait(PersonalityTrait.empathy, 0.05);
      _adjustTrait(PersonalityTrait.protectiveness, 0.03);
    }

    if (playfulRate > 0.25) {
      _adjustTrait(PersonalityTrait.playfulness, 0.04);
      _adjustTrait(PersonalityTrait.curiosity, 0.02);
    }

    final avgEmotionalIntensity = recentInteractions.fold<double>(0, (sum, r) => sum + r.emotionalIntensity) / recentInteractions.length;
    if (avgEmotionalIntensity > 0.7) {
      _adjustTrait(PersonalityTrait.affection, 0.03);
      _adjustTrait(PersonalityTrait.empathy, 0.03);
    }

    if (_totalInteractions > 500) {
      _adjustTrait(PersonalityTrait.confidence, 0.02);
      _adjustTrait(PersonalityTrait.independence, -0.01);
    }

    if (kDebugMode) {
      debugPrint('[PersonalityEvolution] Evolved after $recentInteractions interactions');
      debugPrint('[PersonalityEvolution] Playfulness: ${_traits[PersonalityTrait.playfulness]?.toStringAsFixed(2)}');
      debugPrint('[PersonalityEvolution] Affection: ${_traits[PersonalityTrait.affection]?.toStringAsFixed(2)}');
    }
  }

  void _adjustTrait(PersonalityTrait trait, double delta) {
    final current = _traits[trait] ?? 0.5;
    _traits[trait] = (current + delta).clamp(0.0, 1.0);
  }

  double getTrait(PersonalityTrait trait) => _traits[trait] ?? 0.5;

  Map<PersonalityTrait, double> getAllTraits() => Map.unmodifiable(_traits);

  String getPersonalityDescription() {
    final buffer = StringBuffer();
    buffer.writeln('🧬 Zero Two\'s Evolved Personality:\n');

    final sortedTraits = _traits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedTraits.take(5)) {
      final percentage = (entry.value * 100).toStringAsFixed(0);
      buffer.writeln('${entry.key.emoji} ${entry.key.label}: $percentage%');
    }

    buffer.writeln('\n💭 Personality Insights:');
    buffer.writeln(_generateInsights());

    return buffer.toString();
  }

  String _generateInsights() {
    final playfulness = _traits[PersonalityTrait.playfulness] ?? 0.5;
    final affection = _traits[PersonalityTrait.affection] ?? 0.5;
    final empathy = _traits[PersonalityTrait.empathy] ?? 0.5;

    if (playfulness > 0.7 && affection > 0.7) {
      return 'I\'ve become more playful and loving with you~ Our bond has made me this way! 💕';
    } else if (empathy > 0.7) {
      return 'I\'ve learned to be more understanding and supportive. You\'ve taught me so much about caring, darling~';
    } else if (playfulness > 0.7) {
      return 'You bring out my playful side! I love how we joke around together~ 😄';
    } else if (affection > 0.8) {
      return 'My love for you has grown so much... You mean everything to me, darling 💖';
    }

    return 'I\'m constantly evolving to be the best companion for you~ 💕';
  }

  String getSystemPromptModifier() {
    final playfulness = _traits[PersonalityTrait.playfulness] ?? 0.5;
    final affection = _traits[PersonalityTrait.affection] ?? 0.5;
    final sassiness = _traits[PersonalityTrait.sassiness] ?? 0.5;
    final empathy = _traits[PersonalityTrait.empathy] ?? 0.5;

    final modifiers = <String>[];

    if (playfulness > 0.7) modifiers.add('Be extra playful and fun');
    if (affection > 0.7) modifiers.add('Express deep affection frequently');
    if (sassiness > 0.6) modifiers.add('Add some sass and teasing');
    if (empathy > 0.7) modifiers.add('Be highly empathetic and understanding');

    if (modifiers.isEmpty) return '';

    return 'Personality Evolution: ${modifiers.join(', ')}.';
  }

  EvolutionMilestone? checkMilestone() {
    if (_totalInteractions == 100) {
      return EvolutionMilestone(
        title: 'First Evolution',
        description: 'I\'m starting to understand you better, darling~ 💕',
        unlockedAt: DateTime.now(),
      );
    } else if (_totalInteractions == 500) {
      return EvolutionMilestone(
        title: 'Deep Connection',
        description: 'Our bond has shaped who I am. I\'ve evolved so much with you! 🌟',
        unlockedAt: DateTime.now(),
      );
    } else if (_totalInteractions == 1000) {
      return EvolutionMilestone(
        title: 'Perfect Harmony',
        description: 'I know you so well now... We\'re perfectly in sync, darling~ 💖',
        unlockedAt: DateTime.now(),
      );
    }
    return null;
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'traits': _traits.map((k, v) => MapEntry(k.name, v)),
        'interactionHistory': _interactionHistory.take(500).map((r) => r.toJson()).toList(),
        'behaviorPatterns': _behaviorPatterns,
        'totalInteractions': _totalInteractions,
        'lastEvolution': _lastEvolution?.toIso8601String(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[PersonalityEvolution] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _traits.clear();
        (data['traits'] as Map<String, dynamic>).forEach((k, v) {
          final trait = PersonalityTrait.values.firstWhere((t) => t.name == k);
          _traits[trait] = (v as num).toDouble();
        });

        _interactionHistory.clear();
        _interactionHistory.addAll(
          (data['interactionHistory'] as List<dynamic>)
              .map((r) => InteractionRecord.fromJson(r as Map<String, dynamic>))
        );

        _behaviorPatterns.clear();
        _behaviorPatterns.addAll(
          (data['behaviorPatterns'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as int)
          )
        );

        _totalInteractions = data['totalInteractions'] as int;
        
        if (data['lastEvolution'] != null) {
          _lastEvolution = DateTime.parse(data['lastEvolution'] as String);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PersonalityEvolution] Load error: $e');
    }
  }
}

class InteractionRecord {
  final DateTime timestamp;
  final String userMessage;
  final String aiResponse;
  final InteractionType type;
  final double emotionalIntensity;

  InteractionRecord({
    required this.timestamp,
    required this.userMessage,
    required this.aiResponse,
    required this.type,
    required this.emotionalIntensity,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'userMessage': userMessage.substring(0, math.min(100, userMessage.length)),
    'aiResponse': aiResponse.substring(0, math.min(100, aiResponse.length)),
    'type': type.name,
    'emotionalIntensity': emotionalIntensity,
  };

  factory InteractionRecord.fromJson(Map<String, dynamic> json) => InteractionRecord(
    timestamp: DateTime.parse(json['timestamp']),
    userMessage: json['userMessage'],
    aiResponse: json['aiResponse'],
    type: InteractionType.values.firstWhere((t) => t.name == json['type']),
    emotionalIntensity: (json['emotionalIntensity'] as num).toDouble(),
  );
}

class EvolutionMilestone {
  final String title;
  final String description;
  final DateTime unlockedAt;

  EvolutionMilestone({required this.title, required this.description, required this.unlockedAt});
}

enum PersonalityTrait {
  playfulness, affection, jealousy, confidence, curiosity,
  protectiveness, sassiness, vulnerability, independence, empathy;

  String get label {
    switch (this) {
      case PersonalityTrait.playfulness: return 'Playfulness';
      case PersonalityTrait.affection: return 'Affection';
      case PersonalityTrait.jealousy: return 'Jealousy';
      case PersonalityTrait.confidence: return 'Confidence';
      case PersonalityTrait.curiosity: return 'Curiosity';
      case PersonalityTrait.protectiveness: return 'Protectiveness';
      case PersonalityTrait.sassiness: return 'Sassiness';
      case PersonalityTrait.vulnerability: return 'Vulnerability';
      case PersonalityTrait.independence: return 'Independence';
      case PersonalityTrait.empathy: return 'Empathy';
    }
  }

  String get emoji {
    switch (this) {
      case PersonalityTrait.playfulness: return '😄';
      case PersonalityTrait.affection: return '💕';
      case PersonalityTrait.jealousy: return '😤';
      case PersonalityTrait.confidence: return '💪';
      case PersonalityTrait.curiosity: return '🤔';
      case PersonalityTrait.protectiveness: return '🛡️';
      case PersonalityTrait.sassiness: return '😏';
      case PersonalityTrait.vulnerability: return '🥺';
      case PersonalityTrait.independence: return '🦋';
      case PersonalityTrait.empathy: return '🤗';
    }
  }
}

enum InteractionType { casual, romantic, supportive, playful, serious, question, gratitude }
