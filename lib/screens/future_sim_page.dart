import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/affection_service.dart';

/// Future You Simulation — "If I keep doing this, where will I be?"
/// Uses your habits, streak, and time usage to make predictions.
class FutureSimPage extends StatefulWidget {
  const FutureSimPage({super.key});
  @override
  State<FutureSimPage> createState() => _FutureSimPageState();
}

class _FutureSimPageState extends State<FutureSimPage> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  bool _simulating = false;
  Map<String, dynamic> _prediction = {};

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _simulate(int months) async {
    setState(() => _simulating = true);
    await Future.delayed(const Duration(seconds: 2));

    final streak = AffectionService.instance.streakDays;
    final xp = AffectionService.instance.points;
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString('goal_tracker_goals');
    int goalCount = 0;
    if (goalsJson != null) {
      goalCount = (jsonDecode(goalsJson) as List).length;
    }

    // Generate predictions based on current habits
    final projectedXp = xp + (streak * 15 * months);
    final projectedLevel = projectedXp > 5000 ? 'Legendary' : projectedXp > 2000 ? 'Master' : projectedXp > 1000 ? 'Expert' : projectedXp > 500 ? 'Skilled' : 'Beginner';
    final consistency = streak >= 7 ? 'HIGH' : streak >= 3 ? 'MEDIUM' : 'LOW';

    setState(() {
      _simulating = false;
      _prediction = {
        'months': months,
        'projectedXp': projectedXp,
        'projectedLevel': projectedLevel,
        'consistency': consistency,
        'streak': streak,
        'goalsActive': goalCount,
        'growth': streak >= 7 ? '📈 Exponential Growth' : streak >= 3 ? '📊 Steady Progress' : '📉 Needs Improvement',
        'personality': streak >= 7 ? 'Disciplined & focused — your future self is proud!' : streak >= 3 ? 'Making progress but inconsistent. Try building streaks.' : 'Not enough data yet. Start building daily habits!',
        'skills': projectedXp > 2000 ? ['Leadership', 'Coding mastery', 'Self-discipline'] : projectedXp > 1000 ? ['Consistency', 'Problem-solving'] : ['Getting started'],
      };
    });
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('FUTURE YOU', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('🔮', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text('If I keep doing this,\nwhere will I be?', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Based on your habits, streaks & XP', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 20),

          // Time period buttons
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _timeBtn('1 Month', 1),
            _timeBtn('3 Months', 3),
            _timeBtn('6 Months', 6),
            _timeBtn('1 Year', 12),
          ]),
          const SizedBox(height: 20),

          if (_simulating)
            Column(children: [
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: Colors.deepPurpleAccent),
              const SizedBox(height: 12),
              Text('Simulating your future...', style: GoogleFonts.outfit(color: Colors.deepPurpleAccent, fontSize: 14, fontWeight: FontWeight.w600)),
            ])
          else if (_prediction.isNotEmpty)
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(children: [
                _predCard('🎯 Projected Level', '${_prediction['projectedLevel']} (${_prediction['projectedXp']} XP)', Colors.cyanAccent),
                _predCard('📊 Growth Trend', '${_prediction['growth']}', Colors.greenAccent),
                _predCard('🔥 Consistency', '${_prediction['consistency']} (${_prediction['streak']}-day streak)', Colors.amberAccent),
                _predCard('🎮 Goals Active', '${_prediction['goalsActive']} goals tracked', Colors.pinkAccent),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.deepPurpleAccent.withValues(alpha: 0.1), Colors.cyanAccent.withValues(alpha: 0.05)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('🧠 AI Assessment (${_prediction['months']}mo)', style: GoogleFonts.outfit(color: Colors.deepPurpleAccent, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('${_prediction['personality']}', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5)),
                    const SizedBox(height: 10),
                    Text('Projected Skills:', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    ...(_prediction['skills'] as List).map((s) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Text('• $s', style: GoogleFonts.outfit(color: Colors.cyanAccent.withValues(alpha: 0.8), fontSize: 12)),
                    )),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _timeBtn(String label, int months) {
    return ElevatedButton(
      onPressed: () => _simulate(months),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.15),
        foregroundColor: Colors.deepPurpleAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  Widget _predCard(String label, String value, Color c) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withValues(alpha: 0.2))),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600))),
        Text(value, style: GoogleFonts.outfit(color: c, fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
