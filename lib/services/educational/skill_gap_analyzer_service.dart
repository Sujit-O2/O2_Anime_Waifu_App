import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📊 Skill Gap Analyzer Service
///
/// Identify areas for improvement based on conversations and goals.
class SkillGapAnalyzerService {
  SkillGapAnalyzerService._();
  static final SkillGapAnalyzerService instance = SkillGapAnalyzerService._();

  final List<SkillAssessment> _assessments = [];
  final List<SkillGap> _skillGaps = [];
  final List<LearningGoal> _goals = [];

  int _totalAssessments = 0;

  static const String _storageKey = 'skill_gap_analyzer_v1';

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint(
          '[SkillGapAnalyzer] Initialized with $_totalAssessments assessments');
  }

  Future<SkillAssessment> createAssessment({
    required String title,
    required String description,
    required List<SkillArea> skillAreas,
    required AssessmentType type,
  }) async {
    final assessment = SkillAssessment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      skillAreas: skillAreas,
      type: type,
      status: AssessmentStatus.inProgress,
      scores: {},
      completedAt: null,
      createdAt: DateTime.now(),
    );

    _assessments.insert(0, assessment);
    _totalAssessments++;

    await _saveData();

    if (kDebugMode) debugPrint('[SkillGapAnalyzer] Created assessment: $title');
    return assessment;
  }

  Future<void> addSkillScore({
    required String assessmentId,
    required String skillArea,
    required double score,
    required String notes,
  }) async {
    final assessmentIndex =
        _assessments.indexWhere((a) => a.id == assessmentId);
    if (assessmentIndex == -1) return;

    final assessment = _assessments[assessmentIndex];
    final updatedScores = Map<String, double>.from(assessment.scores);
    updatedScores[skillArea] = score.clamp(0.0, 10.0);

    _assessments[assessmentIndex] = assessment.copyWith(
      scores: updatedScores,
    );

    // Create skill gap if score is low
    if (score < 6.0) {
      await _createSkillGap(assessmentId, skillArea, score, notes);
    }

    await _saveData();

    if (kDebugMode)
      debugPrint('[SkillGapAnalyzer] Added score for $skillArea: $score');
  }

  Future<void> _createSkillGap(
    String assessmentId,
    String skillArea,
    double score,
    String notes,
  ) async {
    final gap = SkillGap(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      assessmentId: assessmentId,
      skillArea: skillArea,
      currentLevel: score,
      targetLevel: 8.0,
      priority: _calculatePriority(score),
      notes: notes,
      status: GapStatus.identified,
      createdAt: DateTime.now(),
    );

    _skillGaps.insert(0, gap);
  }

  GapPriority _calculatePriority(double score) {
    if (score < 4.0) return GapPriority.critical;
    if (score < 6.0) return GapPriority.high;
    if (score < 7.0) return GapPriority.medium;
    return GapPriority.low;
  }

  Future<LearningGoal> createLearningGoal({
    required String title,
    required String description,
    required String skillArea,
    required double targetScore,
    required DateTime deadline,
    required List<String> steps,
  }) async {
    final goal = LearningGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      skillArea: skillArea,
      currentScore: 0,
      targetScore: targetScore,
      deadline: deadline,
      steps: steps,
      completedSteps: 0,
      status: GoalStatus.inProgress,
      createdAt: DateTime.now(),
    );

    _goals.insert(0, goal);

    await _saveData();

    if (kDebugMode)
      debugPrint('[SkillGapAnalyzer] Created learning goal: $title');
    return goal;
  }

  Future<void> updateGoalProgress(
      String goalId, double progress, int completedSteps) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex == -1) return;

    final goal = _goals[goalIndex];
    _goals[goalIndex] = goal.copyWith(
      currentScore: progress,
      completedSteps: completedSteps,
      status: progress >= goal.targetScore
          ? GoalStatus.completed
          : GoalStatus.inProgress,
    );

    await _saveData();

    if (kDebugMode)
      debugPrint('[SkillGapAnalyzer] Updated goal progress: $goalId');
  }

  Future<void> completeAssessment(String assessmentId) async {
    final assessmentIndex =
        _assessments.indexWhere((a) => a.id == assessmentId);
    if (assessmentIndex == -1) return;

    final assessment = _assessments[assessmentIndex];
    _assessments[assessmentIndex] = assessment.copyWith(
      status: AssessmentStatus.completed,
      completedAt: DateTime.now(),
    );

    await _saveData();

    if (kDebugMode)
      debugPrint('[SkillGapAnalyzer] Completed assessment: $assessmentId');
  }

  String getSkillAnalysis(String assessmentId) {
    final assessment = _assessments.firstWhere((a) => a.id == assessmentId);

    if (assessment.scores.isEmpty) {
      return 'No scores recorded for this assessment yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 Skill Analysis for "${assessment.title}":');
    buffer.writeln('');

    final sortedScores = assessment.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedScores) {
      final score = entry.value;
      final bar = '█' * (score * 2).round();
      final status = score >= 8.0
          ? '✅'
          : score >= 6.0
              ? '⚠️'
              : '❌';

      buffer.writeln('$status ${entry.key}: ${score.toStringAsFixed(1)}/10');
      buffer.writeln('   $bar');
      buffer.writeln('');
    }

    final avgScore =
        assessment.scores.values.fold<double>(0, (sum, s) => sum + s) /
            assessment.scores.length;
    buffer.writeln('Average Score: ${avgScore.toStringAsFixed(1)}/10');

    return buffer.toString();
  }

  String getSkillGapReport() {
    if (_skillGaps.isEmpty) {
      return 'No skill gaps identified yet. Complete some assessments to get started!';
    }

    final criticalGaps =
        _skillGaps.where((g) => g.priority == GapPriority.critical).length;
    final highGaps =
        _skillGaps.where((g) => g.priority == GapPriority.high).length;
    final mediumGaps =
        _skillGaps.where((g) => g.priority == GapPriority.medium).length;
    final lowGaps =
        _skillGaps.where((g) => g.priority == GapPriority.low).length;

    final buffer = StringBuffer();
    buffer.writeln('🎯 Skill Gap Report:');
    buffer.writeln('');
    buffer.writeln('Total Gaps Identified: ${_skillGaps.length}');
    buffer.writeln('Critical: $criticalGaps');
    buffer.writeln('High: $highGaps');
    buffer.writeln('Medium: $mediumGaps');
    buffer.writeln('Low: $lowGaps');
    buffer.writeln('');

    if (criticalGaps > 0) {
      buffer.writeln('🚨 Critical Priority Gaps:');
      for (final gap in _skillGaps
          .where((g) => g.priority == GapPriority.critical)
          .take(3)) {
        buffer.writeln(
            '• ${gap.skillArea}: ${gap.currentLevel.toStringAsFixed(1)}/10 (Target: ${gap.targetLevel}/10)');
      }
      buffer.writeln('');
    }

    if (highGaps > 0) {
      buffer.writeln('⚠️ High Priority Gaps:');
      for (final gap
          in _skillGaps.where((g) => g.priority == GapPriority.high).take(3)) {
        buffer.writeln(
            '• ${gap.skillArea}: ${gap.currentLevel.toStringAsFixed(1)}/10 (Target: ${gap.targetLevel}/10)');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String getPersonalizedRecommendations() {
    if (_skillGaps.isEmpty) {
      return 'Complete an assessment to get personalized recommendations!';
    }

    final recommendations = <String>[];

    // Sort gaps by priority
    final sortedGaps = _skillGaps.toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));

    for (final gap in sortedGaps.take(5)) {
      final recommendation = _generateRecommendationForGap(gap);
      recommendations.add(recommendation);
    }

    return '💡 Personalized Recommendations:\n${recommendations.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}';
  }

  String _generateRecommendationForGap(SkillGap gap) {
    switch (gap.skillArea.toLowerCase()) {
      case 'communication':
        return 'Practice active listening and join a public speaking group like Toastmasters';
      case 'technical':
        return 'Complete online courses and work on hands-on projects to build practical experience';
      case 'leadership':
        return 'Take on small leadership roles in projects and seek mentorship from experienced leaders';
      case 'problem-solving':
        return 'Practice with case studies and puzzles, and learn structured problem-solving frameworks';
      case 'time-management':
        return 'Use productivity tools and techniques like Pomodoro and time blocking';
      case 'creativity':
        return 'Engage in creative activities and practice brainstorming techniques regularly';
      case 'emotional-intelligence':
        return 'Practice self-awareness and empathy through mindfulness and reflection exercises';
      case 'adaptability':
        return 'Step out of your comfort zone regularly and embrace new challenges';
      default:
        return 'Focus on deliberate practice and seek feedback from experts in this area';
    }
  }

  String getProgressTracking() {
    if (_assessments.isEmpty) {
      return 'No assessments completed yet. Start tracking your progress!';
    }

    final completedAssessments = _assessments
        .where((a) => a.status == AssessmentStatus.completed)
        .toList();
    final inProgressAssessments = _assessments
        .where((a) => a.status == AssessmentStatus.inProgress)
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('📈 Progress Tracking:');
    buffer.writeln('');
    buffer.writeln('Completed Assessments: ${completedAssessments.length}');
    buffer.writeln('In Progress: ${inProgressAssessments.length}');
    buffer.writeln('Total Skill Gaps Identified: ${_skillGaps.length}');
    buffer.writeln(
        'Active Learning Goals: ${_goals.where((g) => g.status == GoalStatus.inProgress).length}');
    buffer.writeln('');

    if (completedAssessments.isNotEmpty) {
      final avgScores = <String, double>{};

      for (final assessment in completedAssessments) {
        assessment.scores.forEach((skill, score) {
          avgScores[skill] = (avgScores[skill] ?? 0) + score;
        });
      }

      final numAssessments = completedAssessments.length;
      avgScores.forEach((skill, total) {
        avgScores[skill] = total / numAssessments;
      });

      buffer.writeln('Average Scores Across Assessments:');
      final sortedAvgScores = avgScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedAvgScores) {
        final score = entry.value;
        final trend = score >= 8.0
            ? '📈'
            : score >= 6.0
                ? '➡️'
                : '📉';
        buffer.writeln('  $trend ${entry.key}: ${score.toStringAsFixed(1)}/10');
      }
    }

    return buffer.toString();
  }

  List<SkillAssessment> getAssessments() => List.unmodifiable(_assessments);

  List<SkillGap> getSkillGaps() => List.unmodifiable(_skillGaps);

  List<LearningGoal> getGoals() => List.unmodifiable(_goals);

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'assessments': _assessments.take(50).map((a) => a.toJson()).toList(),
        'skillGaps': _skillGaps.take(100).map((g) => g.toJson()).toList(),
        'goals': _goals.take(50).map((g) => g.toJson()).toList(),
        'totalAssessments': _totalAssessments,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[SkillGapAnalyzer] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _assessments.clear();
        _assessments.addAll((data['assessments'] as List<dynamic>? ?? [])
            .map((a) => SkillAssessment.fromJson(a as Map<String, dynamic>)));

        _skillGaps.clear();
        _skillGaps.addAll((data['skillGaps'] as List<dynamic>? ?? [])
            .map((g) => SkillGap.fromJson(g as Map<String, dynamic>)));

        _goals.clear();
        _goals.addAll((data['goals'] as List<dynamic>? ?? [])
            .map((g) => LearningGoal.fromJson(g as Map<String, dynamic>)));

        _totalAssessments = data['totalAssessments'] as int? ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SkillGapAnalyzer] Load error: $e');
    }
  }
}

class SkillAssessment {
  final String id;
  final String title;
  final String description;
  final List<SkillArea> skillAreas;
  final AssessmentType type;
  AssessmentStatus status;
  final Map<String, double> scores;
  DateTime? completedAt;
  final DateTime createdAt;

  SkillAssessment({
    required this.id,
    required this.title,
    required this.description,
    required this.skillAreas,
    required this.type,
    required this.status,
    required this.scores,
    required this.completedAt,
    required this.createdAt,
  });

  SkillAssessment copyWith({
    AssessmentStatus? status,
    Map<String, double>? scores,
    DateTime? completedAt,
  }) {
    return SkillAssessment(
      id: id,
      title: title,
      description: description,
      skillAreas: skillAreas,
      type: type,
      status: status ?? this.status,
      scores: scores ?? this.scores,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'skillAreas': skillAreas.map((s) => s.name).toList(),
        'type': type.name,
        'status': status.name,
        'scores': scores,
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SkillAssessment.fromJson(Map<String, dynamic> json) =>
      SkillAssessment(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        skillAreas: (json['skillAreas'] as List<dynamic>? ?? [])
            .map((s) => SkillArea.values.firstWhere(
                  (e) => e.name == s,
                  orElse: () => SkillArea.communication,
                ))
            .toList(),
        type: AssessmentType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AssessmentType.selfAssessment,
        ),
        status: AssessmentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AssessmentStatus.inProgress,
        ),
        scores: Map<String, double>.from(json['scores'] ?? {}),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class SkillGap {
  final String id;
  final String assessmentId;
  final String skillArea;
  final double currentLevel;
  final double targetLevel;
  final GapPriority priority;
  final String notes;
  final GapStatus status;
  final DateTime createdAt;

  SkillGap({
    required this.id,
    required this.assessmentId,
    required this.skillArea,
    required this.currentLevel,
    required this.targetLevel,
    required this.priority,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'assessmentId': assessmentId,
        'skillArea': skillArea,
        'currentLevel': currentLevel,
        'targetLevel': targetLevel,
        'priority': priority.name,
        'notes': notes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SkillGap.fromJson(Map<String, dynamic> json) => SkillGap(
        id: json['id'],
        assessmentId: json['assessmentId'],
        skillArea: json['skillArea'],
        currentLevel: (json['currentLevel'] as num).toDouble(),
        targetLevel: (json['targetLevel'] as num).toDouble(),
        priority: GapPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => GapPriority.medium,
        ),
        notes: json['notes'] ?? '',
        status: GapStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GapStatus.identified,
        ),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class LearningGoal {
  final String id;
  final String title;
  final String description;
  final String skillArea;
  double currentScore;
  final double targetScore;
  final DateTime deadline;
  final List<String> steps;
  int completedSteps;
  GoalStatus status;
  final DateTime createdAt;

  LearningGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.skillArea,
    required this.currentScore,
    required this.targetScore,
    required this.deadline,
    required this.steps,
    required this.completedSteps,
    required this.status,
    required this.createdAt,
  });

  LearningGoal copyWith({
    double? currentScore,
    int? completedSteps,
    GoalStatus? status,
  }) {
    return LearningGoal(
      id: id,
      title: title,
      description: description,
      skillArea: skillArea,
      currentScore: currentScore ?? this.currentScore,
      targetScore: targetScore,
      deadline: deadline,
      steps: steps,
      completedSteps: completedSteps ?? this.completedSteps,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'skillArea': skillArea,
        'currentScore': currentScore,
        'targetScore': targetScore,
        'deadline': deadline.toIso8601String(),
        'steps': steps,
        'completedSteps': completedSteps,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LearningGoal.fromJson(Map<String, dynamic> json) => LearningGoal(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        skillArea: json['skillArea'],
        currentScore: (json['currentScore'] as num).toDouble(),
        targetScore: (json['targetScore'] as num).toDouble(),
        deadline: DateTime.parse(json['deadline']),
        steps: List<String>.from(json['steps'] ?? []),
        completedSteps: json['completedSteps'] ?? 0,
        status: GoalStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GoalStatus.inProgress,
        ),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

enum SkillArea {
  communication('Communication'),
  technical('Technical'),
  leadership('Leadership'),
  problemSolving('Problem Solving'),
  timeManagement('Time Management'),
  creativity('Creativity'),
  emotionalIntelligence('Emotional Intelligence'),
  adaptability('Adaptability'),
  teamwork('Teamwork'),
  criticalThinking('Critical Thinking');

  final String label;
  const SkillArea(this.label);
}

enum AssessmentType {
  selfAssessment,
  peerReview,
  performanceReview,
  skillsTest
}

enum AssessmentStatus { planning, inProgress, completed }

enum GapPriority { critical, high, medium, low }

enum GapStatus { identified, inProgress, resolved }

enum GoalStatus { inProgress, completed, onHold, cancelled }
