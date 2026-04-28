import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🧘 Meditation Guide Service
///
/// AI-guided meditation sessions with biofeedback integration.
class MeditationGuideService {
  MeditationGuideService._();
  static final MeditationGuideService instance = MeditationGuideService._();

  final List<MeditationSession> _meditationHistory = [];
  final Map<String, double> _sessionScores = {};

  int _totalMinutesMeditated = 0;
  int _totalSessions = 0;
  DateTime? _lastSession;

  static const String _storageKey = 'meditation_guide_v1';

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint('[MeditationGuide] Initialized with $_totalSessions sessions');
  }

  Future<void> startMeditationSession({
    required String type,
    required int durationMinutes,
    required String difficulty,
  }) async {
    // Session initialization - biofeedback monitoring would happen here
    if (kDebugMode)
      debugPrint(
          '[MeditationGuide] Started $type meditation for $durationMinutes minutes');
  }

  Future<void> endMeditationSession({
    required String sessionId,
    required double focusScore,
    required double calmScore,
    required String notes,
  }) async {
    final index = _meditationHistory.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final session = _meditationHistory[index].copyWith(
      endTime: DateTime.now(),
      focusScore: focusScore,
      calmScore: calmScore,
      notes: notes,
      completed: true,
    );

    _meditationHistory[index] = session;
    _totalMinutesMeditated += session.durationMinutes;
    _totalSessions++;
    _lastSession = DateTime.now();

    // Calculate overall session score (0-10)
    final overallScore = ((focusScore + calmScore) / 2) * 10;
    _sessionScores[session.id] = overallScore;

    await _saveData();

    if (kDebugMode) {
      debugPrint(
          '[MeditationGuide] Session ended: Score ${overallScore.toStringAsFixed(1)}/10');
    }
  }

  String getMeditationInsights() {
    if (_meditationHistory.isEmpty) {
      return 'Start meditating to get personalized insights!';
    }

    final completedSessions =
        _meditationHistory.where((s) => s.completed).toList();
    if (completedSessions.isEmpty) {
      return 'Complete some meditation sessions to get insights.';
    }

    final recentSessions = completedSessions.take(5).toList();
    final avgDuration =
        recentSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes) /
            recentSessions.length;
    final avgScore = recentSessions.fold<double>(
            0, (sum, s) => sum + (_sessionScores[s.id] ?? 0)) /
        recentSessions.length;

    final buffer = StringBuffer();
    buffer.writeln('🧘 Meditation Insights (Last 5 sessions):');
    buffer.writeln('• Average Duration: $avgDuration minutes');
    buffer.writeln('• Average Score: ${avgScore.toStringAsFixed(1)}/10');
    buffer.writeln('• Total Practice: $_totalMinutesMeditated minutes');

    if (_totalSessions >= 7) {
      buffer.writeln('🌟 You\'ve built a consistent meditation practice!');
    } else if (_totalSessions >= 3) {
      buffer.writeln('💪 Keep going - you\'re building a great habit!');
    } else {
      buffer.writeln('🌱 Just getting started - every session counts!');
    }

    return buffer.toString();
  }

  String getMeditationRecommendation() {
    if (_meditationHistory.isEmpty)
      return 'Start with a 5-minute breathing meditation to begin.';

    final completedSessions =
        _meditationHistory.where((s) => s.completed).toList();
    if (completedSessions.isEmpty)
      return 'Complete a session first to get recommendations.';

    final lastSession = completedSessions.first;
    final recommendations = <String>[];

    final lastScore = _sessionScores[lastSession.id] ?? 0;

    if (lastScore < 5) {
      recommendations
          .add('Try a shorter session (3-5 minutes) to build confidence');
      recommendations
          .add('Focus on breathing exercises rather than emptying your mind');
    } else if (lastScore < 7) {
      recommendations.add('Try extending your sessions by 2-3 minutes');
      recommendations.add(
          'Experiment with different meditation types (body scan, loving-kindness)');
    } else {
      recommendations
          .add('Consider trying advanced techniques like mantra meditation');
      recommendations
          .add('You might enjoy guiding others or joining a meditation group');
    }

    // Add type-based recommendations
    if (lastSession.type.contains('breath')) {
      recommendations
          .add('Try a body scan meditation next for deeper relaxation');
    } else if (lastSession.type.contains('body')) {
      recommendations
          .add('Try a loving-kindness meditation to cultivate compassion');
    }

    return '🎯 Meditation Recommendation: ${recommendations.join(' • ')}';
  }

  List<String> getAvailableMeditationTypes() {
    return [
      'Breathing Awareness',
      'Body Scan',
      'Loving-Kindness (Metta)',
      'Mindfulness of Thoughts',
      'Walking Meditation',
      'Mantra Meditation',
      'Visualization',
      'Gratitude Meditation',
      'Sleep Meditation',
      'Stress Relief Meditation',
    ];
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'meditationHistory':
            _meditationHistory.take(30).map((s) => s.toJson()).toList(),
        'totalMinutesMeditated': _totalMinutesMeditated,
        'totalSessions': _totalSessions,
        'sessionScores': _sessionScores,
        'lastSession': _lastSession?.toIso8601String(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[MeditationGuide] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _meditationHistory.clear();
        _meditationHistory.addAll((data['meditationHistory'] as List<dynamic>)
            .map((s) => MeditationSession.fromJson(s as Map<String, dynamic>)));

        _totalMinutesMeditated = data['totalMinutesMeditated'] as int;
        _totalSessions = data['totalSessions'] as int;
        final loadedScores =
            Map<String, double>.from(data['sessionScores'] ?? {});
        _sessionScores.clear();
        _sessionScores.addAll(loadedScores);

        if (data['lastSession'] != null) {
          _lastSession = DateTime.parse(data['lastSession'] as String);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[MeditationGuide] Load error: $e');
    }
  }
}

class MeditationSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final String type;
  final int durationMinutes;
  final String difficulty;
  double? focusScore; // 0-1 scale
  double? calmScore; // 0-1 scale
  String? notes;
  bool completed;

  MeditationSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.type,
    required this.durationMinutes,
    required this.difficulty,
    this.focusScore,
    this.calmScore,
    this.notes,
    this.completed = false,
  });

  MeditationSession copyWith({
    DateTime? endTime,
    double? focusScore,
    double? calmScore,
    String? notes,
    bool? completed,
  }) {
    return MeditationSession(
      id: id,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      type: type,
      durationMinutes: durationMinutes,
      difficulty: difficulty,
      focusScore: focusScore ?? this.focusScore,
      calmScore: calmScore ?? this.calmScore,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'type': type,
        'durationMinutes': durationMinutes,
        'difficulty': difficulty,
        'focusScore': focusScore,
        'calmScore': calmScore,
        'notes': notes,
        'completed': completed,
      };

  factory MeditationSession.fromJson(Map<String, dynamic> json) =>
      MeditationSession(
        id: json['id'],
        startTime: DateTime.parse(json['startTime']),
        endTime:
            json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        type: json['type'],
        durationMinutes: json['durationMinutes'],
        difficulty: json['difficulty'],
        focusScore: json['focusScore'] != null
            ? (json['focusScore'] as num).toDouble()
            : null,
        calmScore: json['calmScore'] != null
            ? (json['calmScore'] as num).toDouble()
            : null,
        notes: json['notes'],
        completed: json['completed'] ?? false,
      );
}
