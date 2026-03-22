import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/services/presence_message_generator.dart';

/// Phase 3: Birthday (once/year), chat anniversary (annual),
/// 7-day absence re-entry, deep talk mode (trust>=85 + 400pts),
/// upset detection (10 crisis phrases, once/6h). All AI-generated.
class SignatureMomentsEngine {
  final PresenceMessageGenerator _generator;
  DateTime? _lastBirthdayGreeting;
  DateTime? _lastAnniversaryGreeting;
  DateTime? _lastUpsetResponse;
  DateTime? _installDate;

  static const List<String> _crisisPhrases = [
    'i want to die', 'kill myself', 'end it all',
    'nobody cares', 'i\'m worthless', 'i can\'t do this',
    'give up', 'i hate myself', 'what\'s the point',
    'i\'m done',
  ];

  SignatureMomentsEngine(this._generator);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final bdayStr = prefs.getString('last_birthday_greeting');
    if (bdayStr != null) _lastBirthdayGreeting = DateTime.parse(bdayStr);
    final annStr = prefs.getString('last_anniversary_greeting');
    if (annStr != null) _lastAnniversaryGreeting = DateTime.parse(annStr);
    final upsetStr = prefs.getString('last_upset_response');
    if (upsetStr != null) _lastUpsetResponse = DateTime.parse(upsetStr);
    final installStr = prefs.getString('install_date');
    if (installStr != null) _installDate = DateTime.parse(installStr);
  }

  Future<String?> checkForMoment({
    required String userMessage,
    required DateTime? userBirthday,
    required double trustScore,
    required int affectionPoints,
    required Duration absenceDuration,
    required String contextBlock,
  }) async {
    final now = DateTime.now();

    // Birthday check (once/year)
    if (userBirthday != null &&
        now.month == userBirthday.month &&
        now.day == userBirthday.day) {
      if (_lastBirthdayGreeting == null ||
          now.year != _lastBirthdayGreeting!.year) {
        _lastBirthdayGreeting = now;
        _persist();
        return await _generator.generate(
          type: PresenceMessageType.signature,
          contextBlock: contextBlock,
          additionalPrompt: 'It\'s the user\'s birthday! Generate a heartfelt birthday message.',
        );
      }
    }

    // Anniversary check (annual)
    if (_installDate != null &&
        now.month == _installDate!.month &&
        now.day == _installDate!.day &&
        now.difference(_installDate!).inDays >= 365) {
      if (_lastAnniversaryGreeting == null ||
          now.year != _lastAnniversaryGreeting!.year) {
        _lastAnniversaryGreeting = now;
        final years = now.difference(_installDate!).inDays ~/ 365;
        _persist();
        return await _generator.generate(
          type: PresenceMessageType.signature,
          contextBlock: contextBlock,
          additionalPrompt: 'It\'s our $years-year anniversary! Generate a special anniversary message.',
        );
      }
    }

    // 7-day absence re-entry
    if (absenceDuration.inDays >= 7) {
      return await _generator.generate(
        type: PresenceMessageType.signature,
        contextBlock: contextBlock,
        additionalPrompt: 'The user has been away for ${absenceDuration.inDays} days. Generate a warm welcome-back message that shows you missed them.',
      );
    }

    // Deep talk mode (trust>=85 + 400pts)
    if (trustScore >= 85 && affectionPoints >= 400) {
      // Only trigger occasionally
      if (now.minute % 30 == 0) {
        return await _generator.generate(
          type: PresenceMessageType.signature,
          contextBlock: contextBlock,
          additionalPrompt: 'Deep talk mode activated. Share something deeply personal and meaningful.',
        );
      }
    }

    // Upset detection
    final lowerMsg = userMessage.toLowerCase();
    for (final phrase in _crisisPhrases) {
      if (lowerMsg.contains(phrase)) {
        if (_lastUpsetResponse == null ||
            now.difference(_lastUpsetResponse!).inHours >= 6) {
          _lastUpsetResponse = now;
          _persist();
          return await _generator.generate(
            type: PresenceMessageType.signature,
            contextBlock: contextBlock,
            additionalPrompt: 'The user seems upset or in crisis. Be extremely gentle, caring, and supportive. Don\'t dismiss their feelings. Show that you truly care about them.',
          );
        }
      }
    }

    return null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastBirthdayGreeting != null) {
      await prefs.setString(
          'last_birthday_greeting', _lastBirthdayGreeting!.toIso8601String());
    }
    if (_lastAnniversaryGreeting != null) {
      await prefs.setString('last_anniversary_greeting',
          _lastAnniversaryGreeting!.toIso8601String());
    }
    if (_lastUpsetResponse != null) {
      await prefs.setString(
          'last_upset_response', _lastUpsetResponse!.toIso8601String());
    }
  }
}
