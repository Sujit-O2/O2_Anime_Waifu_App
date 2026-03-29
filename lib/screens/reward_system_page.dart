import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/affection_service.dart';

/// Reward System — Daily login rewards, streaks, affection boosts, and unlockables.
class RewardSystemPage extends StatelessWidget {
  const RewardSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = AffectionService.instance.streakDays;
    final xp = AffectionService.instance.points;
    final rewards = [
      {'day': 1, 'reward': '5 XP', 'icon': '⭐', 'unlocked': streak >= 1},
      {'day': 3, 'reward': '15 XP + Title', 'icon': '🌟', 'unlocked': streak >= 3},
      {'day': 7, 'reward': '50 XP + Voice', 'icon': '🔥', 'unlocked': streak >= 7},
      {'day': 14, 'reward': '100 XP + Theme', 'icon': '💎', 'unlocked': streak >= 14},
      {'day': 30, 'reward': '300 XP + Mode', 'icon': '👑', 'unlocked': streak >= 30},
      {'day': 60, 'reward': '500 XP + Secret', 'icon': '🌌', 'unlocked': streak >= 60},
      {'day': 100, 'reward': '1000 XP + Legend', 'icon': '💫', 'unlocked': streak >= 100},
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('REWARDS', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)), centerTitle: true),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [Colors.amberAccent.withValues(alpha: 0.15), Colors.orangeAccent.withValues(alpha: 0.08)]), border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3))),
          child: Column(children: [
            const Text('🔥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text('$streak Day Streak', style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.w900)),
            Text('$xp Total XP • Keep it up, Darling!', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          ])),
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerLeft, child: Text('MILESTONE REWARDS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
        const SizedBox(height: 10),
        ...rewards.map((r) {
          final unlocked = r['unlocked'] as bool;
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: (unlocked ? Colors.amberAccent : Colors.white).withValues(alpha: unlocked ? 0.08 : 0.03), borderRadius: BorderRadius.circular(14), border: Border.all(color: (unlocked ? Colors.amberAccent : Colors.white24).withValues(alpha: 0.3))),
            child: Row(children: [
              Text(r['icon'] as String, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Day ${r['day']}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                Text(r['reward'] as String, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
              ])),
              Icon(unlocked ? Icons.check_circle : Icons.lock_outline, color: unlocked ? Colors.amberAccent : Colors.white24, size: 22),
            ]));
        }),
        const SizedBox(height: 30),
      ])),
    );
  }
}
