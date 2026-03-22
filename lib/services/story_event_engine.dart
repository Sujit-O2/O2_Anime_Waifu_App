import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/services/presence_message_generator.dart';

/// Phase 3: Daily special (7-10am), affection milestones, streak milestones,
/// 2% random emotional scene. Max 1 story event per 24h. All AI-generated.
class StoryEventEngine {
  final PresenceMessageGenerator _generator;
  DateTime? _lastStoryEvent;
  static final _random = Random();

  StoryEventEngine(this._generator);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString('last_story_event');
    if (lastStr != null) _lastStoryEvent = DateTime.parse(lastStr);
  }

  bool get canTrigger {
    if (_lastStoryEvent == null) return true;
    return DateTime.now().difference(_lastStoryEvent!).inHours >= 24;
  }

  Future<String?> checkAndTrigger({
    required int affectionPoints,
    required int streakDays,
    required String contextBlock,
  }) async {
    if (!canTrigger) return null;

    final now = DateTime.now();
    String? event;

    // Daily special (7-10am)
    if (now.hour >= 7 && now.hour < 10) {
      event = await _generator.generate(
        type: PresenceMessageType.storyEvent,
        contextBlock: contextBlock,
        additionalPrompt: 'Generate a special morning moment or scene.',
      );
    }

    // Affection milestones
    final milestones = [100, 250, 500, 1000, 1500, 2000, 2500];
    for (final m in milestones) {
      if (affectionPoints >= m && affectionPoints < m + 5) {
        event = await _generator.generate(
          type: PresenceMessageType.storyEvent,
          contextBlock: contextBlock,
          additionalPrompt:
              'Celebrate reaching $m affection points milestone!',
        );
        break;
      }
    }

    // Streak milestones
    final streakMilestones = [7, 14, 30, 50, 100];
    for (final s in streakMilestones) {
      if (streakDays == s) {
        event = await _generator.generate(
          type: PresenceMessageType.storyEvent,
          contextBlock: contextBlock,
          additionalPrompt:
              'Celebrate a $s-day streak! We\'ve talked every day for $s days!',
        );
        break;
      }
    }

    // 2% random emotional scene
    if (event == null && _random.nextDouble() < 0.02) {
      event = await _generator.generate(
        type: PresenceMessageType.storyEvent,
        contextBlock: contextBlock,
        additionalPrompt:
            'Generate a random emotional or touching scene/memory.',
      );
    }

    if (event != null) {
      _lastStoryEvent = now;
      _persist();
    }

    return event;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastStoryEvent != null) {
      await prefs.setString(
          'last_story_event', _lastStoryEvent!.toIso8601String());
    }
  }
}
