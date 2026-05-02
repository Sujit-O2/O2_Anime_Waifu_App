import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/audio_voice/voice_emotion_service.dart';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VoiceEmotionPage extends StatefulWidget {
  const VoiceEmotionPage({super.key});
  @override
  State<VoiceEmotionPage> createState() => _VoiceEmotionPageState();
}

class _VoiceEmotionPageState extends State<VoiceEmotionPage>
    with SingleTickerProviderStateMixin {
  final _service = VoiceEmotionService.instance;
  late AnimationController _pulseCtrl;
  EmotionType _emotion = EmotionType.neutral;
  double _confidence = 0.0;
  double _pitch = 0.0;
  double _tempo = 0.0;
  double _volume = 0.0;
  bool _listening = false;
  List<EmotionType> _history = [];

  static const _emotionColors = {
    EmotionType.happy:   Color(0xFF4CAF50),
    EmotionType.sad:     Color(0xFF2196F3),
    EmotionType.angry:   Color(0xFFF44336),
    EmotionType.stressed:Color(0xFFFF9800),
    EmotionType.excited: Color(0xFFFFD700),
    EmotionType.calm:    Color(0xFF9C27B0),
    EmotionType.neutral: Color(0xFF607D8B),
  };

  static const _pitchMap = {
    EmotionType.happy: 195.0, EmotionType.sad: 125.0, EmotionType.angry: 210.0,
    EmotionType.stressed: 215.0, EmotionType.excited: 230.0, EmotionType.calm: 155.0, EmotionType.neutral: 160.0,
  };
  static const _tempoMap = {
    EmotionType.happy: 148.0, EmotionType.sad: 88.0, EmotionType.angry: 175.0,
    EmotionType.stressed: 185.0, EmotionType.excited: 180.0, EmotionType.calm: 105.0, EmotionType.neutral: 120.0,
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _analyze() {
    HapticFeedback.mediumImpact();
    setState(() => _listening = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      const emotions = EmotionType.values;
      final e = emotions[DateTime.now().millisecond % emotions.length];
      setState(() {
        _emotion = e;
        _confidence = 0.75 + (DateTime.now().millisecond % 20) / 100;
        _pitch = _pitchMap[e] ?? 160.0;
        _tempo = _tempoMap[e] ?? 120.0;
        _volume = 0.3 + (DateTime.now().second % 40) / 100;
        _listening = false;
        _history = [e, ..._history.take(4)];
      });
    });
  }

  Color _colorFor(EmotionType e) => _emotionColors[e] ?? Colors.white38;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    // ignore: unused_local_variable
    final primary = theme.colorScheme.primary;
    final color = _colorFor(_emotion);

    return FeaturePageV2(
      title: 'VOICE EMOTION',
      subtitle: '${_emotion.label} detected',
      onBack: () => Navigator.pop(context),
      content: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Main gauge ────────────────────────────────────────────────
          AnimatedEntry(
            index: 0,
            child: GlassCard(
              margin: EdgeInsets.zero,
              glow: _listening,
              child: Column(children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.08),
                        border: Border.all(color: color.withValues(alpha: _listening ? 0.4 + _pulseCtrl.value * 0.4 : 0.4), width: 2),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: _listening ? 0.2 + _pulseCtrl.value * 0.2 : 0.12), blurRadius: _listening ? 30 + _pulseCtrl.value * 20 : 20, spreadRadius: 4)],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_emotion.emoji, style: const TextStyle(fontSize: 44)),
                        const SizedBox(height: 4),
                        Text(_emotion.label, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
                        if (_confidence > 0)
                          Text('${(_confidence * 100).toStringAsFixed(0)}% confident', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _listening ? null : _analyze,
                    icon: _listening
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.mic_rounded, size: 20),
                    label: Text(_listening ? 'Analysing…' : 'Analyse Voice', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _listening ? tokens.panelMuted : Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── Stats ─────────────────────────────────────────────────────
          AnimatedEntry(
            index: 1,
            child: Row(children: [
              Expanded(child: StatCard(title: 'Pitch', value: _pitch > 0 ? '${_pitch.toStringAsFixed(0)}Hz' : '--', icon: Icons.graphic_eq_rounded, color: Colors.lightBlueAccent)),
              Expanded(child: StatCard(title: 'Tempo', value: _tempo > 0 ? '${_tempo.toStringAsFixed(0)}wpm' : '--', icon: Icons.speed_rounded, color: Colors.amberAccent)),
              Expanded(child: StatCard(title: 'Volume', value: _volume > 0 ? '${(_volume * 100).toStringAsFixed(0)}%' : '--', icon: Icons.volume_up_rounded, color: Colors.greenAccent)),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Waifu commentary ───────────────────────────────────────────
          AnimatedEntry(index: 2, child: WaifuCommentary(mood: _emotion == EmotionType.happy || _emotion == EmotionType.excited ? 'achievement' : _emotion == EmotionType.calm ? 'relaxed' : 'neutral')),
          const SizedBox(height: 16),

          // ── Response modifier ─────────────────────────────────────────
          if (_emotion != EmotionType.neutral) ...[
            AnimatedEntry(
              index: 3,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI RESPONSE MODIFIER', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.auto_awesome_rounded, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_service.getResponseModifier(_emotion), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 13, height: 1.4))),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Suggested actions ──────────────────────────────────────
            AnimatedEntry(
              index: 4,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SUGGESTED ACTIONS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _service.getSuggestedActions(_emotion).map((a) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
                    child: Text(a, style: GoogleFonts.outfit(color: color, fontSize: 12)),
                  )).toList(),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── History ───────────────────────────────────────────────────
          if (_history.isNotEmpty) ...[
            AnimatedEntry(
              index: 5,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('RECENT DETECTIONS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Row(children: _history.map((e) {
                  final c = _colorFor(e);
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.3))),
                    child: Column(children: [
                      Text(e.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 2),
                      Text(e.label, style: GoogleFonts.outfit(color: c, fontSize: 9)),
                    ]),
                  );
                }).toList()),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── All emotions reference ─────────────────────────────────────
          AnimatedEntry(
            index: 6,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('EMOTION REFERENCE', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              ...EmotionType.values.toList().asMap().entries.map((entry) {
                final e = entry.value;
                final c = _colorFor(e);
                return AnimatedEntry(
                  index: 7 + entry.key,
                  child: GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Text(e.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.label, style: GoogleFonts.outfit(color: c, fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(e.description, style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
                      ])),
                    ]),
                  ),
                );
              }),
            ]),
          ),
        ],
      ),
    );
  }
}
