import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Performance monitoring service: Analytics, crash reporting, performance tracking
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  // ── Firebase Analytics Events ────────────────────────────────────────────

  /// Log app launch event
  static Future<void> logAppLaunch() async {
    try {
      await FirebaseFirestore.instance.collection('analytics_events').add({
        'event': 'app_launch',
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging app launch: $e');
    }
  }

  /// Log chat message sent
  static Future<void> logChatSent({
    required String? characterId,
    required int messageLength,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('analytics_events').add({
        'event': 'chat_sent',
        'characterId': characterId,
        'messageLength': messageLength,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging chat sent: $e');
    }
  }

  /// Log feature accessed
  static Future<void> logFeatureAccessed({
    required String featureName,
    required String screen,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('analytics_events').add({
        'event': 'feature_accessed',
        'featureName': featureName,
        'screen': screen,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging feature accessed: $e');
    }
  }

  /// Log error occurred
  static Future<void> logErrorOccurred({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('analytics_events').add({
        'event': 'error_occurred',
        'errorType': errorType,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'platform': Platform.operatingSystem,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging error event: $e');
    }
  }

  /// Log custom event
  static Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('analytics_events').add({
        'event': eventName,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging custom event: $e');
    }
  }

  // ── Crash Reporting ──────────────────────────────────────────────────────

  /// Log caught exception
  static Future<void> logException({
    required String exceptionType,
    required String message,
    required String stackTrace,
    String? context,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('crash_reports').add({
        'exceptionType': exceptionType,
        'message': message,
        'stackTrace': stackTrace,
        'context': context,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'platform': Platform.operatingSystem,
        'severity': 'HIGH',
      });

      // Also log to analytics for quick access
      await logErrorOccurred(
        errorType: exceptionType,
        errorMessage: message,
        stackTrace: stackTrace,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging exception: $e');
    }
  }

  /// Get recent crashes
  static Future<List<Map<String, dynamic>>> getRecentCrashes({
    int limit = 20,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('crash_reports')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching crash reports: $e');
      return [];
    }
  }

  /// Get crash statistics
  static Future<Map<String, dynamic>> getCrashStatistics(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('crash_reports')
          .where('userId', isEqualTo: uid)
          .get();

      final crashes = snapshot.docs;
      if (crashes.isEmpty) {
        return {'totalCrashes': 0, 'topError': 'none'};
      }

      // Count by error type
      final errorCounts = <String, int>{};
      for (var crash in crashes) {
        final errorType = crash.get('exceptionType') as String? ?? 'Unknown';
        errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
      }

      final topError = errorCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      return {
        'totalCrashes': crashes.length,
        'topError': topError,
        'errorDistribution': errorCounts,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting crash statistics: $e');
      return {'totalCrashes': 0, 'topError': 'none'};
    }
  }

  // ── Performance Tracking ─────────────────────────────────────────────────

  /// Measure and log API response time
  static Future<void> logApiPerformance({
    required String endpoint,
    required int responseTimeMs,
    required int statusCode,
    String? error,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('performance_metrics')
          .add({
        'endpoint': endpoint,
        'responseTimeMs': responseTimeMs,
        'statusCode': statusCode,
        'error': error,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      });

      // Alert if response time is slow (> 5 seconds)
      if (responseTimeMs > 5000) {
        await _logPerformanceAlert(
          metric: 'slow_api_response',
          value: responseTimeMs,
          endpoint: endpoint,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging API performance: $e');
    }
  }

  /// Measure UI frame rate
  static Future<void> logFrameRate({
    required double fps,
    required String screen,
  }) async {
    try {
      // Only log if FPS is below 50 (performance issue)
      if (fps < 50) {
        await FirebaseFirestore.instance
            .collection('performance_metrics')
            .add({
          'metric': 'frame_rate',
          'value': fps,
          'screen': screen,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging frame rate: $e');
    }
  }

  /// Measure memory usage
  static Future<void> logMemoryUsage({
    required int usedMemoryMb,
    required int totalMemoryMb,
  }) async {
    try {
      if (totalMemoryMb <= 0) return;
      final percentage = (usedMemoryMb / totalMemoryMb * 100).toInt();

      // Only log if memory usage is high (> 60%)
      if (percentage > 60) {
        await FirebaseFirestore.instance
            .collection('performance_metrics')
            .add({
          'metric': 'memory_usage',
          'usedMb': usedMemoryMb,
          'totalMb': totalMemoryMb,
          'percentage': percentage,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        });

        if (percentage > 80) {
          await _logPerformanceAlert(
            metric: 'high_memory_usage',
            value: percentage,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging memory usage: $e');
    }
  }

  /// Log battery drain
  static Future<void> logBatteryUsage({
    required int batteryPercentage,
    required int drainedPercent,
  }) async {
    try {
      if (drainedPercent > 10) {
        // Only log significant drain
        await FirebaseFirestore.instance
            .collection('performance_metrics')
            .add({
          'metric': 'battery_usage',
          'currentBattery': batteryPercentage,
          'drainedRecently': drainedPercent,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging battery usage: $e');
    }
  }

  /// Get performance summary for user
  static Future<Map<String, dynamic>> getPerformanceSummary(String uid) async {
    try {
      final metricsSnapshot = await FirebaseFirestore.instance
          .collection('performance_metrics')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      if (metricsSnapshot.docs.isEmpty) {
        return {
          'avgResponseTime': 0,
          'slowApiCalls': 0,
          'averageFps': 60,
        };
      }

      // Calculate averages
      int totalResponseTime = 0;
      int responseCount = 0;
      int slowApiCount = 0;

      for (var doc in metricsSnapshot.docs) {
        if (doc.get('metric') == 'api_response_time') {
          totalResponseTime += (doc.get('responseTimeMs') as int? ?? 0);
          responseCount++;
          if ((doc.get('responseTimeMs') as int? ?? 0) > 2000) {
            slowApiCount++;
          }
        }
      }

      return {
        'avgResponseTime': responseCount > 0 ? totalResponseTime ~/ responseCount : 0,
        'slowApiCalls': slowApiCount,
        'totalMeasurements': metricsSnapshot.docs.length,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting performance summary: $e');
      return {};
    }
  }

  // ── Performance Alerts ───────────────────────────────────────────────────

  /// Log performance alert
  static Future<void> _logPerformanceAlert({
    required String metric,
    required dynamic value,
    String? endpoint,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('performance_alerts')
          .add({
        'metric': metric,
        'value': value,
        'endpoint': endpoint,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'severity': 'MEDIUM',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging performance alert: $e');
    }
  }

  // ── User Session Tracking ────────────────────────────────────────────────

  /// Log user session start
  static Future<void> logSessionStart() async {
    try {
      await FirebaseFirestore.instance.collection('user_sessions').add({
        'event': 'session_start',
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'startTime': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging session start: $e');
    }
  }

  /// Log user session end
  static Future<void> logSessionEnd({int? sessionDurationSeconds}) async {
    try {
      await FirebaseFirestore.instance.collection('user_sessions').add({
        'event': 'session_end',
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'endTime': FieldValue.serverTimestamp(),
        'sessionDurationSeconds': sessionDurationSeconds,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging session end: $e');
    }
  }

  /// Get session statistics
  static Future<Map<String, dynamic>> getSessionStatistics(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_sessions')
          .where('userId', isEqualTo: uid)
          .orderBy('startTime', descending: true)
          .limit(30)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'totalSessions': 0, 'avgSessionLength': 0};
      }

      int totalDuration = 0;
      int sessionCount = 0;

      for (var doc in snapshot.docs) {
        if (doc.get('event') == 'session_end') {
          final duration = doc.get('sessionDurationSeconds') as int? ?? 0;
          totalDuration += duration;
          sessionCount++;
        }
      }

      return {
        'totalSessions': sessionCount,
        'avgSessionLength': sessionCount > 0 ? totalDuration ~/ sessionCount : 0,
        'totalSessionTime': totalDuration,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting session statistics: $e');
      return {};
    }
  }
}


