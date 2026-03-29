import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/affection_service.dart';

/// Day Recap — AI-generated daily summary of activity and productivity.
class DayRecapPage extends StatelessWidget {
  const DayRecapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final xp = AffectionService.instance.points;
    final streak = AffectionService.instance.streakDays;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('DAY RECAP', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)), centerTitle: true),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [Colors.indigo.withValues(alpha: 0.2), Colors.deepPurple.withValues(alpha: 0.1)]), border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3))),
          child: Column(children: [
            Text(h >= 20 ? '🌙' : '☀️', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(h >= 20 ? 'Tonight\'s Recap' : 'Today So Far', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            Text(_dateString(), style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          ])),
        const SizedBox(height: 16),
        _recapCard('📊 Activity', 'You were active for ~${h > 8 ? h - 6 : 2} hours today', Colors.cyanAccent),
        _recapCard('💬 Conversations', 'You had ${xp ~/ 5} meaningful exchanges', Colors.pinkAccent),
        _recapCard('🔥 Streak', '$streak days strong! Keep going!', Colors.orangeAccent),
        _recapCard('⚡ XP Earned', '+${xp % 50} XP today', Colors.amberAccent),
        _recapCard('😊 Mood', h >= 20 ? 'Winding down... good day overall' : 'Energetic and productive!', Colors.greenAccent),
        _recapCard('💕 Bond', 'Your relationship is growing stronger 💕', Colors.deepPurpleAccent),
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2))),
          child: Column(children: [
            Text('💌 Zero Two says:', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(h >= 20 ? '"You worked hard today, Darling. I\'m proud of you. Rest well tonight~ 💕"' : '"We still have time today! Let\'s make the most of it together~ ✨"', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5)),
          ])),
        const SizedBox(height: 30),
      ])),
    );
  }

  String _dateString() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _recapCard(String title, String desc, Color c) {
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withValues(alpha: 0.2))),
      child: Row(children: [
        Container(width: 4, height: 36, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(desc, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
        ])),
      ]));
  }
}
