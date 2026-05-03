import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/wellness/sleep_tracking_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SleepTrackingPage extends StatefulWidget {
  const SleepTrackingPage({super.key});
  @override
  State<SleepTrackingPage> createState() => _SleepTrackingPageState();
}

class _SleepTrackingPageState extends State<SleepTrackingPage> {
  final _service = SleepTrackingService.instance;
  double _quality = 7;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle() async {
    HapticFeedback.mediumImpact();
    if (_service.isTracking) {
      await _service.stopSleepTracking(sleepQuality: _quality);
      if (mounted) showSuccessSnackbar(context, 'Sleep session saved');
    } else {
      await _service.startSleepTracking();
      if (mounted) showSuccessSnackbar(context, 'Sleep tracking started');
    }
    if (mounted) setState(() {});
  }

  Color _qualityColor(double q) {
    if (q >= 7) return Colors.lightGreenAccent;
    if (q >= 5) return Colors.amberAccent;
    return Colors.redAccent;
  }

  String _qualityLabel(double q) {
    if (q >= 8) return 'Excellent 😴';
    if (q >= 6) return 'Good 🙂';
    if (q >= 4) return 'Fair 😐';
    return 'Poor 😔';
  }

  String _durationLabel(double h) {
    if (h >= 8) return 'Optimal';
    if (h >= 6) return 'Adequate';
    return 'Insufficient';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;
    final sessions = _service.getSessions();
    final isTracking = _service.isTracking;
    final avgQuality = sessions.isEmpty ? 0.0 : sessions.map((s) => s.sleepQuality).reduce((a, b) => a + b) / sessions.length;
    final avgHours = sessions.isEmpty ? 0.0 : sessions.map((s) => s.durationHours).reduce((a, b) => a + b) / sessions.length;

    return FeaturePageV2(
      title: 'SLEEP TRACKING',
      subtitle: isTracking ? '🔴 Tracking now…' : '${sessions.length} sessions recorded',
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
          ? const PremiumLoadingState(label: 'Loading sleep data…', icon: Icons.bedtime_rounded)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Hero ──────────────────────────────────────────────────
                AnimatedEntry(
                  index: 0,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    glow: isTracking,
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(isTracking ? 'Tracking sleep' : 'Sleep monitor', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(isTracking ? 'Session in progress…' : sessions.isEmpty ? 'Start tracking tonight' : 'Avg ${avgHours.toStringAsFixed(1)}h  •  ${_qualityLabel(avgQuality)}', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(_service.getSleepInsights(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                      const SizedBox(width: 16),
                      RepaintBoundary(
                        child: ProgressRing(
                          progress: sessions.isEmpty ? 0 : (avgQuality / 10).clamp(0.0, 1.0),
                          foreground: _qualityColor(avgQuality),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(isTracking ? '😴' : sessions.isEmpty ? '🌙' : '⭐', style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(sessions.isEmpty ? '--' : avgQuality.toStringAsFixed(1), style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
                            Text('Avg score', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 10)),
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
                    Expanded(child: StatCard(title: 'Sessions', value: '${sessions.length}', icon: Icons.history_rounded, color: primary)),
                    Expanded(child: StatCard(title: 'Avg Hours', value: sessions.isEmpty ? '--' : '${avgHours.toStringAsFixed(1)}h', icon: Icons.access_time_rounded, color: Colors.indigoAccent)),
                    Expanded(child: StatCard(title: 'Avg Quality', value: sessions.isEmpty ? '--' : '${avgQuality.toStringAsFixed(1)}/10', icon: Icons.star_rounded, color: Colors.amberAccent)),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Waifu commentary ───────────────────────────────────────
                AnimatedEntry(index: 2, child: WaifuCommentary(mood: avgQuality >= 7 ? 'achievement' : avgQuality >= 5 ? 'motivated' : 'relaxed')),
                const SizedBox(height: 16),

                // ── Recommendation ────────────────────────────────────────
                AnimatedEntry(
                  index: 3,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.tips_and_updates_rounded, color: Colors.indigoAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_service.getSleepRecommendation(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.4))),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Quality slider (when tracking) ────────────────────────
                if (isTracking) ...[
                  AnimatedEntry(
                    index: 4,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Row(children: [
                          Text('Sleep quality: ${_quality.toStringAsFixed(0)}/10', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(_qualityLabel(_quality), style: GoogleFonts.outfit(color: _qualityColor(_quality), fontSize: 12)),
                        ]),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(activeTrackColor: _qualityColor(_quality), thumbColor: _qualityColor(_quality), overlayColor: _qualityColor(_quality).withValues(alpha: 0.12)),
                          child: Slider(value: _quality, min: 1, max: 10, divisions: 9, label: _quality.toStringAsFixed(0), onChanged: (v) => setState(() => _quality = v)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Toggle button ─────────────────────────────────────────
                AnimatedEntry(
                  index: 5,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _toggle,
                      icon: Icon(isTracking ? Icons.stop_rounded : Icons.bedtime_rounded, size: 20),
                      label: Text(isTracking ? 'Stop & Save Session' : 'Start Sleep Tracking', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                      style: FilledButton.styleFrom(
                        backgroundColor: isTracking ? Colors.redAccent : Colors.indigoAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // ── History ───────────────────────────────────────────────
                if (sessions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  AnimatedEntry(
                    index: 6,
                    child: Text('SLEEP HISTORY', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 10),
                  ...sessions.take(7).toList().asMap().entries.map((entry) {
                    final s = entry.value;
                    final qColor = _qualityColor(s.sleepQuality);
                    return AnimatedEntry(
                      index: 7 + entry.key,
                      child: GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: qColor.withValues(alpha: 0.12), border: Border.all(color: qColor.withValues(alpha: 0.3))),
                            child: Center(child: Text(s.sleepQuality.toStringAsFixed(0), style: GoogleFonts.outfit(color: qColor, fontWeight: FontWeight.w900, fontSize: 14))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text('${s.durationHours.toStringAsFixed(1)}h', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: qColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(_durationLabel(s.durationHours), style: GoogleFonts.outfit(color: qColor, fontSize: 10)),
                              ),
                            ]),
                            Text('REM ${s.remPercentage.toStringAsFixed(0)}%  •  Deep ${s.deepSleepPercentage.toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
                          ])),
                        ]),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
