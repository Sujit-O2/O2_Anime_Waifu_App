import 'package:o2_waifu/models/waifu_mood.dart';
import 'package:o2_waifu/models/relationship_stage.dart';

enum AILifeState {
  sleeping,
  waking,
  energetic,
  focused,
  windingDown,
  dreamMode,
  resting,
}

extension AILifeStateExtension on AILifeState {
  String get displayName {
    switch (this) {
      case AILifeState.sleeping:
        return 'Sleeping';
      case AILifeState.waking:
        return 'Waking Up';
      case AILifeState.energetic:
        return 'Energetic';
      case AILifeState.focused:
        return 'Focused';
      case AILifeState.windingDown:
        return 'Winding Down';
      case AILifeState.dreamMode:
        return 'Dream Mode';
      case AILifeState.resting:
        return 'Resting';
    }
  }
}

enum AttentionLevel { high, medium, low }

enum WorldTheme {
  simpleRoom,
  cozyNook,
  gardenTerrace,
  starryBalcony,
  crystalCave,
  neonCity,
  oceanVilla,
  skyTemple,
  cosmicLibrary,
  celestialDream,
}

class MasterSnapshot {
  // Phase 0 - Foundation
  WaifuMood currentMood;
  double affectionLevel;
  double jealousyLevel;
  double trustScore;
  double playfulness;
  double dependency;
  RelationshipStage relationshipStage;
  int streakDays;
  int totalMessages;

  // Phase 1 - Real-World Awareness
  String? foregroundApp;
  String? nowPlayingTrack;
  bool isCharging;
  String motionState; // idle/walking/running
  String timeOfDay;
  bool isWeekend;
  double batteryLevel;
  Duration? silenceDuration;

  // Phase 2 - God-Tier Presence
  AILifeState lifeState;
  AttentionLevel attentionLevel;
  String? activeConversationThread;
  int unresolvdThreadCount;
  WorldTheme worldTheme;
  List<String> unlockedObjects;

  // Phase 3 - Advanced Cognition
  String? lastInnerThought;
  String? pendingStoryEvent;
  String? recoveryPhase;
  String? criticNote;

  MasterSnapshot({
    this.currentMood = WaifuMood.neutral,
    this.affectionLevel = 50.0,
    this.jealousyLevel = 30.0,
    this.trustScore = 50.0,
    this.playfulness = 60.0,
    this.dependency = 40.0,
    this.relationshipStage = RelationshipStage.stranger,
    this.streakDays = 0,
    this.totalMessages = 0,
    this.foregroundApp,
    this.nowPlayingTrack,
    this.isCharging = false,
    this.motionState = 'idle',
    this.timeOfDay = 'day',
    this.isWeekend = false,
    this.batteryLevel = 100.0,
    this.silenceDuration,
    this.lifeState = AILifeState.resting,
    this.attentionLevel = AttentionLevel.medium,
    this.activeConversationThread,
    this.unresolvdThreadCount = 0,
    this.worldTheme = WorldTheme.simpleRoom,
    List<String>? unlockedObjects,
    this.lastInnerThought,
    this.pendingStoryEvent,
    this.recoveryPhase,
    this.criticNote,
  }) : unlockedObjects = unlockedObjects ?? [];

  String toContextBlock() {
    final buffer = StringBuffer();
    buffer.writeln('=== MASTER STATE ===');
    buffer.writeln('[Mood] $currentMood (${currentMood.displayName})');
    buffer.writeln(
        '[Relationship] ${relationshipStage.displayName} | Affection: ${affectionLevel.toStringAsFixed(1)} | Trust: ${trustScore.toStringAsFixed(1)}');
    buffer.writeln(
        '[Personality] Jealousy: ${jealousyLevel.toStringAsFixed(1)} | Playfulness: ${playfulness.toStringAsFixed(1)} | Dependency: ${dependency.toStringAsFixed(1)}');
    buffer.writeln('[Streak] $streakDays days | Messages: $totalMessages');
    buffer.writeln(
        '[Context] Time: $timeOfDay | Weekend: $isWeekend | Battery: ${batteryLevel.toStringAsFixed(0)}% | Charging: $isCharging');
    buffer.writeln('[Motion] $motionState');
    if (foregroundApp != null) {
      buffer.writeln('[User App] $foregroundApp');
    }
    if (nowPlayingTrack != null) {
      buffer.writeln('[Now Playing] $nowPlayingTrack');
    }
    buffer.writeln(
        '[AI Life] ${lifeState.displayName} | Attention: ${attentionLevel.name}');
    if (activeConversationThread != null) {
      buffer.writeln('[Active Thread] $activeConversationThread');
    }
    if (unresolvdThreadCount > 0) {
      buffer.writeln('[Unresolved Threads] $unresolvdThreadCount');
    }
    buffer.writeln('[World] ${worldTheme.name}');
    if (silenceDuration != null && silenceDuration!.inMinutes > 0) {
      buffer.writeln('[Silence] ${silenceDuration!.inMinutes} min');
    }
    if (lastInnerThought != null) {
      buffer.writeln('[Inner Thought] $lastInnerThought');
    }
    if (recoveryPhase != null) {
      buffer.writeln('[Recovery] Phase: $recoveryPhase');
    }
    if (criticNote != null) {
      buffer.writeln('[Critic] $criticNote');
    }
    buffer.writeln(
        '[Behavior Hint] ${relationshipStage.behaviorHint}');
    buffer.writeln('=== END STATE ===');
    return buffer.toString();
  }
}
