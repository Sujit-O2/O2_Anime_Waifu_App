import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles setting native Android alarms through the alarm manager plugin.
class WaifuAlarmService {
  static const int _alarmId = 42; // fixed ID for waifu alarm

  /// Parses time like "7 AM", "07:30", "7:30 PM" from user text.
  static DateTime? parseTime(String text) {
    // Match "7 AM", "7:30 AM", "07:30", "19:00"
    final regexAmPm =
        RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(AM|PM)', caseSensitive: false);
    final regex24 = RegExp(r'\b(\d{1,2}):(\d{2})\b');

    final now = DateTime.now();

    final amPmMatch = regexAmPm.firstMatch(text);
    if (amPmMatch != null) {
      int hour = int.parse(amPmMatch.group(1)!);
      final min = int.tryParse(amPmMatch.group(2) ?? '0') ?? 0;
      final amPm = amPmMatch.group(3)!.toUpperCase();
      if (amPm == 'PM' && hour != 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;
      var alarm = DateTime(now.year, now.month, now.day, hour, min);
      if (alarm.isBefore(now)) alarm = alarm.add(const Duration(days: 1));
      return alarm;
    }

    final match24 = regex24.firstMatch(text);
    if (match24 != null) {
      final hour = int.parse(match24.group(1)!);
      final min = int.parse(match24.group(2)!);
      var alarm = DateTime(now.year, now.month, now.day, hour, min);
      if (alarm.isBefore(now)) alarm = alarm.add(const Duration(days: 1));
      return alarm;
    }
    return null;
  }

  /// Sets an alarm for the given [time] and stores the persona name.
  static Future<String> setAlarm(DateTime time, String persona) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_persona', persona);
      await prefs.setString('alarm_time', time.toIso8601String());

      await AndroidAlarmManager.oneShotAt(
        time,
        _alarmId,
        _alarmCallback,
        exact: true,
        wakeup: true,
      );

      final hhmm =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      return "⏰ Alarm set for **$hhmm**! I'll wake you up then, darling~ 💕";
    } catch (e) {
      debugPrint('Alarm error: $e');
      return "❌ Couldn't set the alarm. Make sure you allowed the app to schedule alarms in settings.";
    }
  }

  @pragma('vm:entry-point')
  static void _alarmCallback() {
    // This runs in background — trigger a local notification.
    // The actual TTS is done when the app is foregrounded from the notification.
    debugPrint('WaifuAlarm: callback triggered!');
  }
}
