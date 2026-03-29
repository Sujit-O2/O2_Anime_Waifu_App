import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auto Learning System — Tracks what responses you like/ignore/correct.
/// AI adapts its behavior automatically based on your feedback patterns.
class AutoLearningPage extends StatefulWidget {
  const AutoLearningPage({super.key});
  @override
  State<AutoLearningPage> createState() => _AutoLearningPageState();
}

class _AutoLearningPageState extends State<AutoLearningPage> {
  Map<String, int> _preferences = {
    'humor': 50,
    'depth': 50,
    'emotion': 50,
    'techTalk': 50,
    'sass': 50,
    'formality': 50,
  };
  List<Map<String, dynamic>> _feedbackLog = [];
  int _totalInteractions = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('auto_learning_prefs');
    if (d != null) {
      setState(() => _preferences = Map<String, int>.from(jsonDecode(d)));
    }
    final f = prefs.getString('auto_learning_feedback');
    if (f != null) {
      setState(() => _feedbackLog = (jsonDecode(f) as List).cast<Map<String, dynamic>>());
    }
    _totalInteractions = prefs.getInt('auto_learning_total') ?? 0;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_learning_prefs', jsonEncode(_preferences));
    await prefs.setString('auto_learning_feedback', jsonEncode(_feedbackLog));
    await prefs.setInt('auto_learning_total', _totalInteractions);
  }

  void _simulateFeedback(String type, bool positive) {
    setState(() {
      final current = _preferences[type] ?? 50;
      _preferences[type] = (current + (positive ? 5 : -5)).clamp(0, 100);
      _totalInteractions++;
      _feedbackLog.insert(0, {
        'type': type,
        'positive': positive,
        'time': DateTime.now().toIso8601String(),
      });
      if (_feedbackLog.length > 50) _feedbackLog = _feedbackLog.sublist(0, 50);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final labels = {
      'humor': ('😂 Humor', 'How much humor/jokes in responses', Colors.amberAccent),
      'depth': ('🧠 Depth', 'Detailed vs concise answers', Colors.cyanAccent),
      'emotion': ('💕 Emotion', 'Emotional warmth level', Colors.pinkAccent),
      'techTalk': ('💻 Tech Talk', 'Technical/code-heavy responses', Colors.greenAccent),
      'sass': ('😏 Sass Level', 'Playful teasing intensity', Colors.orangeAccent),
      'formality': ('🎩 Formality', 'Formal vs casual tone', Colors.purpleAccent),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('AUTO LEARNING', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('🧬', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 6),
          Text('Self-Evolving AI', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          Text('$_totalInteractions interactions analyzed', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 16),

          // Preference sliders
          ...labels.entries.map((e) {
            final info = e.value;
            final val = _preferences[e.key] ?? 50;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: info.$3.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: info.$3.withValues(alpha: 0.15)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(info.$1, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('$val%', style: GoogleFonts.outfit(color: info.$3, fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 2),
                Text(info.$2, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: val / 100, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation(info.$3)),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  _feedbackBtn('👎 Less', () => _simulateFeedback(e.key, false), Colors.redAccent),
                  const SizedBox(width: 8),
                  _feedbackBtn('👍 More', () => _simulateFeedback(e.key, true), Colors.greenAccent),
                ]),
              ]),
            );
          }),

          const SizedBox(height: 12),

          // Recent feedback log
          if (_feedbackLog.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('RECENT ADAPTATIONS', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            const SizedBox(height: 6),
            ...(_feedbackLog.take(5).map((f) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Text(f['positive'] ? '📈' : '📉', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text('${f['type']}', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
                const Spacer(),
                Text(f['positive'] ? '+5%' : '-5%', style: GoogleFonts.outfit(color: f['positive'] ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ))),
          ],
        ]),
      ),
    );
  }

  Widget _feedbackBtn(String label, VoidCallback onTap, Color c) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withValues(alpha: 0.3))),
        child: Text(label, style: GoogleFonts.outfit(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
