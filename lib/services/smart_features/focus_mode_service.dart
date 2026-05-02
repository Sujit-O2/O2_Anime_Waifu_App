import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';

class FocusSession {
  final String id;
  final String goal;
  final int plannedDuration;
  final int actualTime;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isPaused;
  final int distractions;
  final int score;
  final String notes;

  FocusSession({
    required this.id,
    required this.goal,
    required this.plannedDuration,
    required this.actualTime,
    required this.startTime,
    this.endTime,
    this.isPaused = false,
    this.distractions = 0,
    this.score = 0,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal': goal,
        'plannedDuration': plannedDuration,
        'actualTime': actualTime,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isPaused': isPaused,
        'distractions': distractions,
        'score': score,
        'notes': notes,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'],
        goal: json['goal'],
        plannedDuration: json['plannedDuration'],
        actualTime: json['actualTime'],
        startTime: DateTime.parse(json['startTime']),
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        isPaused: json['isPaused'] ?? false,
        distractions: json['distractions'] ?? 0,
        score: json['score'] ?? 0,
        notes: json['notes'] ?? '',
      );
}

class FocusModeService {
  static final FocusModeService instance = FocusModeService._internal();
  factory FocusModeService() => instance;
  FocusModeService._internal();

  static const String _sessionsKey = 'focus_sessions';
  static const String _activeSessionKey = 'active_focus_session';
  FocusSession? _activeSession;
  DateTime? _pauseStartTime;

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<void> startFocusSession({required String goal, required Duration duration}) async {
    final session = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goal: goal,
      plannedDuration: duration.inSeconds,
      actualTime: 0,
      startTime: DateTime.now(),
    );
    _activeSession = session;
    final prefs = await _prefs;
    await prefs.setString(_activeSessionKey, jsonEncode(session.toJson()));
  }

  Future<FocusSession?> endFocusSession() async {
    if (_activeSession == null) return null;
    final endTime = DateTime.now();
    final totalElapsed = endTime.difference(_activeSession!.startTime).inSeconds;
    final distractions = _calculateDistractions(totalElapsed);
    final score = _calculateScore(_activeSession!.plannedDuration, totalElapsed, distractions);
    final completedSession = FocusSession(
      id: _activeSession!.id,
      goal: _activeSession!.goal,
      plannedDuration: _activeSession!.plannedDuration,
      actualTime: totalElapsed,
      startTime: _activeSession!.startTime,
      endTime: endTime,
      distractions: distractions,
      score: score,
    );
    final prefs = await _prefs;
    final sessions = await getSessionHistory();
    sessions.add(completedSession);
    await prefs.setString(_sessionsKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
    await prefs.remove(_activeSessionKey);
    _activeSession = null;
    return completedSession;
  }

  Future<void> pauseSession() async {
    if (_activeSession != null && !_activeSession!.isPaused) {
      _pauseStartTime = DateTime.now();
      _activeSession = FocusSession(
        id: _activeSession!.id,
        goal: _activeSession!.goal,
        plannedDuration: _activeSession!.plannedDuration,
        actualTime: _activeSession!.actualTime,
        startTime: _activeSession!.startTime,
        endTime: _activeSession!.endTime,
        isPaused: true,
        distractions: _activeSession!.distractions,
        score: _activeSession!.score,
        notes: _activeSession!.notes,
      );
      final prefs = await _prefs;
      await prefs.setString(_activeSessionKey, jsonEncode(_activeSession!.toJson()));
    }
  }

  Future<void> resumeSession() async {
    if (_activeSession != null && _activeSession!.isPaused && _pauseStartTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseStartTime!).inSeconds;
      _activeSession = FocusSession(
        id: _activeSession!.id,
        goal: _activeSession!.goal,
        plannedDuration: _activeSession!.plannedDuration,
        actualTime: _activeSession!.actualTime + pauseDuration,
        startTime: _activeSession!.startTime,
        endTime: _activeSession!.endTime,
        isPaused: false,
        distractions: _activeSession!.distractions,
        score: _activeSession!.score,
        notes: _activeSession!.notes,
      );
      _pauseStartTime = null;
      final prefs = await _prefs;
      await prefs.setString(_activeSessionKey, jsonEncode(_activeSession!.toJson()));
    }
  }

  Future<List<FocusSession>> getSessionHistory() async {
    final prefs = await _prefs;
    final data = prefs.getString(_sessionsKey);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => FocusSession.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getFocusStats() async {
    final sessions = await getSessionHistory();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final weekSessions = sessions.where((s) => s.endTime != null && s.endTime!.isAfter(weekStart)).toList();
    final monthSessions = sessions.where((s) => s.endTime != null && s.endTime!.isAfter(monthStart)).toList();
    int calculateStreak(List<FocusSession> allSessions) {
      final dates = allSessions.where((s) => s.endTime != null).map((s) => DateTime(s.endTime!.year, s.endTime!.month, s.endTime!.day)).toSet().toList();
      dates.sort((a, b) => b.compareTo(a));
      if (dates.isEmpty) return 0;
      int streak = 0;
      DateTime checkDate = DateTime.now();
      for (int i = 0; i < 365; i++) {
        final dateToCheck = DateTime(checkDate.year, checkDate.month, checkDate.day - i);
        if (dates.any((d) => d.year == dateToCheck.year && d.month == dateToCheck.month && d.day == dateToCheck.day)) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    }
    return {
      'week': {
        'totalTime': weekSessions.fold(0, (sum, s) => sum + s.actualTime),
        'sessions': weekSessions.length,
        'avgDuration': weekSessions.isEmpty ? 0 : (weekSessions.fold(0, (sum, s) => sum + s.actualTime) / weekSessions.length).round(),
        'streak': calculateStreak(sessions),
      },
      'month': {
        'totalTime': monthSessions.fold(0, (sum, s) => sum + s.actualTime),
        'sessions': monthSessions.length,
        'avgDuration': monthSessions.isEmpty ? 0 : (monthSessions.fold(0, (sum, s) => sum + s.actualTime) / monthSessions.length).round(),
        'streak': calculateStreak(sessions),
      },
      'allTime': {
        'totalTime': sessions.fold(0, (sum, s) => sum + s.actualTime),
        'sessions': sessions.length,
        'avgDuration': sessions.isEmpty ? 0 : (sessions.fold(0, (sum, s) => sum + s.actualTime) / sessions.length).round(),
        'streak': calculateStreak(sessions),
      },
    };
  }

  Future<String> getMotivationalQuote() async {
    try {
      final response = await ApiService().sendConversation([
        {'role': 'user', 'content': 'Give me a short, powerful motivational quote (max 2 sentences) to help someone stay focused on their work or study. Make it energetic and anime-inspired.'},
      ]);
      return response;
    } catch (e) {
      return 'You have the power to achieve anything you set your mind to!';
    }
  }

  int getDistractionCount() {
    if (_activeSession == null) return 0;
    final elapsed = DateTime.now().difference(_activeSession!.startTime).inSeconds - _activeSession!.actualTime;
    return _calculateDistractions(elapsed);
  }

  int _calculateDistractions(int elapsedSeconds) {
    const baseRate = 0.02;
    return (elapsedSeconds / 60 * baseRate).round();
  }

  int _calculateScore(int planned, int actual, int distractions) {
    if (actual == 0) return 0;
    final completionRate = (actual / planned).clamp(0.0, 1.0);
    final distractionPenalty = distractions * 5;
    final score = (completionRate * 100 - distractionPenalty).clamp(0, 100).round();
    return score;
  }

  Future<FocusSession?> getActiveSession() async {
    if (_activeSession != null) return _activeSession;
    final prefs = await _prefs;
    final data = prefs.getString(_activeSessionKey);
    if (data == null) return null;
    _activeSession = FocusSession.fromJson(jsonDecode(data));
    return _activeSession;
  }

  Future<Map<String, int>> getDailyFocusTime(int days) async {
    final sessions = await getSessionHistory();
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final key = '${date.month}/${date.day}';
      final daySessions = sessions.where((s) => s.endTime != null && s.endTime!.year == date.year && s.endTime!.month == date.month && s.endTime!.day == date.day);
      result[key] = daySessions.fold(0, (sum, s) => sum + s.actualTime);
    }
    return result;
  }
}
