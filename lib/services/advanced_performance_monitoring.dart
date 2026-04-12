import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Advanced Performance Monitoring
/// Real-time metrics, bottleneck detection, optimization recommendations
class AdvancedPerformanceMonitoring {
  static final AdvancedPerformanceMonitoring _instance = AdvancedPerformanceMonitoring._internal();

  factory AdvancedPerformanceMonitoring() {
    return _instance;
  }

  AdvancedPerformanceMonitoring._internal();

  late SharedPreferences _prefs;
  final Map<String, PerformanceMetric> _metrics = {};
  final List<PerformanceAlert> _alerts = [];
  DateTime _sessionStart = DateTime.now();
  final Map<String, int> _methodCallCounts = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _sessionStart = DateTime.now();
    debugPrint('[Performance Monitoring] Initialized');
  }

  // ===== PERFORMANCE TRACKING =====
  Future<void> recordMetric({
    required String metricName,
    required double value,
    required String unit,
    Map<String, dynamic>? tags,
  }) async {
    final metric = PerformanceMetric(
      metricId: 'metric_${DateTime.now().millisecondsSinceEpoch}',
      metricName: metricName,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      tags: tags ?? {},
    );

    _metrics[metric.metricId] = metric;

    // Check for anomalies
    if (value > _getThreshold(metricName)) {
      await _createAlert(
        severity: 'warning',
        message: '$metricName exceeds threshold: $value$unit',
      );
    }

    await _saveMetrics();
  }

  Future<void> trackMethodExecution<T>(
    String methodName,
    Future<T> Function() method,
  ) async {
    final startTime = DateTime.now();
    
    try {
      await method();
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      _methodCallCounts[methodName] = (_methodCallCounts[methodName] ?? 0) + 1;

      await recordMetric(
        metricName: 'method_execution',
        value: duration.toDouble(),
        unit: 'ms',
        tags: {'method': methodName, 'status': 'success'},
      );

      // Detect slow methods
      if (duration > 1000) {
        await _createAlert(
          severity: 'warning',
          message: 'Slow method detected: $methodName took ${duration}ms',
        );
      }
      return;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      await recordMetric(
        metricName: 'method_execution',
        value: duration.toDouble(),
        unit: 'ms',
        tags: {'method': methodName, 'status': 'error'},
      );

      rethrow;
    }
  }

  // ===== MEMORY MONITORING =====
  Future<MemoryInfo> getMemoryInfo() async {
    final metricsList = _metrics.values.toList();
    final estimatedMemory = (metricsList.length * 512) / 1024; // Rough estimate

    return MemoryInfo(
      estimatedMemoryUsage: estimatedMemory,
      metricsStored: metricsList.length,
      alertsStored: _alerts.length,
      methodCallsSince: DateTime.now().difference(_sessionStart).inSeconds,
      averageMetricSize: (estimatedMemory / metricsList.length).isFinite 
          ? estimatedMemory / metricsList.length 
          : 0.0,
    );
  }

  // ===== BOTTLENECK DETECTION =====
  Future<BottleneckAnalysis> analyzeBottlenecks() async {
    if (_methodCallCounts.isEmpty) {
      return BottleneckAnalysis(
        slowestMethods: [],
        frequentErrors: 0,
        averageLatency: 0.0,
        recommendedOptimizations: [],
      );
    }

    // Find slowest methods
    final methodMetrics = <String, List<double>>{};
    for (final metric in _metrics.values.where((m) => m.tags['method'] != null)) {
      final method = metric.tags['method'] as String;
      methodMetrics.putIfAbsent(method, () => []).add(metric.value);
    }

    final slowestMethods = methodMetrics.entries
        .map((e) => SlowMethod(
          methodName: e.key,
          avgExecutionTime: e.value.reduce((a, b) => a + b) / e.value.length,
          callCount: _methodCallCounts[e.key] ?? 0,
          maxExecutionTime: e.value.reduce((a, b) => a > b ? a : b),
        ))
        .toList()
      ..sort((a, b) => b.avgExecutionTime.compareTo(a.avgExecutionTime));

    // Find frequent errors
    final errorMetrics = _metrics.values
        .where((m) => m.tags['status'] == 'error')
        .toList();

    final recommendations = _generateOptimizations(slowestMethods, errorMetrics.length);

    return BottleneckAnalysis(
      slowestMethods: slowestMethods.take(5).toList(),
      frequentErrors: errorMetrics.length,
      averageLatency: methodMetrics.values
          .fold<double>(0.0, (prev, list) => prev + (list.reduce((a, b) => a + b) / list.length))
          / methodMetrics.length,
      recommendedOptimizations: recommendations,
    );
  }

  // ===== ALERTS =====
  Future<List<PerformanceAlert>> getAlerts({int limit = 50}) async {
    return _alerts.take(limit).toList();
  }

  Future<void> clearAlerts() async {
    _alerts.clear();
    await _prefs.setStringList('perf_alerts', []);
  }

  // ===== SUMMARY & REPORTING =====
  Future<PerformanceSummary> generatePerformanceSummary() async {
    final memInfo = await getMemoryInfo();
    final bottlenecks = await analyzeBottlenecks();
    final uptime = DateTime.now().difference(_sessionStart).inSeconds;

    return PerformanceSummary(
      sessionUptime: uptime,
      totalMetricsRecorded: _metrics.length,
      totalAlertsGenerated: _alerts.length,
      averageLatency: bottlenecks.averageLatency,
      slowestOperation: bottlenecks.slowestMethods.isNotEmpty 
          ? bottlenecks.slowestMethods.first.methodName 
          : 'none',
      memoryEstimate: memInfo.estimatedMemoryUsage,
      healthStatus: _calculateHealthStatus(bottlenecks, _alerts),
      recommendations: bottlenecks.recommendedOptimizations,
    );
  }

  // ===== INTERNAL HELPERS =====
  double _getThreshold(String metricName) {
    switch (metricName) {
      case 'api_latency':
        return 500.0; // ms
      case 'db_query_time':
        return 1000.0; // ms
      case 'method_execution':
        return 1000.0; // ms
      default:
        return 5000.0;
    }
  }

  Future<void> _createAlert({
    required String severity,
    required String message,
  }) async {
    final alert = PerformanceAlert(
      alertId: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      severity: severity,
      message: message,
      timestamp: DateTime.now(),
    );

    _alerts.add(alert);

    // Keep only last 100 alerts
    if (_alerts.length > 100) {
      _alerts.removeAt(0);
    }

    await _prefs.setStringList(
      'perf_alerts',
      _alerts.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  List<String> _generateOptimizations(List<SlowMethod> slowMethods, int errorCount) {
    final recommendations = <String>[];

    if (slowMethods.isNotEmpty) {
      if (slowMethods.first.avgExecutionTime > 2000) {
        recommendations.add('Optimize ${slowMethods.first.methodName} - currently taking ${slowMethods.first.avgExecutionTime.toStringAsFixed(0)}ms');
      }
    }

    if (errorCount > 10) {
      recommendations.add('High error rate detected ($errorCount errors) - review error logs');
    }

    if (_metrics.length > 10000) {
      recommendations.add('Consider archiving old metrics - currently storing ${_metrics.length} metrics');
    }

    recommendations.add('Use caching for frequently called methods');
    recommendations.add('Implement pagination for large data loads');

    return recommendations;
  }

  String _calculateHealthStatus(BottleneckAnalysis bottlenecks, List<PerformanceAlert> alerts) {
    if (alerts.any((a) => a.severity == 'critical')) return 'critical';
    if (bottlenecks.slowestMethods.isNotEmpty && bottlenecks.slowestMethods.first.avgExecutionTime > 2000) {
      return 'warning';
    }
    if (alerts.any((a) => a.severity == 'warning')) return 'caution';
    return 'healthy';
  }

  Future<void> _saveMetrics() async {
    final data = _metrics.values
        .take(5000) // Keep last 5000 metrics
        .map((m) => jsonEncode(m.toJson()))
        .toList();

    await _prefs.setStringList('perf_metrics', data);
  }
}

// ===== DATA MODELS =====

class PerformanceMetric {
  String metricId;
  String metricName;
  double value;
  String unit;
  DateTime timestamp;
  Map<String, dynamic> tags;

  PerformanceMetric({
    required this.metricId,
    required this.metricName,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
    'metricId': metricId,
    'metricName': metricName,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
    'tags': tags,
  };
}

class PerformanceAlert {
  String alertId;
  String severity;
  String message;
  DateTime timestamp;

  PerformanceAlert({
    required this.alertId,
    required this.severity,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'alertId': alertId,
    'severity': severity,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };
}

class MemoryInfo {
  double estimatedMemoryUsage;
  int metricsStored;
  int alertsStored;
  int methodCallsSince;
  double averageMetricSize;

  MemoryInfo({
    required this.estimatedMemoryUsage,
    required this.metricsStored,
    required this.alertsStored,
    required this.methodCallsSince,
    required this.averageMetricSize,
  });
}

class SlowMethod {
  String methodName;
  double avgExecutionTime;
  int callCount;
  double maxExecutionTime;

  SlowMethod({
    required this.methodName,
    required this.avgExecutionTime,
    required this.callCount,
    required this.maxExecutionTime,
  });
}

class BottleneckAnalysis {
  List<SlowMethod> slowestMethods;
  int frequentErrors;
  double averageLatency;
  List<String> recommendedOptimizations;

  BottleneckAnalysis({
    required this.slowestMethods,
    required this.frequentErrors,
    required this.averageLatency,
    required this.recommendedOptimizations,
  });
}

class PerformanceSummary {
  int sessionUptime;
  int totalMetricsRecorded;
  int totalAlertsGenerated;
  double averageLatency;
  String slowestOperation;
  double memoryEstimate;
  String healthStatus;
  List<String> recommendations;

  PerformanceSummary({
    required this.sessionUptime,
    required this.totalMetricsRecorded,
    required this.totalAlertsGenerated,
    required this.averageLatency,
    required this.slowestOperation,
    required this.memoryEstimate,
    required this.healthStatus,
    required this.recommendations,
  });
}
