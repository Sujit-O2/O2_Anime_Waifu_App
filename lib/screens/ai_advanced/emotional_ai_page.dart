import 'package:anime_waifu/services/ai_personalization/emotional_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EmotionalAiPage extends StatefulWidget {
  const EmotionalAiPage({super.key});

  @override
  State<EmotionalAiPage> createState() => _EmotionalAiPageState();
}

class _EmotionalAiPageState extends State<EmotionalAiPage>
    with SingleTickerProviderStateMixin {
  final _service = EmotionalAIService();
  final _inputCtrl = TextEditingController();
  bool _loading = true;
  bool _analyzing = false;
  DetectedEmotion? _detected;
  EmotionalTrend? _trend;
  Map<String, double> _breakdown = {};
  List<CopingStrategy> _strategies = [];
  String _comfortMsg = '';

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
    if (mounted) {
      setState(() {
        _trend = trend;
        _breakdown = breakdown;
        _loading = false;
      });
    }
  }

  Future<void> _analyze() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _analyzing = true);
    final detected = await _service.detectEmotion(text);
    final comfort = await _service.getComfortResponse(detected.primaryEmotion);
    final strategies = await _service.getCopingStrategies(detected.primaryEmotion);
    final trend = await _service.getEmotionalTrend();
    final breakdown = await _service.getEmotionalBreakdown();
    if (mounted) {
      setState(() {
        _detected = detected;
        _comfortMsg = comfort;
        _strategies = strategies;
        _trend = trend;
        _breakdown = breakdown;
        _analyzing = false;
      });
    }
  }

  Color _colorFor(String emotion) =>
      _emotionColors[emotion] ?? Colors.pinkAccent;

  String _emojiFor(String emotion) =>
      _emotionEmojis[emotion] ?? '💭';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('💖 Emotional AI',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Input card
                _buildInputCard(),
                const SizedBox(height: 16),
                // Detection result
                if (_detected != null) ...[
                  _buildDetectionCard(),
                  const SizedBox(height: 16),
                  _buildComfortCard(),
                  const SizedBox(height: 16),
                  _buildStrategiesCard(),
                  const SizedBox(height: 16),
                ],
                // Trend card
                if (_trend != null) _buildTrendCard(),
                const SizedBox(height: 16),
                // Breakdown
                if (_breakdown.isNotEmpty) _buildBreakdownCard(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling?',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Type anything — I\'ll detect your emotional state.',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _inputCtrl,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. "I\'m feeling really anxious about tomorrow..."',
              hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.5))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _analyzing ? null : _analyze,
              icon: _analyzing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.psychology_rounded, size: 18),
              label: Text(_analyzing ? 'Analyzing...' : 'Analyze Emotion',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard() {
    final d = _detected!;
    final color = _colorFor(d.primaryEmotion);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_emojiFor(d.primaryEmotion),
                style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Detected: ${d.primaryEmotion.toUpperCase()}',
                    style: GoogleFonts.outfit(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text(
                    'Confidence: ${(d.confidence * 100).toStringAsFixed(0)}%  •  Intensity: ${(d.intensity * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text('Emotion Breakdown',
              style: GoogleFonts.outfit(
                  color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          ...d.emotionScores.entries.map((e) {
            final c = _colorFor(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                SizedBox(
                    width: 70,
                    child: Text(e.key,
                        style: GoogleFonts.outfit(
                            color: Colors.white60, fontSize: 11))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.07),
                      valueColor: AlwaysStoppedAnimation(c),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(e.value * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(color: c, fontSize: 11)),
              ]),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(d.recommendation,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildComfortCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💕', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Zero Two says...',
                  style: GoogleFonts.outfit(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(_comfortMsg,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 14, height: 1.4)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coping Strategies',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          ..._strategies.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.self_improvement_rounded,
                        color: Colors.pinkAccent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.name,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(s.description,
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 12)),
                    ]),
                  ),
                  Text('${s.duration}m',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11)),
                ]),
              )),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    final t = _trend!;
    final color = _colorFor(t.dominantEmotion);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7-Day Emotional Trend',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _statChip('Dominant', _emojiFor(t.dominantEmotion),
                  t.dominantEmotion, color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statChip('Stability',
                  t.emotionalStability > 0.6 ? '✅' : '⚠️',
                  '${(t.emotionalStability * 100).toStringAsFixed(0)}%',
                  t.emotionalStability > 0.6
                      ? Colors.greenAccent
                      : Colors.orangeAccent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statChip('Trend',
                  t.trend == 'improving' ? '📈' : t.trend == 'worsening' ? '📉' : '➡️',
                  t.trend, Colors.lightBlueAccent),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('30-Day Emotional Breakdown',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          ..._breakdown.entries.map((e) {
            final c = _colorFor(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text(_emojiFor(e.key),
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                SizedBox(
                    width: 80,
                    child: Text(e.key,
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 12))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.07),
                      valueColor: AlwaysStoppedAnimation(c),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(e.value * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(color: c, fontSize: 12)),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _statChip(String label, String icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.outfit(
                color: color, fontWeight: FontWeight.w700, fontSize: 12),
            textAlign: TextAlign.center),
        Text(label,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
