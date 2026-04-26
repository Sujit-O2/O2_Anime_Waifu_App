import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🧠 Debate & Critical Thinking Trainer Service
/// 
/// Practice arguments with logical feedback.
class DebateCriticalThinkingService {
  DebateCriticalThinkingService._();
  static final DebateCriticalThinkingService instance = DebateCriticalThinkingService._();

  final List<DebateTopic> _topics = [];
  final List<Argument> _arguments = [];
  final List<CriticalThinkingExercise> _exercises = [];
  
  int _totalDebates = 0;
  int _totalArguments = 0;
  
  static const String _storageKey = 'debate_critical_thinking_v1';
  static const int _maxTopics = 50;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[DebateCriticalThinking] Initialized with $_totalDebates debates');
  }

  Future<DebateTopic> createDebateTopic({
    required String title,
    required String description,
    required DebateCategory category,
    required DifficultyLevel difficulty,
    required String position,
    required List<String> keyPoints,
  }) async {
    final topic = DebateTopic(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      difficulty: difficulty,
      position: position,
      keyPoints: keyPoints,
      arguments: [],
      counterArguments: [],
      status: DebateStatus.preparation,
      score: 0,
      feedback: '',
      createdAt: DateTime.now(),
    );
    
    _topics.insert(0, topic);
    _totalDebates++;
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[DebateCriticalThinking] Created debate topic: $title');
    return topic;
  }

  Future<Argument> addArgument({
    required String topicId,
    required String claim,
    required List<String> evidence,
    required String reasoning,
    required ArgumentType type,
    required double confidence,
  }) async {
    final argument = Argument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topicId: topicId,
      claim: claim,
      evidence: evidence,
      reasoning: reasoning,
      type: type,
      confidence: confidence.clamp(0.0, 1.0),
      strengths: [],
      weaknesses: [],
      logicalValidity: 0,
      createdAt: DateTime.now(),
    );
    
    _arguments.insert(0, argument);
    _totalArguments++;
    
    // Add to topic
    final topicIndex = _topics.indexWhere((t) => t.id == topicId);
    if (topicIndex != -1) {
      final topic = _topics[topicIndex];
      _topics[topicIndex] = topic.copyWith(
        arguments: [...topic.arguments, argument.id],
      );
    }
    
    // Analyze argument
    await _analyzeArgument(argument);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[DebateCriticalThinking] Added argument to topic: $topicId');
    return argument;
  }

  Future<void> _analyzeArgument(Argument argument) async {
    final strengths = <String>[];
    final weaknesses = <String>[];
    double logicalValidity = 5.0;
    
    // Check evidence quality
    if (argument.evidence.length >= 3) {
      strengths.add('Strong evidence base with multiple sources');
      logicalValidity += 1.0;
    } else if (argument.evidence.isEmpty) {
      weaknesses.add('No evidence provided to support claim');
      logicalValidity -= 2.0;
    } else {
      weaknesses.add('Limited evidence - consider adding more sources');
      logicalValidity -= 0.5;
    }
    
    // Check reasoning clarity
    if (argument.reasoning.length > 50) {
      strengths.add('Detailed reasoning provided');
      logicalValidity += 0.5;
    } else if (argument.reasoning.length < 20) {
      weaknesses.add('Reasoning is too brief - expand on your logic');
      logicalValidity -= 1.0;
    }
    
    // Check for logical fallacies
    if (argument.claim.toLowerCase().contains('always') || argument.claim.toLowerCase().contains('never')) {
      weaknesses.add('Watch for absolute statements - they may indicate overgeneralization');
      logicalValidity -= 0.5;
    }
    
    if (argument.evidence.any((e) => e.toLowerCase().contains('everyone knows'))) {
      weaknesses.add('Appeal to common belief is not strong evidence');
      logicalValidity -= 0.5;
    }
    
    // Check confidence vs evidence
    if (argument.confidence > 0.8 && argument.evidence.length < 2) {
      weaknesses.add('High confidence with limited evidence - consider being more cautious');
      logicalValidity -= 0.5;
    }
    
    // Update argument
    final argumentIndex = _arguments.indexWhere((a) => a.id == argument.id);
    if (argumentIndex != -1) {
      _arguments[argumentIndex] = argument.copyWith(
        strengths: strengths,
        weaknesses: weaknesses,
        logicalValidity: logicalValidity.clamp(0.0, 10.0),
      );
    }
  }

  Future<CriticalThinkingExercise> createExercise({
    required String title,
    required String scenario,
    required List<String> questions,
    required ExerciseType type,
    required DifficultyLevel difficulty,
  }) async {
    final exercise = CriticalThinkingExercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      scenario: scenario,
      questions: questions,
      type: type,
      difficulty: difficulty,
      responses: [],
      score: 0,
      feedback: '',
      completed: false,
      createdAt: DateTime.now(),
    );
    
    _exercises.insert(0, exercise);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[DebateCriticalThinking] Created exercise: $title');
    return exercise;
  }

  Future<void> addExerciseResponse({
    required String exerciseId,
    required String questionId,
    required String response,
    required double score,
    required String feedback,
  }) async {
    final exerciseIndex = _exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex == -1) return;
    
    final exercise = _exercises[exerciseIndex];
    final responseObj = ExerciseResponse(
      questionId: questionId,
      response: response,
      score: score,
      feedback: feedback,
    );
    
    _exercises[exerciseIndex] = exercise.copyWith(
      responses: [...exercise.responses, responseObj],
      score: exercise.responses.isEmpty ? score : (exercise.score + score) / 2,
      completed: exercise.responses.length + 1 >= exercise.questions.length,
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[DebateCriticalThinking] Added response to exercise: $exerciseId');
  }

  String getArgumentFeedback(String argumentId) {
    final argument = _arguments.firstWhere((a) => a.id == argumentId);
    
    final buffer = StringBuffer();
    buffer.writeln('📝 Argument Analysis for: "${argument.claim}"');
    buffer.writeln('');
    buffer.writeln('Logical Validity Score: ${argument.logicalValidity.toStringAsFixed(1)}/10');
    buffer.writeln('Confidence Level: ${(argument.confidence * 100).toStringAsFixed(0)}%');
    buffer.writeln('');
    
    if (argument.strengths.isNotEmpty) {
      buffer.writeln('✅ Strengths:');
      for (final strength in argument.strengths) {
        buffer.writeln('• $strength');
      }
      buffer.writeln('');
    }
    
    if (argument.weaknesses.isNotEmpty) {
      buffer.writeln('⚠️ Areas for Improvement:');
      for (final weakness in argument.weaknesses) {
        buffer.writeln('• $weakness');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('💡 Suggestions:');
    buffer.writeln(_generateSuggestions(argument));
    
    return buffer.toString();
  }

  String _generateSuggestions(Argument argument) {
    final suggestions = <String>[];
    
    if (argument.evidence.length < 2) {
      suggestions.add('Add more diverse evidence to strengthen your argument');
    }
    
    if (argument.reasoning.length < 30) {
      suggestions.add('Expand your reasoning to show how evidence supports your claim');
    }
    
    if (argument.logicalValidity < 6.0) {
      suggestions.add('Review your argument for logical consistency and potential fallacies');
    }
    
    if (argument.confidence > 0.8 && argument.evidence.length < 3) {
      suggestions.add('Consider lowering confidence or finding more supporting evidence');
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('This is a well-constructed argument. Consider anticipating counter-arguments');
    }
    
    return suggestions.map((s) => '• $s').join('\n');
  }

  String getDebatePreparation(String topicId) {
    final topic = _topics.firstWhere((t) => t.id == topicId);
    
    final buffer = StringBuffer();
    buffer.writeln('🎯 Debate Preparation: ${topic.title}');
    buffer.writeln('');
    buffer.writeln('Category: ${topic.category.name}');
    buffer.writeln('Difficulty: ${topic.difficulty.name}');
    buffer.writeln('Position: ${topic.position}');
    buffer.writeln('');
    buffer.writeln('Description:');
    buffer.writeln(topic.description);
    buffer.writeln('');
    buffer.writeln('Key Points to Address:');
    for (final point in topic.keyPoints) {
      buffer.writeln('• $point');
    }
    buffer.writeln('');
    buffer.writeln('Preparation Checklist:');
    buffer.writeln('• Research multiple perspectives on the topic');
    buffer.writeln('• Gather credible evidence to support your position');
    buffer.writeln('• Anticipate counter-arguments and prepare responses');
    buffer.writeln('• Practice articulating your key points clearly');
    buffer.writeln('• Consider the ethical implications of your position');
    
    return buffer.toString();
  }

  String getCriticalThinkingTips() {
    final tips = [
      '🔍 Question assumptions - don\'t accept things at face value',
      '📊 Look for evidence - claims without evidence are just opinions',
      '🎯 Consider multiple perspectives - truth is often complex',
      '⚖️ Evaluate arguments based on logic, not emotion',
      '🔄 Be willing to change your mind when presented with better evidence',
      '📝 Clarify your thinking by writing it down',
      '🤔 Ask "why" multiple times to get to root causes',
      '⚠️ Watch for logical fallacies in your own and others\' arguments',
      '📚 Distinguish between correlation and causation',
      '🎯 Focus on what can be known, not just what is believed',
    ];
    
    return '🧠 Critical Thinking Tips:\n' + tips.map((t) => '• $t').join('\n');
  }

  String getDebateInsights() {
    if (_topics.isEmpty) {
      return 'No debate topics created yet. Start practicing your critical thinking!';
    }
    
    final inPreparation = _topics.where((t) => t.status == DebateStatus.preparation).length;
    final inProgress = _topics.where((t) => t.status == DebateStatus.inProgress).length;
    const completed = 0; // Would calculate from completed debates
    
    final byCategory = <DebateCategory, int>{};
    for (final topic in _topics) {
      byCategory[topic.category] = (byCategory[topic.category] ?? 0) + 1;
    }
    
    final avgArgumentsPerTopic = _topics.isNotEmpty ? _totalArguments / _topics.length : 0;
    
    final buffer = StringBuffer();
    buffer.writeln('🎯 Debate & Critical Thinking Insights:');
    buffer.writeln('• Total Topics: $_totalDebates');
    buffer.writeln('• In Preparation: $inPreparation');
    buffer.writeln('• In Progress: $inProgress');
    buffer.writeln('• Total Arguments: $_totalArguments');
    buffer.writeln('• Avg Arguments per Topic: ${avgArgumentsPerTopic.toStringAsFixed(1)}');
    buffer.writeln('');
    buffer.writeln('Topics by Category:');
    for (final entry in byCategory.entries) {
      buffer.writeln('  • ${entry.key.label}: ${entry.value}');
    }
    
    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'topics': _topics.take(20).map((t) => t.toJson()).toList(),
        'arguments': _arguments.take(100).map((a) => a.toJson()).toList(),
        'exercises': _exercises.take(50).map((e) => e.toJson()).toList(),
        'totalDebates': _totalDebates,
        'totalArguments': _totalArguments,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[DebateCriticalThinking] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _topics.clear();
        _topics.addAll(
          (data['topics'] as List<dynamic>? ?? [])
              .map((t) => DebateTopic.fromJson(t as Map<String, dynamic>))
        );
        
        _arguments.clear();
        _arguments.addAll(
          (data['arguments'] as List<dynamic>? ?? [])
              .map((a) => Argument.fromJson(a as Map<String, dynamic>))
        );
        
        _exercises.clear();
        _exercises.addAll(
          (data['exercises'] as List<dynamic>? ?? [])
              .map((e) => CriticalThinkingExercise.fromJson(e as Map<String, dynamic>))
        );
        
        _totalDebates = data['totalDebates'] as int? ?? 0;
        _totalArguments = data['totalArguments'] as int? ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DebateCriticalThinking] Load error: $e');
    }
  }
}

class DebateTopic {
  final String id;
  final String title;
  final String description;
  final DebateCategory category;
  final DifficultyLevel difficulty;
  final String position;
  final List<String> keyPoints;
  final List<String> arguments;
  final List<String> counterArguments;
  DebateStatus status;
  double score;
  String feedback;
  final DateTime createdAt;

  DebateTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.position,
    required this.keyPoints,
    required this.arguments,
    required this.counterArguments,
    required this.status,
    required this.score,
    required this.feedback,
    required this.createdAt,
  });

  DebateTopic copyWith({
    List<String>? arguments,
    List<String>? counterArguments,
    DebateStatus? status,
    double? score,
    String? feedback,
  }) {
    return DebateTopic(
      id: id,
      title: title,
      description: description,
      category: category,
      difficulty: difficulty,
      position: position,
      keyPoints: keyPoints,
      arguments: arguments ?? this.arguments,
      counterArguments: counterArguments ?? this.counterArguments,
      status: status ?? this.status,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'difficulty': difficulty.name,
    'position': position,
    'keyPoints': keyPoints,
    'arguments': arguments,
    'counterArguments': counterArguments,
    'status': status.name,
    'score': score,
    'feedback': feedback,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DebateTopic.fromJson(Map<String, dynamic> json) => DebateTopic(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    category: DebateCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => DebateCategory.philosophy,
    ),
    difficulty: DifficultyLevel.values.firstWhere(
      (e) => e.name == json['difficulty'],
      orElse: () => DifficultyLevel.intermediate,
    ),
    position: json['position'],
    keyPoints: List<String>.from(json['keyPoints'] ?? []),
    arguments: List<String>.from(json['arguments'] ?? []),
    counterArguments: List<String>.from(json['counterArguments'] ?? []),
    status: DebateStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => DebateStatus.preparation,
    ),
    score: (json['score'] as num).toDouble(),
    feedback: json['feedback'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class Argument {
  final String id;
  final String topicId;
  final String claim;
  final List<String> evidence;
  final String reasoning;
  final ArgumentType type;
  final double confidence;
  final List<String> strengths;
  final List<String> weaknesses;
  final double logicalValidity;
  final DateTime createdAt;

  Argument({
    required this.id,
    required this.topicId,
    required this.claim,
    required this.evidence,
    required this.reasoning,
    required this.type,
    required this.confidence,
    required this.strengths,
    required this.weaknesses,
    required this.logicalValidity,
    required this.createdAt,
  });

  Argument copyWith({
    List<String>? strengths,
    List<String>? weaknesses,
    double? logicalValidity,
  }) {
    return Argument(
      id: id,
      topicId: topicId,
      claim: claim,
      evidence: evidence,
      reasoning: reasoning,
      type: type,
      confidence: confidence,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      logicalValidity: logicalValidity ?? this.logicalValidity,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'topicId': topicId,
    'claim': claim,
    'evidence': evidence,
    'reasoning': reasoning,
    'type': type.name,
    'confidence': confidence,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'logicalValidity': logicalValidity,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Argument.fromJson(Map<String, dynamic> json) => Argument(
    id: json['id'],
    topicId: json['topicId'],
    claim: json['claim'],
    evidence: List<String>.from(json['evidence'] ?? []),
    reasoning: json['reasoning'],
    type: ArgumentType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ArgumentType.thesis,
    ),
    confidence: (json['confidence'] as num).toDouble(),
    strengths: List<String>.from(json['strengths'] ?? []),
    weaknesses: List<String>.from(json['weaknesses'] ?? []),
    logicalValidity: (json['logicalValidity'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class CriticalThinkingExercise {
  final String id;
  final String title;
  final String scenario;
  final List<String> questions;
  final ExerciseType type;
  final DifficultyLevel difficulty;
  final List<ExerciseResponse> responses;
  double score;
  String feedback;
  bool completed;
  final DateTime createdAt;

  CriticalThinkingExercise({
    required this.id,
    required this.title,
    required this.scenario,
    required this.questions,
    required this.type,
    required this.difficulty,
    required this.responses,
    required this.score,
    required this.feedback,
    required this.completed,
    required this.createdAt,
  });

  CriticalThinkingExercise copyWith({
    List<ExerciseResponse>? responses,
    double? score,
    String? feedback,
    bool? completed,
  }) {
    return CriticalThinkingExercise(
      id: id,
      title: title,
      scenario: scenario,
      questions: questions,
      type: type,
      difficulty: difficulty,
      responses: responses ?? this.responses,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'scenario': scenario,
    'questions': questions,
    'type': type.name,
    'difficulty': difficulty.name,
    'responses': responses.map((r) => r.toJson()).toList(),
    'score': score,
    'feedback': feedback,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CriticalThinkingExercise.fromJson(Map<String, dynamic> json) => CriticalThinkingExercise(
    id: json['id'],
    title: json['title'],
    scenario: json['scenario'],
    questions: List<String>.from(json['questions'] ?? []),
    type: ExerciseType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ExerciseType.analysis,
    ),
    difficulty: DifficultyLevel.values.firstWhere(
      (e) => e.name == json['difficulty'],
      orElse: () => DifficultyLevel.intermediate,
    ),
    responses: (json['responses'] as List<dynamic>? ?? [])
        .map((r) => ExerciseResponse.fromJson(r as Map<String, dynamic>))
        .toList(),
    score: (json['score'] as num).toDouble(),
    feedback: json['feedback'] ?? '',
    completed: json['completed'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class ExerciseResponse {
  final String questionId;
  final String response;
  final double score;
  final String feedback;

  ExerciseResponse({
    required this.questionId,
    required this.response,
    required this.score,
    required this.feedback,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'response': response,
    'score': score,
    'feedback': feedback,
  };

  factory ExerciseResponse.fromJson(Map<String, dynamic> json) => ExerciseResponse(
    questionId: json['questionId'],
    response: json['response'],
    score: (json['score'] as num).toDouble(),
    feedback: json['feedback'],
  );
}

enum DebateCategory {
  philosophy('Philosophy'),
  politics('Politics'),
  ethics('Ethics'),
  science('Science'),
  economics('Economics'),
  social('Social Issues'),
  technology('Technology'),
  education('Education');
  
  final String label;
  const DebateCategory(this.label);
}

enum DebateStatus { preparation, inProgress, completed }
enum ArgumentType { thesis, counterArgument, supporting, refutation }
enum ExerciseType { analysis, evaluation, synthesis, application }
enum DifficultyLevel { beginner, intermediate, advanced }