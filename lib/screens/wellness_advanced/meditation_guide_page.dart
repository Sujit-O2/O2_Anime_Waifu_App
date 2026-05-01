import 'package:anime_waifu/services/wellness/meditation_guide_service.dart';
import 'package:flutter/material.dart';
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
    'Breathing': '🌬️',
    'Body Scan': '🧘',
    'Visualization': '🌅',
    'Loving Kindness': '💕',
    'Mindfulness': '🍃',
    'Sleep': '🌙',
  };

  static const _typeColors = {
    'Breathing': Color(0xFF4FC3F7),
    'Body Scan': Color(0xFF81C784),
    'Visualization': Color(0xFFFFB74D),
    'Loving Kindness': Color(0xFFFF80AB),
    'Mindfulness': Color(0xFF80CBC4),
    'Sleep': Color(0xFF9575CD),
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
    await _service.startMeditationSession(
      type: _type,
      durationMinutes: _duration.round(),
      difficulty: 'beginner',
    );
    if (mounted) setState(() {});
  }

  Future<void> _complete(MeditationSession session) async {
    HapticFeedback.heavyImpact();
    await _service.endMeditationSession(
      sessionId: session.id,
      focusScore: _focus,
      calmScore: _calm,
      notes: 'Completed from guide page',
    );
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session complete! 🧘 Great work.',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Color _typeColor(String t) => _typeColors[t] ?? Colors.tealAccent;
  String _typeEmoji(String t) => _typeEmojis[t] ?? '🧘';

  @override
  Widget build(BuildContext context) {
    final active = _service.getActiveSession();
    final sessions = _service.getSessions();
    final types = _service.getAvailableMeditationTypes();
    final activeColor = _typeColor(_type);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🧘 Guided Meditation',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Active session card
                if (active != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.tealAccent.withValues(alpha: 0.15),
                          Colors.tealAccent.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.tealAccent.withValues(alpha: 0.4)),
                    ),
                    child: Column(children: [
                      Text(_typeEmoji(active.type),
                          style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text('${active.type} — ${active.durationMinutes} min',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('Session in progress...',
                          style: GoogleFonts.outfit(
                              color: Colors.tealAccent, fontSize: 13)),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Column(children: [
                          Text('Focus: ${(_focus * 100).round()}%',
                              style: GoogleFonts.outfit(
                                  color: Colors.white60, fontSize: 12)),
                          Slider(
                            value: _focus,
                            onChanged: (v) => setState(() => _focus = v),
                            activeColor: Colors.lightBlueAccent,
                            inactiveColor: Colors.white12,
                          ),
                        ])),
                        Expanded(child: Column(children: [
                          Text('Calm: ${(_calm * 100).round()}%',
                              style: GoogleFonts.outfit(
                                  color: Colors.white60, fontSize: 12)),
                          Slider(
                            value: _calm,
                            onChanged: (v) => setState(() => _calm = v),
                            activeColor: Colors.tealAccent,
                            inactiveColor: Colors.white12,
                          ),
                        ])),
                      ]),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _complete(active),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text('Complete Session',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Insights
                _infoCard(Icons.insights_rounded, 'Insights',
                    _service.getMeditationInsights(), Colors.tealAccent),
                const SizedBox(height: 10),
                _infoCard(Icons.tips_and_updates_rounded, 'Recommendation',
                    _service.getMeditationRecommendation(), Colors.lightBlueAccent),
                const SizedBox(height: 16),

                // Type selector
                Text('Session Type',
                    style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: types.length,
                    itemBuilder: (_, i) {
                      final t = types[i];
                      final sel = _type == t;
                      final c = _typeColor(t);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _type = t);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? c.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: sel ? c.withValues(alpha: 0.5) : Colors.white12,
                                width: sel ? 1.5 : 1),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Text(_typeEmoji(t),
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(t,
                                style: GoogleFonts.outfit(
                                    color: sel ? c : Colors.white54,
                                    fontSize: 10,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.normal)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Duration
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Duration: ${_duration.round()} min',
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                          _duration <= 5
                              ? 'Quick'
                              : _duration <= 15
                                  ? 'Standard'
                                  : 'Deep',
                          style: GoogleFonts.outfit(
                              color: activeColor, fontSize: 12),
                        ),
                      ]),
                      Slider(
                        value: _duration,
                        min: 3,
                        max: 30,
                        divisions: 27,
                        label: '${_duration.round()} min',
                        activeColor: activeColor,
                        inactiveColor: Colors.white12,
                        onChanged: (v) => setState(() => _duration = v),
                      ),
                      // Quick duration chips
                      Row(children: [3, 5, 10, 15, 20, 30].map((m) {
                        final sel = _duration.round() == m;
                        return GestureDetector(
                          onTap: () => setState(() => _duration = m.toDouble()),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sel
                                  ? activeColor.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel
                                      ? activeColor.withValues(alpha: 0.5)
                                      : Colors.white12),
                            ),
                            child: Text('${m}m',
                                style: GoogleFonts.outfit(
                                    color: sel ? activeColor : Colors.white38,
                                    fontSize: 11)),
                          ),
                        );
                      }).toList()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: active != null ? null : _start,
                    icon: const Icon(Icons.self_improvement_rounded, size: 20),
                    label: Text(
                      active != null
                          ? 'Session Active'
                          : 'Start $_type Session',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // History
                if (sessions.isNotEmpty) ...[
                  Text('Session History',
                      style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1)),
                  const SizedBox(height: 10),
                  ...sessions.take(6).map((s) {
                    final c = _typeColor(s.type);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.withValues(alpha: 0.12),
                          ),
                          child: Center(
                            child: Text(_typeEmoji(s.type),
                                style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('${s.type} • ${s.durationMinutes} min',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                              s.completed ? 'Completed ✓' : 'In progress...',
                              style: GoogleFonts.outfit(
                                  color: s.completed
                                      ? Colors.greenAccent
                                      : Colors.amberAccent,
                                  fontSize: 11),
                            ),
                          ]),
                        ),
                        if (s.completed)
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.greenAccent, size: 18),
                      ]),
                    );
                  }),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _infoCard(IconData icon, String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.outfit(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text(body,
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 13, height: 1.4)),
      ]),
    );
  }
}
