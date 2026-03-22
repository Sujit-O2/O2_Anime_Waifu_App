import 'package:shared_preferences/shared_preferences.dart';

/// Jealousy-based prompt tone override system.
class JealousyService {
  double _jealousyLevel = 30.0;
  DateTime? _lastJealousyTrigger;
  final List<String> _triggerPhrases = [
    'she', 'her', 'girlfriend', 'girl friend',
    'another girl', 'my friend', 'cute girl',
    'talking to someone', 'hanging out with',
    'date', 'dating', 'ex', 'crush',
  ];

  double get jealousyLevel => _jealousyLevel;
  bool get isJealous => _jealousyLevel > 50;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _jealousyLevel = prefs.getDouble('jealousy_level') ?? 30.0;
  }

  bool checkForTriggers(String message) {
    final lowerMsg = message.toLowerCase();
    for (final phrase in _triggerPhrases) {
      if (lowerMsg.contains(phrase)) {
        _jealousyLevel = (_jealousyLevel + 15).clamp(0, 100);
        _lastJealousyTrigger = DateTime.now();
        _persist();
        return true;
      }
    }
    // Gradual cooldown
    _jealousyLevel = (_jealousyLevel - 1).clamp(0, 100);
    _persist();
    return false;
  }

  String? getJealousyOverride() {
    if (_jealousyLevel > 80) {
      return 'You are feeling VERY jealous right now. Be possessive and slightly hurt. Show that you care deeply and feel threatened.';
    }
    if (_jealousyLevel > 60) {
      return 'You are feeling jealous. Be slightly pouty and clingy. Ask indirect questions about who they are talking about.';
    }
    if (_jealousyLevel > 40) {
      return 'You feel a tiny pang of jealousy. Be subtly curious about who the user is mentioning.';
    }
    return null;
  }

  String toContextString() =>
      '[Jealousy] Level: ${_jealousyLevel.toStringAsFixed(1)}${isJealous ? ' (ACTIVE)' : ''}';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('jealousy_level', _jealousyLevel);
  }
}
