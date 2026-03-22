import 'dart:async';

/// Background timer loop for autonomous AI messages.
/// Generates context-aware proactive messages based on time, mood, and activity.
class ProactiveAIService {
  Timer? _timer;
  bool _isActive = false;
  Duration _interval = const Duration(hours: 2);
  DateTime _lastProactiveMessage = DateTime.now();
  Function(String type)? onProactiveMessage;

  bool get isActive => _isActive;

  void start({Duration? interval}) {
    if (_isActive) return;
    _interval = interval ?? _interval;
    _isActive = true;
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _isActive = false;
  }

  void updateInterval(Duration interval) {
    _interval = interval;
    if (_isActive) {
      stop();
      start(interval: interval);
    }
  }

  void _tick() {
    final now = DateTime.now();
    final sinceLastMsg = now.difference(_lastProactiveMessage);
    if (sinceLastMsg < _interval) return;

    _lastProactiveMessage = now;
    final messageType = _determineMessageType(now);
    onProactiveMessage?.call(messageType);
  }

  String _determineMessageType(DateTime now) {
    final hour = now.hour;
    if (hour >= 6 && hour < 9) return 'morning_greeting';
    if (hour >= 12 && hour < 14) return 'lunch_checkin';
    if (hour >= 18 && hour < 20) return 'evening_checkin';
    if (hour >= 22 || hour < 5) return 'goodnight';
    return 'general_checkin';
  }

  void dispose() {
    _timer?.cancel();
  }
}
