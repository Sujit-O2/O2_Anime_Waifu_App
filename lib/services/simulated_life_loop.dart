import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/models/master_snapshot.dart';

/// Phase 2: 7 AI life states mapped to clock time.
/// Recalculates every 15 min. Triggers personality drifts.
class SimulatedLifeLoop {
  AILifeState _currentState = AILifeState.resting;
  Timer? _recalcTimer;
  Function(AILifeState newState)? onStateChange;

  AILifeState get currentState => _currentState;

  void start() {
    _recalcTimer?.cancel();
    _recalculate();
    _recalcTimer =
        Timer.periodic(const Duration(minutes: 15), (_) => _recalculate());
  }

  void stop() {
    _recalcTimer?.cancel();
  }

  void _recalculate() {
    final hour = DateTime.now().hour;
    final oldState = _currentState;

    if (hour >= 0 && hour < 6) {
      _currentState = AILifeState.sleeping;
    } else if (hour >= 6 && hour < 8) {
      _currentState = AILifeState.waking;
    } else if (hour >= 8 && hour < 12) {
      _currentState = AILifeState.energetic;
    } else if (hour >= 12 && hour < 17) {
      _currentState = AILifeState.focused;
    } else if (hour >= 17 && hour < 20) {
      _currentState = AILifeState.windingDown;
    } else if (hour >= 20 && hour < 23) {
      _currentState = AILifeState.dreamMode;
    } else {
      _currentState = AILifeState.resting;
    }

    if (oldState != _currentState) {
      onStateChange?.call(_currentState);
      _persist();
    }
  }

  String get stateDescription {
    switch (_currentState) {
      case AILifeState.sleeping:
        return 'Zero Two is sleeping peacefully... zzz';
      case AILifeState.waking:
        return 'Zero Two is slowly waking up, still a bit drowsy~';
      case AILifeState.energetic:
        return 'Zero Two is full of energy and ready to chat!';
      case AILifeState.focused:
        return 'Zero Two is in a focused, productive mood.';
      case AILifeState.windingDown:
        return 'Zero Two is winding down, feeling relaxed.';
      case AILifeState.dreamMode:
        return 'Zero Two is in dream mode, feeling dreamy and reflective...';
      case AILifeState.resting:
        return 'Zero Two is resting, preparing for sleep.';
    }
  }

  String toContextString() =>
      '[AI Life State] ${_currentState.displayName} - $stateDescription';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('life_state', _currentState.index);
  }

  void dispose() {
    _recalcTimer?.cancel();
  }
}
