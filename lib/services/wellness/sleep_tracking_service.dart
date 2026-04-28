import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 😴 Sleep Tracking & Analysis Service
/// 
/// Integrates with device sensors to monitor sleep patterns and provide 
/// personalized sleep recommendations.
class SleepTrackingService {
  SleepTrackingService._();
  static final SleepTrackingService instance = SleepTrackingService._();

  final Map<String, dynamic> _sleepData = {};
  final List<SleepSession> _sleepHistory = [];
  final Map<String, double> _sleepScores = {};
  
  int _totalNightsTracked = 0;
  DateTime? _lastAnalysis;
  
  static const String _storageKey = 'sleep_tracking_v1';
  static const int _maxHistory = 180; // 6 months of data

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[SleepTracking] Initialized with $_totalNightsTracked nights tracked');
  }

  Future<void> startSleepTracking() async {
    // In a real implementation, this would connect to device sensors
    // For now, we'll simulate the start of a sleep session
    _sleepData['startTime'] = DateTime.now().toIso8601String();
    _sleepData['isTracking'] = true;
    
    if (kDebugMode) debugPrint('[SleepTracking] Sleep tracking started');
  }

  Future<void> stopSleepTracking({required double sleepQuality}) async {
    if (!_sleepData['isTracking']) return;
    
    final endTime = DateTime.now();
    final startTime = DateTime.parse(_sleepData['startTime']);
    final durationInHours = endTime.difference(startTime).inMinutes / 60;
    
    final session = SleepSession(
      startTime: startTime,
      endTime: endTime,
      durationHours: durationInHours,
      sleepQuality: sleepQuality,
      remPercentage: _calculateRemPercentage(sleepQuality),
      deepSleepPercentage: _calculateDeepSleepPercentage(sleepQuality),
      awakeCount: _calculateAwakeCount(sleepQuality),
    );
    
    _sleepHistory.insert(0, session);
    if (_sleepHistory.length > _maxHistory) {
      _sleepHistory.removeLast();
    }
    
    _totalNightsTracked++;
    _sleepScores[endTime.toIso8601String().substring(0, 10)] = sleepQuality;
    _lastAnalysis = endTime;
    
    _sleepData.clear();
    _sleepData['isTracking'] = false;
    
    await _saveData();
    
    if (kDebugMode) {
      debugPrint('[SleepTracking] Sleep session recorded: ${durationInHours.toStringAsFixed(1)}h, Quality: $sleepQuality/10');
    }
  }

  double _calculateRemPercentage(double quality) {
    // Simulate REM percentage based on sleep quality
    return (quality / 10) * 20 + 15; // 15-35% REM
  }

  double _calculateDeepSleepPercentage(double quality) {
    // Simulate deep sleep percentage based on sleep quality
    return (quality / 10) * 25 + 10; // 10-35% deep sleep
  }

  int _calculateAwakeCount(double quality) {
    // Simulate awake count inversely related to sleep quality
    return ((10 - quality) * 2).round().clamp(0, 10);
  }

  String getSleepInsights() {
    if (_sleepHistory.isEmpty) {
      return 'Start tracking your sleep to get personalized insights!';
    }

    final recentSessions = _sleepHistory.take(7).toList();
    final avgDuration = recentSessions.fold<double>(0, (sum, s) => sum + s.durationHours) / recentSessions.length;
    final avgQuality = recentSessions.fold<double>(0, (sum, s) => sum + s.sleepQuality) / recentSessions.length;
    
    final buffer = StringBuffer();
    buffer.writeln('😴 Sleep Insights (Last 7 nights):');
    buffer.writeln('• Average Duration: ${avgDuration.toStringAsFixed(1)} hours');
    buffer.writeln('• Average Quality: ${avgQuality.toStringAsFixed(1)}/10');
    
    if (avgDuration < 7) {
      buffer.writeln('💡 Try to get at least 7-8 hours of sleep for optimal recovery.');
    } else if (avgQuality < 6) {
      buffer.writeln('💡 Your sleep quality could improve. Consider a consistent bedtime routine.');
    } else {
      buffer.writeln('🌟 Great sleep habits! Keep up the consistent routine.');
    }
    
    return buffer.toString();
  }

  String getSleepRecommendation() {
    if (_sleepHistory.isEmpty) return 'Track your sleep first to get personalized recommendations.';
    
    final lastSession = _sleepHistory.first;
    final recommendations = <String>[];
    
    if (lastSession.durationHours < 6) {
      recommendations.add('Try going to bed earlier to increase sleep duration');
    }
    
    if (lastSession.sleepQuality < 5) {
      recommendations.add('Consider reducing screen time before bed');
      recommendations.add('Try relaxation techniques like deep breathing');
    }
    
    if (lastSession.awakeCount > 3) {
      recommendations.add('Limit caffeine intake in the afternoon');
      recommendations.add('Ensure your bedroom is cool and dark');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Your sleep looks great! Maintain your current routine');
    }
    
    return '💤 Sleep Recommendation: ${recommendations.join(' • ')}';
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'sleepHistory': _sleepHistory.take(50).map((s) => s.toJson()).toList(),
        'totalNightsTracked': _totalNightsTracked,
        'sleepScores': _sleepScores,
        'lastAnalysis': _lastAnalysis?.toIso8601String(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[SleepTracking] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _sleepHistory.clear();
        _sleepHistory.addAll(
          (data['sleepHistory'] as List<dynamic>)
              .map((s) => SleepSession.fromJson(s as Map<String, dynamic>))
        );

        _totalNightsTracked = data['totalNightsTracked'] as int;
        final loadedScores = Map<String, double>.from(data['sleepScores'] ?? {});
        _sleepScores.clear();
        _sleepScores.addAll(loadedScores);

        if (data['lastAnalysis'] != null) {
          _lastAnalysis = DateTime.parse(data['lastAnalysis'] as String);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SleepTracking] Load error: $e');
    }
  }
}

class SleepSession {
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;
  final double sleepQuality; // 0-10 scale
  final double remPercentage;
  final double deepSleepPercentage;
  final int awakeCount;

  SleepSession({
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.sleepQuality,
    required this.remPercentage,
    required this.deepSleepPercentage,
    required this.awakeCount,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationHours': durationHours,
    'sleepQuality': sleepQuality,
    'remPercentage': remPercentage,
    'deepSleepPercentage': deepSleepPercentage,
    'awakeCount': awakeCount,
  };

  factory SleepSession.fromJson(Map<String, dynamic> json) => SleepSession(
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    durationHours: (json['durationHours'] as num).toDouble(),
    sleepQuality: (json['sleepQuality'] as num).toDouble(),
    remPercentage: (json['remPercentage'] as num).toDouble(),
    deepSleepPercentage: (json['deepSleepPercentage'] as num).toDouble(),
    awakeCount: (json['awakeCount'] as int),
  );
}