/// Phase 2: Priority-ordered autostart topics.
/// Rate-limited to once/90 min after 20+ min silence.
class SelfInitiatedTopics {
  DateTime _lastInitiation = DateTime.now();
  static const Duration _cooldown = Duration(minutes: 90);
  static const Duration _minSilence = Duration(minutes: 20);

  Function(String topicType, String? detail)? onTopicInitiated;

  /// Check if conditions are met to initiate a topic.
  /// Returns the topic type or null if conditions not met.
  String? checkAndInitiate({
    required Duration silenceDuration,
    String? unresolvedThread,
    String? observation,
    String? emotionalMoment,
    String? absenceMessage,
  }) {
    // Check cooldown
    if (DateTime.now().difference(_lastInitiation) < _cooldown) {
      return null;
    }

    // Must have at least _minSilence of silence
    if (silenceDuration < _minSilence) return null;

    // Priority order:
    // 1. Unresolved thread follow-up
    if (unresolvedThread != null) {
      _lastInitiation = DateTime.now();
      onTopicInitiated?.call('follow_up', unresolvedThread);
      return 'follow_up';
    }

    // 2. Self-reflection observation
    if (observation != null) {
      _lastInitiation = DateTime.now();
      onTopicInitiated?.call('observation', observation);
      return 'observation';
    }

    // 3. Emotional moment
    if (emotionalMoment != null) {
      _lastInitiation = DateTime.now();
      onTopicInitiated?.call('emotional', emotionalMoment);
      return 'emotional';
    }

    // 4. Absence message
    if (absenceMessage != null) {
      _lastInitiation = DateTime.now();
      onTopicInitiated?.call('absence', absenceMessage);
      return 'absence';
    }

    return null;
  }

  String toContextString() {
    final sinceLastInit =
        DateTime.now().difference(_lastInitiation).inMinutes;
    final canInitiate = sinceLastInit >= _cooldown.inMinutes;
    return '[Self-Initiated] ${canInitiate ? "Ready" : "Cooldown (${_cooldown.inMinutes - sinceLastInit}min remaining)"}';
  }
}
