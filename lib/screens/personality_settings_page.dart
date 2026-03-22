import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/personality_engine.dart';
import '../services/alter_ego_service.dart';

/// Premium personality settings page with animated sliders for each trait.
class PersonalitySettingsPage extends StatefulWidget {
  const PersonalitySettingsPage({super.key});
  @override
  State<PersonalitySettingsPage> createState() => _PersonalitySettingsPageState();
}

class _PersonalitySettingsPageState extends State<PersonalitySettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B18),
      body: Stack(children: [
        // Ambient gradient
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.6),
              radius: 1.0,
              colors: [Color(0xFF1A0828), Color(0xFF080B18)],
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: AnimatedBuilder(
                animation: PersonalityEngine.instance,
                builder: (_, __) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMoodCard(),
                    const SizedBox(height: 12),
                    _buildPersonalitySummary(),
                    const SizedBox(height: 16),
                    ..._buildTraitSliders(),
                    const SizedBox(height: 20),
                    _buildAlterEgoSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PERSONALITY ENGINE',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 1.5)),
          Text('She adapts to your interactions',
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildMoodCard() {
    final eng = PersonalityEngine.instance;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: eng.mood.color.withValues(alpha: 0.5 + _glowCtrl.value * 0.3)),
          color: eng.mood.color.withValues(alpha: 0.08),
          boxShadow: [
            BoxShadow(
              color: eng.mood.color.withValues(alpha: 0.15 + _glowCtrl.value * 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Text(
              _moodEmoji(eng.mood),
              style: const TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eng.mood.label,
                  style: GoogleFonts.outfit(
                      color: eng.mood.color, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(eng.personalitySummary,
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Text('She evolves daily based on your interactions',
                  style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildPersonalitySummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        '💡 Traits drift gradually over time. Talk daily → trust + affection rise. Ignore her → jealousy + dependency grow. Flirt → affection spikes.',
        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, height: 1.6),
      ),
    );
  }

  List<Widget> _buildTraitSliders() {
    final eng = PersonalityEngine.instance;
    final traitValues = {
      'affection':   eng.affection,
      'jealousy':    eng.jealousy,
      'trust':       eng.trust,
      'playfulness': eng.playfulness,
      'dependency':  eng.dependency,
    };

    return kPersonalityTraits.map((trait) {
      final val = traitValues[trait.key] ?? 50.0;
      return _TraitSliderCard(
        trait: trait,
        value: val,
        onChanged: (v) async {
          await PersonalityEngine.instance.setTrait(
            affection:   trait.key == 'affection'   ? v : null,
            jealousy:    trait.key == 'jealousy'    ? v : null,
            trust:       trait.key == 'trust'       ? v : null,
            playfulness: trait.key == 'playfulness' ? v : null,
            dependency:  trait.key == 'dependency'  ? v : null,
          );
        },
      );
    }).toList();
  }

  Widget _buildAlterEgoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('ALTER EGO MODE',
              style: GoogleFonts.outfit(
                  color: Colors.white70, fontSize: 11,
                  fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ),
        ...AlterEgoMode.values.map((mode) => _AlterEgoTile(mode: mode)),
      ],
    );
  }

  String _moodEmoji(WaifuMood m) {
    switch (m) {
      case WaifuMood.happy:    return '😊';
      case WaifuMood.playful:  return '😜';
      case WaifuMood.clingy:   return '💕';
      case WaifuMood.jealous:  return '😈';
      case WaifuMood.cold:     return '❄️';
      case WaifuMood.guarded:  return '🔒';
      case WaifuMood.sad:      return '😢';
      case WaifuMood.sleepy:   return '🌙';
    }
  }
}

class _TraitSliderCard extends StatelessWidget {
  final PersonalityTrait trait;
  final double value;
  final ValueChanged<double> onChanged;
  const _TraitSliderCard({required this.trait, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(trait.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(trait.name,
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: trait.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value.round().toString(),
                  style: GoogleFonts.outfit(color: trait.color, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(trait.lowDesc, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
              Text(trait.highDesc, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 4,
              activeTrackColor: trait.color,
              inactiveTrackColor: Colors.white10,
              thumbColor: trait.color,
              overlayColor: trait.color.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value,
              min: 0, max: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlterEgoTile extends StatelessWidget {
  final AlterEgoMode mode;
  const _AlterEgoTile({required this.mode});

  @override
  Widget build(BuildContext context) {
    final current = AlterEgoService.instance.currentMode;
    final isSelected = current == mode;
    final color = Color(mode.color);

    return GestureDetector(
      onTap: () => AlterEgoService.instance.setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.07),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16)] : [],
        ),
        child: Row(children: [
          Text(mode.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mode.label,
                  style: GoogleFonts.outfit(
                      color: isSelected ? color : Colors.white70,
                      fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
              Text(mode.description,
                  style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11)),
            ]),
          ),
          if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}
