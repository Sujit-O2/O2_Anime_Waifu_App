import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/personality_evolution_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalityEvolutionPage extends StatefulWidget {
  const PersonalityEvolutionPage({super.key});
  @override
  State<PersonalityEvolutionPage> createState() => _PersonalityEvolutionPageState();
}

class _PersonalityEvolutionPageState extends State<PersonalityEvolutionPage> {
  final _service = PersonalityEvolutionService.instance;
  bool _loading = true;
  Map<PersonalityTrait, double> _traits = {};
  String _description = '';
  String _modifier = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.initialize();
    if (mounted) {
      setState(() {
        _traits = _service.getAllTraits();
        _description = _service.getPersonalityDescription();
        _modifier = _service.getSystemPromptModifier();
        _loading = false;
      });
    }
  }

  Future<void> _record(InteractionType type) async {
    HapticFeedback.mediumImpact();
    await _service.recordInteraction(
      userMessage: 'Simulated interaction',
      aiResponse: 'Response recorded',
      type: type,
      emotionalIntensity: 0.7,
    );
    if (mounted) {
      setState(() {
        _traits = _service.getAllTraits();
        _description = _service.getPersonalityDescription();
        _modifier = _service.getSystemPromptModifier();
      });
      showSuccessSnackbar(context, '${type.name} interaction recorded');
    }
  }

  String _stage() {
    final avg = _traits.isEmpty ? 0.0 : _traits.values.fold(0.0, (a, b) => a + b) / _traits.length;
    if (avg > 0.75) return '🌟 Fully Evolved';
    if (avg > 0.6) return '💫 Advanced';
    if (avg > 0.45) return '🌱 Developing';
    return '🌀 Awakening';
  }

  double _avgTrait() => _traits.isEmpty ? 0 : _traits.values.fold(0.0, (a, b) => a + b) / _traits.length;

  // Extract the insight line from description
  String _insight() {
    final lines = _description.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.lastWhere((l) => l.contains('~') || l.contains('💕') || l.contains('💖'), orElse: () => lines.isNotEmpty ? lines.last : '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;
    final sorted = _traits.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return FeaturePageV2(
      title: 'PERSONALITY EVOLUTION',
      subtitle: _stage(),
      onBack: () => Navigator.pop(context),
      content: _loading
          ? const PremiumLoadingState(label: 'Loading personality data…', icon: Icons.auto_awesome_rounded)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Hero ──────────────────────────────────────────────────
                AnimatedEntry(
                  index: 0,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    glow: true,
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Evolution stage', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(_stage(), style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          _insight().isNotEmpty ? _insight() : 'Personality evolves with every interaction you have.',
                          style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.35),
                        ),
                      ])),
                      const SizedBox(width: 16),
                      ProgressRing(
                        progress: _avgTrait(),
                        foreground: primary,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🧬', style: TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text('${(_avgTrait() * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('Overall', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 10)),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stats ─────────────────────────────────────────────────
                AnimatedEntry(
                  index: 1,
                  child: Row(children: [
                    Expanded(child: StatCard(title: 'Top Trait', value: sorted.isNotEmpty ? sorted.first.key.label : '--', icon: Icons.star_rounded, color: Colors.amberAccent)),
                    Expanded(child: StatCard(title: 'Avg Level', value: '${(_avgTrait() * 100).toStringAsFixed(0)}%', icon: Icons.trending_up_rounded, color: primary)),
                    Expanded(child: StatCard(title: 'Traits', value: '${_traits.length}', icon: Icons.psychology_rounded, color: Colors.purpleAccent)),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Traits ────────────────────────────────────────────────
                AnimatedEntry(
                  index: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PERSONALITY TRAITS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: sorted.toList().asMap().entries.map((entry) {
                          final trait = entry.value.key;
                          final val = entry.value.value;
                          final color = val > 0.7 ? primary : val > 0.5 ? Colors.purpleAccent : tokens.textMuted;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(children: [
                              Text(trait.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              SizedBox(width: 100, child: Text(trait.label, style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12))),
                              Expanded(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: val.clamp(0.0, 1.0)),
                                  duration: Duration(milliseconds: 500 + entry.key * 60),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, __) => ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(value: v, backgroundColor: tokens.outline, valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${(val * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                            ]),
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                ),

                // ── Active modifier ───────────────────────────────────────
                if (_modifier.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AnimatedEntry(
                    index: 3,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ACTIVE MODIFIERS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      GlassCard(
                        margin: EdgeInsets.zero,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.auto_awesome_rounded, color: primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_modifier, style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.4))),
                        ]),
                      ),
                    ]),
                  ),
                ],

                // ── Record interaction ─────────────────────────────────────
                const SizedBox(height: 16),
                AnimatedEntry(
                  index: 4,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('RECORD INTERACTION', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Personality evolves based on how you interact. Tap a type to record one.', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.4)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: InteractionType.values.map((t) => GestureDetector(
                            onTap: () => _record(t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(t.name, style: GoogleFonts.outfit(color: primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          )).toList(),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }
}
