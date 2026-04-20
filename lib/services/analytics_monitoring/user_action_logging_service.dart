import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User Action Logging Service - Log all significant user interactions
class UserActionLoggingService {
  static final UserActionLoggingService _instance =
      UserActionLoggingService._internal();
  factory UserActionLoggingService() => _instance;
  UserActionLoggingService._internal();

  static const String _actionsLogKey = 'user_actions_log';
  static const String _actionsStatsKey = 'user_actions_stats';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ User Action Logging Service initialized');
  }

  /// Log user action
  Future<void> logAction(
    String action,
    Map<String, dynamic> data, {
    String? screenName,
    String? category,
  }) async {
    try {
      final userAction = UserAction(
        id: _generateId(),
        action: action,
        data: data,
        screenName: screenName,
        category: category,
        timestamp: DateTime.now(),
      );

      final actionsJson = _prefs.getString(_actionsLogKey) ?? '[]';
      final actionsList = jsonDecode(actionsJson) as List;
      actionsList.add(userAction.toJson());

      // Keep only last 10000 actions
      if (actionsList.length > 10000) {
        actionsList.removeRange(0, actionsList.length - 10000);
      }

      await _prefs.setString(_actionsLogKey, jsonEncode(actionsList));
      debugPrint('📝 Action logged: $action');
    } catch (e) {
      debugPrint('❌ Error logging action: $e');
    }
  }

  /// Log button click
  Future<void> logButtonClick(String buttonName, {String? screenName}) async {
    await logAction(
      'button_click',
      {'button': buttonName},
      screenName: screenName,
      category: 'ui_interaction',
    );
  }

  /// Log form submission
  Future<void> logFormSubmission(String formName, bool success) async {
    await logAction(
      'form_submission',
      {'form': formName, 'success': success},
      category: 'form',
    );
  }

  /// Log navigation
  Future<void> logNavigation(String fromScreen, String toScreen) async {
    await logAction(
      'navigation',
      {'from': fromScreen, 'to': toScreen},
      category: 'navigation',
    );
  }

  /// Log theme change
  Future<void> logThemeChange(String oldTheme, String newTheme) async {
    await logAction(
      'theme_changed',
      {'oldTheme': oldTheme, 'newTheme': newTheme},
      category: 'settings',
    );
  }

  /// Log search
  Future<void> logSearch(String query, int resultCount) async {
    await logAction(
      'search',
      {'query': query, 'resultCount': resultCount},
      category: 'search',
    );
  }

  /// Log custom event
  Future<void> logCustomEvent(String eventName, Map<String, dynamic> data) async {
    await logAction(eventName, data, category: 'custom');
  }

  /// Get all actions
  Future<List<UserAction>> getAllActions() async {
    try {
      final actionsJson = _prefs.getString(_actionsLogKey) ?? '[]';
      final actionsList = jsonDecode(actionsJson) as List;
      return actionsList
          .cast<Map<String, dynamic>>()
          .map((json) => UserAction.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting all actions: $e');
      return [];
    }
  }

  /// Get actions by category
  Future<List<UserAction>> getActionsByCategory(String category) async {
    try {
      final actions = await getAllActions();
      return actions.where((a) => a.category == category).toList();
    } catch (e) {
      debugPrint('❌ Error getting actions by category: $e');
      return [];
    }
  }

  /// Get actions on specific screen
  Future<List<UserAction>> getActionsOnScreen(String screenName) async {
    try {
      final actions = await getAllActions();
      return actions.where((a) => a.screenName == screenName).toList();
    } catch (e) {
      debugPrint('❌ Error getting actions on screen: $e');
      return [];
    }
  }

  /// Get user action statistics
  Future<UserActionStats> getUserActionStats() async {
    try {
      final actions = await getAllActions();

      int totalActions = actions.length;
      Map<String, int> actionCounts = {};
      Map<String, int> screenCounts = {};
      Map<String, int> categoryCounts = {};

      for (final action in actions) {
        // Count by action type
        actionCounts[action.action] = (actionCounts[action.action] ?? 0) + 1;

        // Count by screen
        if (action.screenName != null) {
          screenCounts[action.screenName!] =
              (screenCounts[action.screenName!] ?? 0) + 1;
        }

        // Count by category
        if (action.category != null) {
          categoryCounts[action.category!] =
              (categoryCounts[action.category!] ?? 0) + 1;
        }
      }

      return UserActionStats(
        totalActions: totalActions,
        actionCounts: actionCounts,
        screenCounts: screenCounts,
        categoryCounts: categoryCounts,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting user action stats: $e');
      return UserActionStats(
        totalActions: 0,
        actionCounts: {},
        screenCounts: {},
        categoryCounts: {},
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get most used screens
  Future<List<ScreenUsage>> getMostUsedScreens() async {
    try {
      final stats = await getUserActionStats();
      final screenUsage = <ScreenUsage>[];

      stats.screenCounts.forEach((screen, count) {
        screenUsage.add(ScreenUsage(name: screen, actionCount: count));
      });

      screenUsage.sort((a, b) => b.actionCount.compareTo(a.actionCount));
      return screenUsage;
    } catch (e) {
      debugPrint('❌ Error getting most used screens: $e');
      return [];
    }
  }

  /// Get most common actions
  Future<List<ActionFrequency>> getMostCommonActions() async {
    try {
      final stats = await getUserActionStats();
      final actionFrequency = <ActionFrequency>[];

      stats.actionCounts.forEach((action, count) {
        actionFrequency.add(ActionFrequency(name: action, count: count));
      });

      actionFrequency.sort((a, b) => b.count.compareTo(a.count));
      return actionFrequency.take(10).toList();
    } catch (e) {
      debugPrint('❌ Error getting most common actions: $e');
      return [];
    }
  }

  /// Get actions in time range
  Future<List<UserAction>> getActionsInTimeRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final actions = await getAllActions();
      return actions
          .where((a) => a.timestamp.isAfter(startTime) && a.timestamp.isBefore(endTime))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting actions in time range: $e');
      return [];
    }
  }

  /// Get user session summary
  Future<UserSessionSummary> getUserSessionSummary() async {
    try {
      final stats = await getUserActionStats();
      final mostUsedScreen = (await getMostUsedScreens()).firstOrNull;
      final mostCommonAction = (await getMostCommonActions()).firstOrNull;

      return UserSessionSummary(
        totalActions: stats.totalActions,
        uniqueScreens: stats.screenCounts.length,
        uniqueActions: stats.actionCounts.length,
        categories: stats.categoryCounts.length,
        mostActiveScreen: mostUsedScreen?.name,
        mostCommonAction: mostCommonAction?.name,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting session summary: $e');
      return UserSessionSummary(
        totalActions: 0,
        uniqueScreens: 0,
        uniqueActions: 0,
        categories: 0,
        mostActiveScreen: null,
        mostCommonAction: null,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get hourly action pattern
  Future<Map<int, int>> getHourlyActionPattern() async {
    try {
      final actions = await getAllActions();
      final hourlyPattern = <int, int>{};

      // Initialize hours
      for (int i = 0; i < 24; i++) {
        hourlyPattern[i] = 0;
      }

      // Count actions per hour
      for (final action in actions) {
        final hour = action.timestamp.hour;
        hourlyPattern[hour] = (hourlyPattern[hour] ?? 0) + 1;
      }

      return hourlyPattern;
    } catch (e) {
      debugPrint('❌ Error getting hourly action pattern: $e');
      return {};
    }
  }

  /// Get daily action trend
  Future<Map<String, int>> getDailyActionTrend(int lastDays) async {
    try {
      final actions = await getAllActions();
      final dailyTrend = <String, int>{};
      final now = DateTime.now();

      // Initialize dates
      for (int i = 0; i < lastDays; i++) {
        final date = now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
        dailyTrend[date] = 0;
      }

      // Count actions per day
      for (final action in actions) {
        final date = action.timestamp.toIso8601String().split('T')[0];
        if (dailyTrend.containsKey(date)) {
          dailyTrend[date] = (dailyTrend[date] ?? 0) + 1;
        }
      }

      return dailyTrend;
    } catch (e) {
      debugPrint('❌ Error getting daily action trend: $e');
      return {};
    }
  }

  String _generateId() {
    return 'action_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Clear all action logs
  Future<void> clearActionLogs() async {
    try {
      await _prefs.remove(_actionsLogKey);
      await _prefs.remove(_actionsStatsKey);
      debugPrint('✅ User action logs cleared');
    } catch (e) {
      debugPrint('❌ Error clearing action logs: $e');
    }
  }
}

/// User Action Model
class UserAction {
  final String id;
  final String action;
  final Map<String, dynamic> data;
  final String? screenName;
  final String? category;
  final DateTime timestamp;

  UserAction({
    required this.id,
    required this.action,
    required this.data,
    this.screenName,
    this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'data': data,
        'screenName': screenName,
        'category': category,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UserAction.fromJson(Map<String, dynamic> json) => UserAction(
        id: json['id'],
        action: json['action'],
        data: json['data'] ?? {},
        screenName: json['screenName'],
        category: json['category'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// User Action Statistics
class UserActionStats {
  final int totalActions;
  final Map<String, int> actionCounts;
  final Map<String, int> screenCounts;
  final Map<String, int> categoryCounts;
  final DateTime timestamp;

  UserActionStats({
    required this.totalActions,
    required this.actionCounts,
    required this.screenCounts,
    required this.categoryCounts,
    required this.timestamp,
  });

  @override
  String toString() =>
      'UserActionStats(total: $totalActions, actions: ${actionCounts.length}, screens: ${screenCounts.length})';
}

/// Screen Usage Model
class ScreenUsage {
  final String name;
  final int actionCount;

  ScreenUsage({required this.name, required this.actionCount});

  @override
  String toString() => 'ScreenUsage($name: $actionCount actions)';
}

/// Action Frequency Model
class ActionFrequency {
  final String name;
  final int count;

  ActionFrequency({required this.name, required this.count});

  @override
  String toString() => 'ActionFrequency($name: $count times)';
}

/// User Session Summary
class UserSessionSummary {
  final int totalActions;
  final int uniqueScreens;
  final int uniqueActions;
  final int categories;
  final String? mostActiveScreen;
  final String? mostCommonAction;
  final DateTime timestamp;

  UserSessionSummary({
    required this.totalActions,
    required this.uniqueScreens,
    required this.uniqueActions,
    required this.categories,
    this.mostActiveScreen,
    this.mostCommonAction,
    required this.timestamp,
  });

  @override
  String toString() =>
      'UserSessionSummary(total: $totalActions, screens: $uniqueScreens, actions: $uniqueActions)';
}

/// Global instance
final userActionLoggingService = UserActionLoggingService();


