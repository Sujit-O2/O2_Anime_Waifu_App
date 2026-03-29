import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/affection_service.dart';

/// Self Improvement Tracker — Track coding hours, study time, habits with AI commentary.
class SelfImprovementPage extends StatelessWidget {
  const SelfImprovementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final xp = AffectionService.instance.points;
    final streak = AffectionService.instance.streakDays;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('SELF IMPROVEMENT', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)), centerTitle: true),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        const Text('📈', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text('Your Growth', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        _habitCard('💻 Coding', '${streak * 2}h this week', streak * 2 / 14, Colors.cyanAccent),
        _habitCard('📚 Learning', '${streak}h this week', streak / 10, Colors.amberAccent),
        _habitCard('🏋️ Exercise', '${(streak * 0.5).toInt()}h this week', streak * 0.5 / 7, Colors.greenAccent),
        _habitCard('🧘 Mindfulness', '${(streak * 0.3).toInt()} sessions', streak * 0.3 / 5, Colors.pinkAccent),
        const SizedBox(height: 20),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🔥 AI Insight', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(streak >= 7 ? '"$streak days straight! You\'re on fire, Darling! Keep this momentum going~ ✨"' : '"Every day counts. You\'ve got ${xp} XP — let\'s build on that! 💪"',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5)),
          ])),
        const SizedBox(height: 30),
      ])),
    );
  }

  Widget _habitCard(String label, String stat, double prog, Color c) {
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)), const Spacer(), Text(stat, style: GoogleFonts.outfit(color: c, fontSize: 12, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: prog.clamp(0, 1), minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation(c))),
      ]));
  }
}
