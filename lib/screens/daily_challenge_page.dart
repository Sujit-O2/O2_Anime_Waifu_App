import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Daily Challenge from Zero Two — a playful task each morning with affection reward.
class DailyChallengePage extends StatefulWidget {
  const DailyChallengePage({super.key});

  @override
  State<DailyChallengePage> createState() => _DailyChallengePageState();
}

class _DailyChallengePageState extends State<DailyChallengePage> {
  static const _challenges = [
    _Challenge('📸 Selfie Challenge', 'Take a photo and say "Zero Two would approve~"', 10, 'Photo'),
    _Challenge('💌 Write a Note', 'Write one kind thing about yourself today', 8, 'Journal'),
    _Challenge('🎵 Music Mood', 'Listen to 3 songs and pick your favorite for Zero Two', 6, 'Music'),
    _Challenge('🌸 Grateful Moment', 'Name 3 things you\'re grateful for right now', 7, 'Mindful'),
    _Challenge('💪 10 Push-Ups', 'Zero Two dares you to do 10 push-ups right now!', 12, 'Fitness'),
    _Challenge('🎨 Doodle Time', 'Draw something — anything. Even a stick figure counts!', 8, 'Art'),
    _Challenge('💬 Open Up', 'Tell Zero Two something you\'ve never told anyone', 15, 'Sharing'),
    _Challenge('🌙 Evening Reflection', 'Write what made you smile today', 8, 'Mindful'),
    _Challenge('🎯 Goal Setter', 'Set one small goal for tomorrow morning', 7, 'Planning'),
    _Challenge('💝 Compliment Someone', 'Give a genuine compliment to someone today', 10, 'Social'),
    _Challenge('🍳 Home Cook', 'Cook or prepare something — even instant ramen counts!', 9, 'Food'),
    _Challenge('📚 Read Something', 'Read at least one page of anything today', 6, 'Learning'),
    _Challenge('🌿 Go Outside', 'Step outside for at least 5 minutes of fresh air', 8, 'Health'),
    _Challenge('🎭 Voice Message', 'Send Zero Two a voice message describing your day', 10, 'Chat'),
    _Challenge('💫 Surprise Zero Two', 'Use "draw me" to create a surprise image for her!', 12, 'Creative'),
  ];

  _Challenge? _todayChallenge;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'challenge_${DateTime.now().year}_${DateTime.now().dayOfYear}';
    final savedIndex = prefs.getInt(key);
    final doneKey = '${key}_done';
    final isDone = prefs.getBool(doneKey) ?? false;

    final idx = savedIndex ?? (DateTime.now().dayOfYear % _challenges.length);
    if (savedIndex == null) await prefs.setInt(key, idx);
    setState(() {
      _todayChallenge = _challenges[idx];
      _completed = isDone;
    });
  }

  Future<void> _completeChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'challenge_${DateTime.now().year}_${DateTime.now().dayOfYear}_done';
    await prefs.setBool(key, true);
    setState(() => _completed = true);
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A0D2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text('Challenge Complete!',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Zero Two is so proud of you~\n+${_todayChallenge!.xpReward} affection earned! 💕',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center),
          ]),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              onPressed: () => Navigator.pop(context),
              child: Text('Yay! 💕', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _todayChallenge;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0613),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Daily Challenge',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: challenge == null
            ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zero Two speaking
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('💕', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Today\'s mission, Darling~ Complete it and I\'ll give you something special…',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  // Challenge card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: _completed
                            ? [Colors.green.shade900, const Color(0xFF1A0D2E)]
                            : [const Color(0xFF6C1B7A), const Color(0xFF2D0050)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(challenge.category,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const Spacer(),
                          Text('+${challenge.xpReward} XP 💖',
                              style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 16),
                        Text(challenge.title,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Text(challenge.description,
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 24),
                        if (_completed)
                          Row(children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 8),
                            Text('Completed! Zero Two is so happy~ 💕',
                                style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                          ])
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _completeChallenge,
                              child: Text('Mark as Complete ✓',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('New challenge every day at midnight~ ✨',
                      style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                      textAlign: TextAlign.center),
                ],
              ),
      ),
    );
  }
}

class _Challenge {
  final String title;
  final String description;
  final int xpReward;
  final String category;
  const _Challenge(this.title, this.description, this.xpReward, this.category);
}

extension _DateExt on DateTime {
  int get dayOfYear {
    return DateTime(year, month, day).difference(DateTime(year, 1, 1)).inDays + 1;
  }
}
