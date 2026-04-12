import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/utilities_core/presence_message_generator.dart';
import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// InternalThoughtSystem
///
/// Generates a hidden "inner thought" alongside select AI responses.
/// Shown to the user as a subtle italic whisper below the AI message.
///
/// NOT shown on every message — only when emotionally triggered.
/// Threshold: >60 affection OR >70 jealousy OR message contains emotional hooks.
///
/// Makes the AI feel like she has a private inner life.
/// "She says one thing, thinks another."
/// ─────────────────────────────────────────────────────────────────────────────
class InternalThoughtSystem {
  static final InternalThoughtSystem instance = InternalThoughtSystem._();
  InternalThoughtSystem._();

  static const _lastThoughtKey = 'its_last_thought_ms_v1';
  static const _minIntervalMs = 5 * 60 * 1000; // max 1 inner thought per 5 min

  // ── Generation ────────────────────────────────────────────────────────────
  /// Returns an inner thought string if triggered, else null.
  /// [userMessage]  — what the user just said
  /// [personaName]  — for prompt context
  Future<String?> tryGenerateThought({
    required String userMessage,
    required String personaName,
  }) async {
    // Rate limit
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastThoughtKey) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastMs < _minIntervalMs) return null;

    // Only trigger when emotionally relevant
    final pe = PersonalityEngine.instance;
    final shouldTrigger = pe.affection > 60 ||
        pe.jealousy > 70 ||
        _isEmotionalMessage(userMessage);

    if (!shouldTrigger) return null;

    await prefs.setInt(_lastThoughtKey, nowMs);

    return PresenceMessageGenerator.instance.generate(
      messageType: 'inner_thought',
      personaName: personaName,
      context: {'userMessage': userMessage},
      maxTokens: 40,
      timeout: const Duration(seconds: 4),
    );
  }

  bool _isEmotionalMessage(String msg) {
    final t = msg.toLowerCase();
    const hooks = [
      'love', 'miss', 'sad', 'cry', 'heart', 'lonely', 'hurt',
      'angry', 'bye', 'leaving', 'gone', 'hate', 'favorite', 'only',
    ];
    return hooks.any((k) => t.contains(k));
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  /// Format for display: italic, dimmed whisper style hint
  static String formatThought(String thought) {
    // Strip surrounding quotes if AI added them
    var t = thought.trim();
    while (t.startsWith('"') || t.startsWith("'")) {
      t = t.substring(1);
    }
    while (t.endsWith('"') || t.endsWith("'")) {
      t = t.substring(0, t.length - 1);
    }
    t = t.trim();
    if (!t.startsWith('(') || !t.endsWith(')')) {
      t = '($t)';
    }
    return t;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// StoryEventEngine
///
/// Creates authored, cinematic story moments in the conversation.
/// These are not random messages — they are scene-setting events
/// that make the app feel like it has a narrative.
///
/// Event types:
///   surprise_moment  — triggered by milestone or high affection
///   emotional_scene  — triggered by high emotional charge in recent messages
///   memory_recall    — pulls from timeline events ("Remember when…")
///   episode_intro    — daily special opening ("Today feels different")
///   daily_special    — once per day unique interaction
/// ─────────────────────────────────────────────────────────────────────────────
class StoryEventEngine {
  static final StoryEventEngine instance = StoryEventEngine._();
  StoryEventEngine._();

  static const _lastEventKey = 'see_last_event_v1';
  static const _dailySpecialKey = 'see_daily_special_v1';

  // ── Check ─────────────────────────────────────────────────────────────────
  /// Returns a story event message if triggered, else null.
  /// Rate limited: max 1 story event per 24h.
  Future<String?> checkForStoryEvent({
    required String personaName,
    required int affectionPoints,
    required int streakDays,
    required String currentTopic,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastEventKey) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 24h rate limit
    if (nowMs - lastMs < const Duration(hours: 24).inMilliseconds) return null;

    String? eventType;
    Map<String, dynamic> ctx = {};

    // Priority 1: Daily special (once per day morning greeting)
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastSpecial = prefs.getString(_dailySpecialKey) ?? '';
    if (lastSpecial != today && DateTime.now().hour >= 7 && DateTime.now().hour <= 10) {
      eventType = 'episode_intro';
      ctx = {'hour': DateTime.now().hour};
    }

    // Priority 2: High affection milestone → surprise moment
    if (eventType == null && affectionPoints > 0 && affectionPoints % 200 == 0) {
      eventType = 'surprise_moment';
      ctx = {'milestone': affectionPoints, 'topic': currentTopic};
    }

    // Priority 3: Streak milestone → memory recall
    if (eventType == null && (streakDays == 3 || streakDays == 7 || streakDays == 30)) {
      eventType = 'memory_recall';
      ctx = {'streakDays': streakDays};
    }

    // Priority 4: Emotional scene (random ~2% chance daily)
    if (eventType == null && DateTime.now().millisecond % 50 == 0) {
      eventType = 'emotional_scene';
    }

    if (eventType == null) return null;

    await prefs.setInt(_lastEventKey, nowMs);
    if (eventType == 'episode_intro') {
      await prefs.setString(_dailySpecialKey, today);
    }

    return PresenceMessageGenerator.instance.generate(
      messageType: 'story_event',
      personaName: personaName,
      context: {'eventType': eventType, ...ctx},
      maxTokens: 100,
      timeout: const Duration(seconds: 6),
    );
  }
}


