import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎯 Predictive Proactive Messages Service
class PredictiveAIService {
  PredictiveAIService._();
  static final PredictiveAIService instance = PredictiveAIService._();

  final List<EmotionalEvent> _history = [];
  final Map<String, List<double>> _patterns = {};

  Future<void> initialize() async {
    await _loadHistory();
    _analyzePatterns();
    if (kDebugMode) debugPrint('[PredictiveAI] Initialized with ${_history.length} events');
  }

  Future<void> recordEmotionalEvent(EmotionalState state, {String? trigger}) async {
    final event = EmotionalEvent(
      state: state,
      timestamp: DateTime.now(),
      dayOfWeek: DateTime.now().weekday,
      hourOfDay: DateTime.now().hour,
      trigger: trigger,
    );
    _history.insert(0, event);
    if (_history.length > 1000) _history.removeLast();
    await _saveHistory();
    _analyzePatterns();
  }

  List<EmotionalPrediction> predictEmotionalNeeds({int hoursAhead = 24}) {
    final predictions = <EmotionalPrediction>[];
    final now = DateTime.now();

    for (int i = 0; i < hoursAhead; i++) {
      final targetTime = now.add(Duration(hours: i));
      final prediction = _predictForTime(targetTime);
      if (prediction != null && prediction.confidence > 0.7) {
        predictions.add(prediction);
      }
    }

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions.take(5).toList();
  }

  EmotionalPrediction? _predictForTime(DateTime time) {
    final dayOfWeek = time.weekday;
    final hour = time.hour;
    final historicalEvents = _history.where((e) => 
      e.dayOfWeek == dayOfWeek && (e.hourOfDay - hour).abs() <= 1
    ).toList();

    if (historicalEvents.length < 3) return null;

    final lowMoodCount = historicalEvents.where((e) => 
      e.state == EmotionalState.sad || e.state == EmotionalState.stressed
    ).length;

    final confidence = (lowMoodCount / historicalEvents.length).clamp(0.0, 1.0);

    if (confidence > 0.5) {
      return EmotionalPrediction(
        time: time,
        predictedState: EmotionalState.needsSupport,
        confidence: confidence,
        reason: _generateReason(dayOfWeek, hour, historicalEvents),
      );
    }

    return null;
  }

  String _generateReason(int dayOfWeek, int hour, List<EmotionalEvent> events) {
    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dayOfWeek - 1];
    final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';
    
    if (events.length >= 5) {
      return '$dayName $timeOfDay pattern detected (${events.length} similar events)';
    }
    return 'Historical pattern suggests support needed';
  }

  void _analyzePatterns() {
    _patterns.clear();
    for (int day = 1; day <= 7; day++) {
      for (int hour = 0; hour < 24; hour++) {
        final key = '${day}_$hour';
        final events = _history.where((e) => e.dayOfWeek == day && e.hourOfDay == hour).toList();
        if (events.isNotEmpty) {
          final lowMoodRate = events.where((e) => 
            e.state == EmotionalState.sad || e.state == EmotionalState.stressed
          ).length / events.length;
          _patterns[key] = [lowMoodRate, events.length.toDouble()];
        }
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('predictive_history', jsonEncode(_history.map((e) => e.toJson()).toList()));
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('predictive_history');
    if (data != null) {
      _history.clear();
      _history.addAll((jsonDecode(data) as List).map((e) => EmotionalEvent.fromJson(e)));
    }
  }
}

class EmotionalEvent {
  final EmotionalState state;
  final DateTime timestamp;
  final int dayOfWeek;
  final int hourOfDay;
  final String? trigger;

  EmotionalEvent({required this.state, required this.timestamp, required this.dayOfWeek, required this.hourOfDay, this.trigger});

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'timestamp': timestamp.toIso8601String(),
    'dayOfWeek': dayOfWeek,
    'hourOfDay': hourOfDay,
    'trigger': trigger,
  };

  factory EmotionalEvent.fromJson(Map<String, dynamic> json) => EmotionalEvent(
    state: EmotionalState.values.firstWhere((e) => e.name == json['state']),
    timestamp: DateTime.parse(json['timestamp']),
    dayOfWeek: json['dayOfWeek'],
    hourOfDay: json['hourOfDay'],
    trigger: json['trigger'],
  );
}

class EmotionalPrediction {
  final DateTime time;
  final EmotionalState predictedState;
  final double confidence;
  final String reason;

  EmotionalPrediction({required this.time, required this.predictedState, required this.confidence, required this.reason});
}

enum EmotionalState { happy, sad, stressed, calm, needsSupport, neutral }
