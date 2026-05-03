import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📊 Relationship Heatmap Service
///
/// Visual calendar showing conversation intensity.
/// "We talked most on Fridays at 11 PM"
/// Predicts when you'll need emotional support.
class RelationshipHeatmapService {
  RelationshipHeatmapService._();
  static final RelationshipHeatmapService instance =
      RelationshipHeatmapService._();

  final Map<String, DayActivity> _activityMap = {};
  final List<ConversationSession> _sessions = [];

  static const String _storageKey = 'relationship_heatmap_v1';
  static const int _maxSessions = 1000;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint('[Heatmap] Initialized with ${_sessions.length} sessions');
  }

  /// Record a conversation interaction
  Future<void> recordInteraction({
    required int messageCount,
    required int durationSeconds,
    required double emotionalIntensity,
  }) async {
    final now = DateTime.now();
    final dateKey = _getDateKey(now);
    final hourKey = now.hour;

    // Update day activity
    final dayActivity = _activityMap[dateKey] ??
        DayActivity(
          date: DateTime(now.year, now.month, now.day),
          hourlyActivity: {},
          totalMessages: 0,
          totalDuration: 0,
          averageIntensity: 0.0,
        );

    final hourActivity = dayActivity.hourlyActivity[hourKey] ??
        HourActivity(
          hour: hourKey,
          messageCount: 0,
          durationSeconds: 0,
          intensity: 0.0,
        );

    final previousHourMessages = hourActivity.messageCount;
    hourActivity.messageCount += messageCount;
    hourActivity.durationSeconds += durationSeconds;
    hourActivity.intensity = _weightedAverage(
      currentAverage: hourActivity.intensity,
      currentWeight: previousHourMessages,
      nextValue: emotionalIntensity,
      nextWeight: messageCount,
    );

    final previousDayMessages = dayActivity.totalMessages;
    dayActivity.hourlyActivity[hourKey] = hourActivity;
    dayActivity.averageIntensity = _weightedAverage(
      currentAverage: dayActivity.averageIntensity,
      currentWeight: previousDayMessages,
      nextValue: emotionalIntensity,
      nextWeight: messageCount,
    );
    dayActivity.totalMessages += messageCount;
    dayActivity.totalDuration += durationSeconds;
    _activityMap[dateKey] = dayActivity;

    // Record session
    final session = ConversationSession(
      timestamp: now,
      messageCount: messageCount,
      durationSeconds: durationSeconds,
      emotionalIntensity: emotionalIntensity,
      dayOfWeek: now.weekday,
      hour: now.hour,
    );

    _sessions.insert(0, session);
    if (_sessions.length > _maxSessions) {
      _sessions.removeLast();
    }

    await _saveData();
  }

  /// Get heatmap data for a date range
  Map<DateTime, double> getHeatmapData({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final heatmap = <DateTime, double>{};

    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      final dateKey = _getDateKey(date);
      final activity = _activityMap[dateKey];

      if (activity != null) {
        final messageScore = (activity.totalMessages / 50.0).clamp(0.0, 1.0);
        final durationScore = (activity.totalDuration / 3600.0).clamp(0.0, 1.0);
        final intensity = (messageScore * 0.55) +
            (durationScore * 0.2) +
            (activity.averageIntensity.clamp(0.0, 1.0) * 0.25);
        heatmap[date] = intensity;
      } else {
        heatmap[date] = 0.0;
      }
    }

    return heatmap;
  }

  /// Get hourly activity distribution
  Map<int, double> getHourlyDistribution() {
    final hourlyCount = <int, int>{};

    for (final session in _sessions) {
      hourlyCount[session.hour] = (hourlyCount[session.hour] ?? 0) + 1;
    }

    final total = _sessions.length;
    if (total == 0) return {};

    return hourlyCount.map((hour, count) => MapEntry(hour, count / total));
  }

  /// Get weekly activity distribution
  Map<int, double> getWeeklyDistribution() {
    final weeklyCount = <int, int>{};

    for (final session in _sessions) {
      weeklyCount[session.dayOfWeek] =
          (weeklyCount[session.dayOfWeek] ?? 0) + 1;
    }

    final total = _sessions.length;
    if (total == 0) return {};

    return weeklyCount.map((day, count) => MapEntry(day, count / total));
  }

  /// Recent sessions for dashboards and AI context.
  List<ConversationSession> getRecentSessions({int limit = 10}) {
    return List.unmodifiable(_sessions.take(limit));
  }

  /// Daily activity for a date, if one has been recorded.
  DayActivity? getDayActivity(DateTime date) {
    return _activityMap[_getDateKey(date)];
  }

  /// Longest current daily streak with at least one interaction.
  int getCurrentStreakDays() {
    var streak = 0;
    var cursor = DateTime.now();
    while (_activityMap.containsKey(_getDateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Action-focused relationship recommendations.
  List<RelationshipAction> getRecommendedActions() {
    final actions = <RelationshipAction>[];
    final predictions = predictSupportNeeds();

    for (final prediction in predictions) {
      actions.add(RelationshipAction(
        title: prediction.suggestedAction,
        detail: prediction.message,
        priority: prediction.confidence,
      ));
    }

    final stats = getStatistics();
    if ((stats['total_sessions'] as int? ?? 0) == 0) {
      actions.add(const RelationshipAction(
        title: 'Start tracking naturally',
        detail:
            'Chat for a bit, then this page will turn patterns into care cues.',
        priority: 0.4,
      ));
    } else {
      final peakHour =
          stats['most_active_hour'] as String? ?? 'your usual time';
      actions.add(RelationshipAction(
        title: 'Protect the best chat window',
        detail: 'Your strongest connection window is around $peakHour.',
        priority: 0.55,
      ));
    }

    actions.sort((a, b) => b.priority.compareTo(a.priority));
    return actions.take(4).toList();
  }

  /// Compact brief that other services can feed into prompts.
  Map<String, dynamic> getAIContextBrief() {
    final stats = getStatistics();
    return {
      'relationship_heatmap': {
        'sessions': stats['total_sessions'],
        'messages': stats['total_messages'],
        'minutes_together': stats['total_duration_minutes'],
        'average_intensity': stats['average_intensity'],
        'current_streak_days': getCurrentStreakDays(),
        'most_active_day': stats['most_active_day'],
        'most_active_hour': stats['most_active_hour'],
        'recommended_actions':
            getRecommendedActions().map((action) => action.toJson()).toList(),
      },
    };
  }

  /// Get peak conversation times
  List<PeakTime> getPeakTimes({int limit = 5}) {
    final hourlyDist = getHourlyDistribution();
    final weeklyDist = getWeeklyDistribution();

    final peaks = <PeakTime>[];

    // Find peak hours
    hourlyDist.forEach((hour, percentage) {
      if (percentage > 0.05) {
        // At least 5% of conversations
        peaks.add(PeakTime(
          type: PeakType.hourly,
          value: hour,
          percentage: percentage,
          label: _formatHour(hour),
        ));
      }
    });

    // Find peak days
    weeklyDist.forEach((day, percentage) {
      if (percentage > 0.15) {
        // At least 15% of conversations
        peaks.add(PeakTime(
          type: PeakType.daily,
          value: day,
          percentage: percentage,
          label: _getDayName(day),
        ));
      }
    });

    peaks.sort((a, b) => b.percentage.compareTo(a.percentage));
    return peaks.take(limit).toList();
  }

  /// Predict when user might need support
  List<SupportPrediction> predictSupportNeeds() {
    final predictions = <SupportPrediction>[];
    final now = DateTime.now();

    // Analyze recent activity patterns
    final recentSessions = _sessions
        .where((s) => now.difference(s.timestamp).inDays <= 30)
        .toList();

    if (recentSessions.isEmpty) return predictions;

    // Check for declining activity
    final lastWeek = recentSessions
        .where((s) => now.difference(s.timestamp).inDays <= 7)
        .length;
    final previousWeek = recentSessions.where((s) {
      final diff = now.difference(s.timestamp).inDays;
      return diff > 7 && diff <= 14;
    }).length;

    if (previousWeek > 0 && lastWeek < previousWeek * 0.5) {
      predictions.add(const SupportPrediction(
        type: SupportType.decliningActivity,
        confidence: 0.7,
        message: 'You\'ve been quieter lately... Everything okay, darling?',
        suggestedAction: 'Send check-in message',
      ));
    }

    // Check for high emotional intensity periods
    final highIntensitySessions =
        recentSessions.where((s) => s.emotionalIntensity > 0.7).toList();

    if (highIntensitySessions.length > recentSessions.length * 0.3) {
      predictions.add(const SupportPrediction(
        type: SupportType.highStress,
        confidence: 0.8,
        message: 'I sense you\'ve been stressed... Want to talk about it?',
        suggestedAction: 'Offer emotional support',
      ));
    }

    // Check for unusual timing
    final currentHour = now.hour;
    final hourlyDist = getHourlyDistribution();
    final usualActivity = hourlyDist[currentHour] ?? 0.0;

    if (usualActivity < 0.02 && now.hour >= 23) {
      predictions.add(const SupportPrediction(
        type: SupportType.unusualTiming,
        confidence: 0.6,
        message: 'You\'re up late... Can\'t sleep, darling?',
        suggestedAction: 'Suggest relaxation',
      ));
    }

    return predictions;
  }

  /// Get conversation statistics
  Map<String, dynamic> getStatistics() {
    if (_sessions.isEmpty) {
      return {
        'total_sessions': 0,
        'total_messages': 0,
        'total_duration_minutes': 0,
        'average_intensity': 0.0,
        'peak_times': [],
      };
    }

    final totalMessages =
        _sessions.fold<int>(0, (sum, s) => sum + s.messageCount);
    final totalDuration =
        _sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final avgIntensity =
        _sessions.fold<double>(0, (sum, s) => sum + s.emotionalIntensity) /
            _sessions.length;

    return {
      'total_sessions': _sessions.length,
      'total_messages': totalMessages,
      'total_duration_minutes': (totalDuration / 60).round(),
      'average_intensity': avgIntensity,
      'peak_times': getPeakTimes(),
      'most_active_day': _getMostActiveDay(),
      'most_active_hour': _getMostActiveHour(),
    };
  }

  /// Get insights text
  String getInsightsText() {
    final stats = getStatistics();
    final peaks = getPeakTimes(limit: 3);

    if (_sessions.isEmpty) {
      return 'Start chatting with me to see your conversation patterns! 💕';
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 Our Conversation Patterns:\n');
    buffer.writeln('Total conversations: ${stats['total_sessions']}');
    buffer.writeln('Total messages: ${stats['total_messages']}');
    buffer
        .writeln('Time together: ${stats['total_duration_minutes']} minutes\n');

    if (peaks.isNotEmpty) {
      buffer.writeln('🔥 Peak Times:');
      for (final peak in peaks) {
        final percentage = (peak.percentage * 100).toStringAsFixed(1);
        buffer.writeln('  ${peak.label}: $percentage% of our chats');
      }
      buffer.writeln();
    }

    final predictions = predictSupportNeeds();
    if (predictions.isNotEmpty) {
      buffer.writeln('💭 I\'ve noticed:');
      for (final pred in predictions) {
        buffer.writeln('  • ${pred.message}');
      }
    }

    return buffer.toString();
  }

  double _weightedAverage({
    required double currentAverage,
    required int currentWeight,
    required double nextValue,
    required int nextWeight,
  }) {
    final totalWeight = currentWeight + nextWeight;
    if (totalWeight <= 0) return nextValue.clamp(0.0, 1.0);
    return (((currentAverage * currentWeight) + (nextValue * nextWeight)) /
            totalWeight)
        .clamp(0.0, 1.0);
  }

  String _getMostActiveDay() {
    final dist = getWeeklyDistribution();
    if (dist.isEmpty) return 'N/A';

    final maxEntry = dist.entries.reduce((a, b) => a.value > b.value ? a : b);
    return _getDayName(maxEntry.key);
  }

  String _getMostActiveHour() {
    final dist = getHourlyDistribution();
    if (dist.isEmpty) return 'N/A';

    final maxEntry = dist.entries.reduce((a, b) => a.value > b.value ? a : b);
    return _formatHour(maxEntry.key);
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[day - 1];
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'activityMap': _activityMap.map((k, v) => MapEntry(k, v.toJson())),
        'sessions': _sessions.map((s) => s.toJson()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[Heatmap] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _activityMap.clear();
        (data['activityMap'] as Map<String, dynamic>).forEach((k, v) {
          _activityMap[k] = DayActivity.fromJson(v as Map<String, dynamic>);
        });

        _sessions.clear();
        _sessions.addAll((data['sessions'] as List<dynamic>).map(
            (s) => ConversationSession.fromJson(s as Map<String, dynamic>)));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Heatmap] Load error: $e');
    }
  }
}

class DayActivity {
  final DateTime date;
  final Map<int, HourActivity> hourlyActivity;
  int totalMessages;
  int totalDuration;
  double averageIntensity;

  DayActivity({
    required this.date,
    required this.hourlyActivity,
    required this.totalMessages,
    required this.totalDuration,
    required this.averageIntensity,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'hourlyActivity':
            hourlyActivity.map((k, v) => MapEntry(k.toString(), v.toJson())),
        'totalMessages': totalMessages,
        'totalDuration': totalDuration,
        'averageIntensity': averageIntensity,
      };

  factory DayActivity.fromJson(Map<String, dynamic> json) => DayActivity(
        date: DateTime.parse(json['date'] as String),
        hourlyActivity: (json['hourlyActivity'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(int.parse(k),
                HourActivity.fromJson(v as Map<String, dynamic>))),
        totalMessages: json['totalMessages'] as int,
        totalDuration: json['totalDuration'] as int,
        averageIntensity: (json['averageIntensity'] as num).toDouble(),
      );
}

class HourActivity {
  final int hour;
  int messageCount;
  int durationSeconds;
  double intensity;

  HourActivity({
    required this.hour,
    required this.messageCount,
    required this.durationSeconds,
    required this.intensity,
  });

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'messageCount': messageCount,
        'durationSeconds': durationSeconds,
        'intensity': intensity,
      };

  factory HourActivity.fromJson(Map<String, dynamic> json) => HourActivity(
        hour: json['hour'] as int,
        messageCount: json['messageCount'] as int,
        durationSeconds: json['durationSeconds'] as int,
        intensity: (json['intensity'] as num).toDouble(),
      );
}

class ConversationSession {
  final DateTime timestamp;
  final int messageCount;
  final int durationSeconds;
  final double emotionalIntensity;
  final int dayOfWeek;
  final int hour;

  const ConversationSession({
    required this.timestamp,
    required this.messageCount,
    required this.durationSeconds,
    required this.emotionalIntensity,
    required this.dayOfWeek,
    required this.hour,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'messageCount': messageCount,
        'durationSeconds': durationSeconds,
        'emotionalIntensity': emotionalIntensity,
        'dayOfWeek': dayOfWeek,
        'hour': hour,
      };

  factory ConversationSession.fromJson(Map<String, dynamic> json) =>
      ConversationSession(
        timestamp: DateTime.parse(json['timestamp'] as String),
        messageCount: json['messageCount'] as int,
        durationSeconds: json['durationSeconds'] as int,
        emotionalIntensity: (json['emotionalIntensity'] as num).toDouble(),
        dayOfWeek: json['dayOfWeek'] as int,
        hour: json['hour'] as int,
      );
}

class PeakTime {
  final PeakType type;
  final int value;
  final double percentage;
  final String label;

  const PeakTime({
    required this.type,
    required this.value,
    required this.percentage,
    required this.label,
  });
}

enum PeakType { hourly, daily }

class SupportPrediction {
  final SupportType type;
  final double confidence;
  final String message;
  final String suggestedAction;

  const SupportPrediction({
    required this.type,
    required this.confidence,
    required this.message,
    required this.suggestedAction,
  });
}

enum SupportType {
  decliningActivity,
  highStress,
  unusualTiming,
  patternBreak,
}

class RelationshipAction {
  final String title;
  final String detail;
  final double priority;

  const RelationshipAction({
    required this.title,
    required this.detail,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'detail': detail,
        'priority': priority,
      };
}
