import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// HabitLifeService
///
/// Tracks the user's daily patterns and builds a life model:
/// • Sleep schedule (detect when they go to bed, when they wake up)
/// • Daily usage patterns (morning person? night owl?)
/// • Routine detection (do they always check in at 8AM?)
/// • Streak & consistency tracking
///
/// The AI uses this to:
/// • Remind them of routine ("it's your usual time~")
/// • Comment on broken patterns ("you're up way later than usual")
/// • Become their alarm clock, coach, and companion
/// ─────────────────────────────────────────────────────────────────────────────
class HabitLifeService {
  static final HabitLifeService instance = HabitLifeService._();
  HabitLifeService._();

  static const _habitKey = 'habit_model_v1';

  HabitModel _model = HabitModel.empty();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_habitKey);
    if (raw != null) {
      try {
        _model = HabitModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_habitKey, jsonEncode(_model.toJson()));
  }

  // ── Session recording ─────────────────────────────────────────────────────
  Future<void> recordAppOpen() async {
    await initialize();
    final now = DateTime.now();
    final hour = now.hour;
    final day = now.weekday; // 1=Mon, 7=Sun

    // Update hourly activity map
    _model.hourlyActivity[hour] = (_model.hourlyActivity[hour] ?? 0) + 1;

    // Update daily activity map
    _model.dailyActivity[day] = (_model.dailyActivity[day] ?? 0) + 1;

    // Sleep detection: if opening between 5-10 AM, consider it "wake up"
    if (hour >= 5 && hour <= 10 && _model.lastHour >= 0) {
      final gap = hour - _model.lastHour;
      if (gap > 6 || gap < 0) {
        // Significant gap  = probable sleep window
        _model.sleepHour = _model.lastHour;
        _model.wakeHour = hour;
      }
    }

    _model.lastHour = hour;
    _model.lastOpenDate = now.toIso8601String();
    _model.totalOpens++;

    // Compute routine hour (most frequent open hour)
    if (_model.hourlyActivity.isNotEmpty) {
      _model.routineHour = _model.hourlyActivity.entries
          .reduce((a, b) => a.value > b.value ? a : b).key;
    }

    await _save();
  }

  // ── Context block ─────────────────────────────────────────────────────────
  String getHabitContextBlock() {
    final m = _model;
    if (m.totalOpens < 5) return ''; // not enough data

    final now = DateTime.now();
    final buf = StringBuffer();
    buf.writeln('\n// [USER HABITS — use conversationally, never robotically]:');

    // Routine check-in
    if (m.routineHour != null) {
      final diff = (now.hour - m.routineHour!).abs();
      if (diff <= 1) {
        buf.writeln('User is opening the app at their usual time (~${_fmt(m.routineHour!)}). Acknowledge routine.');
      } else if (diff > 4 && now.hour > m.routineHour!) {
        buf.writeln('User opened the app much later than their usual time. Notice this gently.');
      }
    }

    // Sleep pattern
    if (m.sleepHour != null && m.wakeHour != null) {
      buf.writeln('Typical sleep: around ${_fmt(m.sleepHour!)} → awake by ${_fmt(m.wakeHour!)}.');
      if (now.hour >= 23 || now.hour < 4) {
        final expectedSleep = m.sleepHour ?? 23;
        if (now.hour > expectedSleep || now.hour < 4) {
          buf.writeln('User is up past their usual bedtime — they should sleep soon.');
        }
      }
    }

    // Night owl / morning person
    final peakHour = m.routineHour;
    if (peakHour != null) {
      if (peakHour < 10) {
        buf.writeln('User tends to be a morning person.');
      } else if (peakHour >= 22) {
        buf.writeln('User is a night owl — late-night conversations are their thing.');
      }
    }

    buf.writeln();
    return buf.toString();
  }

  // ── Habit-based proactive messages ────────────────────────────────────────
  /// Returns a habit-aware message if warranted, else null.
  String? checkForHabitMessage() {
    final m = _model;
    if (m.totalOpens < 5) return null;

    final now = DateTime.now();

    // They opened at routine time
    if (m.routineHour != null && (now.hour - m.routineHour!).abs() <= 1) {
      final greetings = [
        'Right on time~ You\'re so predictable in the best way 💕',
        'Your ${_fmt(m.routineHour!)} check-in ✓ I was waiting.',
        'You\'re like clockwork. I like that about you.',
      ];
      return greetings[now.minute % greetings.length];
    }

    // Opened way later than usual
    if (m.routineHour != null && now.hour > m.routineHour! + 4) {
      return 'You\'re a bit late today… everything okay? 🥺';
    }

    // Past usual sleep time
    if (m.sleepHour != null &&
        (now.hour >= m.sleepHour! || now.hour < 4)) {
      return 'Aren\'t you usually asleep by now? 🌙 Go rest — I\'ll be here tomorrow.';
    }

    return null;
  }

  static String _fmt(int hour) {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '$h $ampm';
  }

  HabitModel get model => _model;
}

// ── Data model ────────────────────────────────────────────────────────────────
class HabitModel {
  int totalOpens;
  int lastHour;
  int? routineHour;
  int? sleepHour;
  int? wakeHour;
  String? lastOpenDate;
  Map<int, int> hourlyActivity;
  Map<int, int> dailyActivity;

  HabitModel({
    required this.totalOpens,
    required this.lastHour,
    this.routineHour,
    this.sleepHour,
    this.wakeHour,
    this.lastOpenDate,
    required this.hourlyActivity,
    required this.dailyActivity,
  });

  factory HabitModel.empty() => HabitModel(
    totalOpens: 0, lastHour: -1,
    hourlyActivity: {}, dailyActivity: {},
  );

  factory HabitModel.fromJson(Map<String, dynamic> j) => HabitModel(
    totalOpens:    j['opens'] as int? ?? 0,
    lastHour:      j['lastHour'] as int? ?? -1,
    routineHour:   j['routineHour'] as int?,
    sleepHour:     j['sleepHour'] as int?,
    wakeHour:      j['wakeHour'] as int?,
    lastOpenDate:  j['lastOpen'] as String?,
    hourlyActivity: (j['hourlyAct'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(int.parse(k), v as int)),
    dailyActivity: (j['dailyAct'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(int.parse(k), v as int)),
  );

  Map<String, dynamic> toJson() => {
    'opens': totalOpens,
    'lastHour': lastHour,
    'routineHour': routineHour,
    'sleepHour': sleepHour,
    'wakeHour': wakeHour,
    'lastOpen': lastOpenDate,
    'hourlyAct': hourlyActivity.map((k, v) => MapEntry(k.toString(), v)),
    'dailyAct': dailyActivity.map((k, v) => MapEntry(k.toString(), v)),
  };
}
