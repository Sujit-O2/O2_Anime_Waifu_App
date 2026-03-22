class PersonalityTraits {
  double affection;
  double jealousy;
  double trust;
  double playfulness;
  double dependency;

  PersonalityTraits({
    this.affection = 50.0,
    this.jealousy = 30.0,
    this.trust = 50.0,
    this.playfulness = 60.0,
    this.dependency = 40.0,
  });

  Map<String, dynamic> toJson() => {
        'affection': affection,
        'jealousy': jealousy,
        'trust': trust,
        'playfulness': playfulness,
        'dependency': dependency,
      };

  factory PersonalityTraits.fromJson(Map<String, dynamic> json) =>
      PersonalityTraits(
        affection: (json['affection'] as num?)?.toDouble() ?? 50.0,
        jealousy: (json['jealousy'] as num?)?.toDouble() ?? 30.0,
        trust: (json['trust'] as num?)?.toDouble() ?? 50.0,
        playfulness: (json['playfulness'] as num?)?.toDouble() ?? 60.0,
        dependency: (json['dependency'] as num?)?.toDouble() ?? 40.0,
      );

  void applyDailyDrift() {
    affection += (affection > 70) ? -0.5 : 0.2;
    jealousy += (jealousy > 60) ? -0.3 : 0.1;
    trust += 0.1;
    playfulness += (playfulness < 40) ? 0.3 : -0.1;
    dependency += (dependency > 80) ? -0.4 : 0.15;
    _clamp();
  }

  void _clamp() {
    affection = affection.clamp(0.0, 100.0);
    jealousy = jealousy.clamp(0.0, 100.0);
    trust = trust.clamp(0.0, 100.0);
    playfulness = playfulness.clamp(0.0, 100.0);
    dependency = dependency.clamp(0.0, 100.0);
  }

  String toContextString() {
    return '[Personality] Affection: ${affection.toStringAsFixed(1)}, '
        'Jealousy: ${jealousy.toStringAsFixed(1)}, '
        'Trust: ${trust.toStringAsFixed(1)}, '
        'Playfulness: ${playfulness.toStringAsFixed(1)}, '
        'Dependency: ${dependency.toStringAsFixed(1)}';
  }
}
