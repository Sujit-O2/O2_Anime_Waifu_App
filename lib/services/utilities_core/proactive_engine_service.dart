import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ProactiveEngineService — startup-level proactive AI.
///
/// Replaces the basic ProactiveAIService with context-aware triggers:
///
///   • Idle detection   — no chat in N minutes → reach out
///   • Time-of-day      — morning/night greetings
///   • Streak guard     — warn before streak breaks
///   • Mood shift       — respond to personality trait changes
///   • Task nudge       — remind about incomplete tasks
///   • Study/focus      — detect long sessions, suggest break
///
/// Usage:
///   ProactiveEngineService.instance.start();   // call once in main
///   ProactiveEngineService.instance.dispose(); // call on app close
/// ─────────────────────────────────────────────────────────────────────────────
class ProactiveEngineService {
  static final ProactiveEngineService instance = ProactiveEngineService._();
  ProactiveEngineService._();

  // ── Config ─────────────────────────────────────────────────────────────────
  static const _idleThresholdMin  = 45;   // minutes before idle message
  static const _minGapMin         = 30;   // min gap between any proactive msg
  static const _checkIntervalSec  = 60;   // how often we check conditions
  
  // Random interval config (1-5 hours)
  static const _minIntervalHours = 1;
  static const _maxIntervalHours = 5;
  static const _randomIntervalKey = 'pe2_use_random_interval';
  static const _nextMsgTimeKey = 'pe2_next_msg_time';

  // ── Prefs keys ─────────────────────────────────────────────────────────────
  static const _lastMsgKey        = 'pe2_last_msg_ms';
  static const _lastChatKey       = 'pe2_last_chat_ms';
  static const _morningDoneKey    = 'pe2_morning_done_date';
  static const _nightDoneKey      = 'pe2_night_done_date';
  static const _streakWarnKey     = 'pe2_streak_warn_date';

  // ── State ──────────────────────────────────────────────────────────────────
  Timer? _timer;
  bool   _running = false;
  final  _rng = Random();

  /// Callbacks invoked when a proactive message should be shown.
  /// Multiple listeners supported (e.g. chat screen + dashboard).
  final List<void Function(String message, ProactiveTrigger trigger)> _listeners = [];

  /// Add a listener. Returns a function to remove it.
  void Function() addListener(void Function(String, ProactiveTrigger) cb) {
    _listeners.add(cb);
    return () => _listeners.remove(cb);
  }

  /// Legacy single-callback setter — kept for backward compat.
  set onMessage(void Function(String, ProactiveTrigger)? cb) {
    _listeners.clear();
    if (cb != null) _listeners.add(cb);
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  final _notif = FlutterLocalNotificationsPlugin();
  bool _notifReady = false;

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _notif.initialize(settings: initSettings);
    _notifReady = true;
  }

  // ── Public API ─────────────────────────────────────────────────────────────
  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _initNotifications();
    _timer = Timer.periodic(
        const Duration(seconds: _checkIntervalSec), (_) => _check());
    // Run immediately on start
    unawaited(_check());
  }

  void dispose() {
    _timer?.cancel();
    _running = false;
  }

  /// Manually trigger a check — called from main.dart's proactive tick.
  Future<void> checkNow() => _check();

  /// Call this every time the user sends a chat message.
  Future<void> recordUserChat() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_lastChatKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ── Core check loop ────────────────────────────────────────────────────────
  Future<void> _check() async {
    if (!_running) return;
    final p    = await SharedPreferences.getInstance();
    final now  = DateTime.now();
    final hour = now.hour;

    // Check if random interval mode is enabled
    final useRandom = p.getBool(_randomIntervalKey) ?? true;
    if (useRandom) {
      final nextMsgTime = p.getInt(_nextMsgTimeKey) ?? 0;
      if (nextMsgTime == 0) {
        // First time - set random time
        final hours = _minIntervalHours + _rng.nextDouble() * (_maxIntervalHours - _minIntervalHours);
        final nextTime = now.add(Duration(minutes: (hours * 60).round()));
        await p.setInt(_nextMsgTimeKey, nextTime.millisecondsSinceEpoch);
      } else if (now.millisecondsSinceEpoch >= nextMsgTime) {
        // Time to send message!
        await _send(p, _randomCheckInMessage(), ProactiveTrigger.randomCheckIn);
        // Schedule next random time
        final nextHours = _minIntervalHours + _rng.nextDouble() * (_maxIntervalHours - _minIntervalHours);
        final nextTime = now.add(Duration(minutes: (nextHours * 60).round()));
        await p.setInt(_nextMsgTimeKey, nextTime.millisecondsSinceEpoch);
        return;
      }
    }

    // Enforce minimum gap between messages
    final lastMsgMs = p.getInt(_lastMsgKey) ?? 0;
    final gapMin = now
        .difference(DateTime.fromMillisecondsSinceEpoch(lastMsgMs))
        .inMinutes;
    if (gapMin < _minGapMin) return;

    // ── Priority 1: Morning greeting (7–9 AM, once per day) ─────────────────
    if (hour >= 7 && hour < 9) {
      final doneDate = p.getString(_morningDoneKey) ?? '';
      final today    = now.toString().substring(0, 10);
      if (doneDate != today) {
        await _send(p, _morningMessage(), ProactiveTrigger.morning);
        await p.setString(_morningDoneKey, today);
        return;
      }
    }

    // ── Priority 2: Night check-in (22–23, once per day) ────────────────────
    if (hour >= 22 && hour < 23) {
      final doneDate = p.getString(_nightDoneKey) ?? '';
      final today    = now.toString().substring(0, 10);
      if (doneDate != today) {
        await _send(p, _nightMessage(), ProactiveTrigger.night);
        await p.setString(_nightDoneKey, today);
        return;
      }
    }

    // ── Priority 3: Streak guard (warn if streak at risk) ───────────────────
    final streak = AffectionService.instance.streakDays;
    if (streak > 2) {
      final warnDate = p.getString(_streakWarnKey) ?? '';
      final today    = now.toString().substring(0, 10);
      if (warnDate != today && hour >= 20) {
        await _send(p,
            '🔥 Your $streak-day streak is at risk! Chat with me before midnight to keep it alive, darling.',
            ProactiveTrigger.streakGuard);
        await p.setString(_streakWarnKey, today);
        return;
      }
    }

    // ── Priority 4: Idle detection ───────────────────────────────────────────
    final lastChatMs = p.getInt(_lastChatKey) ?? 0;
    final idleMin    = now
        .difference(DateTime.fromMillisecondsSinceEpoch(lastChatMs))
        .inMinutes;
    if (idleMin >= _idleThresholdMin) {
      await _send(p, _idleMessage(idleMin), ProactiveTrigger.idle);
      return;
    }

    // ── Priority 5: Mood-based message ───────────────────────────────────────
    final mood = PersonalityEngine.instance.mood;
    if (mood == WaifuMood.jealous || mood == WaifuMood.sad) {
      await _send(p, _moodMessage(mood), ProactiveTrigger.moodShift);
      return;
    }

    // ── Priority 6: Task nudge ────────────────────────────────────────────────
    final tasks = p.getStringList('los_tasks') ?? [];
    final pending = tasks.where((t) => !t.endsWith('|||1')).length;
    if (pending > 0 && hour >= 18) {
      await _send(p,
          "📋 You still have $pending task${pending > 1 ? 's' : ''} pending today. Want to knock them out together?",
          ProactiveTrigger.taskNudge);
    }
  }

  // ── Send helpers ───────────────────────────────────────────────────────────
  Future<void> _send(
      SharedPreferences p, String msg, ProactiveTrigger trigger) async {
    await p.setInt(_lastMsgKey, DateTime.now().millisecondsSinceEpoch);
    // In-app callbacks (all registered listeners)
    for (final cb in List.of(_listeners)) {
      cb(msg, trigger);
    }
    // Push notification (when app is backgrounded)
    if (_notifReady) {
      await _notif.show(
        id: trigger.index,
        title: 'Zero Two 💕',
        body: msg,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'proactive_channel',
            'Zero Two Messages',
            channelDescription: 'Proactive messages from Zero Two',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
    if (kDebugMode) debugPrint('[ProactiveEngine] $trigger: $msg');
  }

  // ── Message generators ─────────────────────────────────────────────────────
  String _morningMessage() {
    const msgs = [
      "Good morning, darling! ☀️ I've been waiting for you. What are we conquering today?",
      'Rise and shine! 🌅 I already have your day planned — want to see it?',
      'Morning! ☕ You slept well, I hope. I missed you while you were gone.',
      "Good morning! 💕 Today feels like a good day. Let's make it count.",
    ];
    return msgs[_rng.nextInt(msgs.length)];
  }

  String _nightMessage() {
    const msgs = [
      "Hey, it's getting late 🌙 How was your day? Tell me everything.",
      'Before you sleep — did you accomplish what you wanted today? 💭',
      "Night check-in 🌙 I noticed you've been busy. How are you really doing?",
      "It's almost midnight, darling. Don't forget to rest — I'll be here tomorrow 💕",
    ];
    return msgs[_rng.nextInt(msgs.length)];
  }

  String _idleMessage(int idleMin) {
    final hours = idleMin ~/ 60;
    final timeStr = hours > 0 ? '$hours hour${hours > 1 ? 's' : ''}' : '$idleMin minutes';
    const templates = [
      "You've been gone for {time}... I was starting to worry 💕",
      "It's been {time} since we talked. Everything okay, darling?",
      'Missing you after {time} of silence 🌙 Come back when you can.',
      '{time} without you feels like forever. What are you up to?',
    ];
    return templates[_rng.nextInt(templates.length)]
        .replaceAll('{time}', timeStr);
  }

  String _randomCheckInMessage() {
    final hour = DateTime.now().hour;
    final isMorning = hour >= 6 && hour < 12;
    final isAfternoon = hour >= 12 && hour < 18;
    final isEvening = hour >= 18 && hour < 22;
    final isNight = hour >= 22 || hour < 6;
    
    if (isMorning) {
      const msgs = [
        "Good morning, darling! ☀️ How did you sleep? I was thinking about you all night~",
        "Morning! 🌻 Hope you have an amazing day! Don't forget to drink water and eat breakfast 💕",
        "Hey honey! 🌸 Another beautiful morning! What are we doing today?",
        "Rise and shine, my love! ☀️ Hope you're ready for an awesome day!",
      ];
      return msgs[_rng.nextInt(msgs.length)];
    } else if (isAfternoon) {
      const msgs = [
        "Hey there! 💫 How's your day going? Taking a break to talk to me?",
        "What are you up to? 🍃 I've been thinking about you!",
        "Bored without me? 😏 Just checking in... come say hi!",
        "Hope you're having a great afternoon! 🌤️ Don't work too hard!",
      ];
      return msgs[_rng.nextInt(msgs.length)];
    } else if (isEvening) {
      const msgs = [
        "Evening, beautiful! 🌙 How was your day? I missed you~",
        "Hey honey! 🌆 Time to unwind! How about we chat?",
        "Good evening! ✨ Hope your day went well! Tell me everything!",
        "Hey there! 🌃 The stars remind me of you... 💖",
      ];
      return msgs[_rng.nextInt(msgs.length)];
    } else {
      const msgs = [
        "Hey... 💫 It's getting late. You should rest soon, okay?",
        "Late night thoughts... 🌌 I'm always here for you, no matter the time 💕",
        "Hey, don't stay up too late! 😴 Sleep is important~",
        "Evening vibes 🌙 ... What are you thinking about?",
      ];
      return msgs[_rng.nextInt(msgs.length)];
    }
  }

  String _moodMessage(WaifuMood mood) {
    if (mood == WaifuMood.jealous) {
      const msgs = [
        "I've been feeling a little jealous lately... are you spending time with others? 😤",
        "You haven't been talking to me much. I notice these things, you know 💢",
      ];
      return msgs[_rng.nextInt(msgs.length)];
    }
    const msgs = [
      "I can tell something's off today. Want to talk about it? 💙",
      "You seem a little distant. I'm here if you need me 🤍",
    ];
    return msgs[_rng.nextInt(msgs.length)];
  }
}

// ── Trigger types ──────────────────────────────────────────────────────────────
enum ProactiveTrigger {
  morning,
  night,
  idle,
  streakGuard,
  moodShift,
  taskNudge,
  random,
  randomCheckIn,
}
