import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A/B Testing Framework
/// Variant testing, feature flags, experimentation
class ABTestingFramework {
  static final ABTestingFramework _instance = ABTestingFramework._internal();

  factory ABTestingFramework() {
    return _instance;
  }

  ABTestingFramework._internal();

  late SharedPreferences _prefs;
  final Map<String, ABTest> _tests = {};
  final Map<String, String> _userVariants = {};
  final Map<String, ABTestResult> _results = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTests();
    debugPrint('[A/B Testing] Initialized');
  }

  // ===== TEST CREATION =====
  Future<ABTest> createTest({
    required String testName,
    required String description,
    required Map<String, dynamic> variantA,
    required Map<String, dynamic> variantB,
    required DateTime startDate,
    required DateTime endDate,
    required double splitPercentage, // 0.5 = 50-50 split
  }) async {
    final test = ABTest(
      testId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      testName: testName,
      description: description,
      variantA: variantA,
      variantB: variantB,
      startDate: startDate,
      endDate: endDate,
      splitPercentage: splitPercentage,
      status: 'active',
      audienceSize: 0,
      participantsA: 0,
      participantsB: 0,
    );

    _tests[test.testId] = test;
    await _saveTests();
    return test;
  }

  Future<ABTest?> getTest(String testId) async {
    return _tests[testId];
  }

  Future<List<ABTest>> getActiveTests() async {
    final now = DateTime.now();
    return _tests.values
        .where((t) => t.status == 'active' && t.startDate.isBefore(now) && t.endDate.isAfter(now))
        .toList();
  }

  // ===== VARIANT ASSIGNMENT =====
  Future<String> assignUserVariant(String userId, String testId) async {
    final key = '$testId:$userId';
    
    if (_userVariants.containsKey(key)) {
      return _userVariants[key]!;
    }

    final test = _tests[testId];
    if (test == null) throw Exception('Test not found');

    // Assign based on split percentage
    final variant = (userId.hashCode % 100) / 100 < test.splitPercentage ? 'A' : 'B';
    _userVariants[key] = variant;

    if (variant == 'A') {
      test.participantsA++;
    } else {
      test.participantsB++;
    }

    test.audienceSize++;
    await _saveTests();
    return variant;
  }

  Future<String?> getUserVariant(String userId, String testId) async {
    return _userVariants['$testId:$userId'];
  }

  Future<Map<String, dynamic>?> getVariantConfig(String userId, String testId) async {
    final variant = await getUserVariant(userId, testId);
    final test = _tests[testId];

    if (variant == null || test == null) return null;

    return variant == 'A' ? test.variantA : test.variantB;
  }

  // ===== METRICS & TRACKING =====
  Future<void> trackEvent(String userId, String testId, String eventName, Map<String, dynamic>? data) async {
    final variant = await getUserVariant(userId, testId);
    if (variant == null) return;

    final key = testId;
    final result = _results.putIfAbsent(
      key,
      () => ABTestResult(
        testId: testId,
        conversionsA: 0,
        conversionsB: 0,
        totalRevenueA: 0.0,
        totalRevenueB: 0.0,
        eventsA: [],
        eventsB: [],
      ),
    );

    final event = {
      'userId': userId,
      'eventName': eventName,
      'data': data ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (variant == 'A') {
      result.eventsA.add(event);
    } else {
      result.eventsB.add(event);
    }

    await _prefs.setString('ab_result:$key', jsonEncode(result.toJson()));
  }

  Future<void> recordConversion(String userId, String testId, double value) async {
    final variant = await getUserVariant(userId, testId);
    if (variant == null) return;

    final result = _results[testId] ?? ABTestResult(
      testId: testId,
      conversionsA: 0,
      conversionsB: 0,
      totalRevenueA: 0.0,
      totalRevenueB: 0.0,
      eventsA: [],
      eventsB: [],
    );

    if (variant == 'A') {
      result.conversionsA++;
      result.totalRevenueA += value;
    } else {
      result.conversionsB++;
      result.totalRevenueB += value;
    }

    _results[testId] = result;
    await _prefs.setString('ab_result:$testId', jsonEncode(result.toJson()));
  }

  // ===== ANALYSIS & REPORTING =====
  Future<ABTestAnalysis> analyzeTest(String testId) async {
    final test = _tests[testId];
    final result = _results[testId];

    if (test == null || result == null) {
      return ABTestAnalysis.empty();
    }

    final conversionRateA = result.participantsA > 0 
        ? result.conversionsA / result.participantsA 
        : 0.0;
    final conversionRateB = result.participantsB > 0 
        ? result.conversionsB / result.participantsB 
        : 0.0;

    final revenuePerUserA = result.participantsA > 0 
        ? result.totalRevenueA / result.participantsA 
        : 0.0;
    final revenuePerUserB = result.participantsB > 0 
        ? result.totalRevenueB / result.participantsB 
        : 0.0;

    // Simple statistical significance (mock)
    final isSignificant = (conversionRateA - conversionRateB).abs() > 0.05;
    final winner = conversionRateA > conversionRateB ? 'A' : 'B';
    final confidence = _calculateConfidence(result.participantsA, result.participantsB);

    return ABTestAnalysis(
      testId: testId,
      testName: test.testName,
      participants: test.audienceSize,
      conversionRateA: conversionRateA,
      conversionRateB: conversionRateB,
      revenuePerUserA: revenuePerUserA,
      revenuePerUserB: revenuePerUserB,
      isStatisticallySignificant: isSignificant,
      recommendedWinner: winner,
      confidence: confidence,
      recommendation: _getRecommendation(isSignificant, winner, confidence),
    );
  }

  Future<void> concludeTest(String testId, String winningVariant) async {
    final test = _tests[testId];
    if (test != null) {
      test.status = 'concluded';
      test.winningVariant = winningVariant;
      await _saveTests();
    }
  }

  // ===== FEATURE FLAGS =====
  Future<void> setFeatureFlag(String flagName, bool enabled, {double? rolloutPercentage}) async {
    await _prefs.setBool('flag_$flagName', enabled);
    if (rolloutPercentage != null) {
      await _prefs.setDouble('flag_rollout_$flagName', rolloutPercentage);
    }
  }

  Future<bool> isFeatureFlagEnabled(String flagName, String userId) async {
    final enabled = _prefs.getBool('flag_$flagName') ?? false;
    if (!enabled) return false;

    final rollout = _prefs.getDouble('flag_rollout_$flagName') ?? 1.0;
    return (userId.hashCode % 100) / 100 < rollout;
  }

  // ===== INTERNAL HELPERS =====
  double _calculateConfidence(int samplesA, int samplesB) {
    final minSamples = 1000;
    final avgSamples = (samplesA + samplesB) / 2;
    return (avgSamples / minSamples).clamp(0.0, 1.0);
  }

  String _getRecommendation(bool isSignificant, String winner, double confidence) {
    if (!isSignificant) return 'Inconclusive - continue testing';
    if (confidence < 0.7) return 'Low confidence - gather more data';
    return 'Variant $winner is the clear winner with ${(confidence * 100).toStringAsFixed(0)}% confidence';
  }

  Future<void> _loadTests() async {
    // Load tests from storage
  }

  Future<void> _saveTests() async {
    final data = _tests.entries
        .map((e) => jsonEncode({'key': e.key, 'value': e.value.toJson()}))
        .toList();
    await _prefs.setStringList('ab_tests', data);
  }
}

// ===== DATA MODELS =====

class ABTest {
  String testId;
  String testName;
  String description;
  Map<String, dynamic> variantA;
  Map<String, dynamic> variantB;
  DateTime startDate;
  DateTime endDate;
  double splitPercentage;
  String status;
  int audienceSize;
  int participantsA;
  int participantsB;
  String? winningVariant;

  ABTest({
    required this.testId,
    required this.testName,
    required this.description,
    required this.variantA,
    required this.variantB,
    required this.startDate,
    required this.endDate,
    required this.splitPercentage,
    required this.status,
    required this.audienceSize,
    required this.participantsA,
    required this.participantsB,
    this.winningVariant,
  });

  Map<String, dynamic> toJson() => {
    'testId': testId,
    'testName': testName,
    'description': description,
    'variantA': variantA,
    'variantB': variantB,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'splitPercentage': splitPercentage,
    'status': status,
    'audienceSize': audienceSize,
    'participantsA': participantsA,
    'participantsB': participantsB,
    'winningVariant': winningVariant,
  };
}

class ABTestResult {
  String testId;
  int participantsA;
  int participantsB;
  int conversionsA;
  int conversionsB;
  double totalRevenueA;
  double totalRevenueB;
  List<Map<String, dynamic>> eventsA;
  List<Map<String, dynamic>> eventsB;

  ABTestResult({
    required this.testId,
    required this.conversionsA,
    required this.conversionsB,
    required this.totalRevenueA,
    required this.totalRevenueB,
    required this.eventsA,
    required this.eventsB,
    int? participantsA,
    int? participantsB,
  })  : participantsA = participantsA ?? 0,
        participantsB = participantsB ?? 0;

  Map<String, dynamic> toJson() => {
    'testId': testId,
    'conversionsA': conversionsA,
    'conversionsB': conversionsB,
    'revenueA': totalRevenueA,
    'revenueB': totalRevenueB,
    'eventsA': eventsA,
    'eventsB': eventsB,
  };
}

class ABTestAnalysis {
  String testId;
  String testName;
  int participants;
  double conversionRateA;
  double conversionRateB;
  double revenuePerUserA;
  double revenuePerUserB;
  bool isStatisticallySignificant;
  String recommendedWinner;
  double confidence;
  String recommendation;

  ABTestAnalysis({
    required this.testId,
    required this.testName,
    required this.participants,
    required this.conversionRateA,
    required this.conversionRateB,
    required this.revenuePerUserA,
    required this.revenuePerUserB,
    required this.isStatisticallySignificant,
    required this.recommendedWinner,
    required this.confidence,
    required this.recommendation,
  });

  factory ABTestAnalysis.empty() => ABTestAnalysis(
    testId: '',
    testName: '',
    participants: 0,
    conversionRateA: 0.0,
    conversionRateB: 0.0,
    revenuePerUserA: 0.0,
    revenuePerUserB: 0.0,
    isStatisticallySignificant: false,
    recommendedWinner: 'none',
    confidence: 0.0,
    recommendation: 'No data available',
  );
}


