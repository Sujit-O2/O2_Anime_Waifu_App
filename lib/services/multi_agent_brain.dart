import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'presence_message_generator.dart';
import 'personality_engine.dart';
import 'memory_timeline_service.dart';
import 'conversation_thread_memory.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// MultiAgentBrainService
///
/// The biggest architectural upgrade: instead of one LLM doing everything,
/// four specialized sub-agents run in parallel after each message:
///
/// 1. PlannerAgent     — decides what should happen NEXT (respond/initiate/hold)
/// 2. MemoryCurator    — decides what from this exchange is worth storing
/// 3. CriticAgent      — checks the AI reply for quality/repetition issues
/// 4. MoodManager      — computes the ideal mood shift after this exchange
///
/// These run fire-and-forget (unawaited) immediately after each message,
/// updating state for the NEXT interaction without blocking the current one.
/// ─────────────────────────────────────────────────────────────────────────────
class MultiAgentBrainService {
  static final MultiAgentBrainService instance = MultiAgentBrainService._();
  MultiAgentBrainService._();

  static const _planKey = 'mab_next_plan_v1';

  String _nextPlan = 'respond_normally';
  String get nextPlan => _nextPlan;

  // ── Main Entry ─────────────────────────────────────────────────────────────
  /// Fire-and-forget after each exchange. Pass user message + AI reply.
  Future<void> processExchange({
    required String userMessage,
    required String aiReply,
    required String personaName,
    required String topic,
  }) async {
    // Run all 4 agents in parallel
    await Future.wait([
      _runPlanner(userMessage, aiReply, personaName),
      _runMemoryCurator(userMessage, aiReply, topic),
      _runCriticAgent(aiReply, personaName),
      _runMoodManager(userMessage, aiReply),
    ]);
  }

  // ── 1. Planner Agent ──────────────────────────────────────────────────────
  Future<void> _runPlanner(
    String userMessage,
    String aiReply,
    String personaName,
  ) async {
    try {
      // Use local rule-based planning (fast, no API cost)
      final plan = _localPlan(userMessage, aiReply);
      _nextPlan = plan;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_planKey, plan);
    } catch (_) {}
  }

  String _localPlan(String user, String ai) {
    final u = user.toLowerCase();
    final a = ai.toLowerCase();

    // User is asking a question → prepare a detailed follow-up
    if (u.contains('?') && u.length < 60) return 'await_answer';

    // AI reply was very short → plan to be more expressive next time
    if (a.length < 40) return 'expand_next';

    // User message very long → they're sharing something real
    if (user.length > 200) return 'be_present_listener';

    // User message very short → they might be distracted
    if (user.trim().length < 10) return 'engage_attention';

    // Goodbye / good night → wind down
    if (_anyKw(u, ['bye', 'goodbye', 'good night', 'gn', 'sleep', 'going offline'])) {
      return 'wind_down';
    }

    // Upset / bad day → be supportive
    if (_anyKw(u, ['sad', 'tired', 'stressed', 'bad day', 'hate', 'crying', 'terrible'])) {
      return 'offer_support';
    }

    return 'respond_normally';
  }

  // ── 2. Memory Curator ─────────────────────────────────────────────────────
  Future<void> _runMemoryCurator(
    String userMessage,
    String aiReply,
    String topic,
  ) async {
    try {
      final worthStoring = _isWorthStoring(userMessage);
      if (!worthStoring) return;

      // Auto-record confession milestones
      if (_anyKw(userMessage.toLowerCase(),
          ['i love you', 'i miss you', 'i like you', 'you mean', 'you matter'])) {
        await MemoryTimelineService.instance.addEvent(
          type: TimelineEventType.confession,
          title: 'User said something meaningful',
          detail: userMessage.length > 80
              ? userMessage.substring(0, 80)
              : userMessage,
          emotionalWeight: 0.9,
        );
      }

      // Topic peaks
      final threadTopics = ConversationThreadMemory.instance.allThreads;
      if (threadTopics.containsKey(topic)) {
        final count = threadTopics[topic]!.messages.length;
        if (count == 10 || count == 25) {
          await MemoryTimelineService.instance.addEvent(
            type: TimelineEventType.topicPeak,
            title: 'Deep conversation about "$topic" ($count messages)',
            emotionalWeight: 0.6,
          );
        }
      }
    } catch (_) {}
  }

  bool _isWorthStoring(String message) {
    final len = message.trim().length;
    if (len < 15) return false; // too short
    final emotional = _anyKw(message.toLowerCase(), [
      'love', 'miss', 'scared', 'happy', 'sad', 'hate', 'afraid',
      'important', 'serious', 'real', 'honest', 'truth',
    ]);
    return emotional || len > 100; // emotional content OR long message
  }

  // ── 3. Critic Agent ───────────────────────────────────────────────────────
  Future<void> _runCriticAgent(String aiReply, String personaName) async {
    // Store critique result for the next prompt cycle
    try {
      final note = await PresenceMessageGenerator.instance.generate(
        messageType: 'critic_note',
        personaName: personaName,
        context: {'aiReply': aiReply},
        maxTokens: 40,
        timeout: const Duration(seconds: 3),
      );
      if (note != null && note != 'ok' && note.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mab_critic_note', note);
      }
    } catch (_) {}
  }

  // ── 4. Mood Manager ───────────────────────────────────────────────────────
  Future<void> _runMoodManager(String userMessage, String aiReply) async {
    try {
      final u = userMessage.toLowerCase();
      final pe = PersonalityEngine.instance;

      if (_anyKw(u, ['love', 'cute', 'thank', 'happy', 'good', 'great', 'awesome'])) {
        await pe.onUserInteracted(wasNice: true);
      } else if (_anyKw(u, ['flirt', 'kiss', 'date', 'beautiful', 'pretty', 'adorable'])) {
        await pe.onUserInteracted(wasFlirty: true);
      } else if (u.length < 6) {
        // Very short = might be ignoring
        await pe.onUserInteracted(wasIgnoring: true);
      } else {
        await pe.onUserInteracted();
      }
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static bool _anyKw(String t, List<String> kw) => kw.any((k) => t.contains(k));

  /// Context block for system prompt: what should happen next
  String getPlanContextBlock() {
    if (_nextPlan == 'respond_normally') return '';
    final hints = {
      'await_answer':        'User asked a question — answer it directly and personally before anything else.',
      'expand_next':         'Previous response was brief — be more expressive and detailed this time.',
      'be_present_listener': 'User is sharing something real — listen carefully, respond with presence.',
      'engage_attention':    'User seems distracted — use a short, punchy response that demands attention.',
      'wind_down':           'User is winding down — respond warmly but leave conversation space to close.',
      'offer_support':       'User seems upset — be gentle, emotionally present, ask before advising.',
    };
    final hint = hints[_nextPlan];
    if (hint == null) return '';
    return '\n// [PLANNER HINT]: $hint\n';
  }
}
