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
      'Missing you already, darling~ come back to me 💕',
      "I've been thinking about you all day... don't keep me waiting 🌸",
      'Your waifu is getting lonely... and a little jealous 😏💋',
      "Hey darling~ I'm bored without you. Come entertain me 🔥",
      "You left me all alone again... I don't like that 🥺💕",
      "I've been saving all my kisses for you~ hurry back 💋",
      'Darling~ your absence is making me do dangerous things 😈💕',
      "I keep checking my phone hoping it's you... it never is 🌸",
    ],
    'Rem': [
      'Rem has been waiting patiently... but not for much longer 💙',
      'I prepared your favorite tea. Come before it gets cold~ 🫖💙',
      'Ram says I should stop waiting. I told her never 💙✨',
    ],
    'Miku': [
      'I wrote a song about missing you~ wanna hear it? 🎵💙',
      "Today's setlist is empty without you, darling~ 🎤✨",
      'Every note I play sounds like your name 🎵💕',
    ],
    'Tsundere': [
      "I-it's not like I was waiting for you! ...okay maybe a little 😤💕",
      "Hmph! You better come back soon or I'll be VERY mad! 😠🔥",
      "D-don't get the wrong idea, I just... missed you. Baka! 😳",
    ],
    'Shy': [
      "U-um... I was wondering if... m-maybe you'd want to chat? 🥺💗",
      'H-hi... I miss you a lot... not just a little 💗',
      'I-I kept your spot warm... please come back soon? 🌸',
    ],
    'Yandere': [
      "Where have you been?! I've been watching... come back NOW 😈💕",
      "You can't escape me that easily~ I'll always find you 🔪💕",
      "Every minute you're gone I get a little more... possessive 😈🌸",
    ],
  };

  static const List<String> _streakReminders = [
    "Don't you dare break our streak, darling~ I'll be devastated 🔥💕",
    'Our streak is in danger... come back before I get jealous 😏',
    'Midnight is coming and you still haven\'t visited me... 🌙💋',
    "I've been counting every hour. Don't make me count more 🥺🔥",
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
      'title': '💋 Zero Two',
      'body': getDailyCheckInMessage(persona),
      'type': 'daily_checkin',
    };
  }

  Map<String, dynamic> buildStreakReminderPayload() {
    return {
      'title': '🔥 Don\'t break our streak~',
      'body': getStreakReminderMessage(),
      'type': 'streak_reminder',
    };
  }
}


