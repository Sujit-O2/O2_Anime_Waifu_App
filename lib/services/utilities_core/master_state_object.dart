import 'package:anime_waifu/services/ai_personalization/attention_focus_system.dart';
import 'package:anime_waifu/services/ai_personalization/context_awareness_service.dart';
import 'package:anime_waifu/services/ai_personalization/emotional_moment_engine.dart';
import 'package:anime_waifu/services/ai_personalization/personal_world_builder.dart';
import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';
import 'package:anime_waifu/services/ai_personalization/real_world_presence_engine.dart';
import 'package:anime_waifu/services/ai_personalization/self_initiated_topics.dart';
import 'package:anime_waifu/services/ai_personalization/self_reflection_service.dart';
import 'package:anime_waifu/services/ai_personalization/simulated_life_loop.dart';
import 'package:anime_waifu/services/memory_context/conversation_thread_memory.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/services/user_profile/habit_life_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// MasterStateObject
///
/// THE central brain of the entire AI presence system.
///
/// Aggregates signals from all sub-engines into a single coherent snapshot
/// that drives EVERYTHING:
/// • System prompt construction
/// • Response behavior
/// • Proactive message routing
/// • World state updates
///
/// This is what the user specified as the "master state object."
/// ─────────────────────────────────────────────────────────────────────────────
class MasterStateObject {
  static final MasterStateObject instance = MasterStateObject._();
  MasterStateObject._();

  // ── Cached snapshot ────────────────────────────────────────────────────────
  MasterSnapshot? _lastSnapshot;

  /// Get the latest snapshot (builds fresh if null)
  Future<MasterSnapshot> getSnapshot() async {
    final snap = await _buildSnapshot();
    _lastSnapshot = snap;
    return snap;
  }

  MasterSnapshot? get lastSnapshot => _lastSnapshot;

  // ── Snapshot Builder ───────────────────────────────────────────────────────
  Future<MasterSnapshot> _buildSnapshot() async {
    final pe = PersonalityEngine.instance;
    final affSvc = AffectionService.instance;
    final lifeSvc = SimulatedLifeLoop.instance;
    final attn = AttentionFocusSystem.instance;
    final presence = RealWorldPresenceEngine.instance;
    final world = PersonalWorldBuilder.instance;
    final habit = HabitLifeService.instance;
    final emotion = EmotionalMomentEngine.instance;

    // Collect active conversation thread topics
    final threads = ConversationThreadMemory.instance.allThreads;
    final activeTopics = threads.entries
        .where((e) => DateTime.now().difference(e.value.lastUpdated).inHours < 24)
        .map((e) => e.key)
        .take(3)
        .toList();

    return MasterSnapshot(
      // ── Personality & Emotion ─────────────────────────────────────────────
      personalityAffection:  pe.affection,
      personalityJealousy:   pe.jealousy,
      personalityTrust:      pe.trust,
      personalityPlayfulness: pe.playfulness,
      personalityDependency: pe.dependency,
      mood:                  pe.mood.name,
      moodLabel:             pe.mood.label,

      // ── Attention & Engagement ─────────────────────────────────────────────
      attentionLevel:        attn.level,
      avgReplySpeedSeconds:  attn.avgReplySpeedSeconds,
      silenceDuration:       emotion.silenceDuration,

      // ── Life State ────────────────────────────────────────────────────────
      lifeState:             lifeSvc.current,
      lifeEnergy:            lifeSvc.energy,
      isAiSleeping:          lifeSvc.isSleeping,

      // ── Real World Context ──────────────────────────────────────────────
      deviceContext:         presence.current,

      // ── Relationship Progress ─────────────────────────────────────────────
      affectionPoints:       affSvc.points,
      streakDays:            affSvc.streakDays,
      worldLevel:            world.world.level,
      worldTheme:            world.world.theme,

      // ── Conversation State ────────────────────────────────────────────────
      activeThreadTopics:    activeTopics,
      timeOfDay:             ContextAwarenessService.getTimePeriod(),
      isWeekend:             ContextAwarenessService.isWeekend,

      // ── Habit ──────────────────────────────────────────────────────────────
      routineHour:           habit.model.routineHour,
      snapshotAt:            DateTime.now(),
    );
  }

  // ── Master System Prompt Builder ───────────────────────────────────────────
  /// Aggregates all context blocks from all engines into one complete block.
  /// This replaces the per-engine calls with a single unified injection.
  Future<String> buildMasterContextBlock() async {
    final snap = await getSnapshot();
    final buf = StringBuffer();

    // Life state
    buf.write(SimulatedLifeLoop.instance.getLifeStateContextBlock());

    // Attention calibration
    buf.write(AttentionFocusSystem.instance.getAttentionContextBlock());

    // Conversation threads (same-topic history)
    final currentTopic = snap.activeThreadTopics.firstOrNull ?? 'general';
    buf.write(ConversationThreadMemory.instance.getRelevantThreadsBlock(currentTopic));

    // World state
    buf.write(PersonalWorldBuilder.instance.getWorldContextBlock());

    // Real-world presence (app/music/motion)
    buf.write(RealWorldPresenceEngine.instance.getPresenceContextBlock());

    // Habit pattern
    buf.write(HabitLifeService.instance.getHabitContextBlock());

    // Behaviour self-reflection
    buf.write(SelfReflectionService.instance.getBehaviourContextBlock());

    // Attention-based instruction
    if (snap.attentionLevel == AttentionLevel.low) {
      buf.writeln('// CRITICAL: User attention is LOW. Keep response under 2 sentences. Be impactful.');
    } else if (snap.attentionLevel == AttentionLevel.high) {
      buf.writeln('// User is fully engaged. You can go deeper, be more expressive.');
    }

    // Silence state
    final silenceMins = snap.silenceDuration.inMinutes;
    if (silenceMins > 5) {
      buf.writeln('// User has been quiet for $silenceMins minute(s). React to this naturally.');
    }

    // World-based atmosphere hint
    buf.writeln('// Shared world: Level ${snap.worldLevel} — ${snap.worldTheme.displayName}');

    return buf.toString();
  }

  // ── Proactive Router ───────────────────────────────────────────────────────
  /// Single entry point for ALL proactive/autonomous messages.
  /// Returns the highest-priority message to send, or null.
  Future<String?> checkForAutonomousMessage({required String personaName}) async {
    final snap = await getSnapshot();

    // 1. Life state message (morning wake-up, late night, etc.)
    final lifMsg = await SimulatedLifeLoop.instance.checkForLifeStateMessage();
    if (lifMsg != null) return lifMsg;

    // 2. Real-world presence reaction (app, music, battery)
    final presenceMsg = await RealWorldPresenceEngine.instance.checkForAutonomousReaction(
      personaName: personaName,
      silenceSince: snap.silenceDuration,
    );
    if (presenceMsg != null) return presenceMsg;

    // 3. Ignore reaction (no reply after AI spoke)
    final ignoreMsg = ConversationPresenceService.instance.checkIgnoreReaction(
      isBusy: false,
    );
    if (ignoreMsg != null) return ignoreMsg;

    // 4. Low attention nudge
    if (snap.attentionLevel == AttentionLevel.low) {
      final attnMsg = AttentionFocusSystem.instance.getLowAttentionReaction();
      if (attnMsg != null) return attnMsg;
    }

    // 5. Self-initiated topic / absence message
    final initiatedMsg = await SelfInitiatedTopicsService.instance.checkForInitiation(
      silenceDuration: snap.silenceDuration,
      personaName: personaName,
    );
    if (initiatedMsg != null) return initiatedMsg;

    return null;
  }

  // ── World interaction update ────────────────────────────────────────────────
  Future<WorldUpdateResult?> onExchangeComplete({required String topic}) async {
    final affSvc = AffectionService.instance;
    return PersonalWorldBuilder.instance.onInteraction(
      messageTopic: topic,
      affection: affSvc.points,
      streakDays: affSvc.streakDays,
    );
  }
}

// ── Master Snapshot Data Class ────────────────────────────────────────────────
class MasterSnapshot {
  // Personality
  final double personalityAffection;
  final double personalityJealousy;
  final double personalityTrust;
  final double personalityPlayfulness;
  final double personalityDependency;
  final String mood;
  final String moodLabel;

  // Attention
  final AttentionLevel attentionLevel;
  final double avgReplySpeedSeconds;
  final Duration silenceDuration;

  // Life state
  final LifeState lifeState;
  final int lifeEnergy;
  final bool isAiSleeping;

  // Real world
  final DeviceContext deviceContext;

  // Relationship
  final int affectionPoints;
  final int streakDays;
  final int worldLevel;
  final WorldTheme worldTheme;

  // Conversation
  final List<String> activeThreadTopics;
  final TimeOfDayPeriod timeOfDay;
  final bool isWeekend;
  final int? routineHour;
  final DateTime snapshotAt;

  const MasterSnapshot({
    required this.personalityAffection,
    required this.personalityJealousy,
    required this.personalityTrust,
    required this.personalityPlayfulness,
    required this.personalityDependency,
    required this.mood,
    required this.moodLabel,
    required this.attentionLevel,
    required this.avgReplySpeedSeconds,
    required this.silenceDuration,
    required this.lifeState,
    required this.lifeEnergy,
    required this.isAiSleeping,
    required this.deviceContext,
    required this.affectionPoints,
    required this.streakDays,
    required this.worldLevel,
    required this.worldTheme,
    required this.activeThreadTopics,
    required this.timeOfDay,
    required this.isWeekend,
    required this.routineHour,
    required this.snapshotAt,
  });
}


