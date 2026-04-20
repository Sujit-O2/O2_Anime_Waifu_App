import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase Analytics Service - Track themes, email metrics, user actions
class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance =
      FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  static const String _eventsKey = 'analytics_events';
  static const String _themeUsageKey = 'theme_analytics';
  static const String _emailMetricsKey = 'email_metrics';
  static const String _userActionsKey = 'user_actions';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ Firebase Analytics Service initialized');
  }

  /// Log theme selection event
  Future<void> logThemeSelected(String themeId, String themeName) async {
    try {
      await _logEvent(
        'theme_selected',
        {
          'theme_id': themeId,
          'theme_name': themeName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 Logged: theme_selected - $themeName');
    } catch (e) {
      debugPrint('❌ Error logging theme selected: $e');
    }
  }

  /// Track theme usage time
  Future<void> trackThemeUsageTime(String themeId, int durationSeconds) async {
    try {
      await _logEvent(
        'theme_usage_time',
        {
          'theme_id': themeId,
          'duration_seconds': durationSeconds,
          'duration_minutes': durationSeconds ~/ 60,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 Logged: theme_usage_time - ${durationSeconds.toStringAsFixed(0)}s');
    } catch (e) {
      debugPrint('❌ Error tracking theme usage time: $e');
    }
  }

  /// Log email send event
  Future<void> logEmailSent(String recipient, String provider, bool success) async {
    try {
      await _logEvent(
        'email_sent',
        {
          'recipient': recipient,
          'provider': provider,
          'success': success,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📧 Logged: email_sent - $provider (${success ? "✅" : "❌"})');
    } catch (e) {
      debugPrint('❌ Error logging email sent: $e');
    }
  }

  /// Track email success rate
  Future<EmailMetrics> trackEmailMetrics() async {
    try {
      final events = await _getEvents();
      final emailEvents = events
          .where((e) => e['event_name'] == 'email_sent')
          .toList();

      int totalSent = emailEvents.length;
      int successful = emailEvents.where((e) => e['data']['success'] == true).length;
      int failed = totalSent - successful;
      double successRate = totalSent > 0 ? (successful / totalSent) * 100 : 0;

      final metrics = EmailMetrics(
        totalEmailsSent: totalSent,
        successfulEmails: successful,
        failedEmails: failed,
        successRate: successRate,
        timestamp: DateTime.now(),
      );

      await _prefs.setString(_emailMetricsKey, jsonEncode(metrics.toJson()));
      debugPrint('📊 Email metrics: $successRate% success rate');
      return metrics;
    } catch (e) {
      debugPrint('❌ Error tracking email metrics: $e');
      return EmailMetrics(
        totalEmailsSent: 0,
        successfulEmails: 0,
        failedEmails: 0,
        successRate: 0,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Log user action
  Future<void> logUserAction(String action, Map<String, dynamic> data) async {
    try {
      await _logEvent(
        'user_action',
        {
          'action': action,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 Logged: user_action - $action');
    } catch (e) {
      debugPrint('❌ Error logging user action: $e');
    }
  }

  /// Log app open
  Future<void> logAppOpen() async {
    try {
      await _logEvent(
        'app_open',
        {
          'timestamp': DateTime.now().toIso8601String(),
          'platform': defaultTargetPlatform.toString(),
        },
      );
      debugPrint('📊 Logged: app_open');
    } catch (e) {
      debugPrint('❌ Error logging app open: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName, String screenClass) async {
    try {
      await _logEvent(
        'screen_view',
        {
          'screen_name': screenName,
          'screen_class': screenClass,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 Logged: screen_view - $screenName');
    } catch (e) {
      debugPrint('❌ Error logging screen view: $e');
    }
  }

  /// Log custom event
  Future<void> logCustomEvent(String eventName, Map<String, dynamic> data) async {
    try {
      await _logEvent(eventName, data);
      debugPrint('📊 Logged custom event: $eventName');
    } catch (e) {
      debugPrint('❌ Error logging custom event: $e');
    }
  }

  /// Get all events
  Future<List<AnalyticsEvent>> getAllEvents() async {
    try {
      return _getEvents();
    } catch (e) {
      debugPrint('❌ Error getting all events: $e');
      return [];
    }
  }

  /// Get events for date range
  Future<List<AnalyticsEvent>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final events = await _getEvents();
      return events.where((e) {
        final eventDate = DateTime.parse(e['data']['timestamp']);
        return eventDate.isAfter(startDate) && eventDate.isBefore(endDate);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting events by date range: $e');
      return [];
    }
  }

  /// Get analytics dashboard data
  Future<AnalyticsDashboard> getDashboardData() async {
    try {
      final allEvents = await _getEvents();
      final emailMetricsJson = _prefs.getString(_emailMetricsKey);
      
      // Count theme selections
      final themeSelections = allEvents
          .where((e) => e['event_name'] == 'theme_selected')
          .length;

      // Count user actions
      final userActions = allEvents
          .where((e) => e['event_name'] == 'user_action')
          .length;

      // Get email metrics
      EmailMetrics emailMetrics = EmailMetrics(
        totalEmailsSent: 0,
        successfulEmails: 0,
        failedEmails: 0,
        successRate: 0,
        timestamp: DateTime.now(),
      );

      if (emailMetricsJson != null) {
        emailMetrics = EmailMetrics.fromJson(jsonDecode(emailMetricsJson));
      }

      return AnalyticsDashboard(
        totalEvents: allEvents.length,
        themeSelections: themeSelections,
        userActions: userActions,
        emailMetrics: emailMetrics,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting dashboard data: $e');
      return AnalyticsDashboard(
        totalEvents: 0,
        themeSelections: 0,
        userActions: 0,
        emailMetrics: EmailMetrics(
          totalEmailsSent: 0,
          successfulEmails: 0,
          failedEmails: 0,
          successRate: 0,
          timestamp: DateTime.now(),
        ),
        timestamp: DateTime.now(),
      );
    }
  }

  Future<void> _logEvent(String eventName, Map<String, dynamic> data) async {
    try {
      final event = {
        'event_name': eventName,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final eventsJson = _prefs.getString(_eventsKey) ?? '[]';
      final eventsList = jsonDecode(eventsJson) as List;
      eventsList.add(event);

      // Keep only last 1000 events
      if (eventsList.length > 1000) {
        eventsList.removeRange(0, eventsList.length - 1000);
      }

      await _prefs.setString(_eventsKey, jsonEncode(eventsList));
    } catch (e) {
      debugPrint('❌ Error logging event: $e');
    }
  }

  Future<List<AnalyticsEvent>> _getEvents() async {
    try {
      final eventsJson = _prefs.getString(_eventsKey) ?? '[]';
      final eventsList = jsonDecode(eventsJson) as List;
      return eventsList.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('❌ Error getting events: $e');
      return [];
    }
  }

  /// Clear all analytics data
  Future<void> clearAnalyticsData() async {
    try {
      await _prefs.remove(_eventsKey);
      await _prefs.remove(_themeUsageKey);
      await _prefs.remove(_emailMetricsKey);
      await _prefs.remove(_userActionsKey);
      debugPrint('✅ All analytics data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing analytics data: $e');
    }
  }
}

/// Analytics Event Model
typedef AnalyticsEvent = Map<String, dynamic>;

/// Email Metrics Model
class EmailMetrics {
  final int totalEmailsSent;
  final int successfulEmails;
  final int failedEmails;
  final double successRate;
  final DateTime timestamp;

  EmailMetrics({
    required this.totalEmailsSent,
    required this.successfulEmails,
    required this.failedEmails,
    required this.successRate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'totalEmailsSent': totalEmailsSent,
        'successfulEmails': successfulEmails,
        'failedEmails': failedEmails,
        'successRate': successRate,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EmailMetrics.fromJson(Map<String, dynamic> json) => EmailMetrics(
        totalEmailsSent: json['totalEmailsSent'],
        successfulEmails: json['successfulEmails'],
        failedEmails: json['failedEmails'],
        successRate: json['successRate'],
        timestamp: DateTime.parse(json['timestamp']),
      );

  @override
  String toString() =>
      'EmailMetrics(success: ${successRate.toStringAsFixed(1)}%, sent: $totalEmailsSent)';
}

/// Analytics Dashboard Model
class AnalyticsDashboard {
  final int totalEvents;
  final int themeSelections;
  final int userActions;
  final EmailMetrics emailMetrics;
  final DateTime timestamp;

  AnalyticsDashboard({
    required this.totalEvents,
    required this.themeSelections,
    required this.userActions,
    required this.emailMetrics,
    required this.timestamp,
  });

  @override
  String toString() =>
      'AnalyticsDashboard(events: $totalEvents, themes: $themeSelections, actions: $userActions)';
}

/// Global instance
final firebaseAnalyticsService = FirebaseAnalyticsService();


