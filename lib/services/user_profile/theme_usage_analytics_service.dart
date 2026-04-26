import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Usage Analytics Service - Track theme usage patterns and metrics
class ThemeUsageAnalyticsService {
  static final ThemeUsageAnalyticsService _instance =
      ThemeUsageAnalyticsService._internal();
  factory ThemeUsageAnalyticsService() => _instance;
  ThemeUsageAnalyticsService._internal();

  static const String _themeSessionsKey = 'theme_sessions';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) debugPrint('✅ Theme Usage Analytics Service initialized');
  }

  /// Record theme session start
  Future<void> recordThemeSessionStart(String themeId, String themeName) async {
    try {
      final session = ThemeSession(
        id: _generateId(),
        themeId: themeId,
        themeName: themeName,
        startedAt: DateTime.now(),
        endedAt: null,
      );

      final json = jsonEncode(session.toJson());
      await _prefs.setString('current_theme_session', json);
      if (kDebugMode) debugPrint('📊 Theme session started: $themeName');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error recording theme session start: $e');
    }
  }

  /// Record theme session end
  Future<void> recordThemeSessionEnd() async {
    try {
      final sessionJson = _prefs.getString('current_theme_session');
      if (sessionJson != null) {
        final session = ThemeSession.fromJson(jsonDecode(sessionJson));
        final endedSession = ThemeSession(
          id: session.id,
          themeId: session.themeId,
          themeName: session.themeName,
          startedAt: session.startedAt,
          endedAt: DateTime.now(),
        );

        // Save completed session
        final sessionsJson = _prefs.getString(_themeSessionsKey) ?? '[]';
        final sessionsList = jsonDecode(sessionsJson) as List;
        sessionsList.add(endedSession.toJson());

        await _prefs.setString(_themeSessionsKey, jsonEncode(sessionsList));
        await _prefs.remove('current_theme_session');

        final duration = endedSession.endedAt!
            .difference(endedSession.startedAt)
            .inSeconds;
        if (kDebugMode) debugPrint('📊 Theme session ended: ${duration}s');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error recording theme session end: $e');
    }
  }

  /// Get theme usage statistics
  Future<ThemeUsageStats> getThemeUsageStats() async {
    try {
      final sessionsJson = _prefs.getString(_themeSessionsKey) ?? '[]';
      final sessionsList = jsonDecode(sessionsJson) as List;

      final stats = <String, dynamic>{};
      int totalSessions = 0;
      int totalMinutes = 0;

      for (final sessionJson in sessionsList) {
        final session = ThemeSession.fromJson(sessionJson);
        totalSessions++;

        if (session.endedAt != null) {
          final duration = session.endedAt!.difference(session.startedAt);
          totalMinutes += duration.inMinutes;

          // Track per-theme stats
          if (!stats.containsKey(session.themeId)) {
            stats[session.themeId] = {
              'name': session.themeName,
              'sessions': 0,
              'minutes': 0,
            };
          }
          stats[session.themeId]['sessions']++;
          stats[session.themeId]['minutes'] += duration.inMinutes;
        }
      }

      return ThemeUsageStats(
        totalSessions: totalSessions,
        totalMinutesUsed: totalMinutes,
        uniqueThemesUsed: stats.keys.length,
        themeDetails: stats.cast<String, Map<String, dynamic>>(),
        mostUsedTheme: _getMostUsedTheme(stats),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting theme usage stats: $e');
      return ThemeUsageStats(
        totalSessions: 0,
        totalMinutesUsed: 0,
        uniqueThemesUsed: 0,
        themeDetails: {},
        mostUsedTheme: null,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get theme popularity ranking
  Future<List<ThemePopularity>> getThemePopularityRanking() async {
    try {
      final usageStats = await getThemeUsageStats();
      final rankings = <ThemePopularity>[];

      usageStats.themeDetails.forEach((themeId, details) {
        rankings.add(ThemePopularity(
          themeId: themeId,
          themeName: details['name'],
          usageCount: details['sessions'],
          totalMinutes: details['minutes'],
          score: (details['sessions'] * 10 + details['minutes']).toDouble(),
        ));
      });

      // Sort by score descending
      rankings.sort((a, b) => b.score.compareTo(a.score));
      return rankings;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting theme popularity: $e');
      return [];
    }
  }

  /// Get themes used in time range
  Future<List<ThemeTimeSeries>> getThemeTimeSeriesData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final sessionsJson = _prefs.getString(_themeSessionsKey) ?? '[]';
      final sessionsList = jsonDecode(sessionsJson) as List;

      final timeSeries = <String, List<int>>{};

      for (final sessionJson in sessionsList) {
        final session = ThemeSession.fromJson(sessionJson);

        if (session.startedAt.isAfter(startDate) &&
            session.startedAt.isBefore(endDate)) {
          if (!timeSeries.containsKey(session.themeId)) {
            timeSeries[session.themeId] = [];
          }
          timeSeries[session.themeId]!.add(session.startedAt.hour);
        }
      }

      final result = <ThemeTimeSeries>[];
      timeSeries.forEach((themeId, hours) {
        result.add(ThemeTimeSeries(
          themeId: themeId,
          hoursUsed: hours,
          peakHour: _getPeakHour(hours),
        ));
      });

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting theme time series: $e');
      return [];
    }
  }

  /// Get theme engagement score (0-100)
  Future<int> getThemeEngagementScore(String themeId) async {
    try {
      final popularity = await getThemePopularityRanking();
      final theme = popularity.firstWhere(
        (t) => t.themeId == themeId,
        orElse: () => ThemePopularity(
          themeId: '',
          themeName: '',
          usageCount: 0,
          totalMinutes: 0,
          score: 0,
        ),
      );

      if (theme.themeId.isEmpty) return 0;

      // Calculate engagement: (usage_count * 5) + (minutes / 10)
      int score = (theme.usageCount * 5 + theme.totalMinutes ~/ 10).clamp(0, 100);
      return score;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting theme engagement score: $e');
      return 0;
    }
  }

  /// Get daily theme usage trend
  Future<Map<String, int>> getDailyThemeUsageTrend(int lastDays) async {
    try {
      final sessionsJson = _prefs.getString(_themeSessionsKey) ?? '[]';
      final sessionsList = jsonDecode(sessionsJson) as List;

      final trend = <String, int>{};
      final now = DateTime.now();

      for (int i = 0; i < lastDays; i++) {
        final date = now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
        trend[date] = 0;
      }

      for (final sessionJson in sessionsList) {
        final session = ThemeSession.fromJson(sessionJson);
        final date = session.startedAt.toIso8601String().split('T')[0];

        if (trend.containsKey(date)) {
          trend[date] = (trend[date] ?? 0) + 1;
        }
      }

      return trend;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting daily theme usage: $e');
      return {};
    }
  }

  String _generateId() {
    return 'ts_${DateTime.now().millisecondsSinceEpoch}';
  }

  String? _getMostUsedTheme(Map<String, dynamic> stats) {
    if (stats.isEmpty) return null;

    var mostUsed = stats.entries.first;
    for (final entry in stats.entries) {
      if (entry.value['minutes'] > mostUsed.value['minutes']) {
        mostUsed = entry;
      }
    }

    return mostUsed.value['name'];
  }

  int _getPeakHour(List<int> hours) {
    if (hours.isEmpty) return 0;
    int peak = hours[0];
    int maxCount = 1;

    for (int i = 0; i < hours.length; i++) {
      int count = 0;
      for (final hour in hours) {
        if (hour == hours[i]) count++;
      }
      if (count > maxCount) {
        peak = hours[i];
        maxCount = count;
      }
    }

    return peak;
  }

  /// Clear analytics data
  Future<void> clearAnalyticsData() async {
    try {
      await _prefs.remove(_themeSessionsKey);
      await _prefs.remove('current_theme_session');
      if (kDebugMode) debugPrint('✅ Theme usage analytics cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearing analytics data: $e');
    }
  }
}

/// Theme Session Model
class ThemeSession {
  final String id;
  final String themeId;
  final String themeName;
  final DateTime startedAt;
  final DateTime? endedAt;

  ThemeSession({
    required this.id,
    required this.themeId,
    required this.themeName,
    required this.startedAt,
    this.endedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'themeId': themeId,
        'themeName': themeName,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
      };

  factory ThemeSession.fromJson(Map<String, dynamic> json) => ThemeSession(
        id: json['id'],
        themeId: json['themeId'],
        themeName: json['themeName'],
        startedAt: DateTime.parse(json['startedAt']),
        endedAt:
            json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      );
}

/// Theme Usage Statistics
class ThemeUsageStats {
  final int totalSessions;
  final int totalMinutesUsed;
  final int uniqueThemesUsed;
  final Map<String, Map<String, dynamic>> themeDetails;
  final String? mostUsedTheme;
  final DateTime timestamp;

  ThemeUsageStats({
    required this.totalSessions,
    required this.totalMinutesUsed,
    required this.uniqueThemesUsed,
    required this.themeDetails,
    this.mostUsedTheme,
    required this.timestamp,
  });

  @override
  String toString() =>
      'ThemeUsageStats(sessions: $totalSessions, minutes: $totalMinutesUsed, themes: $uniqueThemesUsed)';
}

/// Theme Popularity Model
class ThemePopularity {
  final String themeId;
  final String themeName;
  final int usageCount;
  final int totalMinutes;
  final double score;

  ThemePopularity({
    required this.themeId,
    required this.themeName,
    required this.usageCount,
    required this.totalMinutes,
    required this.score,
  });

  @override
  String toString() =>
      'ThemePopularity($themeName: $usageCount times, ${totalMinutes}min, score: ${score.toStringAsFixed(0)})';
}

/// Theme Time Series Data
class ThemeTimeSeries {
  final String themeId;
  final List<int> hoursUsed;
  final int peakHour;

  ThemeTimeSeries({
    required this.themeId,
    required this.hoursUsed,
    required this.peakHour,
  });
}

/// Global instance
final themeUsageAnalyticsService = ThemeUsageAnalyticsService();


