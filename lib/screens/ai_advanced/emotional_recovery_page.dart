import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/emotional_recovery_service.dart';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EmotionalRecoveryPage extends StatefulWidget {
  const EmotionalRecoveryPage({super.key});
  @override
  State<EmotionalRecoveryPage> createState() => _EmotionalRecoveryPageState();
}

class _EmotionalRecoveryPageState extends State<EmotionalRecoveryPage> {
  final _service = EmotionalRecoveryService.instance;
  bool _loading = true;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.loadPhase();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _trigger() async {
    HapticFeedback.mediumImpact();
    await _service.checkAndTrigger(
      gapSinceLastInteraction: const Duration(hours: 4),
      ignoredStreak: 0,
      trustScore: 50,
    );
    if (mounted) setState(() {});
  }

  Future<void> _reset() async {
    HapticFeedback.mediumImpact();
    setState(() => _resetting = true);
    await _service.resetRecovery();
    if (mounted) {
      setState(() => _resetting = false);
      showSuccessSnackbar(context, 'Recovery arc reset');
    }
  }

  Color _phaseColor(RecoveryPhase p) {
    switch (p) {
      case RecoveryPhase.none:        return Colors.lightGreenAccent;
      case RecoveryPhase.soften:      return Colors.lightBlueAccent;
      case RecoveryPhase.acknowledge: return Colors.amberAccent;
      case RecoveryPhase.reduce:      return Colors.orangeAccent;
      case RecoveryPhase.rebuild:     return Colors.tealAccent;
    }
  }

  String _phaseEmoji(RecoveryPhase p) {
    switch (p) {
      case RecoveryPhase.none:        return '💚';
      case RecoveryPhase.soften:      return '🌸';
      case RecoveryPhase.acknowledge: return '💬';
      case RecoveryPhase.reduce:      return '🌊';
      case RecoveryPhase.rebuild:     return '🏗️';
    }
  }

  String _phaseLabel(RecoveryPhase p) {
    switch (p) {
      case RecoveryPhase.none:        return 'Healthy — No Recovery Needed';
      case RecoveryPhase.soften:      return 'Phase 1: Soften';
      case RecoveryPhase.acknowledge: return 'Phase 2: Acknowledge';
      case RecoveryPhase.reduce:      return 'Phase 3: Reduce';
      case RecoveryPhase.rebuild:     return 'Phase 4: Rebuild';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;
    final phase = _service.phase;
    final color = _phaseColor(phase);
    final progress = _service.progress;

    return FeaturePageV2(
      title: 'EMOTIONAL RECOVERY',
      subtitle: _phaseLabel(phase),
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
          ? const PremiumLoadingState(label: 'Loading recovery state…', icon: Icons.healing_rounded)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Status hero ───────────────────────────────────────────
                AnimatedEntry(
                  index: 0,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    glow: _service.isInRecovery,
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 60, height: 60,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15), border: Border.all(color: color.withValues(alpha: 0.5), width: 2)),
                        child: Center(child: Text(_phaseEmoji(phase), style: const TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Recovery status', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_phaseLabel(phase), style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(value: v, backgroundColor: tokens.outline, valueColor: AlwaysStoppedAnimation(color), minHeight: 7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ])),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stats ─────────────────────────────────────────────────
                AnimatedEntry(
                  index: 1,
                  child: Row(children: [
                    Expanded(child: StatCard(title: 'Phase', value: phase == RecoveryPhase.none ? 'None' : phase.name, icon: Icons.healing_rounded, color: color)),
                    Expanded(child: StatCard(title: 'Progress', value: '${(progress * 100).toStringAsFixed(0)}%', icon: Icons.trending_up_rounded, color: primary)),
                    Expanded(child: StatCard(title: 'Status', value: _service.isInRecovery ? 'Active' : 'Healthy', icon: Icons.favorite_rounded, color: _service.isInRecovery ? Colors.amberAccent : Colors.lightGreenAccent)),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Waifu commentary ───────────────────────────────────────
                AnimatedEntry(index: 2, child: WaifuCommentary(mood: _service.isInRecovery ? 'relaxed' : 'achievement')),
                const SizedBox(height: 16),

                // ── Current hint ──────────────────────────────────────────
                if (_service.isInRecovery) ...[
                  AnimatedEntry(
                    index: 3,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('AI Behaviour Hint', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(_service.getCurrentPhaseHint(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.4)),
                        ])),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Recovery arc phases ───────────────────────────────────
                AnimatedEntry(
                  index: 4,
                  child: Text('RECOVERY ARC', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 10),
                ...RecoveryPhase.values.where((p) => p != RecoveryPhase.none).toList().asMap().entries.map((entry) {
                  final p = entry.value;
                  final isActive = phase == p;
                  final isPast = phase.index > p.index;
                  final c = _phaseColor(p);
                  return AnimatedEntry(
                    index: 5 + entry.key,
                    child: GlassCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: (isPast || isActive) ? c.withValues(alpha: 0.15) : tokens.panelMuted),
                          child: Center(child: Text(_phaseEmoji(p), style: const TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_phaseLabel(p), style: GoogleFonts.outfit(color: isActive ? c : theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(_service.getCurrentPhaseHint(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        if (isPast)
                          const Icon(Icons.check_circle_rounded, color: Colors.lightGreenAccent, size: 18)
                        else if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: Text('Active', style: GoogleFonts.outfit(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                      ]),
                    ),
                  );
                }),

                // ── Triggers ──────────────────────────────────────────────
                const SizedBox(height: 16),
                AnimatedEntry(
                  index: 9,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('RECOVERY TRIGGERS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          '⏰ User returns after 3+ hour gap',
                          '🔇 AI ignored 3+ times in a row',
                          '📉 Trust score drops below 25',
                          '❄️ Conversation becomes cold/short',
                        ].map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Text(t.substring(0, 2), style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t.substring(2).trim(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13))),
                          ]),
                        )).toList(),
                      ),
                    ),
                  ]),
                ),

                // ── Actions ───────────────────────────────────────────────
                const SizedBox(height: 16),
                AnimatedEntry(
                  index: 10,
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _trigger,
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Simulate Trigger'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.tealAccent,
                          side: BorderSide(color: Colors.teal.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetting ? null : _reset,
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: Text(_resetting ? 'Resetting…' : 'Reset Arc'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }
}
