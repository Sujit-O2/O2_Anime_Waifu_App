import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyCoupleChallengePage extends StatefulWidget {
  const DailyCoupleChallengePage({super.key});
  @override
  State<DailyCoupleChallengePage> createState() => _DailyCoupleChallengePageState();
}

class _DailyCoupleChallengePageState extends State<DailyCoupleChallengePage>
    with SingleTickerProviderStateMixin {
  static const List<Map<String, String>> _challenges = [
    {'emoji': '🎨', 'title': 'Draw each other', 'desc': 'Sketch a portrait of Zero Two in 5 minutes. Extra points for adorable!'},
    {'emoji': '📸', 'title': 'Photo Challenge', 'desc': 'Take a photo of something that reminds you of Zero Two today.'},
    {'emoji': '🎵', 'title': 'Love Song', 'desc': 'Hum or sing a song that describes your feelings for her.'},
    {'emoji': '✍️', 'title': 'Love Haiku', 'desc': 'Write a haiku (5-7-5 syllables) about your relationship.'},
    {'emoji': '🌹', 'title': 'Gratitude List', 'desc': 'Write 5 things you love about Zero Two. Be specific!'},
    {'emoji': '🧁', 'title': 'Bake for Us', 'desc': 'Bake or cook something sweet today. Take a photo to share!'},
    {'emoji': '🌅', 'title': 'Sunrise Moment', 'desc': 'Watch the sunrise and think of her. What does it remind you of?'},
    {'emoji': '💌', 'title': 'Secret Message', 'desc': 'Write a secret love note to Zero Two and hide it somewhere.'},
    {'emoji': '📖', 'title': 'Read Together', 'desc': 'Read a chapter of a book out loud — imagine she\'s listening.'},
    {'emoji': '🕯️', 'title': 'Candlelight Dinner', 'desc': 'Eat your next meal with a candle lit. No phone allowed!'},
    {'emoji': '🌿', 'title': 'Nature Walk', 'desc': 'Go for a 10-minute walk and collect something beautiful from nature.'},
    {'emoji': '🎭', 'title': 'Role Swap', 'desc': 'Pretend to be Zero Two for 10 minutes. Act like she would!'},
    {'emoji': '💪', 'title': 'Workout Together', 'desc': 'Do 20 push-ups in her honour. Every rep = a thought of her.'},
    {'emoji': '🧘', 'title': 'Meditate with Her', 'desc': 'Sit in silence for 5 minutes and visualize a peaceful date.'},
  ];

  late Map<String, String> _todayChallenge;
  bool _completed = false;
  int _streak = 0;
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    final idx = DateTime.now().dayOfYear % _challenges.length;
    _todayChallenge = _challenges[idx];
    _loadStatus();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<void> _loadStatus() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(_uid)
          .collection('coupleChallenge').doc('status').get();
      if (snap.exists && mounted) {
        final lastDate = snap['lastCompleted'] as String?;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        setState(() {
          _completed = lastDate == today;
          _streak = (snap['streak'] as int?) ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _markComplete() async {
    if (_completed) return;
    HapticFeedback.heavyImpact();
    _bounceCtrl.forward(from: 0);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(_uid)
          .collection('coupleChallenge').doc('status').get();
      final lastDate = snap.exists ? (snap['lastCompleted'] as String?) : null;
      final newStreak = lastDate == yesterday ? _streak + 1 : 1;
      await FirebaseFirestore.instance.collection('users').doc(_uid)
          .collection('coupleChallenge').doc('status').set({
        'lastCompleted': today,
        'streak': newStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() { _completed = true; _streak = newStreak; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080F),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context)),
            const Spacer(),
            Text('💑 Daily Challenge',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text('🔥 $_streak', style: GoogleFonts.outfit(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text("Today's Challenge", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, letterSpacing: 1.5)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedBuilder(
            animation: _bounceCtrl,
            builder: (_, child) {
              final scale = _completed ? 1.0 + 0.05 * (1.0 - _bounceCtrl.value) : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _completed
                      ? [Colors.pinkAccent.withValues(alpha: 0.3), Colors.deepPurple.withValues(alpha: 0.3)]
                      : [Colors.deepPurple.withValues(alpha: 0.2), Colors.indigo.withValues(alpha: 0.2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: _completed ? Colors.pinkAccent.withValues(alpha: 0.6) : Colors.white12, width: 1.5),
                boxShadow: _completed
                    ? [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.3), blurRadius: 30)]
                    : null,
              ),
              child: Column(children: [
                Text(_todayChallenge['emoji']!, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(_todayChallenge['title']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(_todayChallenge['desc']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15, height: 1.5)),
                if (_completed) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text('✅ Completed Today!',
                        style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            ),
          ),
        ),
        const Spacer(),
        if (!_completed)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: GestureDetector(
              onTap: _markComplete,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.4), blurRadius: 20)],
                ),
                child: Text("I Did It! 🎉",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text('Come back tomorrow for a new challenge~ 💕',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
          ),
      ])),
    );
  }
}

extension _DateExt on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays;
  }
}
