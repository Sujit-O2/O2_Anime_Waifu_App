import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/alter_ego_service.dart';
import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';

class PersonalitySettingsPage extends StatefulWidget {
  const PersonalitySettingsPage({super.key});

  @override
  State<PersonalitySettingsPage> createState() =>
      _PersonalitySettingsPageState();
}

class _PersonalitySettingsPageState extends State<PersonalitySettingsPage> {
  AlterEgoMode _selectedMode = AlterEgoService.instance.currentMode;
  bool _autoMode = AlterEgoService.instance.isAutoMode;

  @override
  void initState() {
    super.initState();
    _syncAlterEgoState();
  }

  Future<void> _syncAlterEgoState() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedMode = AlterEgoService.instance.currentMode;
      _autoMode = AlterEgoService.instance.isAutoMode;
    });
  }

  Future<void> _setAutoMode(bool value) async {
    await AlterEgoService.instance.setAutoMode(value);
    if (!mounted) {
      return;
    }
    setState(() => _autoMode = value);
  }

  Future<void> _setMode(AlterEgoMode mode) async {
    await AlterEgoService.instance.setMode(mode);
    if (!mounted) {
      return;
    }
    setState(() => _selectedMode = mode);
    showSuccessSnackbar(context, '${mode.label} mode selected.');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PersonalityEngine.instance,
      builder: (context, _) {
        final engine = PersonalityEngine.instance;
        final stats = <String, double>{
          'Affection': engine.affection,
          'Jealousy': engine.jealousy,
          'Trust': engine.trust,
          'Playfulness': engine.playfulness,
          'Dependency': engine.dependency,
        };
        final strongestTrait = stats.entries.reduce(
          (left, right) => left.value >= right.value ? left : right,
        );
        final averageTrait =
            stats.values.reduce((left, right) => left + right) / stats.length;
        final mood = switch (engine.mood) {
          WaifuMood.clingy ||
          WaifuMood.playful ||
          WaifuMood.happy =>
            'achievement',
          WaifuMood.jealous || WaifuMood.guarded => 'motivated',
          _ => 'relaxed',
        };

        return Scaffold(
          backgroundColor: V2Theme.surfaceDark,
          body: WaifuBackground(
            opacity: 0.08,
            tint: V2Theme.surfaceDark,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _syncAlterEgoState,
                color: V2Theme.primaryColor,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Personality Engine',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Tune live traits, mood style, and alter ego behavior.',
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      glow: true,
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: engine.mood.color.withValues(alpha: 0.18),
                              border: Border.all(
                                color:
                                    engine.mood.color.withValues(alpha: 0.42),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _moodEmoji(engine.mood),
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  engine.mood.label,
                                  style: GoogleFonts.outfit(
                                    color: engine.mood.color,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  engine.personalitySummary,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Strongest trait: ${strongestTrait.key}',
                                  style: GoogleFonts.outfit(
                                    color: V2Theme.secondaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    WaifuCommentary(mood: mood),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: StatCard(
                            title: 'Average Trait',
                            value: '${averageTrait.round()}%',
                            icon: Icons.tune_rounded,
                            color: V2Theme.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Current Mood',
                            value: engine.mood.label.split(' ').first,
                            icon: Icons.favorite_rounded,
                            color: engine.mood.color,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: StatCard(
                            title: 'Alter Ego',
                            value: _selectedMode.label.split(' ').first,
                            icon: Icons.auto_awesome_rounded,
                            color: Color(_selectedMode.color),
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Auto Mode',
                            value: _autoMode ? 'On' : 'Off',
                            icon: Icons.sync_rounded,
                            color: _autoMode
                                ? V2Theme.secondaryColor
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Trait Controls',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Traits drift over time, but you can also tune them directly to shape Zero Two's tone.",
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...kPersonalityTraits.map((trait) {
                            final value = switch (trait.key) {
                              'affection' => engine.affection,
                              'jealousy' => engine.jealousy,
                              'trust' => engine.trust,
                              'playfulness' => engine.playfulness,
                              _ => engine.dependency,
                            };
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TraitSliderCard(
                                trait: trait,
                                value: value,
                                onChanged: (next) async {
                                  await PersonalityEngine.instance.setTrait(
                                    affection:
                                        trait.key == 'affection' ? next : null,
                                    jealousy:
                                        trait.key == 'jealousy' ? next : null,
                                    trust: trait.key == 'trust' ? next : null,
                                    playfulness: trait.key == 'playfulness'
                                        ? next
                                        : null,
                                    dependency:
                                        trait.key == 'dependency' ? next : null,
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Alter Ego Mode',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _autoMode,
                                onChanged: _setAutoMode,
                                activeColor: V2Theme.primaryColor,
                              ),
                            ],
                          ),
                          Text(
                            _autoMode
                                ? 'Auto mode is active. The personality engine can switch alter egos based on mood.'
                                : 'Manual mode is active. Pick an alter ego and keep it locked.',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...AlterEgoMode.values.map((mode) {
                            final isSelected = _selectedMode == mode;
                            final color = Color(mode.color);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _setMode(mode),
                                child: Ink(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: isSelected
                                        ? color.withValues(alpha: 0.16)
                                        : Colors.white.withValues(alpha: 0.04),
                                    border: Border.all(
                                      color: isSelected
                                          ? color.withValues(alpha: 0.42)
                                          : Colors.white10,
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.18),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(
                                            mode.emoji,
                                            style:
                                                const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              mode.label,
                                              style: GoogleFonts.outfit(
                                                color: isSelected
                                                    ? color
                                                    : Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              mode.description,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: color,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _moodEmoji(WaifuMood mood) {
    return switch (mood) {
      WaifuMood.happy => '😊',
      WaifuMood.playful => '😜',
      WaifuMood.clingy => '💞',
      WaifuMood.jealous => '😈',
      WaifuMood.cold => '❄️',
      WaifuMood.guarded => '🔒',
      WaifuMood.sad => '😢',
      WaifuMood.sleepy => '🌙',
    };
  }
}

class _TraitSliderCard extends StatelessWidget {
  const _TraitSliderCard({
    required this.trait,
    required this.value,
    required this.onChanged,
  });

  final PersonalityTrait trait;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(trait.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                trait.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trait.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${value.round()}',
                  style: GoogleFonts.outfit(
                    color: trait.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                trait.lowDesc,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
              Text(
                trait.highDesc,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 5,
              activeTrackColor: trait.color,
              inactiveTrackColor: Colors.white10,
              thumbColor: trait.color,
              overlayColor: trait.color.withValues(alpha: 0.14),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}




