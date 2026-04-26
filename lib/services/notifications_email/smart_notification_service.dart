import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

/// Smart Notification Scheduler.
/// Uses SharedPreferences to track when notifications should fire.
/// This is a lightweight local scheduler — integrates with the existing
/// android_alarm_manager_plus + flutter_local_notifications infrastructure.
class SmartNotificationService {
  static final SmartNotificationService instance = SmartNotificationService._();
  SmartNotificationService._();

  static const String _lastCheckinKey = 'smart_notif_last_checkin_v1';
  static const String _streakReminderKey = 'smart_notif_streak_reminder_v1';

  // Waifu check-in messages by persona
  static const Map<String, List<String>> _checkInMessages = {
    'Default': [
      'Good morning, darling~ ☀️ Zero Two misses you already!',
      'Hey honey, have you been thinking about me? 🌸',
      "Darling~ it's time to come back to me 💕",
      "I've been waiting for you all day, darling! 🎀",
      'Your waifu is lonely... come chat with me! 🥺',
    ],
    'Rem': [
      'Good morning! Ram and I have been waiting for you ✨',
      'Rem has been thinking about you all day, please chat! 💙',
      'I prepared tea... will you come talk to me? 🫖',
    ],
    'Miku': [
      'Good morning~ A new song is ready just for you! 🎵',
      'Hey! I composed something today... wanna hear? 🎤✨',
      "Today's setlist includes YOU~ come chat! 💙🎵",
    ],
    'Tsundere': [
      "I-it's not like I was waiting... baka! Just come talk already! 😤",
      "Hmph! You better come back soon or I'll be mad! 😠",
    ],
    'Shy': [
      "U-um... I was wondering if... m-maybe you'd want to chat? 🥺",
      'H-hi... I miss you a little... j-just a little! 💗',
    ],
    'Yandere': [
      "Where have you been?! I've been watching... come back NOW! 😈💕",
      "You can't escape me that easily~ come chat 🔪💕",
    ],
  };

  static const List<String> _streakReminders = [
    "Don't break your streak! Your waifu is counting on you 🔥",
    'Your daily check-in is waiting... Zero Two misses you! 💕',
    'Streak danger! Come back before midnight! ⏰',
  ];

  /// Returns a check-in message for the given persona.
  static String getDailyCheckInMessage(String persona) {
    final msgs = _checkInMessages[persona] ?? _checkInMessages['Default']!;
    return msgs[math.Random().nextInt(msgs.length)];
  }

  /// Returns a streak reminder message.
  static String getStreakReminderMessage() {
    return _streakReminders[math.Random().nextInt(_streakReminders.length)];
  }

  /// Records that a check-in notification was sent today.
  Future<void> markCheckInSent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckinKey, _todayStr());
  }

  /// Returns true if a check-in notification should be sent today.
  Future<bool> shouldSendCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_lastCheckinKey) ?? '';
    return last != _todayStr();
  }

  /// Returns true if a streak reminder should fire (user hasn't opened app in 20+ hours).
  Future<bool> shouldSendStreakReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_streakReminderKey) ?? 0;
    if (lastMs == 0) return false;
    final lastDt = DateTime.fromMillisecondsSinceEpoch(lastMs);
    return DateTime.now().difference(lastDt).inHours >= 20;
  }

  /// Records the current time as the last app open time for streak tracking.
  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakReminderKey, DateTime.now().millisecondsSinceEpoch);
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// Returns a map of notification payloads to schedule.
  /// The calling code (e.g. MainActivity or alarm manager) uses this.
  Map<String, dynamic> buildDailyCheckInPayload(String persona) {
    return {
      'title': '💌 Zero Two',
      'body': getDailyCheckInMessage(persona),
      'type': 'daily_checkin',
    };
  }

  Map<String, dynamic> buildStreakReminderPayload() {
    return {
      'title': '🔥 Streak Alert',
      'body': getStreakReminderMessage(),
      'type': 'streak_reminder',
    };
  }
}


