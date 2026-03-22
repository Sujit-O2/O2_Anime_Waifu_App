import 'package:battery_plus/battery_plus.dart';

/// Context awareness: time of day, battery, inactivity, weekend detection.
class ContextAwarenessService {
  final Battery _battery = Battery();
  String _timeOfDay = 'day';
  bool _isWeekend = false;
  double _batteryLevel = 100.0;
  bool _isCharging = false;
  DateTime _lastActivity = DateTime.now();

  String get timeOfDay => _timeOfDay;
  bool get isWeekend => _isWeekend;
  double get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;
  Duration get inactivityDuration =>
      DateTime.now().difference(_lastActivity);

  Future<void> update() async {
    final now = DateTime.now();
    _timeOfDay = _getTimeOfDay(now.hour);
    _isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    try {
      _batteryLevel = (await _battery.batteryLevel).toDouble();
      final state = await _battery.batteryState;
      _isCharging = state == BatteryState.charging ||
          state == BatteryState.full;
    } catch (_) {}
  }

  void recordActivity() {
    _lastActivity = DateTime.now();
  }

  String _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 9) return 'early_morning';
    if (hour >= 9 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 14) return 'noon';
    if (hour >= 14 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 20) return 'evening';
    if (hour >= 20 && hour < 23) return 'night';
    return 'late_night';
  }

  String toContextString() {
    final buffer = StringBuffer();
    buffer.writeln('[Context] Time: $_timeOfDay | Weekend: $_isWeekend');
    buffer.writeln(
        '[Device] Battery: ${_batteryLevel.toStringAsFixed(0)}% | Charging: $_isCharging');
    final inactiveMin = inactivityDuration.inMinutes;
    if (inactiveMin > 5) {
      buffer.writeln('[Inactivity] $inactiveMin minutes');
    }
    return buffer.toString();
  }
}
