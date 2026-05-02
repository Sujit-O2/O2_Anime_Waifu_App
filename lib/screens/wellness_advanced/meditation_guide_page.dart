import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/wellness/meditation_guide_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MeditationGuidePage extends StatefulWidget {
  const MeditationGuidePage({super.key});
  @override
  State<MeditationGuidePage> createState() => _MeditationGuidePageState();
}

class _MeditationGuidePageState extends State<MeditationGuidePage> {
  final _service = MeditationGuideService.instance;
  String _type = 'Breathing Awareness';
  double _duration = 5;
  double _focus = 0.7;
  double _calm = 0.7;
  bool _loading = true;

  static const _typeEmojis = {
    'Breathing Awareness': '🌬️',
    'Body Scan': '🧘',
    'Visualization': '🌅',
    'Loving Kindness': '💕',
    'Mindfulness': '🍃',
    'Sleep': '🌙',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    await _service.startMeditationSession(type: _type, durationMinutes: _duration.round(), difficulty: 'beginner');
    if (mounted) setState(() {});
  }

  Future<void> _complete(MeditationSession session) async {
    HapticFeedback.heavyImpact();
    await _service.endMeditationSession(sessionId: session.id, focusScore: _focus, calmScore: _calm, notes: 'Completed');
    if (mounted) {
      setState(() {});
      showSuccessSnackbar(context, 'Session complete! 🧘 Great work.');
    }
  }

  String _emoji(String t) => _typeEmojis[t] ?? '🧘';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;
    final active = _service.getActiveSession();
    final sessions = _service.getSessions();
    final types = _service.getAvailableMeditationTypes();
    final completedCount = sessions.where((s) => s.completed).length;

    return FeaturePageV2(
      title: 'GUIDED MEDITATION',
      subtitle: '$completedCount sessions completed',
      onBack: () => Navigator.pop(context),
      content: _loading
          ? const PremiumLoadingState(label: 'Loading meditation guide…', icon: Icons.self_improvement_rounded)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Active session ─────────────────────────────────────────
                if (active != null) ...[
                  AnimatedEntry(
                    index: 0,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      glow: true,
                      child: Column(children: [
                        Text(_emoji(active.type), style: const TextStyle(fontSize: 44)),
                        const SizedBox(height: 8),
                        Text('${active.type} — ${active.durationMinutes} min', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('Session in progress…', style: GoogleFonts.outfit(color: primary, fontSize: 13)),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: Column(children: [
                            Text('Focus ${(_focus * 100).round()}%', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12)),
                            Slider(value: _focus, onChanged: (v) => setState(() => _focus = v)),
                          ])),
                          Expanded(child: Column(children: [
                            Text('Calm ${(_calm * 100).round()}%', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12)),
                            Slider(value: _calm, onChanged: (v) => setState(() => _calm = v)),
                          ])),
                        ]),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _complete(active),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text('Complete Session', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Hero card ──────────────────────────────────────────────
                AnimatedEntry(
                  index: 1,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    glow: active == null,
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Mindfulness centre', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(active != null ? 'Session active' : 'Choose your session', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(_service.getMeditationRecommendation(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                      const SizedBox(width: 16),
                      ProgressRing(
                        progress: completedCount / 10,
                        foreground: primary,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.self_improvement_rounded, size: 26),
                          const SizedBox(height: 4),
                          Text('$completedCount', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('Done', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 10)),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stats ─────────────────────────────────────────────────
                AnimatedEntry(
                  index: 2,
                  child: Row(children: [
                    Expanded(child: StatCard(title: 'Sessions', value: '${sessions.length}', icon: Icons.history_rounded, color: primary)),
                    Expanded(child: StatCard(title: 'Completed', value: '$completedCount', icon: Icons.check_circle_rounded, color: Colors.lightGreenAccent)),
                    Expanded(child: StatCard(title: 'Duration', value: '${_duration.round()}m', icon: Icons.timer_rounded, color: Colors.amberAccent)),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Waifu commentary ───────────────────────────────────────
                AnimatedEntry(index: 3, child: WaifuCommentary(mood: completedCount > 3 ? 'achievement' : 'relaxed')),
                const SizedBox(height: 16),

                // ── Insights ──────────────────────────────────────────────
                AnimatedEntry(
                  index: 4,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.insights_rounded, color: primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_service.getMeditationInsights(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.4))),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Type selector ──────────────────────────────────────────
                AnimatedEntry(
                  index: 5,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SESSION TYPE', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: types.length,
                        itemBuilder: (_, i) {
                          final t = types[i];
                          final sel = _type == t;
                          return GestureDetector(
                            onTap: () { HapticFeedback.selectionClick(); setState(() => _type = t); },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? primary.withValues(alpha: 0.15) : tokens.panelMuted,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: sel ? primary.withValues(alpha: 0.5) : tokens.outline, width: sel ? 1.5 : 1),
                              ),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(_emoji(t), style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(t.split(' ').first, style: GoogleFonts.outfit(color: sel ? primary : tokens.textMuted, fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Duration ──────────────────────────────────────────────
                AnimatedEntry(
                  index: 6,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DURATION', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Row(children: [
                          Text('${_duration.round()} minutes', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(_duration <= 5 ? 'Quick' : _duration <= 15 ? 'Standard' : 'Deep', style: GoogleFonts.outfit(color: primary, fontSize: 12)),
                        ]),
                        Slider(value: _duration, min: 3, max: 30, divisions: 27, label: '${_duration.round()} min', onChanged: (v) => setState(() => _duration = v)),
                        Row(children: [3, 5, 10, 15, 20, 30].map((m) {
                          final sel = _duration.round() == m;
                          return Expanded(child: GestureDetector(
                            onTap: () => setState(() => _duration = m.toDouble()),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: sel ? primary.withValues(alpha: 0.15) : tokens.panelMuted,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sel ? primary.withValues(alpha: 0.4) : tokens.outline),
                              ),
                              child: Center(child: Text('${m}m', style: GoogleFonts.outfit(color: sel ? primary : tokens.textMuted, fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.normal))),
                            ),
                          ));
                        }).toList()),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Start button ───────────────────────────────────────────
                AnimatedEntry(
                  index: 7,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: active != null ? null : _start,
                      icon: const Icon(Icons.self_improvement_rounded, size: 20),
                      label: Text(active != null ? 'Session Active' : 'Start ${_type.split(' ').first} Session', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ),

                // ── History ───────────────────────────────────────────────
                if (sessions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  AnimatedEntry(
                    index: 8,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('SESSION HISTORY', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      ...sessions.take(5).toList().asMap().entries.map((entry) => AnimatedEntry(
                        index: 9 + entry.key,
                        child: GlassCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.1)),
                              child: Center(child: Text(_emoji(entry.value.type), style: const TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${entry.value.type} • ${entry.value.durationMinutes} min', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(entry.value.completed ? 'Completed ✓' : 'In progress…', style: GoogleFonts.outfit(color: entry.value.completed ? Colors.lightGreenAccent : Colors.amberAccent, fontSize: 11)),
                            ])),
                            if (entry.value.completed) const Icon(Icons.check_circle_rounded, color: Colors.lightGreenAccent, size: 18),
                          ]),
                        ),
                      )),
                    ]),
                  ),
                ],
              ],
            ),
    );
  }
}
