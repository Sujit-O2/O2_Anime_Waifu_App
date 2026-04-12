import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Crash Reporting Service
/// Error tracking, bug reporting, analytics, session replay
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();

  factory CrashReportingService() {
    return _instance;
  }

  CrashReportingService._internal();

  late SharedPreferences _prefs;
  final List<CrashReport> _crashReports = [];
  final List<ErrorLog> _errorLogs = [];
  final Map<String, ErrorFrequency> _errorFrequency = {};
  final List<String> _sessionEvents = [];
  bool _isEnabled = true;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCrashHistory();
    _isEnabled = true;
    debugPrint('[CrashReporting] Service initialized');
  }

  // ===== CRASH REPORTING =====
  /// Report a crash
  Future<void> reportCrash({
    required String exception,
    required String stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (!_isEnabled) return;

    final report = CrashReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exception: exception,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      severity: _calculateSeverity(exception),
      additionalInfo: additionalInfo ?? {},
      sessionId: _generateSessionId(),
      sessionEvents: List.from(_sessionEvents),
    );

    _crashReports.add(report);

    // Keep last 100 crashes
    if (_crashReports.length > 100) {
      _crashReports.removeAt(0);
    }

    await _saveCrashReports();
    debugPrint('[CrashReporting] Crash reported: $exception');

    // Send to backend (simulated)
    await _sendToBackend(report);
  }

  /// Get crash summary
  Future<List<CrashReport>> getCrashReports({int limit = 50}) async {
    return _crashReports.reversed.take(limit).toList();
  }

  /// Get crash by id
  Future<CrashReport?> getCrashReport(String id) async {
    try {
      return _crashReports.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Mark crash as ignored
  Future<void> ignoreCrash(String id) async {
    try {
      final crash = _crashReports.firstWhere((c) => c.id == id);
      crash.isIgnored = true;
      await _saveCrashReports();
    } catch (e) {
      debugPrint('[CrashReporting] Error ignoring crash: $e');
    }
  }

  // ===== ERROR LOGGING =====
  /// Log an error (non-fatal)
  Future<void> logError({
    required String message,
    String? category,
    Map<String, dynamic>? context,
  }) async {
    if (!_isEnabled) return;

    final error = ErrorLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      category: category ?? 'general',
      timestamp: DateTime.now(),
      context: context ?? {},
      level: 'error',
    );

    _errorLogs.add(error);

    // Update frequency
    final key = error.category;
    _errorFrequency[key] = ErrorFrequency(
      category: key,
      count: (_errorFrequency[key]?.count ?? 0) + 1,
      lastOccurrence: DateTime.now(),
    );

    // Keep last 500 errors
    if (_errorLogs.length > 500) {
      _errorLogs.removeAt(0);
    }

    await _saveErrorLogs();
    debugPrint('[CrashReporting] Error logged: $message');
  }

  /// Log warning
  Future<void> logWarning(String message, {String? category}) async {
    if (!_isEnabled) return;

    final error = ErrorLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      category: category ?? 'general',
      timestamp: DateTime.now(),
      context: {},
      level: 'warning',
    );

    _errorLogs.add(error);
    debugPrint('[CrashReporting] Warning: $message');
  }

  /// Get error logs by category
  Future<List<ErrorLog>> getErrorLogsByCategory(String category) async {
    return _errorLogs
        .where((e) => e.category == category)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get most common errors
  Future<List<ErrorFrequency>> getMostCommonErrors({int limit = 10}) async {
    final sorted = _errorFrequency.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return sorted.take(limit).toList();
  }

  // ===== SESSION TRACKING =====
  /// Record session event
  Future<void> recordSessionEvent(String event, {Map<String, dynamic>? data}) async {
    _sessionEvents.add('[${DateTime.now()}] $event');
    
    if (data != null) {
      _sessionEvents.add('  Data: ${jsonEncode(data)}');
    }

    // Keep last 1000 events
    if (_sessionEvents.length > 1000) {
      _sessionEvents.removeAt(0);
    }

    debugPrint('[CrashReporting] Session event: $event');
  }

  /// Start session
  Future<void> startSession(String sessionId, Map<String, dynamic> deviceInfo) async {
    await recordSessionEvent('SESSION_START', data: deviceInfo);
  }

  /// End session
  Future<void> endSession(String sessionId) async {
    await recordSessionEvent('SESSION_END');
  }

  /// Get session events
  Future<List<String>> getSessionEvents({int limit = 100}) async {
    return _sessionEvents.reversed.take(limit).toList();
  }

  // ===== PERFORMANCE MONITORING =====
  /// Track performance metric
  Future<void> trackPerformanceMetric({
    required String metricName,
    required double value,
    String? unit,
  }) async {
    await recordSessionEvent('PERFORMANCE', data: {
      'metric': metricName,
      'value': value,
      'unit': unit,
    });
  }

  /// Track method execution time
  Future<T> trackMethodExecution<T>({
    required String methodName,
    required Future<T> Function() method,
  }) async {
    final startTime = DateTime.now();
    try {
      final result = await method();
      final duration = DateTime.now().difference(startTime);
      await trackPerformanceMetric(
        metricName: methodName,
        value: duration.inMilliseconds.toDouble(),
        unit: 'ms',
      );
      return result;
    } catch (e) {
      await logError(
        message: 'Method execution error: $e',
        category: 'performance',
      );
      rethrow;
    }
  }

  // ===== CRASH ANALYSIS =====
  /// Analyze crashes for patterns
  Future<CrashAnalysis> analyzeCrashes() async {
    if (_crashReports.isEmpty) {
      return CrashAnalysis(
        totalCrashes: 0,
        criticalCrashes: 0,
        topCrashingFeature: 'none',
        topException: 'none',
        crashRate: 0.0,
        trend: 'stable',
        recommendations: [],
      );
    }

    final critical = _crashReports.where((c) => c.severity == 'critical').length;
    final exceptionFrequency = <String, int>{};
    
    for (final crash in _crashReports) {
      final firstLine = crash.exception.split('\n').first;
      exceptionFrequency[firstLine] = (exceptionFrequency[firstLine] ?? 0) + 1;
    }

    final topException = exceptionFrequency.entries.isNotEmpty
        ? exceptionFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'none';

    final recommendations = _generateRecommendations(critical, topException);

    return CrashAnalysis(
      totalCrashes: _crashReports.length,
      criticalCrashes: critical,
      topCrashingFeature: 'Unknown',
      topException: topException,
      crashRate: (critical / _crashReports.length),
      trend: _calculateTrend(),
      recommendations: recommendations,
    );
  }

  /// Generate diagnostic report
  Future<String> generateDiagnosticReport() async {
    final analysis = await analyzeCrashes();
    final mostCommon = await getMostCommonErrors(limit: 5);
    final recentCrashes = await getCrashReports(limit: 5);

    return '''
=== CRASH DIAGNOSTIC REPORT ===
Generated: ${DateTime.now()}

SUMMARY:
- Total Crashes: ${analysis.totalCrashes}
- Critical Crashes: ${analysis.criticalCrashes}
- Crash Rate: ${(analysis.crashRate * 100).toStringAsFixed(2)}%
- Trend: ${analysis.trend}

TOP EXCEPTION:
${analysis.topException}

MOST COMMON ERRORS:
${mostCommon.map((e) => '- ${e.category}: ${e.count} occurrences').join('\n')}

RECENT CRASHES:
${recentCrashes.take(5).map((c) => '- ${c.timestamp}: ${c.exception.split('\n').first}').join('\n')}

RECOMMENDATIONS:
${analysis.recommendations.map((r) => '✓ $r').join('\n')}

SESSION EVENTS (Last 10):
${_sessionEvents.reversed.take(10).map((e) => '- $e').join('\n')}
''';
  }

  // ===== CONTROL =====
  void enableCrashReporting() {
    _isEnabled = true;
  }

  void disableCrashReporting() {
    _isEnabled = false;
  }

  /// Clear all crash data
  Future<void> clearAllData() async {
    _crashReports.clear();
    _errorLogs.clear();
    _errorFrequency.clear();
    _sessionEvents.clear();
    await _prefs.remove('crash_reports');
    await _prefs.remove('error_logs');
    debugPrint('[CrashReporting] All data cleared');
  }

  // ===== INTERNAL HELPERS =====
  String _calculateSeverity(String exception) {
    if (exception.contains('OutOfMemory') || exception.contains('StackOverflow')) {
      return 'critical';
    } else if (exception.contains('DatabaseException') || exception.contains('NetworkError')) {
      return 'high';
    } else if (exception.contains('Assertion')) {
      return 'medium';
    }
    return 'low';
  }

  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  List<String> _generateRecommendations(int critical, String topException) {
    final recommendations = <String>[];

    if (critical > 5) {
      recommendations.add('Address critical crashes immediately - $critical found');
    }

    if (topException.contains('Null')) {
      recommendations.add('Review null safety - many null pointer exceptions detected');
    }

    if (topException.contains('Memory')) {
      recommendations.add('Optimize memory usage - memory-related errors detected');
    }

    recommendations.add('Implement unit tests for error-prone code');
    recommendations.add('Add more defensive programming checks');

    return recommendations;
  }

  String _calculateTrend() {
    if (_crashReports.length < 2) return 'insufficient_data';

    final recent = _crashReports.where(
      (c) => c.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 1)))
    ).length;

    final older = _crashReports.where(
      (c) => c.timestamp.isBefore(DateTime.now().subtract(const Duration(days: 1))) &&
          c.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 2)))
    ).length;

    if (recent > older) return 'increasing';
    if (recent < older) return 'decreasing';
    return 'stable';
  }

  Future<void> _sendToBackend(CrashReport report) async {
    // Simulate sending to backend
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('[CrashReporting] Crash sent to backend: ${report.id}');
  }

  Future<void> _saveCrashReports() async {
    final data = _crashReports.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList('crash_reports', data);
  }

  Future<void> _loadCrashHistory() async {
    final data = _prefs.getStringList('crash_reports') ?? [];
    for (final item in data) {
      try {
        _crashReports.add(CrashReport.fromJson(jsonDecode(item)));
      } catch (e) {
        debugPrint('[CrashReporting] Error loading crash: $e');
      }
    }
  }

  Future<void> _saveErrorLogs() async {
    final data = _errorLogs.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('error_logs', data);
  }
}

// ===== DATA MODELS =====

class CrashReport {
  final String id;
  final String exception;
  final String stackTrace;
  final DateTime timestamp;
  final String severity;
  final Map<String, dynamic> additionalInfo;
  final String sessionId;
  final List<String> sessionEvents;
  bool isIgnored;

  CrashReport({
    required this.id,
    required this.exception,
    required this.stackTrace,
    required this.timestamp,
    required this.severity,
    required this.additionalInfo,
    required this.sessionId,
    required this.sessionEvents,
    this.isIgnored = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'exception': exception,
    'stackTrace': stackTrace,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity,
    'additionalInfo': additionalInfo,
    'sessionId': sessionId,
    'sessionEvents': sessionEvents,
    'isIgnored': isIgnored,
  };

  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      id: json['id'] as String,
      exception: json['exception'] as String,
      stackTrace: json['stackTrace'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      severity: json['severity'] as String,
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>? ?? {},
      sessionId: json['sessionId'] as String? ?? '',
      sessionEvents: List<String>.from(json['sessionEvents'] as List? ?? []),
      isIgnored: json['isIgnored'] as bool? ?? false,
    );
  }
}

class ErrorLog {
  final String id;
  final String message;
  final String category;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final String level; // 'error', 'warning', 'info'

  ErrorLog({
    required this.id,
    required this.message,
    required this.category,
    required this.timestamp,
    required this.context,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
    'level': level,
  };

  factory ErrorLog.fromJson(Map<String, dynamic> json) {
    return ErrorLog(
      id: json['id'] as String,
      message: json['message'] as String,
      category: json['category'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: json['context'] as Map<String, dynamic>? ?? {},
      level: json['level'] as String? ?? 'error',
    );
  }
}

class ErrorFrequency {
  final String category;
  int count;
  DateTime? lastOccurrence;

  ErrorFrequency({
    required this.category,
    required this.count,
    this.lastOccurrence,
  });
}

class CrashAnalysis {
  final int totalCrashes;
  final int criticalCrashes;
  final String topCrashingFeature;
  final String topException;
  final double crashRate;
  final String trend;
  final List<String> recommendations;

  CrashAnalysis({
    required this.totalCrashes,
    required this.criticalCrashes,
    required this.topCrashingFeature,
    required this.topException,
    required this.crashRate,
    required this.trend,
    required this.recommendations,
  });
}


