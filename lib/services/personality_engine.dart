import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/models/personality_traits.dart';
import 'package:o2_waifu/models/waifu_mood.dart';

/// 5 dynamic personality traits with mood system and daily drift.
class PersonalityEngine {
  PersonalityTraits _traits = PersonalityTraits();
  WaifuMood _currentMood = WaifuMood.neutral;
  DateTime _lastDriftDate = DateTime.now();

  PersonalityTraits get traits => _traits;
  WaifuMood get currentMood => _currentMood;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('personality_traits');
    if (stored != null) {
      _traits =
          PersonalityTraits.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    }
    final moodIndex = prefs.getInt('current_mood') ?? WaifuMood.neutral.index;
    _currentMood = WaifuMood.values[moodIndex.clamp(0, WaifuMood.values.length - 1)];
    final driftStr = prefs.getString('last_drift_date');
    if (driftStr != null) _lastDriftDate = DateTime.parse(driftStr);

    _checkDailyDrift();
  }

  void updateMood(WaifuMood mood) {
    _currentMood = mood;
    _persist();
  }

  void adjustTrait({
    double? affection,
    double? jealousy,
    double? trust,
    double? playfulness,
    double? dependency,
  }) {
    if (affection != null) _traits.affection += affection;
    if (jealousy != null) _traits.jealousy += jealousy;
    if (trust != null) _traits.trust += trust;
    if (playfulness != null) _traits.playfulness += playfulness;
    if (dependency != null) _traits.dependency += dependency;
    _traits = PersonalityTraits(
      affection: _traits.affection.clamp(0, 100),
      jealousy: _traits.jealousy.clamp(0, 100),
      trust: _traits.trust.clamp(0, 100),
      playfulness: _traits.playfulness.clamp(0, 100),
      dependency: _traits.dependency.clamp(0, 100),
    );
    _persist();
  }

  WaifuMood inferMoodFromContext({
    required double sentiment,
    bool isLongSilence = false,
    bool mentionedOtherPerson = false,
  }) {
    if (mentionedOtherPerson && _traits.jealousy > 50) {
      return WaifuMood.jealous;
    }
    if (isLongSilence && _traits.dependency > 60) {
      return WaifuMood.sad;
    }
    if (sentiment > 0.7 && _traits.affection > 60) {
      return WaifuMood.affectionate;
    }
    if (sentiment > 0.5) return WaifuMood.happy;
    if (sentiment < 0.3) return WaifuMood.sad;
    return WaifuMood.neutral;
  }

  void _checkDailyDrift() {
    final now = DateTime.now();
    if (now.difference(_lastDriftDate).inHours >= 24) {
      _traits.applyDailyDrift();
      _lastDriftDate = now;
      _persist();
    }
  }

  String toContextString() {
    return '${_traits.toContextString()}\n[Mood] ${_currentMood.displayName} ${_currentMood.emoji}';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personality_traits', jsonEncode(_traits.toJson()));
    await prefs.setInt('current_mood', _currentMood.index);
    await prefs.setString('last_drift_date', _lastDriftDate.toIso8601String());
  }
}
