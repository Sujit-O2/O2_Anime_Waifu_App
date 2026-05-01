import 'package:anime_waifu/services/audio_voice/voice_emotion_service.dart';
import 'package:flutter/material.dart';
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
  EmotionType _currentEmotion = EmotionType.neutral;
  double _confidence = 0.0;
  double _pitch = 0.0;
  double _tempo = 0.0;
  double _volume = 0.0;
  bool _isListening = false;
  List<EmotionType> _history = [];

  static const _emotionColors = {
    EmotionType.happy: Color(0xFF4CAF50),
    EmotionType.sad: Color(0xFF2196F3),
    EmotionType.angry: Color(0xFFF44336),
    EmotionType.stressed: Color(0xFFFF9800),
    EmotionType.excited: Color(0xFFFFD700),
    EmotionType.calm: Color(0xFF9C27B0),
    EmotionType.neutral: Color(0xFF607D8B),
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _simulateAnalysis() {
    // Simulate voice analysis with realistic values
    HapticFeedback.mediumImpact();
    setState(() => _isListening = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      // Generate realistic simulated values
      const emotions = EmotionType.values;
      final emotion = emotions[DateTime.now().millisecond % emotions.length];
      final pitchMap = {
        EmotionType.happy: 195.0,
        EmotionType.sad: 125.0,
        EmotionType.angry: 210.0,
        EmotionType.stressed: 215.0,
        EmotionType.excited: 230.0,
        EmotionType.calm: 155.0,
        EmotionType.neutral: 160.0,
      };
      final tempoMap = {
        EmotionType.happy: 148.0,
        EmotionType.sad: 88.0,
        EmotionType.angry: 175.0,
        EmotionType.stressed: 185.0,
        EmotionType.excited: 180.0,
        EmotionType.calm: 105.0,
        EmotionType.neutral: 120.0,
      };
      setState(() {
        _currentEmotion = emotion;
        _confidence = 0.75 + (DateTime.now().millisecond % 20) / 100;
        _pitch = pitchMap[emotion] ?? 160.0;
        _tempo = tempoMap[emotion] ?? 120.0;
        _volume = 0.3 + (DateTime.now().second % 40) / 100;
        _isListening = false;
        _history = [emotion, ..._history.take(4)];
      });
    });
  }

  Color _colorFor(EmotionType e) => _emotionColors[e] ?? Colors.white38;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(_currentEmotion);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🎤 Voice Emotion',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main emotion display
          Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(
                    color: color.withValues(
                        alpha:
                            _isListening ? 0.4 + _pulseCtrl.value * 0.4 : 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(
                          alpha: _isListening
                              ? 0.2 + _pulseCtrl.value * 0.2
                              : 0.15),
                      blurRadius:
                          _isListening ? 30 + _pulseCtrl.value * 20 : 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_currentEmotion.emoji,
                        style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 6),
                    Text(_currentEmotion.label,
                        style: GoogleFonts.outfit(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    if (_confidence > 0)
                      Text(
                          '${(_confidence * 100).toStringAsFixed(0)}% confident',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Analyze button
          Center(
            child: GestureDetector(
              onTap: _isListening ? null : _simulateAnalysis,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [Colors.white12, Colors.white12]
                        : [
                            Colors.redAccent.withValues(alpha: 0.8),
                            Colors.red.shade700.withValues(alpha: 0.8),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: _isListening
                          ? Colors.white12
                          : Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'Analyzing...' : 'Analyze Voice',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Voice metrics
          if (_pitch > 0) ...[
            Text('Voice Metrics',
                style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _metricCard('Pitch', '${_pitch.toStringAsFixed(0)} Hz',
                      Icons.graphic_eq_rounded, Colors.lightBlueAccent)),
              const SizedBox(width: 8),
              Expanded(
                  child: _metricCard(
                      'Tempo',
                      '${_tempo.toStringAsFixed(0)} WPM',
                      Icons.speed_rounded,
                      Colors.amberAccent)),
              const SizedBox(width: 8),
              Expanded(
                  child: _metricCard(
                      'Volume',
                      '${(_volume * 100).toStringAsFixed(0)}%',
                      Icons.volume_up_rounded,
                      Colors.greenAccent)),
            ]),
            const SizedBox(height: 16),
          ],

          // Response modifier
          if (_currentEmotion != EmotionType.neutral) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.auto_awesome_rounded, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text('AI Response Modifier',
                        style: GoogleFonts.outfit(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  Text(_service.getResponseModifier(_currentEmotion),
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Suggested actions
          if (_currentEmotion != EmotionType.neutral) ...[
            Text('Suggested Actions',
                style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _service
                  .getSuggestedActions(_currentEmotion)
                  .map((action) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(action,
                            style:
                                GoogleFonts.outfit(color: color, fontSize: 12)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // History
          if (_history.isNotEmpty) ...[
            Text('Recent Detections',
                style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Row(
              children: _history.map((e) {
                final c = _colorFor(e);
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    Text(e.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 2),
                    Text(e.label,
                        style: GoogleFonts.outfit(color: c, fontSize: 9)),
                  ]),
                );
              }).toList(),
            ),
          ],

          // All emotions reference
          const SizedBox(height: 16),
          Text('Emotion Reference',
              style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          ...EmotionType.values.map((e) {
            final c = _colorFor(e);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(children: [
                Text(e.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.label,
                            style: GoogleFonts.outfit(
                                color: c,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(e.description,
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 11)),
                      ]),
                ),
              ]),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        Text(label,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10)),
      ]),
    );
  }
}
