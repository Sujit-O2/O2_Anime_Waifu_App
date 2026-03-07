import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderItem {
  final String id;
  final String text;
  final DateTime triggerAt;
  final bool fired;

  ReminderItem({
    required this.id,
    required this.text,
    required this.triggerAt,
    this.fired = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'triggerAt': triggerAt.toIso8601String(),
        'fired': fired,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> map) => ReminderItem(
        id: map['id'] as String,
        text: map['text'] as String,
        triggerAt: DateTime.parse(map['triggerAt'] as String),
        fired: map['fired'] as bool? ?? false,
      );
}

/// Manages reminders stored locally. Uses platform channel for scheduling.
class ReminderService {
  static const MethodChannel _channel =
      MethodChannel('anime_waifu/assistant_mode');
  static const String _prefKey = 'assistant_reminders_v1';

  /// Schedule a reminder [delayMinutes] from now with [text].
  static Future<String> scheduleReminder({
    required String text,
    required int delayMinutes,
  }) async {
    if (delayMinutes <= 0) return 'Delay must be at least 1 minute.';
    final triggerAt = DateTime.now().add(Duration(minutes: delayMinutes));
    final id = 'rem_${DateTime.now().millisecondsSinceEpoch}';

    final item = ReminderItem(id: id, text: text, triggerAt: triggerAt);
    await _saveReminder(item);

    // Request Android notification scheduling via platform channel
    try {
      await _channel.invokeMethod('scheduleReminder', {
        'id': id,
        'text': text,
        'delayMs': delayMinutes * 60 * 1000,
      });
    } catch (_) {
      // Non-fatal: reminder is stored, native scheduling best-effort
    }

    final h = delayMinutes ~/ 60;
    final m = delayMinutes % 60;
    final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
    return 'Reminder set for $text in $timeStr.';
  }

  static Future<void> _saveReminder(ReminderItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    final List<dynamic> list = raw != null ? jsonDecode(raw) as List : [];
    list.add(item.toJson());
    await prefs.setString(_prefKey, jsonEncode(list));
  }

  static Future<List<ReminderItem>> getAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> clearFired() async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllReminders();
    final pending = all.where((r) => !r.fired).toList();
    await prefs.setString(
        _prefKey, jsonEncode(pending.map((r) => r.toJson()).toList()));
  }

  /// Parse delay from natural language like "in 30 minutes", "in 2 hours"
  static int? parseDelayMinutes(String input) {
    final s = input.toLowerCase().trim();
    // "in X minutes/hours"
    final mMins = RegExp(r'(\d+)\s*min').firstMatch(s);
    final mHours = RegExp(r'(\d+)\s*hour').firstMatch(s);
    int mins = 0;
    if (mHours != null) mins += int.parse(mHours.group(1)!) * 60;
    if (mMins != null) mins += int.parse(mMins.group(1)!);
    return mins > 0 ? mins : null;
  }
}
