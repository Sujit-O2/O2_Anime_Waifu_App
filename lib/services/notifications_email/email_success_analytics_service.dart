import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Email Success Analytics Service - Monitor email delivery rates and performance
class EmailSuccessAnalyticsService {
  static final EmailSuccessAnalyticsService _instance =
      EmailSuccessAnalyticsService._internal();
  factory EmailSuccessAnalyticsService() => _instance;
  EmailSuccessAnalyticsService._internal();

  static const String _emailRecordsKey = 'email_success_records';
  static const String _providerStatsKey = 'email_provider_stats';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ Email Success Analytics Service initialized');
  }

  /// Record email send attempt
  Future<void> recordEmailAttempt(
    String recipient,
    String provider,
    bool success,
    String? errorMessage,
  ) async {
    try {
      final record = EmailRecord(
        id: _generateId(),
        recipient: recipient,
        provider: provider,
        success: success,
        errorMessage: errorMessage,
        timestamp: DateTime.now(),
      );

      final recordsJson = _prefs.getString(_emailRecordsKey) ?? '[]';
      final recordsList = jsonDecode(recordsJson) as List;
      recordsList.add(record.toJson());

      // Keep only last 5000 records
      if (recordsList.length > 5000) {
        recordsList.removeRange(0, recordsList.length - 5000);
      }

      await _prefs.setString(_emailRecordsKey, jsonEncode(recordsList));
      debugPrint('📧 Email record: $provider ${success ? "✅" : "❌"}');
    } catch (e) {
      debugPrint('❌ Error recording email attempt: $e');
    }
  }

  /// Get overall email success metrics
  Future<EmailSuccessMetrics> getSuccessMetrics() async {
    try {
      final recordsJson = _prefs.getString(_emailRecordsKey) ?? '[]';
      final recordsList = jsonDecode(recordsJson) as List;

      int totalAttempts = recordsList.length;
      int successful = 0;
      int failed = 0;

      for (final record in recordsList) {
        if (record['success'] == true) {
          successful++;
        } else {
          failed++;
        }
      }

      double successRate = totalAttempts > 0 ? (successful / totalAttempts) * 100 : 0;
      double failureRate = 100 - successRate;

      return EmailSuccessMetrics(
        totalAttempts: totalAttempts,
        successfulEmails: successful,
        failedEmails: failed,
        successRate: successRate,
        failureRate: failureRate,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting success metrics: $e');
      return EmailSuccessMetrics(
        totalAttempts: 0,
        successfulEmails: 0,
        failedEmails: 0,
        successRate: 0,
        failureRate: 100,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get provider-specific success rates
  Future<Map<String, ProviderStats>> getProviderStats() async {
    try {
      final recordsJson = _prefs.getString(_emailRecordsKey) ?? '[]';
      final recordsList = jsonDecode(recordsJson) as List;

      final providerMap = <String, Map<String, int>>{};

      for (final recordJson in recordsList) {
        final record = EmailRecord.fromJson(recordJson);
        if (!providerMap.containsKey(record.provider)) {
          providerMap[record.provider] = {
            'total': 0,
            'success': 0,
            'failed': 0,
          };
        }

        providerMap[record.provider]!['total'] = providerMap[record.provider]!['total']! + 1;
        if (record.success) {
          providerMap[record.provider]!['success'] = providerMap[record.provider]!['success']! + 1;
        } else {
          providerMap[record.provider]!['failed'] = providerMap[record.provider]!['failed']! + 1;
        }
      }

      final result = <String, ProviderStats>{};
      providerMap.forEach((provider, stats) {
        double rate = stats['total']! > 0
            ? (stats['success']! / stats['total']!) * 100
            : 0;

        result[provider] = ProviderStats(
          provider: provider,
          totalAttempts: stats['total']!,
          successCount: stats['success']!,
          failureCount: stats['failed']!,
          successRate: rate,
        );
      });

      await _prefs.setString(_providerStatsKey, jsonEncode(_serializeProviderStats(result)));
      return result;
    } catch (e) {
      debugPrint('❌ Error getting provider stats: $e');
      return {};
    }
  }

  /// Get most used email provider
  Future<String?> getMostReliableProvider() async {
    try {
      final providerStats = await getProviderStats();
      if (providerStats.isEmpty) return null;

      var mostReliable = providerStats.values.first;
      for (final stats in providerStats.values) {
        if (stats.successRate > mostReliable.successRate) {
          mostReliable = stats;
        }
      }

      return mostReliable.provider;
    } catch (e) {
      debugPrint('❌ Error getting most reliable provider: $e');
      return null;
    }
  }

  /// Get most common errors
  Future<Map<String, int>> getCommonErrors() async {
    try {
      final recordsJson = _prefs.getString(_emailRecordsKey) ?? '[]';
      final recordsList = jsonDecode(recordsJson) as List;

      final errorCounts = <String, int>{};

      for (final recordJson in recordsList) {
        final record = EmailRecord.fromJson(recordJson);
        if (record.errorMessage != null && record.errorMessage!.isNotEmpty) {
          errorCounts[record.errorMessage!] =
              (errorCounts[record.errorMessage] ?? 0) + 1;
        }
      }

      return errorCounts;
    } catch (e) {
      debugPrint('❌ Error getting common errors: $e');
      return {};
    }
  }

  /// Get recipient that had most failures
  Future<String?> getMostProblematicRecipient() async {
    try {
      final recordsJson = _prefs.getString(_emailRecordsKey) ?? '[]';
      final recordsList = jsonDecode(recordsJson) as List;

      final recipientFailures = <String, int>{};

      for (final recordJson in recordsList) {
        final record = EmailRecord.fromJson(recordJson);
        if (!record.success) {
          recipientFailures[record.recipient] =
              (recipientFailures[record.recipient] ?? 0) + 1;
        }
      }

      if (recipientFailures.isEmpty) return null;

      return recipientFailures.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    } catch (e) {
      debugPrint('❌ Error getting most problematic recipient: $e');
      return null;
    }
  }

  /// Get daily success rate trend
  Future<Map<String, double>> getDailySuccessRateTrend(int lastDays) async {
    try {
      final recordsJson = _prefs.getString(_emailRecordsKey) ?? '[]';
      final recordsList = jsonDecode(recordsJson) as List;

      final dailyStats = <String, Map<String, int>>{};
      final now = DateTime.now();

      // Initialize dates
      for (int i = 0; i < lastDays; i++) {
        final date = now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
        dailyStats[date] = {'total': 0, 'success': 0};
      }

      // Count records
      for (final recordJson in recordsList) {
        final record = EmailRecord.fromJson(recordJson);
        final date = record.timestamp.toIso8601String().split('T')[0];

        if (dailyStats.containsKey(date)) {
          dailyStats[date]!['total'] = dailyStats[date]!['total']! + 1;
          if (record.success) {
            dailyStats[date]!['success'] = dailyStats[date]!['success']! + 1;
          }
        }
      }

      // Calculate rates
      final trend = <String, double>{};
      dailyStats.forEach((date, stats) {
        final rate = stats['total']! > 0
            ? (stats['success']! / stats['total']!) * 100
            : 0.0;
        trend[date] = rate;
      });

      return trend;
    } catch (e) {
      debugPrint('❌ Error getting daily success trend: $e');
      return {};
    }
  }

  /// Get hourly success pattern
  Future<Map<int, double>> getHourlySuccessPattern() async {
    try {
      final recordsJson = _prefs.getString(_emailRecordsKey) ?? '[]';
      final recordsList = jsonDecode(recordsJson) as List;

      final hourlyStats = <int, Map<String, int>>{};

      // Initialize hours
      for (int i = 0; i < 24; i++) {
        hourlyStats[i] = {'total': 0, 'success': 0};
      }

      // Count records
      for (final recordJson in recordsList) {
        final record = EmailRecord.fromJson(recordJson);
        final hour = record.timestamp.hour;

        hourlyStats[hour]!['total'] = hourlyStats[hour]!['total']! + 1;
        if (record.success) {
          hourlyStats[hour]!['success'] = hourlyStats[hour]!['success']! + 1;
        }
      }

      // Calculate rates
      final pattern = <int, double>{};
      hourlyStats.forEach((hour, stats) {
        final rate = stats['total']! > 0
            ? (stats['success']! / stats['total']!) * 100
            : 0.0;
        pattern[hour] = rate;
      });

      return pattern;
    } catch (e) {
      debugPrint('❌ Error getting hourly success pattern: $e');
      return {};
    }
  }

  /// Get comprehensive email delivery report
  Future<EmailDeliveryReport> getDeliveryReport() async {
    try {
      final metrics = await getSuccessMetrics();
      final providerStats = await getProviderStats();
      final commonErrors = await getCommonErrors();
      final dailyTrend = await getDailySuccessRateTrend(7);
      final mostReliable = await getMostReliableProvider();

      return EmailDeliveryReport(
        timestamp: DateTime.now(),
        overallMetrics: metrics,
        providerPerformance: providerStats,
        commonErrors: commonErrors,
        dailySuccessRateTrend: dailyTrend,
        mostReliableProvider: mostReliable,
        recommendations: _generateRecommendations(metrics, providerStats),
      );
    } catch (e) {
      debugPrint('❌ Error generating delivery report: $e');
      return EmailDeliveryReport(
        timestamp: DateTime.now(),
        overallMetrics: EmailSuccessMetrics(
          totalAttempts: 0,
          successfulEmails: 0,
          failedEmails: 0,
          successRate: 0,
          failureRate: 100,
          timestamp: DateTime.now(),
        ),
        providerPerformance: {},
        commonErrors: {},
        dailySuccessRateTrend: {},
        mostReliableProvider: null,
        recommendations: [],
      );
    }
  }

  String _generateId() {
    return 'email_${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> _serializeProviderStats(Map<String, ProviderStats> stats) {
    final result = <String, dynamic>{};
    stats.forEach((provider, stat) {
      result[provider] = {
        'provider': stat.provider,
        'totalAttempts': stat.totalAttempts,
        'successCount': stat.successCount,
        'failureCount': stat.failureCount,
        'successRate': stat.successRate,
      };
    });
    return result;
  }

  List<String> _generateRecommendations(
    EmailSuccessMetrics metrics,
    Map<String, ProviderStats> providerStats,
  ) {
    final recommendations = <String>[];

    if (metrics.successRate < 80) {
      recommendations.add('⚠️ Success rate is below target (80%). Investigate failed emails.');
    } else {
      recommendations.add('✅ Success rate is acceptable (${metrics.successRate.toStringAsFixed(1)}%)');
    }

    if (providerStats.isNotEmpty) {
      final best = providerStats.values.reduce(
        (a, b) => a.successRate > b.successRate ? a : b,
      );
      recommendations.add('✅ Best provider: ${best.provider} (${best.successRate.toStringAsFixed(1)}% success)');
    }

    return recommendations;
  }

  /// Clear analytics data
  Future<void> clearAnalyticsData() async {
    try {
      await _prefs.remove(_emailRecordsKey);
      await _prefs.remove(_providerStatsKey);
      debugPrint('✅ Email analytics data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing analytics data: $e');
    }
  }
}

/// Email Record Model
class EmailRecord {
  final String id;
  final String recipient;
  final String provider;
  final bool success;
  final String? errorMessage;
  final DateTime timestamp;

  EmailRecord({
    required this.id,
    required this.recipient,
    required this.provider,
    required this.success,
    this.errorMessage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient': recipient,
        'provider': provider,
        'success': success,
        'errorMessage': errorMessage,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EmailRecord.fromJson(Map<String, dynamic> json) => EmailRecord(
        id: json['id'],
        recipient: json['recipient'],
        provider: json['provider'],
        success: json['success'],
        errorMessage: json['errorMessage'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// Email Success Metrics
class EmailSuccessMetrics {
  final int totalAttempts;
  final int successfulEmails;
  final int failedEmails;
  final double successRate;
  final double failureRate;
  final DateTime timestamp;

  EmailSuccessMetrics({
    required this.totalAttempts,
    required this.successfulEmails,
    required this.failedEmails,
    required this.successRate,
    required this.failureRate,
    required this.timestamp,
  });

  @override
  String toString() =>
      'EmailSuccessMetrics(${successRate.toStringAsFixed(1)}% success, $successfulEmails/$totalAttempts)';
}

/// Provider Statistics
class ProviderStats {
  final String provider;
  final int totalAttempts;
  final int successCount;
  final int failureCount;
  final double successRate;

  ProviderStats({
    required this.provider,
    required this.totalAttempts,
    required this.successCount,
    required this.failureCount,
    required this.successRate,
  });

  @override
  String toString() =>
      'ProviderStats($provider: ${successRate.toStringAsFixed(1)}% success)';
}

/// Email Delivery Report
class EmailDeliveryReport {
  final DateTime timestamp;
  final EmailSuccessMetrics overallMetrics;
  final Map<String, ProviderStats> providerPerformance;
  final Map<String, int> commonErrors;
  final Map<String, double> dailySuccessRateTrend;
  final String? mostReliableProvider;
  final List<String> recommendations;

  EmailDeliveryReport({
    required this.timestamp,
    required this.overallMetrics,
    required this.providerPerformance,
    required this.commonErrors,
    required this.dailySuccessRateTrend,
    this.mostReliableProvider,
    required this.recommendations,
  });

  @override
  String toString() =>
      'EmailDeliveryReport(${overallMetrics.successRate.toStringAsFixed(1)}% overall success)';
}

/// Global instance
final emailSuccessAnalyticsService = EmailSuccessAnalyticsService();


