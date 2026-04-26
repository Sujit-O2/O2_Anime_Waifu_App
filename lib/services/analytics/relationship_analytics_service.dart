import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📊 Relationship Analytics Dashboard Service
class RelationshipAnalyticsService {
  RelationshipAnalyticsService._();
  static final RelationshipAnalyticsService instance = RelationshipAnalyticsService._();

  final List<AnalyticsDataPoint> _dataPoints = [];

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[Analytics] Initialized');
  }

  Future<void> recordDataPoint({required int affectionScore, required int messageCount, required int conversationDuration, required double emotionalIntensity}) async {
    _dataPoints.insert(0, AnalyticsDataPoint(timestamp: DateTime.now(), affectionScore: affectionScore, messageCount: messageCount, conversationDuration: conversationDuration, emotionalIntensity: emotionalIntensity));
    if (_dataPoints.length > 365) _dataPoints.removeLast();
    await _saveData();
  }

  RelationshipReport generateReport({required TimeRange timeRange}) {
    final cutoff = _getCutoffDate(timeRange);
    final relevantData = _dataPoints.where((d) => d.timestamp.isAfter(cutoff)).toList();
    if (relevantData.isEmpty) return RelationshipReport.empty();

    final avgAffection = relevantData.fold<int>(0, (sum, d) => sum + d.affectionScore) / relevantData.length;
    final totalMessages = relevantData.fold<int>(0, (sum, d) => sum + d.messageCount);
    final totalDuration = relevantData.fold<int>(0, (sum, d) => sum + d.conversationDuration);
    final avgEmotionalIntensity = relevantData.fold<double>(0, (sum, d) => sum + d.emotionalIntensity) / relevantData.length;

    return RelationshipReport(timeRange: timeRange, averageAffection: avgAffection.round(), totalMessages: totalMessages, totalDurationMinutes: (totalDuration / 60).round(), averageEmotionalIntensity: avgEmotionalIntensity, dataPoints: relevantData);
  }

  DateTime _getCutoffDate(TimeRange range) {
    final now = DateTime.now();
    switch (range) {
      case TimeRange.last7Days: return now.subtract(const Duration(days: 7));
      case TimeRange.last30Days: return now.subtract(const Duration(days: 30));
      case TimeRange.last90Days: return now.subtract(const Duration(days: 90));
      case TimeRange.allTime: return DateTime(2000);
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_data', jsonEncode(_dataPoints.map((d) => d.toJson()).toList()));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('analytics_data');
    if (data != null) {
      _dataPoints.clear();
      _dataPoints.addAll((jsonDecode(data) as List).map((e) => AnalyticsDataPoint.fromJson(e)));
    }
  }
}

class AnalyticsDataPoint {
  final DateTime timestamp;
  final int affectionScore;
  final int messageCount;
  final int conversationDuration;
  final double emotionalIntensity;

  AnalyticsDataPoint({required this.timestamp, required this.affectionScore, required this.messageCount, required this.conversationDuration, required this.emotionalIntensity});

  Map<String, dynamic> toJson() => {'timestamp': timestamp.toIso8601String(), 'affectionScore': affectionScore, 'messageCount': messageCount, 'conversationDuration': conversationDuration, 'emotionalIntensity': emotionalIntensity};
  factory AnalyticsDataPoint.fromJson(Map<String, dynamic> json) => AnalyticsDataPoint(timestamp: DateTime.parse(json['timestamp']), affectionScore: json['affectionScore'], messageCount: json['messageCount'], conversationDuration: json['conversationDuration'], emotionalIntensity: json['emotionalIntensity']);
}

class RelationshipReport {
  final TimeRange timeRange;
  final int averageAffection;
  final int totalMessages;
  final int totalDurationMinutes;
  final double averageEmotionalIntensity;
  final List<AnalyticsDataPoint> dataPoints;

  RelationshipReport({required this.timeRange, required this.averageAffection, required this.totalMessages, required this.totalDurationMinutes, required this.averageEmotionalIntensity, required this.dataPoints});
  factory RelationshipReport.empty() => RelationshipReport(timeRange: TimeRange.last7Days, averageAffection: 0, totalMessages: 0, totalDurationMinutes: 0, averageEmotionalIntensity: 0, dataPoints: []);
}

enum TimeRange { last7Days, last30Days, last90Days, allTime }
