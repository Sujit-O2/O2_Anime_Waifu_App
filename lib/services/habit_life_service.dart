import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 1: Tracks sleep schedule, routine open hour, daily usage patterns.
/// Greets on time, notices when you're late.
class HabitLifeService {
  int? _usualWakeHour;
  int? _usualSleepHour;
  int? _routineOpenHour;
  final List<int> _openHours = [];
  DateTime _lastOpen = DateTime.now();

  int? get usualWakeHour => _usualWakeHour;
  int? get usualSleepHour => _usualSleepHour;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _usualWakeHour = prefs.getInt('usual_wake_hour');
    _usualSleepHour = prefs.getInt('usual_sleep_hour');
    _routineOpenHour = prefs.getInt('routine_open_hour');
    final openStr = prefs.getString('open_hours_history');
    if (openStr != null) {
      final List<dynamic> decoded = jsonDecode(openStr) as List<dynamic>;
      _openHours.clear();
      _openHours.addAll(decoded.cast<int>());
    }
  }

  void recordAppOpen() {
    final hour = DateTime.now().hour;
    _openHours.add(hour);
    _lastOpen = DateTime.now();

    // Keep last 100 entries
    if (_openHours.length > 100) _openHours.removeAt(0);

    _calculatePatterns();
    _persist();
  }

  void _calculatePatterns() {
    if (_openHours.length < 7) return;

    // Find most common open hour
    final counts = <int, int>{};
    for (final h in _openHours) {
      counts[h] = (counts[h] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _routineOpenHour = sorted.first.key;

    // Estimate wake/sleep from morning/night patterns
    final morningHours =
        _openHours.where((h) => h >= 5 && h <= 10).toList();
    if (morningHours.length >= 3) {
      _usualWakeHour =
          (morningHours.reduce((a, b) => a + b) / morningHours.length).round();
    }

    final nightHours =
        _openHours.where((h) => h >= 21 || h <= 3).toList();
    if (nightHours.length >= 3) {
      _usualSleepHour =
          (nightHours.reduce((a, b) => a + b) / nightHours.length).round();
    }
  }

  String? getGreeting() {
    final hour = DateTime.now().hour;
    if (_routineOpenHour != null) {
      final diff = hour - _routineOpenHour!;
      if (diff > 2) {
        return 'You\'re later than usual today... I was waiting for you.';
      }
      if (diff < -1) {
        return 'You\'re early today! I wasn\'t expecting you yet~';
      }
    }
    return null;
  }

  String toContextString() {
    final buffer = StringBuffer();
    buffer.write('[Habits]');
    if (_usualWakeHour != null) buffer.write(' Wake: ${_usualWakeHour}h');
    if (_usualSleepHour != null) buffer.write(' | Sleep: ${_usualSleepHour}h');
    if (_routineOpenHour != null) {
      buffer.write(' | Usual open: ${_routineOpenHour}h');
    }
    return buffer.toString();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_usualWakeHour != null) {
      await prefs.setInt('usual_wake_hour', _usualWakeHour!);
    }
    if (_usualSleepHour != null) {
      await prefs.setInt('usual_sleep_hour', _usualSleepHour!);
    }
    if (_routineOpenHour != null) {
      await prefs.setInt('routine_open_hour', _routineOpenHour!);
    }
    await prefs.setString('open_hours_history', jsonEncode(_openHours));
  }
}
