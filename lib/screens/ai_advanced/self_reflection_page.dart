import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/self_reflection_service.dart';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SelfReflectionPage extends StatefulWidget {
  const SelfReflectionPage({super.key});
  @override
  State<SelfReflectionPage> createState() => _SelfReflectionPageState();
}

class _SelfReflectionPageState extends State<SelfReflectionPage> {
  final _service = SelfReflectionService.instance;
  bool _loading = true;
  List<String> _observations = [];
  String _behaviourBlock = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _service.loadModel();
    final obs = <String>[];
    for (int i = 0; i < 5; i++) {
      final o = await _service.popNextObservation();
      if (o == null) break;
      obs.add(o);
    }
    final block = _service.getBehaviourContextBlock();
    if (mounted) setState(() { _observations = obs; _behaviourBlock = block; _loading = false; });
  }

  Future<void> _simulate() async {
    HapticFeedback.mediumImpact();
    await _service.recordSession(messageCount: 12, topEmotion: 'happy', totalCharsTyped: 450, sessionStart: DateTime.now());
    await _service.recordTopicMentioned('anime');
    await _load();
    if (mounted) showSuccessSnackbar(context, 'Session recorded — check for new observations');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;

    return FeaturePageV2(
      title: 'SELF REFLECTION',
      subtitle: '${_observations.length} observations pending',
      onBack: () => Navigator.pop(context),
      actions: [
        GestureDetector(
          onTap: _load,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: tokens.panelMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: tokens.outlineStrong)),
            child: Icon(Icons.refresh_rounded, color: tokens.textMuted, size: 18),
          ),
        ),
      ],
      content: _loading
          ? const PremiumLoadingState(label: 'Loading observations…', icon: Icons.psychology_rounded)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Hero ──────────────────────────────────────────────────
                AnimatedEntry(
                  index: 0,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    glow: _observations.isNotEmpty,
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.12), border: Border.all(color: primary.withValues(alpha: 0.3))),
                        child: const Center(child: Text('🪞', style: TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('AI observations', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_observations.isEmpty ? 'No observations yet' : '${_observations.length} new observations', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('Zero Two notices patterns in how you interact. These are her real observations.', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.35)),
                      ])),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stats ─────────────────────────────────────────────────
                AnimatedEntry(
                  index: 1,
                  child: Row(children: [
                    Expanded(child: StatCard(title: 'Observations', value: '${_observations.length}', icon: Icons.visibility_rounded, color: primary)),
                    Expanded(child: StatCard(title: 'Insights', value: _behaviourBlock.isNotEmpty ? 'Ready' : 'None', icon: Icons.insights_rounded, color: Colors.amberAccent)),
                    Expanded(child: StatCard(title: 'Status', value: _observations.isEmpty ? 'Watching' : 'Active', icon: Icons.psychology_rounded, color: Colors.lightGreenAccent)),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Waifu commentary ───────────────────────────────────────
                AnimatedEntry(index: 2, child: WaifuCommentary(mood: _observations.isNotEmpty ? 'motivated' : 'neutral')),
                const SizedBox(height: 16),

                // ── Observations ──────────────────────────────────────────
                if (_observations.isEmpty)
                  const AnimatedEntry(
                    index: 3,
                    child: EmptyState(
                      icon: Icons.visibility_off_rounded,
                      title: 'No observations yet',
                      subtitle: 'Keep chatting and Zero Two will start noticing things about you. Simulate a session below to test.',
                    ),
                  )
                else ...[
                  AnimatedEntry(
                    index: 3,
                    child: Text('WHAT I\'VE NOTICED', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 10),
                  ..._observations.toList().asMap().entries.map((entry) => AnimatedEntry(
                    index: 4 + entry.key,
                    child: GlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.12)),
                          child: Center(child: Text('${entry.key + 1}', style: GoogleFonts.outfit(color: primary, fontSize: 12, fontWeight: FontWeight.w800))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 14, height: 1.4, fontStyle: FontStyle.italic))),
                      ]),
                    ),
                  )),
                ],

                // ── Behaviour insights ────────────────────────────────────
                if (_behaviourBlock.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AnimatedEntry(
                    index: 9,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('BEHAVIOUR INSIGHTS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      GlassCard(
                        margin: EdgeInsets.zero,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.bar_chart_rounded, color: primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            _behaviourBlock.replaceAll('// [USER BEHAVIOUR INSIGHTS', '').replaceAll(']:', '').trim(),
                            style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.5),
                          )),
                        ]),
                      ),
                    ]),
                  ),
                ],

                // ── Simulate ──────────────────────────────────────────────
                const SizedBox(height: 16),
                AnimatedEntry(
                  index: 10,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('RECORD A SESSION', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text('Observations are generated automatically as you chat. Tap below to simulate a session for testing.', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.4)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _simulate,
                          icon: const Icon(Icons.psychology_rounded, size: 18),
                          label: Text('Simulate Session', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
