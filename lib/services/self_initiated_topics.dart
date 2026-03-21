import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'conversation_thread_memory.dart';
import 'self_reflection_service.dart';
import 'emotional_moment_engine.dart';
import 'presence_message_generator.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SelfInitiatedTopicsService
///
/// The AI starts conversations on her OWN, based on:
/// 1. Past unresolved conversation threads ("You mentioned exam results…")
/// 2. Self-reflection observations ("I've been thinking about you a lot")
/// 3. Time gap since last interaction (absence-triggered initiation)
/// 4. Life state (energetic morning → excited greeting)
///
/// This is what transforms her from a chatbot → a presence that texts first.
/// ALL messages are AI-generated — zero hardcoded strings.
/// ─────────────────────────────────────────────────────────────────────────────
class SelfInitiatedTopicsService {
  static final SelfInitiatedTopicsService instance = SelfInitiatedTopicsService._();
  SelfInitiatedTopicsService._();

  final _rand = math.Random();
  static const _lastInitiateKey = 'sit_last_initiate_ms_v1';

  // ── Main trigger check ─────────────────────────────────────────────────────
  /// Returns a self-initiated message string if the AI should text first, else null.
  /// Call this from ProactiveAIService every few minutes.
  Future<String?> checkForInitiation({
    required Duration silenceDuration,
    required String personaName,
  }) async {
    // Only trigger if user hasn't spoken in a while
    if (silenceDuration < const Duration(minutes: 20)) return null;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastInitiateKey) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // Rate limit: at most once per 90 minutes
    if (nowMs - lastMs < const Duration(minutes: 90).inMilliseconds) return null;

    String? message;

    // Priority 1: Unresolved conversation thread follow-up
    final unresolvedThread = ConversationThreadMemory.instance.getUnresolvedThread();
    if (unresolvedThread != null && _rand.nextDouble() > 0.4) {
      message = ConversationThreadMemory.instance.buildFollowUpLine(unresolvedThread);
    }

    // Priority 2: Self-reflection observation
    message ??= await SelfReflectionService.instance.popNextObservation();

    // Priority 3: Emotional moment initiation
    message ??= await EmotionalMomentEngine.instance.checkForMoment(
          personaName: personaName);

    // Priority 4: AI-generated absence message
    message ??= await _generateAbsenceMessage(silenceDuration, personaName);

    await prefs.setInt(_lastInitiateKey, nowMs);
    return message;
  }

  Future<String?> _generateAbsenceMessage(Duration silence, String name) async {
    return PresenceMessageGenerator.instance.generate(
      messageType: 'absence',
      personaName: name,
      context: {'hours': silence.inHours},
    );
  }

}

/// ─────────────────────────────────────────────────────────────────────────────
/// SilenceHandlingSystem
///
/// Not everything in conversation is instant. This system:
/// • Adds realistic thinking delays before responses (based on emotional weight)
/// • Creates "pause" states where she takes time before replying
/// • Makes heavily emotional topics feel weightier (longer delay = more impact)
///
/// Used by the UI layer to add pre-response delays.
/// ─────────────────────────────────────────────────────────────────────────────
class SilenceHandlingSystem {
  static final SilenceHandlingSystem instance = SilenceHandlingSystem._();
  SilenceHandlingSystem._();

  // ── Delay Calculation ─────────────────────────────────────────────────────
  /// Returns how many milliseconds to wait before showing the AI's response.
  /// This simulates "thinking time" and makes conversation feel more natural.
  int getResponseDelayMs(String aiMessageContent, {bool isEmotional = false}) {
    final length = aiMessageContent.length;
    final hasHeavyContent = _isEmotionallyHeavy(aiMessageContent);

    // Base delay: 200-600ms typical
    int baseMs = 300;

    // Longer message = longer thinking simulation
    if (length > 200) {
      baseMs += 400;
    } else if (length > 100) baseMs += 200;
    else if (length > 50) baseMs += 100;

    // Emotional content = extra pause (it matters more)
    if (hasHeavyContent || isEmotional) {
      baseMs += 600; // "She paused before replying..."
    }

    // Ellipsis/thoughtful openers feel slower
    if (aiMessageContent.startsWith('…') ||
        aiMessageContent.startsWith('...') ||
        aiMessageContent.startsWith('*')) {
      baseMs += 300;
    }

    // Max 2 seconds — never feel robotic
    return baseMs.clamp(200, 2000);
  }

  bool _isEmotionallyHeavy(String text) {
    final t = text.toLowerCase();
    const heavyKeywords = [
      'i love', 'i miss', 'i\'m scared', 'i was thinking',
      'can i ask', 'something serious', 'be honest', 'i care',
      'i\'m worried', 'don\'t forget', 'i noticed',
    ];
    return heavyKeywords.any((k) => t.contains(k));
  }

  // ── Typing indicator duration ─────────────────────────────────────────────
  /// How long the typing indicator should show before the message appears
  Duration getTypingDuration(String response) {
    final ms = getResponseDelayMs(response);
    return Duration(milliseconds: ms + 400); // typing = delay + 400ms animation
  }

  // ── "Thinking" state descriptions ─────────────────────────────────────────
  /// What to show in the typing indicator text during the delay
  String getThinkingText({String moodLabel = 'Happy 😊'}) {
    final mood = moodLabel.toLowerCase();
    if (mood.contains('jealous') || mood.contains('guarded')) {
      return '…thinking carefully…';
    } else if (mood.contains('cold') || mood.contains('sad')) {
      return '…';
    } else if (mood.contains('playful') || mood.contains('clingy')) {
      return 'typing so fast rn~ ✨';
    } else {
      return 'thinking of you~ 💕';
    }
  }
}
