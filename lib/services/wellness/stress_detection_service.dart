import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 😣 Stress Detection Service
/// 
/// Uses voice analysis and typing patterns to detect stress levels and offer coping strategies.
class StressDetectionService {
  StressDetectionService._();
  static final StressDetectionService instance = StressDetectionService._();

  final List<StressReading> _stressHistory = [];
  final Map<String, double> _dailyStressScores = {};
  
  int _totalReadings = 0;
  DateTime? _lastAssessment;
  
  static const String _storageKey = 'stress_detection_v1';
  static const int _maxHistory = 1000;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[StressDetection] Initialized with $_totalReadings readings');
  }

  /// Analyze voice characteristics for stress indicators
  double analyzeVoiceStress({
    required double pitchVariance,
    required double speakingRate,
    required double volumeVariance,
    required double pauseFrequency,
  }) {
    // Normalize inputs (0-1 scale where higher = more stressed)
    final pitchStress = (pitchVariance - 0.5).abs() * 2; // Higher variance = more stress
    final rateStress = (speakingRate - 0.5).abs() * 2; // Deviations from normal rate = stress
    final volumeStress = volumeVariance; // Higher variance = more stress
    final pauseStress = pauseFrequency.clamp(0.0, 1.0); // More pauses = more stress
    
    // Weighted average
    return (pitchStress * 0.3 + rateStress * 0.2 + volumeStress * 0.3 + pauseStress * 0.2);
  }

  /// Analyze typing patterns for stress indicators
  double analyzeTypingStress({
    required double typingSpeed,
    required double errorRate,
    required double backspaceFrequency,
    required double pressureVariance,
  }) {
    // Normalize inputs
    final speedStress = (typingSpeed - 0.5).abs() * 2; // Too fast or slow = stress
    final errorStress = errorRate.clamp(0.0, 1.0); // More errors = more stress
    final backspaceStress = backspaceFrequency.clamp(0.0, 1.0); // More corrections = stress
    final pressureStress = pressureVariance; // Harder typing = stress
    
    // Weighted average
    return (speedStress * 0.25 + errorStress * 0.25 + backspaceStress * 0.25 + pressureStress * 0.25);
  }

  Future<void> recordStressReading({
    required double voiceStress,
    required double typingStress,
    required String context,
  }) async {
    final combinedStress = ((voiceStress + typingStress) / 2).clamp(0.0, 1.0);
    
    final reading = StressReading(
      timestamp: DateTime.now(),
      voiceStress: voiceStress,
      typingStress: typingStress,
      combinedStress: combinedStress,
      context: context,
    );
    
    _stressHistory.insert(0, reading);
    if (_stressHistory.length > _maxHistory) {
      _stressHistory.removeLast();
    }
    
    _totalReadings++;
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    _dailyStressScores[todayKey] = combinedStress;
    _lastAssessment = DateTime.now();
    
    await _saveData();
    
    if (kDebugMode) {
      debugPrint('[StressDetection] Stress reading recorded: ${(combinedStress * 100).toStringAsFixed(0)}%');
    }
  }

  String getStressInsights() {
    if (_stressHistory.isEmpty) {
      return "Start monitoring your stress levels to get personalized insights!";
    }

    final recentReadings = _stressHistory.take(10).toList();
    final avgStress = recentReadings.fold<double>(0, (sum, r) => sum + r.combinedStress) / recentReadings.length;
    
    final buffer = StringBuffer();
    buffer.writeln('😣 Stress Insights (Last 10 readings):');
    buffer.writeln('• Average Stress Level: ${(avgStress * 100).toStringAsFixed(0)}%');
    
    if (avgStress > 0.7) {
      buffer.writeln('🚨 High stress detected. Consider taking breaks and practicing relaxation techniques.');
    } else if (avgStress > 0.4) {
      buffer.writeln('⚠️ Moderate stress levels. Monitor your stress triggers and practice self-care.');
    } else {
      buffer.writeln('🌟 Low stress levels. Your stress management appears effective.');
    }
    
    return buffer.toString();
  }

  String getCopingStrategies() {
    if (_stressHistory.isEmpty) return "Monitor your stress first to get personalized coping strategies.";
    
    final recentStress = _stressHistory.take(3).fold<double>(0, (sum, r) => sum + r.combinedStress) / 3;
    final strategies = <String>[];
    
    if (recentStress > 0.7) {
      strategies.add('Try 4-7-8 breathing: inhale 4s, hold 7s, exhale 8s');
      strategies.add('Take a 10-minute walk outside');
      strategies.add('Practice progressive muscle relaxation');
    } else if (recentStress > 0.4) {
      strategies.add('Take short breaks every hour');
      strategies.add('Stay hydrated and have a healthy snack');
      strategies.add('Listen to calming music for 5 minutes');
    } else {
      strategies.add('Maintain your current stress management routine');
      strategies.add('Continue regular exercise and adequate sleep');
    }
    
    return '💪 Coping Strategies: ${strategies.join(' • ')}';
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'stressHistory': _stressHistory.take(50).map((s) => s.toJson()).toList(),
        'totalReadings': _totalReadings,
        'dailyStressScores': _dailyStressScores,
        'lastAssessment': _lastAssessment?.toIso8601String(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[StressDetection] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _stressHistory.clear();
        _stressHistory.addAll(
          (data['stressHistory'] as List<dynamic>)
              .map((s) => StressReading.fromJson(s as Map<String, dynamic>))
        );
        
        _totalReadings = data['totalReadings'] as int;
        final loadedScores = Map<String, double>.from(data['dailyStressScores'] ?? {});
        _dailyStressScores.clear();
        _dailyStressScores.addAll(loadedScores);
        
        if (data['lastAssessment'] != null) {
          _lastAssessment = DateTime.parse(data['lastAssessment'] as String);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StressDetection] Load error: $e');
    }
  }
}

class StressReading {
  final DateTime timestamp;
  final double voiceStress; // 0-1 scale
  final double typingStress; // 0-1 scale
  final double combinedStress; // 0-1 scale
  final String context;

  StressReading({
    required this.timestamp,
    required this.voiceStress,
    required this.typingStress,
    required this.combinedStress,
    required this.context,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'voiceStress': voiceStress,
    'typingStress': typingStress,
    'combinedStress': combinedStress,
    'context': context,
  };

  factory StressReading.fromJson(Map<String, dynamic> json) => StressReading(
    timestamp: DateTime.parse(json['timestamp']),
    voiceStress: (json['voiceStress'] as num).toDouble(),
    typingStress: (json['typingStress'] as num).toDouble(),
    combinedStress: (json['combinedStress'] as num).toDouble(),
    context: json['context'],
  );
}