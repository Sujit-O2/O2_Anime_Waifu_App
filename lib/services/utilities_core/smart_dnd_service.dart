import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔔 Smart Do Not Disturb Service
class SmartDNDService {
  SmartDNDService._();
  static final SmartDNDService instance = SmartDNDService._();

  final List<DNDPattern> _patterns = [];
  final List<DNDEvent> _history = [];
  bool _isEnabled = true;

  Future<void> initialize() async {
    await _loadData();
    _analyzePatterns();
    if (kDebugMode) debugPrint('[SmartDND] Initialized');
  }

  bool shouldNotify({required DateTime currentTime, required UserActivity userActivity, required MessageUrgency urgency}) {
    if (!_isEnabled) return true;
    if (urgency == MessageUrgency.critical) return true;

    final hour = currentTime.hour;
    if (hour >= 22 || hour < 7) return false;
    if (userActivity == UserActivity.inMeeting || userActivity == UserActivity.driving) return false;
    if (userActivity == UserActivity.focusMode) return urgency == MessageUrgency.high;

    final pattern = _findMatchingPattern(currentTime, userActivity);
    if (pattern != null && pattern.shouldBlock) return false;

    return true;
  }

  Future<void> recordEvent({required DateTime time, required UserActivity activity, required bool wasBlocked}) async {
    _history.insert(0, DNDEvent(timestamp: time, activity: activity, wasBlocked: wasBlocked));
    if (_history.length > 500) _history.removeLast();
    await _saveData();
    _analyzePatterns();
  }

  DNDPattern? _findMatchingPattern(DateTime time, UserActivity activity) {
    return _patterns.firstWhere((p) => p.hour == time.hour && p.dayOfWeek == time.weekday && p.activity == activity, orElse: () => DNDPattern(hour: 0, dayOfWeek: 0, activity: UserActivity.idle, shouldBlock: false, confidence: 0));
  }

  void _analyzePatterns() {
    _patterns.clear();
    for (int day = 1; day <= 7; day++) {
      for (int hour = 0; hour < 24; hour++) {
        for (final activity in UserActivity.values) {
          final events = _history.where((e) => e.timestamp.weekday == day && e.timestamp.hour == hour && e.activity == activity).toList();
          if (events.length >= 3) {
            final blockedCount = events.where((e) => e.wasBlocked).length;
            final shouldBlock = blockedCount > events.length * 0.6;
            _patterns.add(DNDPattern(hour: hour, dayOfWeek: day, activity: activity, shouldBlock: shouldBlock, confidence: blockedCount / events.length));
          }
        }
      }
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (kDebugMode) debugPrint('[SmartDND] ${enabled ? 'Enabled' : 'Disabled'}');
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dnd_history', jsonEncode(_history.map((e) => e.toJson()).toList()));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('dnd_history');
    if (data != null) {
      _history.clear();
      _history.addAll((jsonDecode(data) as List).map((e) => DNDEvent.fromJson(e)));
    }
  }
}

class DNDPattern {
  final int hour;
  final int dayOfWeek;
  final UserActivity activity;
  final bool shouldBlock;
  final double confidence;

  DNDPattern({required this.hour, required this.dayOfWeek, required this.activity, required this.shouldBlock, required this.confidence});
}

class DNDEvent {
  final DateTime timestamp;
  final UserActivity activity;
  final bool wasBlocked;

  DNDEvent({required this.timestamp, required this.activity, required this.wasBlocked});

  Map<String, dynamic> toJson() => {'timestamp': timestamp.toIso8601String(), 'activity': activity.name, 'wasBlocked': wasBlocked};
  factory DNDEvent.fromJson(Map<String, dynamic> json) => DNDEvent(timestamp: DateTime.parse(json['timestamp']), activity: UserActivity.values.firstWhere((e) => e.name == json['activity']), wasBlocked: json['wasBlocked']);
}

enum UserActivity { idle, inMeeting, driving, focusMode, sleeping, working, exercising }
enum MessageUrgency { low, medium, high, critical }
