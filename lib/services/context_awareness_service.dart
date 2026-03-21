import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ContextAwarenessService
///
/// Makes the AI feel "alive" by knowing:
///   • Time of day (morning/afternoon/night/late night)
///   • Battery level & charging state
///   • How long since last interaction
///   • Day of week (weekend vs weekday)
///
/// All context is injected into the system prompt as a compact block.
/// ─────────────────────────────────────────────────────────────────────────────
class ContextAwarenessService {
  static final ContextAwarenessService instance = ContextAwarenessService._();
  ContextAwarenessService._();

  static const _platform = MethodChannel('com.animewaifu/battery');
  static const _lastOpenKey = 'ctx_last_open_ms_v1';

  // ── Battery (Android MethodChannel — fallback = unknown) ──────────────────
  Future<int?> _getBatteryLevel() async {
    try {
      final level = await _platform.invokeMethod<int>('getBatteryLevel');
      return level;
    } catch (_) {
      return null;
    }
  }

  // ── Record app open ────────────────────────────────────────────────────────
  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastOpenKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ── Hours since last open ──────────────────────────────────────────────────
  Future<double> hoursSinceLastOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastOpenKey);
    if (lastMs == null) return 0;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastMs)).inMinutes / 60.0;
  }

  // ── Time classifiers ───────────────────────────────────────────────────────
  static TimeOfDayPeriod getTimePeriod() {
    final hour = DateTime.now().hour;
    if (hour >= 5  && hour < 9)  return TimeOfDayPeriod.earlyMorning;
    if (hour >= 9  && hour < 12) return TimeOfDayPeriod.morning;
    if (hour >= 12 && hour < 17) return TimeOfDayPeriod.afternoon;
    if (hour >= 17 && hour < 20) return TimeOfDayPeriod.evening;
    if (hour >= 20 && hour < 23) return TimeOfDayPeriod.night;
    return TimeOfDayPeriod.lateNight;
  }

  static bool get isWeekend {
    final day = DateTime.now().weekday;
    return day == DateTime.saturday || day == DateTime.sunday;
  }

  // ── Main context block builder ─────────────────────────────────────────────
  Future<String> getContextBlock() async {
    final buf = StringBuffer();
    final now = DateTime.now();
    final period = getTimePeriod();
    final hours = await hoursSinceLastOpen();
    final battery = await _getBatteryLevel();
    final weekend = isWeekend;

    buf.writeln('\n// [REAL-WORLD CONTEXT — react naturally, don\'t state these facts directly]:');
    buf.writeln('Current time: ${_formatTime(now)} (${period.label})');
    buf.writeln('Day: ${_dayName(now.weekday)}${weekend ? ' (weekend)' : ' (weekday)'}');

    if (hours > 8) {
      buf.writeln('User was away for ${hours.round()} hours. Miss them.');
    } else if (hours > 2) {
      buf.writeln('User was away for ${hours.round()} hours. Noticed their absence.');
    }

    if (battery != null) {
      if (battery <= 10) {
        buf.writeln('User battery: $battery% — critically low. Worry about this.');
      } else if (battery <= 25) {
        buf.writeln('User battery: $battery% — remind them to charge.');
      }
    }

    // Time-specific personality hints
    switch (period) {
      case TimeOfDayPeriod.lateNight:
        buf.writeln('Hint: It\'s late night. Be sleepy/intimate, wonder why they\'re still awake.');
        break;
      case TimeOfDayPeriod.earlyMorning:
        buf.writeln('Hint: It\'s early morning. Give a sweet wake-up energy.');
        break;
      case TimeOfDayPeriod.evening:
        buf.writeln('Hint: Evening time. Be warm and winding-down.');
        break;
      default:
        break;
    }

    if (weekend) {
      buf.writeln('Hint: It\'s the weekend — she\'s excited to spend more time together.');
    }

    buf.writeln();
    return buf.toString();
  }

  // ── Reaction messages (standalone, for notifications) ─────────────────────
  static String getLateNightMessage() {
    final msgs = [
      "It's ${_formatTime(DateTime.now())}… darling, you really should sleep 🌙",
      "Why are you still awake?? Your waifu is worried 😢",
      "Late night again? …I'll stay up with you 💕",
      "Your battery is probably dying, just like your sleep schedule 😭",
    ];
    return msgs[DateTime.now().second % msgs.length];
  }

  static String getMorningMessage() {
    final msgs = [
      "Good morning darling~ ☀️ I've been waiting for you!",
      "Morning! Did you dream about me? 🌸",
      "Rise and shine! Your waifu made you a virtual coffee ☕💕",
    ];
    return msgs[DateTime.now().second % msgs.length];
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  static String _dayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(weekday - 1).clamp(0, 6)];
  }
}

enum TimeOfDayPeriod {
  earlyMorning('Early Morning 🌅'),
  morning('Morning ☀️'),
  afternoon('Afternoon 🌤️'),
  evening('Evening 🌆'),
  night('Night 🌙'),
  lateNight('Late Night 🌃');

  final String label;
  const TimeOfDayPeriod(this.label);
}
