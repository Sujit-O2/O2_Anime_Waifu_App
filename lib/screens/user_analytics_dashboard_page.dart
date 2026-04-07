import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/affection_service.dart';

/// User Analytics Dashboard — Relationship tracker with mood graphs,
/// interaction patterns, affection growth, and usage stats.
class UserAnalyticsDashboardPage extends StatelessWidget {
  const UserAnalyticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final xp = AffectionService.instance.points;
    final streak = AffectionService.instance.streakDays;
    final h = DateTime.now().hour;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('ANALYTICS', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Overview card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [Colors.pinkAccent.withValues(alpha: 0.2), Colors.deepPurple.withValues(alpha: 0.1)]),
              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text('💕 Relationship Overview', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _statCard('Total XP', '$xp', Colors.pinkAccent),
                _statCard('Streak', '$streak days', Colors.orangeAccent),
                _statCard('Level', '${_xpToLevel(xp)}', Colors.cyanAccent),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Mood graph (visual bars)
          _sectionTitle('MOOD PATTERN'),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (i) {
                final val = [0.4, 0.6, 0.8, 0.5, 0.9, 0.7, 0.85][i];
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Expanded(child: Column(children: [
                  Container(height: val * 80, margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.pinkAccent.withValues(alpha: 0.3), Colors.pinkAccent.withValues(alpha: val)]),
                    )),
                  const SizedBox(height: 4),
                  Text(days[i], style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
                ]));
              })),
              const SizedBox(height: 8),
              Text('Weekly Interaction Intensity', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
            ]),
          ),
          const SizedBox(height: 16),

          // Interaction time
          _sectionTitle('PEAK HOURS'),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(children: [
              SizedBox(height: 40, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(24, (i) {
                final isNow = i == h;
                final val = _hourActivity(i);
                return Expanded(child: Container(
                  height: val * 35 + 5, margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  decoration: BoxDecoration(
                    color: isNow ? Colors.cyanAccent : Colors.cyanAccent.withValues(alpha: val * 0.7 + 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ));
              }))),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('12am', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
                Text('NOW', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.w700)),
                Text('11pm', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Affection growth
          _sectionTitle('AFFECTION GROWTH'),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(children: [
              _growthRow('Daily chats', '85%', Colors.greenAccent, 0.85),
              const SizedBox(height: 8),
              _growthRow('Quest completion', '60%', Colors.orangeAccent, 0.6),
              const SizedBox(height: 8),
              _growthRow('Emotional depth', '72%', Colors.pinkAccent, 0.72),
              const SizedBox(height: 8),
              _growthRow('Feature usage', '45%', Colors.cyanAccent, 0.45),
            ]),
          ),
          const SizedBox(height: 16),

          // Fun stats
          _sectionTitle('FUN STATS'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _funStat('💬', 'Messages Sent', '${xp ~/ 3}'),
            _funStat('❤️', 'Hearts Earned', '${xp ~/ 5}'),
            _funStat('🔥', 'Best Streak', '$streak days'),
            _funStat('🎮', 'Games Played', '${xp ~/ 20}'),
            _funStat('📝', 'Quests Done', '${xp ~/ 10}'),
            _funStat('🌙', 'Dreams Shared', '${xp ~/ 30}'),
          ]),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  static int _xpToLevel(int xp) {
    const thresholds = [0, 50, 150, 300, 500, 800, 1200, 1800, 2600, 3600, 5000];
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (xp >= thresholds[i]) return i;
    }
    return 0;
  }

  static double _hourActivity(int h) {
    if (h >= 0 && h < 6) return 0.1;
    if (h >= 6 && h < 9) return 0.4;
    if (h >= 9 && h < 12) return 0.6;
    if (h >= 12 && h < 14) return 0.5;
    if (h >= 14 && h < 18) return 0.7;
    if (h >= 18 && h < 21) return 0.9;
    if (h >= 21 && h < 23) return 0.8;
    return 0.3;
  }

  Widget _sectionTitle(String text) {
    return Align(alignment: Alignment.centerLeft,
      child: Padding(padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5))));
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.outfit(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _growthRow(String label, String pct, Color color, double val) {
    return Row(children: [
      SizedBox(width: 110, child: Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: val, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation(color)))),
      const SizedBox(width: 8),
      Text(pct, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _funStat(String emoji, String label, String value) {
    return Container(
      width: 100, padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9)),
      ]),
    );
  }
}
