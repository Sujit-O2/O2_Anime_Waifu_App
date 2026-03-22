import 'package:shared_preferences/shared_preferences.dart';

/// Phase 3: 4-phase recovery arc: soften->acknowledge->reduce->rebuild.
/// Triggers on 3h gap / 3+ ignored streak / trust<25.
/// Phase advances every 10 min of active conversation.
enum RecoveryPhase { soften, acknowledge, reduce, rebuild, none }

extension RecoveryPhaseExtension on RecoveryPhase {
  String get promptOverride {
    switch (this) {
      case RecoveryPhase.soften:
        return 'Be gentle and careful. Don\'t assume everything is okay. Test the waters softly.';
      case RecoveryPhase.acknowledge:
        return 'Acknowledge that there was a gap or tension. Show you noticed and you care.';
      case RecoveryPhase.reduce:
        return 'Actively work to reduce any negative feelings. Be extra sweet and attentive.';
      case RecoveryPhase.rebuild:
        return 'Focus on rebuilding trust and warmth. Reference positive shared memories.';
      case RecoveryPhase.none:
        return '';
    }
  }
}

class EmotionalRecoveryService {
  RecoveryPhase _currentPhase = RecoveryPhase.none;
  DateTime? _recoveryStartTime;
  int _activeMinutesInRecovery = 0;
  static const int _minutesPerPhase = 10;

  RecoveryPhase get currentPhase => _currentPhase;
  bool get isInRecovery => _currentPhase != RecoveryPhase.none;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final phaseIndex =
        prefs.getInt('recovery_phase') ?? RecoveryPhase.none.index;
    _currentPhase = RecoveryPhase.values[
        phaseIndex.clamp(0, RecoveryPhase.values.length - 1)];
    _activeMinutesInRecovery =
        prefs.getInt('recovery_active_minutes') ?? 0;
  }

  void checkTriggers({
    required Duration timeSinceLastMessage,
    required int ignoredStreak,
    required double trustScore,
  }) {
    if (_currentPhase != RecoveryPhase.none) return;

    bool shouldTrigger = false;

    // 3h gap
    if (timeSinceLastMessage.inHours >= 3) shouldTrigger = true;
    // 3+ ignored streak
    if (ignoredStreak >= 3) shouldTrigger = true;
    // Trust below 25
    if (trustScore < 25) shouldTrigger = true;

    if (shouldTrigger) {
      _currentPhase = RecoveryPhase.soften;
      _recoveryStartTime = DateTime.now();
      _activeMinutesInRecovery = 0;
      _persist();
    }
  }

  void recordActiveMinute() {
    if (!isInRecovery) return;

    _activeMinutesInRecovery++;

    // Advance phase every 10 active minutes
    if (_activeMinutesInRecovery >= _minutesPerPhase) {
      _activeMinutesInRecovery = 0;
      switch (_currentPhase) {
        case RecoveryPhase.soften:
          _currentPhase = RecoveryPhase.acknowledge;
          break;
        case RecoveryPhase.acknowledge:
          _currentPhase = RecoveryPhase.reduce;
          break;
        case RecoveryPhase.reduce:
          _currentPhase = RecoveryPhase.rebuild;
          break;
        case RecoveryPhase.rebuild:
          _currentPhase = RecoveryPhase.none;
          break;
        case RecoveryPhase.none:
          break;
      }
      _persist();
    }
  }

  String toContextString() {
    if (!isInRecovery) return '';
    return '[Recovery] Phase: ${_currentPhase.name} | ${_currentPhase.promptOverride}';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recovery_phase', _currentPhase.index);
    await prefs.setInt(
        'recovery_active_minutes', _activeMinutesInRecovery);
  }
}
