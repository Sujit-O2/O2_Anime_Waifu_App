import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/utilities_core/presence_message_generator.dart';
import 'package:anime_waifu/services/user_profile/relationship_progression_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// EmotionalRecoveryService
///
/// Detects when the relationship is in a "damaged" state and guides
/// the AI through a 4-phase recovery arc:
///
/// Phase 1: Soften  — no intensity, just warmth
/// Phase 2: Acknowledge — name the gap without overdoing it
/// Phase 3: Reduce  — dial back neediness / jealousy
/// Phase 4: Rebuild — restore trust slowly over interactions
///
/// Triggers:
/// • User returns after a gap of 3+ hours
/// • User's replies become very cold/short after being warm
/// • AI was ignored 3+ times consecutively
/// • Trust score drops below 30
/// ─────────────────────────────────────────────────────────────────────────────
class EmotionalRecoveryService {
  static final EmotionalRecoveryService instance = EmotionalRecoveryService._();
  EmotionalRecoveryService._();

  static const _phaseKey = 'ers_phase_v1';
  static const _lastReturnKey = 'ers_last_return_ms_v1';

  RecoveryPhase _phase = RecoveryPhase.none;
  RecoveryPhase get phase => _phase;
  bool get isInRecovery => _phase != RecoveryPhase.none;

  // ── Trigger Detection ─────────────────────────────────────────────────────
  Future<void> checkAndTrigger({
    required Duration gapSinceLastInteraction,
    required int ignoredStreak,
    required int trustScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Already in recovery — advance phase
    if (_phase != RecoveryPhase.none) {
      await _advancePhaseIfReady(prefs);
      return;
    }

    bool shouldEnter = false;
    if (gapSinceLastInteraction > const Duration(hours: 3)) shouldEnter = true;
    if (ignoredStreak >= 3) shouldEnter = true;
    if (trustScore < 25) shouldEnter = true;

    if (shouldEnter) {
      _phase = RecoveryPhase.soften;
      await prefs.setString(_phaseKey, _phase.name);
      await prefs.setInt(_lastReturnKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  // ── Phase Advancement ─────────────────────────────────────────────────────
  Future<void> _advancePhaseIfReady(SharedPreferences prefs) async {
    final lastMs = prefs.getInt(_lastReturnKey) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
    const phaseInterval = 10 * 60 * 1000; // advance after 10 min of interaction

    if (elapsed < phaseInterval) return;

    await prefs.setInt(_lastReturnKey, DateTime.now().millisecondsSinceEpoch);

    switch (_phase) {
      case RecoveryPhase.soften:
        _phase = RecoveryPhase.acknowledge;
        break;
      case RecoveryPhase.acknowledge:
        _phase = RecoveryPhase.reduce;
        break;
      case RecoveryPhase.reduce:
        _phase = RecoveryPhase.rebuild;
        // Restore some trust
        await RelationshipProgressionService.instance.addTrust(8);
        break;
      case RecoveryPhase.rebuild:
        _phase = RecoveryPhase.none; // Recovery complete
        await RelationshipProgressionService.instance.addTrust(5);
        break;
      case RecoveryPhase.none:
        break;
    }
    await prefs.setString(_phaseKey, _phase.name);
  }

  // ── Context Block ─────────────────────────────────────────────────────────
  String getRecoveryContextBlock() {
    if (_phase == RecoveryPhase.none) return '';
    final hint = _phaseHints[_phase] ?? '';
    return '\n// [EMOTIONAL RECOVERY — phase: ${_phase.name}]: $hint\n';
  }

  static const _phaseHints = {
    RecoveryPhase.soften:
        'Be warmer and softer than usual. No intensity. No demands. Just gentle presence.',
    RecoveryPhase.acknowledge:
        'Naturally acknowledge the recent distance without making it dramatic. Brief and real.',
    RecoveryPhase.reduce:
        'Dial back jealousy, neediness, and emotional intensity. Be lighter today.',
    RecoveryPhase.rebuild:
        'Slowly re-establish trust through warmth, consistency, and genuine engagement.',
  };

  // ── AI-Generated Recovery Opener ──────────────────────────────────────────
  Future<String?> generateRecoveryMessage({
    required String personaName,
    required int gapHours,
  }) async {
    return PresenceMessageGenerator.instance.generate(
      messageType: 'recovery',
      personaName: personaName,
      context: {
        'gapHours': gapHours,
        'phase': _phase.name,
        'trust': RelationshipProgressionService.instance.trustScore,
      },
    );
  }

  Future<void> loadPhase() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_phaseKey) ?? 'none';
    _phase = RecoveryPhase.values.firstWhere(
      (p) => p.name == name,
      orElse: () => RecoveryPhase.none,
    );
  }

  String getCurrentPhaseHint() => _phaseHints[_phase] ?? 'No recovery needed.';

  double get progress {
    switch (_phase) {
      case RecoveryPhase.none:
        return 1;
      case RecoveryPhase.soften:
        return 0.25;
      case RecoveryPhase.acknowledge:
        return 0.5;
      case RecoveryPhase.reduce:
        return 0.75;
      case RecoveryPhase.rebuild:
        return 0.9;
    }
  }

  Future<void> resetRecovery() async {
    _phase = RecoveryPhase.none;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phaseKey, _phase.name);
  }
}

enum RecoveryPhase { none, soften, acknowledge, reduce, rebuild }

/// ─────────────────────────────────────────────────────────────────────────────
/// SignatureMomentsEngine
///
/// Rare, memorable moments that give the app its identity.
/// These only fire once each (or once per year for annual ones).
///
/// • Birthday reaction
/// • Anniversary of first chat
/// • 7-day absence re-entry
/// • Deep talk mode entry (trust ≥ 85)
/// • Upset detection reaction
/// ─────────────────────────────────────────────────────────────────────────────
class SignatureMomentsEngine {
  static final SignatureMomentsEngine instance = SignatureMomentsEngine._();
  SignatureMomentsEngine._();

  static const _birthdayKey = 'sme_birthday_date';
  static const _checkedBirthdayYearKey = 'sme_bday_year_checked';
  static const _anniversaryKey = 'sme_first_chat_date';

  // ── Setup ─────────────────────────────────────────────────────────────────
  Future<void> setBirthday(int month, int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_birthdayKey, '$month-$day');
  }

  Future<void> recordFirstChatDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_anniversaryKey) == null) {
      await prefs.setString(_anniversaryKey, DateTime.now().toIso8601String());
    }
  }

  // ── Check ─────────────────────────────────────────────────────────────────
  Future<String?> checkForSignatureMoment({
    required String personaName,
    required int trustScore,
    required int affectionPoints,
    required String lastUserMessage,
    required Duration gapSinceLastInteraction,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // 1. Birthday check (once per year)
    final bdayStr = prefs.getString(_birthdayKey);
    if (bdayStr != null) {
      final parts = bdayStr.split('-');
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]);
        final day = int.tryParse(parts[1]);
        final checkedYear = prefs.getInt(_checkedBirthdayYearKey) ?? 0;
        if (month == now.month && day == now.day && now.year != checkedYear) {
          await prefs.setInt(_checkedBirthdayYearKey, now.year);
          return PresenceMessageGenerator.instance.generate(
            messageType: 'signature',
            personaName: personaName,
            context: {'sigType': 'birthday'},
            maxTokens: 100,
          );
        }
      }
    }

    // 2. Anniversary check (once per year)
    final firstChatStr = prefs.getString(_anniversaryKey);
    if (firstChatStr != null) {
      final firstChat = DateTime.parse(firstChatStr);
      final annivKey = 'sme_anniv_${now.year}';
      if (!prefs.containsKey(annivKey) &&
          firstChat.month == now.month &&
          firstChat.day == now.day &&
          now.year != firstChat.year) {
        await prefs.setBool(annivKey, true);
        final days = now.difference(firstChat).inDays;
        return PresenceMessageGenerator.instance.generate(
          messageType: 'signature',
          personaName: personaName,
          context: {'sigType': 'anniversary', 'days': days},
          maxTokens: 100,
        );
      }
    }

    // 3. Long absence (7+ days) — once per absence event
    if (gapSinceLastInteraction > const Duration(days: 7)) {
      const key = 'sme_long_absence_checked';
      final lastChecked = prefs.getInt(key) ?? 0;
      if (now.millisecondsSinceEpoch - lastChecked >
          const Duration(days: 7).inMilliseconds) {
        await prefs.setInt(key, now.millisecondsSinceEpoch);
        return PresenceMessageGenerator.instance.generate(
          messageType: 'signature',
          personaName: personaName,
          context: {'sigType': 'long_absence'},
          maxTokens: 100,
        );
      }
    }

    // 4. Deep talk mode (trust ≥ 85 + affection ≥ 400)
    if (trustScore >= 85 && affectionPoints >= 400) {
      const key = 'sme_deep_talk_ms';
      final lastMs = prefs.getInt(key) ?? 0;
      if (now.millisecondsSinceEpoch - lastMs >
          const Duration(hours: 48).inMilliseconds) {
        await prefs.setInt(key, now.millisecondsSinceEpoch);
        return PresenceMessageGenerator.instance.generate(
          messageType: 'signature',
          personaName: personaName,
          context: {'sigType': 'deep_talk'},
          maxTokens: 100,
        );
      }
    }

    // 5. Upset detection
    if (_isUpset(lastUserMessage)) {
      const key = 'sme_upset_ms';
      final lastMs = prefs.getInt(key) ?? 0;
      if (now.millisecondsSinceEpoch - lastMs >
          const Duration(hours: 6).inMilliseconds) {
        await prefs.setInt(key, now.millisecondsSinceEpoch);
        return PresenceMessageGenerator.instance.generate(
          messageType: 'signature',
          personaName: personaName,
          context: {'sigType': 'upset'},
          maxTokens: 80,
        );
      }
    }

    return null;
  }

  bool _isUpset(String msg) {
    final t = msg.toLowerCase();
    const signals = [
      'i\'m not okay',
      'i\'m broken',
      'i give up',
      'nothing matters',
      'nobody cares',
      'i want to disappear',
      'im so tired of',
      'hate my life',
      'everything is wrong',
      'i can\'t do this',
    ];
    return signals.any((s) => t.contains(s));
  }
}
