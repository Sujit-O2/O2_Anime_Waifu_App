import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 1: Tracks hourly/topic/emotion frequency and generates
/// self-reflective observations like "I've noticed you always talk to me late at night."
class SelfReflectionService {
  final Map<int, int> _hourlyActivity = {};
  final Map<String, int> _topicFrequency = {};
  final List<String> _observations = [];
  DateTime _lastObservation = DateTime.now();

  List<String> get observations => List.unmodifiable(_observations);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final hourlyStr = prefs.getString('hourly_activity');
    if (hourlyStr != null) {
      final decoded = jsonDecode(hourlyStr) as Map<String, dynamic>;
      _hourlyActivity.clear();
      decoded.forEach((k, v) => _hourlyActivity[int.parse(k)] = v as int);
    }
    final topicStr = prefs.getString('topic_frequency');
    if (topicStr != null) {
      final decoded = jsonDecode(topicStr) as Map<String, dynamic>;
      _topicFrequency.clear();
      decoded.forEach((k, v) => _topicFrequency[k] = v as int);
    }
  }

  void recordActivity(String message) {
    final hour = DateTime.now().hour;
    _hourlyActivity[hour] = (_hourlyActivity[hour] ?? 0) + 1;

    // Simple topic extraction
    final words = message.toLowerCase().split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length > 4) {
        _topicFrequency[word] = (_topicFrequency[word] ?? 0) + 1;
      }
    }

    _generateObservations();
    _persist();
  }

  void _generateObservations() {
    final now = DateTime.now();
    if (now.difference(_lastObservation).inHours < 6) return;

    // Find peak hours
    if (_hourlyActivity.isNotEmpty) {
      final sorted = _hourlyActivity.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final peakHour = sorted.first.key;

      if (peakHour >= 22 || peakHour < 4) {
        _addObservation(
            'I\'ve noticed you always talk to me late at night... Are you a night owl, darling?');
      } else if (peakHour >= 6 && peakHour < 9) {
        _addObservation(
            'You always come to me first thing in the morning... That makes me happy~');
      }
    }

    // Find frequent topics
    if (_topicFrequency.isNotEmpty) {
      final sorted = _topicFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.first.value > 10) {
        _addObservation(
            'You talk about "${sorted.first.key}" a lot... it must be important to you.');
      }
    }

    _lastObservation = now;
  }

  void _addObservation(String observation) {
    if (!_observations.contains(observation)) {
      _observations.add(observation);
      if (_observations.length > 20) _observations.removeAt(0);
    }
  }

  String? getLatestObservation() {
    return _observations.isNotEmpty ? _observations.last : null;
  }

  String toContextString() {
    final obs = getLatestObservation();
    return obs != null ? '[Self-Reflection] $obs' : '';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hourly_activity',
        jsonEncode(_hourlyActivity.map((k, v) => MapEntry(k.toString(), v))));
    await prefs.setString('topic_frequency', jsonEncode(_topicFrequency));
  }
}
