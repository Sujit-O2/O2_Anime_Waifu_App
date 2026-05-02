import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/wellness/stress_detection_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class StressDetectionPage extends StatefulWidget {
  const StressDetectionPage({super.key});
  @override
  State<StressDetectionPage> createState() => _StressDetectionPageState();
}

class _StressDetectionPageState extends State<StressDetectionPage> {
  final _service = StressDetectionService.instance;
  double _voice = 0.35;
  double _typing = 0.35;
  bool _loading = true;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _record() async {
    HapticFeedback.mediumImpact();
    setState(() => _recording = true);
    await _service.recordStressReading(voiceStress: _voice, typingStress: _typing, context: 'Manual wellness check');
    if (mounted) {
      setState(() => _recording = false);
      showSuccessSnackbar(context, 'Stress reading recorded');
    }
  }

  Color _stressColor(double s) {
    if (s < 0.3) return Colors.lightGreenAccent;
    if (s < 0.6) return Colors.amberAccent;
    return Colors.redAccent;
  }

  String _stressLabel(double s) {
    if (s < 0.3) return 'Low 😌';
    if (s < 0.6) return 'Moderate 😐';
    return 'High 😰';
  }

  String _commentaryMood(double s) {
    if (s < 0.3) return 'achievement';
    if (s < 0.6) return 'motivated';
    return 'relaxed';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final latest = _service.latestReading;
    final stress = latest?.combinedStress ?? 0.0;
    final stressColor = _stressColor(stress);
    final readings = _service.getReadings();

    return FeaturePageV2(
      title: 'STRESS DETECTION',
      subtitle: _loading ? 'Loading…' : _stressLabel(stress),
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
          ? const PremiumLoadingState(label: 'Initialising stress monitor…', icon: Icons.monitor_heart_rounded)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Hero gauge ────────────────────────────────────────────
                AnimatedEntry(
                  index: 0,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    glow: true,
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Current stress level', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(_stressLabel(stress), style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: stress.clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(value: v, backgroundColor: tokens.outline, valueColor: AlwaysStoppedAnimation(stressColor), minHeight: 10),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(latest == null ? 'No readings yet — record one below.' : 'Voice ${(latest.voiceStress * 100).toStringAsFixed(0)}%  •  Typing ${(latest.typingStress * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
                      ])),
                      const SizedBox(width: 16),
                      RepaintBoundary(
                        child: ProgressRing(
                          progress: stress,
                          foreground: stressColor,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(stress < 0.3 ? '😌' : stress < 0.6 ? '😐' : '😰', style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text('${(stress * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
                            Text('Stress', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 10)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stats ─────────────────────────────────────────────────
                AnimatedEntry(
                  index: 1,
                  child: Row(children: [
                    Expanded(child: StatCard(title: 'Readings', value: '${readings.length}', icon: Icons.history_rounded, color: theme.colorScheme.primary)),
                    Expanded(child: StatCard(title: 'Voice', value: '${(_voice * 100).toStringAsFixed(0)}%', icon: Icons.mic_rounded, color: Colors.lightBlueAccent)),
                    Expanded(child: StatCard(title: 'Typing', value: '${(_typing * 100).toStringAsFixed(0)}%', icon: Icons.keyboard_rounded, color: Colors.amberAccent)),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Waifu commentary ───────────────────────────────────────
                AnimatedEntry(index: 2, child: WaifuCommentary(mood: _commentaryMood(stress))),
                const SizedBox(height: 16),

                // ── Insights ──────────────────────────────────────────────
                AnimatedEntry(
                  index: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('INSIGHTS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.insights_rounded, color: theme.colorScheme.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_service.getStressInsights(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.4))),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.self_improvement_rounded, color: Colors.tealAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_service.getCopingStrategies(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.4))),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Manual check ──────────────────────────────────────────
                AnimatedEntry(
                  index: 4,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('MANUAL CHECK', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Row(children: [
                          Text('Voice stress', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12)),
                          const Spacer(),
                          Text('${(_voice * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: _stressColor(_voice), fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(activeTrackColor: _stressColor(_voice), thumbColor: _stressColor(_voice), overlayColor: _stressColor(_voice).withValues(alpha: 0.12)),
                          child: Slider(value: _voice, onChanged: (v) => setState(() => _voice = v)),
                        ),
                        Row(children: [
                          Text('Typing stress', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12)),
                          const Spacer(),
                          Text('${(_typing * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: _stressColor(_typing), fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(activeTrackColor: _stressColor(_typing), thumbColor: _stressColor(_typing), overlayColor: _stressColor(_typing).withValues(alpha: 0.12)),
                          child: Slider(value: _typing, onChanged: (v) => setState(() => _typing = v)),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _recording ? null : _record,
                            icon: _recording
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.monitor_heart_rounded, size: 18),
                            label: Text(_recording ? 'Recording…' : 'Record Stress Check', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),

                // ── History ───────────────────────────────────────────────
                if (readings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AnimatedEntry(
                    index: 5,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('READING HISTORY', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      ...readings.take(5).toList().asMap().entries.map((entry) {
                        final r = entry.value;
                        final c = _stressColor(r.combinedStress);
                        return AnimatedEntry(
                          index: 6 + entry.key,
                          child: GlassCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.12), border: Border.all(color: c.withValues(alpha: 0.3))),
                                child: Center(child: Text('${(r.combinedStress * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: c, fontWeight: FontWeight.w800, fontSize: 11))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(r.context, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(_stressLabel(r.combinedStress), style: GoogleFonts.outfit(color: c, fontSize: 11)),
                              ])),
                            ]),
                          ),
                        );
                      }),
                    ]),
                  ),
                ],
              ],
            ),
    );
  }
}
