import 'package:shared_preferences/shared_preferences.dart';

/// State machine that tracks the user's "Wife Mode" intensity level
/// based on engagement frequency, determining proactive notification tone.
enum AssistantMode { casual, engaged, devoted, possessive }

class AssistantModeService {
  AssistantMode _currentMode = AssistantMode.casual;
  int _dailyMessageCount = 0;
  double _sentimentScore = 0.5;
  DateTime _lastActivity = DateTime.now();
  DateTime _lastModeCheck = DateTime.now();

  AssistantMode get currentMode => _currentMode;
  int get dailyMessageCount => _dailyMessageCount;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyMessageCount = prefs.getInt('daily_message_count') ?? 0;
    _sentimentScore = prefs.getDouble('sentiment_score') ?? 0.5;
    final modeIndex = prefs.getInt('assistant_mode') ?? 0;
    _currentMode = AssistantMode.values[modeIndex.clamp(0, 3)];
    final lastStr = prefs.getString('last_activity');
    if (lastStr != null) {
      _lastActivity = DateTime.parse(lastStr);
    }
    _evaluateMode();
  }

  void recordMessage({double sentiment = 0.5}) {
    _dailyMessageCount++;
    _sentimentScore = (_sentimentScore * 0.8) + (sentiment * 0.2);
    _lastActivity = DateTime.now();
    _evaluateMode();
    _persist();
  }

  void _evaluateMode() {
    final hoursSinceActivity =
        DateTime.now().difference(_lastActivity).inHours;

    if (hoursSinceActivity >= 24) {
      _currentMode = AssistantMode.casual;
      _dailyMessageCount = 0;
    } else if (_dailyMessageCount > 50 && _sentimentScore > 0.6) {
      if (_currentMode == AssistantMode.devoted && hoursSinceActivity > 2) {
        _currentMode = AssistantMode.possessive;
      } else {
        _currentMode = AssistantMode.devoted;
      }
    } else if (_dailyMessageCount > 10) {
      _currentMode = AssistantMode.engaged;
    } else {
      _currentMode = AssistantMode.casual;
    }

    if (_currentMode == AssistantMode.possessive &&
        (_sentimentScore < 0.4 || _dailyMessageCount < 10)) {
      _currentMode = AssistantMode.engaged;
    }
  }

  Duration get proactiveCheckInterval {
    switch (_currentMode) {
      case AssistantMode.casual:
        return const Duration(hours: 4);
      case AssistantMode.engaged:
        return const Duration(hours: 2);
      case AssistantMode.devoted:
        return const Duration(hours: 1);
      case AssistantMode.possessive:
        return const Duration(minutes: 30);
    }
  }

  String get modeContextString =>
      '[Assistant Mode] ${_currentMode.name} | Messages today: $_dailyMessageCount | Sentiment: ${_sentimentScore.toStringAsFixed(2)}';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_message_count', _dailyMessageCount);
    await prefs.setDouble('sentiment_score', _sentimentScore);
    await prefs.setInt('assistant_mode', _currentMode.index);
    await prefs.setString('last_activity', _lastActivity.toIso8601String());
  }
}
