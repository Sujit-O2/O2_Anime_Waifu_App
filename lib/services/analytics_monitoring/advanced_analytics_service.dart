import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Advanced Analytics Service - Track theme popularity and usage
class AdvancedAnalyticsService {
  static final AdvancedAnalyticsService _instance =
      AdvancedAnalyticsService._internal();
  factory AdvancedAnalyticsService() => _instance;
  AdvancedAnalyticsService._internal();

  static const String _analyticsKey = 'theme_analytics';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Track theme usage
  Future<void> trackThemeUsage(String themeId) async {
    try {
      final analytics = await _getAnalytics();
      if (analytics.containsKey(themeId)) {
        analytics[themeId]!['usageCount'] =
            (analytics[themeId]!['usageCount'] as int) + 1;
        analytics[themeId]!['lastUsed'] = DateTime.now().toIso8601String();
      } else {
        analytics[themeId] = {
          'themeId': themeId,
          'usageCount': 1,
          'firstUsed': DateTime.now().toIso8601String(),
          'lastUsed': DateTime.now().toIso8601String(),
          'totalTimeMinutes': 0,
        };
      }
      await _prefs.setString(_analyticsKey, jsonEncode(analytics));
      if (kDebugMode) debugPrint('✅ Theme usage tracked: $themeId');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error tracking theme usage: $e');
    }
  }

  /// Track theme session duration
  Future<void> trackThemeSessionTime(String themeId, int durationMinutes) async {
    try {
      final analytics = await _getAnalytics();
      if (analytics.containsKey(themeId)) {
        analytics[themeId]!['totalTimeMinutes'] =
            (analytics[themeId]!['totalTimeMinutes'] as int) + durationMinutes;
      }
      await _prefs.setString(_analyticsKey, jsonEncode(analytics));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error tracking session time: $e');
    }
  }

  /// Get theme analytics
  Future<Map<String, dynamic>?> getThemeAnalytics(String themeId) async {
    final analytics = await _getAnalytics();
    return analytics[themeId];
  }

  /// Get all analytics
  Future<Map<String, dynamic>> getAllAnalytics() async {
    return _getAnalytics();
  }

  /// Get most popular themes
  Future<List<ThemeAnalytic>> getMostPopularThemes({int limit = 10}) async {
    try {
      final analytics = await _getAnalytics();
      final list = analytics.values
          .cast<Map<String, dynamic>>()
          .map((json) => ThemeAnalytic.fromJson(json))
          .toList();
      list.sort((a, b) => b.usageCount.compareTo(a.usageCount));
      return list.take(limit).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting popular themes: $e');
      return [];
    }
  }

  /// Get most used themes in last N days
  Future<List<ThemeAnalytic>> getMostUsedThemesInDays(int days) async {
    try {
      final analytics = await _getAnalytics();
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final list = analytics.values
          .cast<Map<String, dynamic>>()
          .where((json) {
            final lastUsed = DateTime.parse(json['lastUsed']);
            return lastUsed.isAfter(cutoff);
          })
          .map((json) => ThemeAnalytic.fromJson(json))
          .toList();
      list.sort((a, b) => b.usageCount.compareTo(a.usageCount));
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting recent themes: $e');
      return [];
    }
  }

  /// Get theme engagement score (0-100)
  Future<int> getThemeEngagementScore(String themeId) async {
    try {
      final analytics = await getThemeAnalytics(themeId);
      if (analytics == null) return 0;

      int score = 0;
      score += (analytics['usageCount'] as int).clamp(0, 50); // Max 50 points
      score += ((analytics['totalTimeMinutes'] as int) ~/ 60).clamp(0, 30); // Max 30
      score += 20; // Base points for having analytics

      return score.clamp(0, 100);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error calculating engagement score: $e');
      return 0;
    }
  }

  /// Get usage statistics
  Future<UsageStats> getUsageStats() async {
    try {
      final analytics = await _getAnalytics();
      int totalUsage = 0;
      int totalMinutes = 0;
      for (var data in analytics.values) {
        totalUsage += data['usageCount'] as int;
        totalMinutes += data['totalTimeMinutes'] as int;
      }
      return UsageStats(
        totalThemesUsed: analytics.length,
        totalUsageCount: totalUsage,
        totalMinutesUsed: totalMinutes,
        averageUsagePerTheme:
            analytics.isEmpty ? 0 : totalUsage ~/ analytics.length,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting usage stats: $e');
      return UsageStats(
        totalThemesUsed: 0,
        totalUsageCount: 0,
        totalMinutesUsed: 0,
        averageUsagePerTheme: 0,
      );
    }
  }

  /// Clear analytics
  Future<void> clearAnalytics() async {
    try {
      await _prefs.remove(_analyticsKey);
      if (kDebugMode) debugPrint('✅ Analytics cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearing analytics: $e');
    }
  }

  Future<Map<String, dynamic>> _getAnalytics() async {
    try {
      final json = _prefs.getString(_analyticsKey) ?? '{}';
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading analytics: $e');
      return {};
    }
  }
}

/// Theme Analytic Model
class ThemeAnalytic {
  final String themeId;
  final int usageCount;
  final DateTime firstUsed;
  final DateTime lastUsed;
  final int totalTimeMinutes;

  ThemeAnalytic({
    required this.themeId,
    required this.usageCount,
    required this.firstUsed,
    required this.lastUsed,
    required this.totalTimeMinutes,
  });

  factory ThemeAnalytic.fromJson(Map<String, dynamic> json) => ThemeAnalytic(
        themeId: json['themeId'],
        usageCount: json['usageCount'],
        firstUsed: DateTime.parse(json['firstUsed']),
        lastUsed: DateTime.parse(json['lastUsed']),
        totalTimeMinutes: json['totalTimeMinutes'],
      );

  Map<String, dynamic> toJson() => {
        'themeId': themeId,
        'usageCount': usageCount,
        'firstUsed': firstUsed.toIso8601String(),
        'lastUsed': lastUsed.toIso8601String(),
        'totalTimeMinutes': totalTimeMinutes,
      };
}

/// Usage Statistics
class UsageStats {
  final int totalThemesUsed;
  final int totalUsageCount;
  final int totalMinutesUsed;
  final int averageUsagePerTheme;

  UsageStats({
    required this.totalThemesUsed,
    required this.totalUsageCount,
    required this.totalMinutesUsed,
    required this.averageUsagePerTheme,
  });

  @override
  String toString() =>
      'UsageStats(themes: $totalThemesUsed, usage: $totalUsageCount, minutes: $totalMinutesUsed)';
}

/// Global instance
final analyticsService = AdvancedAnalyticsService();


