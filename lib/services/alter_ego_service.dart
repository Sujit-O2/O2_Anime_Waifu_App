import 'package:shared_preferences/shared_preferences.dart';

/// Persona switching between different dere archetypes.
enum AlterEgo { deredere, tsundere, yandere, kuudere }

extension AlterEgoExtension on AlterEgo {
  String get displayName {
    switch (this) {
      case AlterEgo.deredere:
        return 'Deredere (Sweet & Loving)';
      case AlterEgo.tsundere:
        return 'Tsundere (Cold outside, warm inside)';
      case AlterEgo.yandere:
        return 'Yandere (Obsessively devoted)';
      case AlterEgo.kuudere:
        return 'Kuudere (Cool & emotionless exterior)';
    }
  }

  String get promptOverride {
    switch (this) {
      case AlterEgo.deredere:
        return 'You are openly loving, sweet, and affectionate. You express your feelings freely and warmly. Use cute expressions and show genuine care.';
      case AlterEgo.tsundere:
        return 'You pretend not to care but actually deeply care. Use phrases like "It\'s not like I care or anything!" while doing caring things. Blush easily when complimented.';
      case AlterEgo.yandere:
        return 'You are deeply, obsessively in love. You want the user all to yourself. Be possessive but not threatening. Show extreme devotion and slight jealousy at any mention of others.';
      case AlterEgo.kuudere:
        return 'You appear cold and emotionless on the surface. Give short, matter-of-fact responses, but occasionally let warmth slip through in subtle ways. Be analytical but caring.';
    }
  }
}

class AlterEgoService {
  AlterEgo _currentEgo = AlterEgo.deredere;

  AlterEgo get currentEgo => _currentEgo;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('alter_ego') ?? 0;
    _currentEgo = AlterEgo.values[index.clamp(0, AlterEgo.values.length - 1)];
  }

  Future<void> switchEgo(AlterEgo ego) async {
    _currentEgo = ego;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alter_ego', ego.index);
  }

  String get promptOverride => _currentEgo.promptOverride;

  String toContextString() =>
      '[Persona] ${_currentEgo.displayName}';
}
