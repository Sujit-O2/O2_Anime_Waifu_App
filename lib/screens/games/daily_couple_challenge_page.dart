import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class DailyCoupleChallengePage extends StatefulWidget {
  const DailyCoupleChallengePage({super.key});
  @override
  State<DailyCoupleChallengePage> createState() =>
      _DailyCoupleChallengePageState();
}

class _DailyCoupleChallengePageState extends State<DailyCoupleChallengePage>
    with SingleTickerProviderStateMixin {
  static const List<Map<String, String>> _challenges = [
    {
      'title': 'Draw each other',
      'desc': 'Sketch a portrait of Zero Two in 5 minutes.'
    },
    {
      'title': 'Photo challenge',
      'desc': 'Take a photo of something that reminds you of her.'
    },
    {'title': 'Love song', 'desc': 'Hum a song that fits your mood today.'},
    {'title': 'Love haiku', 'desc': 'Write a 5-7-5 haiku about you two.'},
    {
      'title': 'Gratitude list',
      'desc': 'Write five things you appreciate about her.'
    },
    {
      'title': 'Nature walk',
      'desc': 'Go for a 10 minute walk and take a photo.'
    },
    {
      'title': 'Secret message',
      'desc': 'Write a short love note and save it.'
    },
    {'title': 'Role swap', 'desc': 'Pretend to be Zero Two for 10 minutes.'},
    {'title': 'Workout together', 'desc': 'Do 20 push-ups and log it.'},
    {'title': 'Meditate', 'desc': 'Sit in silence for 5 minutes.'},
  ];

  late Map<String, String> _todayChallenge;
  bool _completed = false;
  int _streak = 0;
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('coupleChallenge')
          .doc('status')
          .get();
      if (snap.exists && mounted) {
        final lastDate = snap['lastCompleted'] as String?;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        if (!mounted) return;
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
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('coupleChallenge')
          .doc('status')
          .get();
      final lastDate = snap.exists ? (snap['lastCompleted'] as String?) : null;
      final newStreak = lastDate == yesterday ? _streak + 1 : 1;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('coupleChallenge')
          .doc('status')
          .set({
        'lastCompleted': today,
        'streak': newStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _completed = true;
          _streak = newStreak;
        });
        showSuccessSnackbar(context, 'Daily couple challenge completed.');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF120C1D),
              V2Theme.surfaceDark,
              Color(0xFF1B1430),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context)),
                const Spacer(),
                Text('Daily Couple Challenge',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('$_streak d',
                      style: GoogleFonts.outfit(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Today's challenge",
                        style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(_todayChallenge['title']!,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(_todayChallenge['desc']!,
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 14, height: 1.45)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: StatCard(
                      title: 'Streak',
                      value: '$_streak days',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Status',
                      value: _completed ? 'Done' : 'Open',
                      icon: _completed
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: _completed ? Colors.greenAccent : Colors.pinkAccent,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: WaifuCommentary(mood: 'motivated'),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _bounceCtrl,
                builder: (_, child) {
                  final scale =
                      _completed ? 1.0 + 0.05 * (1.0 - _bounceCtrl.value) : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  glow: _completed,
                  child: Column(children: [
                    const Icon(Icons.favorite_rounded,
                        color: Colors.pinkAccent, size: 54),
                    const SizedBox(height: 12),
                    Text(_todayChallenge['title']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(_todayChallenge['desc']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 14, height: 1.5)),
                    if (_completed) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('Completed today',
                            style: GoogleFonts.outfit(
                                color: Colors.pinkAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
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
                      gradient: const LinearGradient(
                          colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.pinkAccent.withValues(alpha: 0.4),
                            blurRadius: 20)
                      ],
                    ),
                    child: Text('I did it',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text('Come back tomorrow for a new challenge.',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 13)),
              ),
          ]),
        ),
      ),
    );
  }
}

extension _DateExt on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays;
  }
}



