import 'package:o2_waifu/models/master_snapshot.dart';
import 'package:o2_waifu/services/personality_engine.dart';
import 'package:o2_waifu/services/affection_service.dart';
import 'package:o2_waifu/services/context_awareness_service.dart';
import 'package:o2_waifu/services/real_world_presence_engine.dart';
import 'package:o2_waifu/services/emotional_moment_engine.dart';
import 'package:o2_waifu/services/self_reflection_service.dart';
import 'package:o2_waifu/services/habit_life_service.dart';
import 'package:o2_waifu/services/simulated_life_loop.dart';
import 'package:o2_waifu/services/conversation_thread_memory.dart';
import 'package:o2_waifu/services/attention_focus_system.dart';
import 'package:o2_waifu/services/personal_world_builder.dart';
import 'package:o2_waifu/services/mood_service.dart';
import 'package:o2_waifu/services/jealousy_service.dart';

/// THE central brain — 25-field MasterSnapshot. Unified LLM context block
/// from all 8 systems. Central proactive message router.
class MasterStateService {
  final PersonalityEngine personalityEngine;
  final AffectionService affectionService;
  final ContextAwarenessService contextAwareness;
  final RealWorldPresenceEngine presenceEngine;
  final EmotionalMomentEngine emotionalMoments;
  final SelfReflectionService selfReflection;
  final HabitLifeService habitLife;
  final SimulatedLifeLoop lifeLoop;
  final ConversationThreadMemory threadMemory;
  final AttentionFocusSystem attentionSystem;
  final PersonalWorldBuilder worldBuilder;
  final MoodService moodService;
  final JealousyService jealousyService;

  MasterStateService({
    required this.personalityEngine,
    required this.affectionService,
    required this.contextAwareness,
    required this.presenceEngine,
    required this.emotionalMoments,
    required this.selfReflection,
    required this.habitLife,
    required this.lifeLoop,
    required this.threadMemory,
    required this.attentionSystem,
    required this.worldBuilder,
    required this.moodService,
    required this.jealousyService,
  });

  MasterSnapshot getSnapshot() {
    return MasterSnapshot(
      currentMood: personalityEngine.currentMood,
      affectionLevel: personalityEngine.traits.affection,
      jealousyLevel: jealousyService.jealousyLevel,
      trustScore: personalityEngine.traits.trust,
      playfulness: personalityEngine.traits.playfulness,
      dependency: personalityEngine.traits.dependency,
      relationshipStage: affectionService.stage,
      streakDays: affectionService.streakDays,
      totalMessages: 0,
      foregroundApp: presenceEngine.foregroundApp,
      nowPlayingTrack: presenceEngine.nowPlayingTrack,
      isCharging: presenceEngine.isCharging,
      motionState: presenceEngine.motionState,
      timeOfDay: contextAwareness.timeOfDay,
      isWeekend: contextAwareness.isWeekend,
      batteryLevel: contextAwareness.batteryLevel,
      silenceDuration: emotionalMoments.silenceDuration,
      lifeState: lifeLoop.currentState,
      attentionLevel: attentionSystem.currentLevel,
      activeConversationThread: null,
      unresolvdThreadCount: threadMemory.unresolvedCount,
      worldTheme: worldBuilder.currentTheme,
    );
  }

  /// Generate the unified 18-layer context block for system prompt
  String generateContextBlock() {
    final buffer = StringBuffer();

    // Layer 1: Personality
    buffer.writeln(personalityEngine.toContextString());
    // Layer 2: Affection
    buffer.writeln(affectionService.toContextString());
    // Layer 3: Context Awareness
    buffer.writeln(contextAwareness.toContextString());
    // Layer 4: Mood
    buffer.writeln(moodService.toContextString());
    // Layer 5: Jealousy
    buffer.writeln(jealousyService.toContextString());
    // Layer 6: Real World Presence
    buffer.writeln(presenceEngine.toContextString());
    // Layer 7: Emotional Moments
    buffer.writeln(emotionalMoments.toContextString());
    // Layer 8: Self Reflection
    buffer.writeln(selfReflection.toContextString());
    // Layer 9: Habits
    buffer.writeln(habitLife.toContextString());
    // Layer 10: Life Loop
    buffer.writeln(lifeLoop.toContextString());
    // Layer 11: Conversation Threads
    buffer.writeln(threadMemory.toContextString());
    // Layer 12: Attention
    buffer.writeln(attentionSystem.toContextString());
    // Layer 13: World
    buffer.writeln(worldBuilder.toContextString());
    // Layer 14-18: Phase 3 context (injected by Phase 3 services)

    return buffer.toString();
  }

  /// Get full master snapshot context
  String getFullContext() {
    final snapshot = getSnapshot();
    return '${snapshot.toContextBlock()}\n${generateContextBlock()}';
  }
}
