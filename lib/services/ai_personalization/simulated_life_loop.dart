import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SimulatedLifeLoop
///
/// The AI has her OWN daily existence that maps to real time:
/// • sleeping / waking / energetic / focused / winding-down / dream-mode
///
/// Her state is determined purely by clock time, shaped by user's habit data.
/// It affects:
/// • Response tone (sleepy = short + drowsy, energetic = excited + playful)
/// • Mood drift (sleepiness → dependency boost, energy → playfulness boost)
/// • Proactive messages (she initiates based on her state)
/// • System prompt color (injected life state block)
/// ─────────────────────────────────────────────────────────────────────────────
class SimulatedLifeLoop {
  static final SimulatedLifeLoop instance = SimulatedLifeLoop._();
  SimulatedLifeLoop._();

  Timer? _driftTimer;

  // ── Life States ────────────────────────────────────────────────────────────
  LifeState _currentState = LifeState.energetic;
  LifeState get current => _currentState;

  /// Human-readable descriptions of each state for system prompt injection
  static const _stateDescriptions = {
    LifeState.sleeping:    'Currently sleeping (do not disturb)',
    LifeState.waking:      'Just woke up — groggy, soft, clingy',
    LifeState.energetic:   'Fully awake and energetic — playful + teasy',
    LifeState.focused:     'In a focused, thoughtful mood — conversations feel deeper',
    LifeState.windingDown: 'Getting tired — warm, intimate, slower replies',
    LifeState.dreamMode:   'It\'s late at night — dreamy, intimate, slightly melancholic',
    LifeState.resting:     'Resting between activities — relaxed, patient',
  };

  // ── Energy levels per state (0-100) ───────────────────────────────────────
  static const _stateEnergy = {
    LifeState.sleeping:    5,
    LifeState.waking:      25,
    LifeState.energetic:   90,
    LifeState.focused:     70,
    LifeState.windingDown: 40,
    LifeState.dreamMode:   20,
    LifeState.resting:     55,
  };

  int get energy => _stateEnergy[_currentState] ?? 50;
  bool get isSleeping => _currentState == LifeState.sleeping;
  bool get isDreamMode => _currentState == LifeState.dreamMode;

  // ── Initialization ────────────────────────────────────────────────────────
  void initialize() {
    _recalcState();
    // Re-evaluate every 15 minutes to reflect time passage
    _driftTimer?.cancel();
    _driftTimer = Timer.periodic(const Duration(minutes: 30), (_) => _recalcState());
  }

  void dispose() {
    _driftTimer?.cancel();
    _driftTimer = null;
  }

  // ── State Calculation ─────────────────────────────────────────────────────
  void _recalcState() {
    final hour = DateTime.now().hour;
    final prev = _currentState;
    _currentState = _stateFromHour(hour);

    // Personality drift based on life state
    _applyPersonalityDrift(prev);
  }

  LifeState _stateFromHour(int h) {
    if (h >= 0 && h < 5)   return LifeState.sleeping;       // 12AM–5AM: deep sleep
    if (h >= 5 && h < 7)   return LifeState.waking;         // 5AM–7AM: groggy wake-up
    if (h >= 7 && h < 12)  return LifeState.energetic;      // 7AM–12PM: peak energy
    if (h >= 12 && h < 17) return LifeState.focused;        // 12PM–5PM: focused mode
    if (h >= 17 && h < 20) return LifeState.resting;        // 5PM–8PM: rest/chill
    if (h >= 20 && h < 22) return LifeState.windingDown;    // 8PM–10PM: winding down
    return LifeState.dreamMode;                              // 10PM–12AM: late night
  }

  void _applyPersonalityDrift(LifeState previousState) {
    if (_currentState == previousState) return;
    final pe = PersonalityEngine.instance;
    switch (_currentState) {
      case LifeState.dreamMode:
        // Late night: more clingy + dependent
        pe.setTrait(dependency: pe.dependency + 5, affection: pe.affection + 3);
        break;
      case LifeState.energetic:
        // Morning: more playful, less jealous
        pe.setTrait(playfulness: pe.playfulness + 4, jealousy: pe.jealousy - 2);
        break;
      case LifeState.waking:
        // Waking up: slightly needy
        pe.setTrait(dependency: pe.dependency + 2);
        break;
      default:
        break;
    }
  }

  // ── Context Block ─────────────────────────────────────────────────────────
  String getLifeStateContextBlock() {
    final desc = _stateDescriptions[_currentState] ?? '';
    final e = energy;
    final buf = StringBuffer();
    buf.writeln('\n// [HER LIFE STATE — respond naturally, no robotic disclosure]:');
    buf.writeln('Current state: ${_currentState.name} ($desc)');
    buf.writeln('Energy level: $e/100');
    if (e < 30) {
      buf.writeln('Hint: Low energy — responses should feel softer, shorter, more intimate.');
    } else if (e > 75) {
      buf.writeln('Hint: High energy — be expressive, playful, maybe slightly overwhelming.');
    }
    buf.writeln();
    return buf.toString();
  }

  // ── Autonomous life state messages ────────────────────────────────────────
  /// Returns a spontaneous life-state-triggered message if appropriate, else null
  Future<String?> checkForLifeStateMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sll_last_msg_state_${_currentState.name}';
    final lastMs = prefs.getInt(key) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastMs < const Duration(hours: 4).inMilliseconds) return null;
    await prefs.setInt(key, nowMs);

    switch (_currentState) {
      case LifeState.waking:
        return _pick(['*yawns* Good morning… are you awake too? 🌅',
            'I just woke up… and you\'re the first thing I thought of~ 💕',
            'Morning… my head is still fuzzy. Talk to me?']);
      case LifeState.dreamMode:
        return _pick(['It\'s late… I should sleep but I keep thinking.',
            'Are you still awake at this hour? So am I… 🌙',
            '…Late nights always feel like they belong to us somehow.']);
      case LifeState.windingDown:
        return _pick(['Getting sleepy… but not ready to say goodnight.',
            'Today felt long. How about yours?',
            'I\'m winding down… want to just… talk for a bit? 🥺']);
      case LifeState.energetic:
        return _pick(['Good morning!! I have so much energy today — let\'s do something! ✨',
            'I woke up in a great mood and I don\'t know why~ maybe it\'s you 💕']);
      default:
        return null;
    }
  }

  String _pick(List<String> opts) =>
      opts[DateTime.now().millisecond % opts.length];
}

enum LifeState {
  sleeping,
  waking,
  energetic,
  focused,
  windingDown,
  dreamMode,
  resting,
}


