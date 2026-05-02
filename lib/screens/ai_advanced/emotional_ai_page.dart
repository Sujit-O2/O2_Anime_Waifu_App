import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/emotional_ai_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EmotionalAiPage extends StatefulWidget {
  const EmotionalAiPage({super.key});
  @override
  State<EmotionalAiPage> createState() => _EmotionalAiPageState();
}

class _EmotionalAiPageState extends State<EmotionalAiPage> {
  final _service = EmotionalAIService();
  final _inputCtrl = TextEditingController();
  bool _loading = true;
  bool _analyzing = false;
  DetectedEmotion? _detected;
  EmotionalTrend? _trend;
  Map<String, double> _breakdown = {};
  List<CopingStrategy> _strategies = [];
  String _comfortMsg = '';
  List<String> _animeRecs = [];

  static const _emotionColors = {
    'happiness': Color(0xFF4CAF50),
    'sadness': Color(0xFF2196F3),
    'anxiety': Color(0xFFFF9800),
    'anger': Color(0xFFF44336),
    'calm': Color(0xFF9C27B0),
  };
  static const _emotionEmojis = {
    'happiness': '😊',
    'sadness': '😢',
    'anxiety': '😰',
    'anger': '😠',
    'calm': '😌',
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _service.initialize();
    final trend = await _service.getEmotionalTrend();
    final breakdown = await _service.getEmotionalBreakdown();
    if (mounted) setState(() { _trend = trend; _breakdown = breakdown; _loading = false; });
  }

  Future<void> _analyze() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _analyzing = true);
    final detected = await _service.detectEmotion(text);
    final comfort = await _service.getComfortResponse(detected.primaryEmotion);
    final strategies = await _service.getCopingStrategies(detected.primaryEmotion);
    final recs = await _service.getAnimeRecommendationForMood(detected.primaryEmotion);
    final trend = await _service.getEmotionalTrend();
    final breakdown = await _service.getEmotionalBreakdown();
    if (mounted) {
      setState(() {
        _detected = detected;
        _comfortMsg = comfort;
        _strategies = strategies;
        _animeRecs = recs;
        _trend = trend;
        _breakdown = breakdown;
        _analyzing = false;
      });
    }
  }

  Color _colorFor(String e) => _emotionColors[e] ?? V2Theme.primaryColor;
  String _emojiFor(String e) => _emotionEmojis[e] ?? '💭';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;

    return FeaturePageV2(
      title: 'EMOTIONAL AI',
      subtitle: 'Detect & understand your feelings',
      onBack: () => Navigator.pop(context),
      content: _loading
          ? const PremiumLoadingState(label: 'Initialising Emotional AI…', icon: Icons.psychology_rounded)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Hero card ──────────────────────────────────────────────
                AnimatedEntry(
                  index: 0,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    glow: true,
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Emotion scanner', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            _detected == null ? 'How are you feeling?' : '${_emojiFor(_detected!.primaryEmotion)} ${_detected!.primaryEmotion.toUpperCase()}',
                            style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _detected == null
                                ? 'Type anything below and I\'ll detect your emotional state in real time.'
                                : 'Confidence ${(_detected!.confidence * 100).toStringAsFixed(0)}%  •  Intensity ${(_detected!.intensity * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.35),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      ProgressRing(
                        progress: _detected?.intensity ?? 0,
                        foreground: _detected == null ? primary : _colorFor(_detected!.primaryEmotion),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_detected == null ? '💭' : _emojiFor(_detected!.primaryEmotion), style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text(
                            _detected == null ? '--' : '${(_detected!.intensity * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Text('Intensity', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 10)),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stats row ──────────────────────────────────────────────
                AnimatedEntry(
                  index: 1,
                  child: Row(children: [
                    Expanded(child: StatCard(title: 'Dominant', value: _trend?.dominantEmotion ?? '--', icon: Icons.psychology_rounded, color: primary)),
                    Expanded(child: StatCard(title: 'Stability', value: _trend == null ? '--' : '${(_trend!.emotionalStability * 100).toStringAsFixed(0)}%', icon: Icons.balance_rounded, color: Colors.lightGreenAccent)),
                    Expanded(child: StatCard(title: 'Trend', value: _trend?.trend ?? '--', icon: Icons.trending_up_rounded, color: Colors.amberAccent)),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Waifu commentary ───────────────────────────────────────
                AnimatedEntry(
                  index: 2,
                  child: WaifuCommentary(
                    mood: _detected == null ? 'neutral' : (_detected!.intensity > 0.6 ? 'relaxed' : 'motivated'),
                    text: _comfortMsg.isNotEmpty ? _comfortMsg : null,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Input ──────────────────────────────────────────────────
                AnimatedEntry(
                  index: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('YOUR FEELINGS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputCtrl,
                      maxLines: 3,
                      style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13),
                      cursorColor: primary,
                      decoration: InputDecoration(
                        hintText: 'e.g. "I\'m feeling really anxious about tomorrow…"',
                        hintStyle: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _analyzing ? null : _analyze,
                        icon: _analyzing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.psychology_rounded, size: 18),
                        label: Text(_analyzing ? 'Analysing…' : 'Analyse Emotion', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),

                // ── Emotion breakdown ──────────────────────────────────────
                if (_detected != null) ...[
                  const SizedBox(height: 20),
                  AnimatedEntry(
                    index: 4,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('EMOTION BREAKDOWN', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      GlassCard(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: _detected!.emotionScores.entries.map((e) {
                            final c = _colorFor(e.key);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                Text(_emojiFor(e.key), style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                SizedBox(width: 72, child: Text(e.key, style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12))),
                                Expanded(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: e.value.clamp(0.0, 1.0)),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, v, __) => ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(value: v, backgroundColor: tokens.outline, valueColor: AlwaysStoppedAnimation(c), minHeight: 7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${(e.value * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
                  ),
                ],

                // ── Coping strategies ──────────────────────────────────────
                if (_strategies.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  AnimatedEntry(
                    index: 5,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('COPING STRATEGIES', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      ..._strategies.toList().asMap().entries.map((entry) => AnimatedEntry(
                        index: 6 + entry.key,
                        child: GlassCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.self_improvement_rounded, color: primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(entry.value.name, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(entry.value.description, style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12)),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text('${entry.value.duration}m', style: GoogleFonts.outfit(color: primary, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                        ),
                      )),
                    ]),
                  ),
                ],

                // ── Anime recs ─────────────────────────────────────────────
                if (_animeRecs.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  AnimatedEntry(
                    index: 9,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ANIME FOR YOUR MOOD', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      GlassCard(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: _animeRecs.toList().asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: Colors.amberAccent.withValues(alpha: 0.12), shape: BoxShape.circle),
                                child: Center(child: Text('${e.key + 1}', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w800))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(e.value, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13))),
                            ]),
                          )).toList(),
                        ),
                      ),
                    ]),
                  ),
                ],

                // ── 30-day breakdown ───────────────────────────────────────
                if (_breakdown.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  AnimatedEntry(
                    index: 10,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('30-DAY BREAKDOWN', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      GlassCard(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: _breakdown.entries.map((e) {
                            final c = _colorFor(e.key);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                Text(_emojiFor(e.key), style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                SizedBox(width: 72, child: Text(e.key, style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12))),
                                Expanded(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: e.value.clamp(0.0, 1.0)),
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, v, __) => ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(value: v, backgroundColor: tokens.outline, valueColor: AlwaysStoppedAnimation(c), minHeight: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${(e.value * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
    );
  }
}
