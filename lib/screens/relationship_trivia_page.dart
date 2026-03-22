import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/affection_service.dart';
import '../services/game_sounds_service.dart';

class RelationshipTriviaPage extends StatefulWidget {
  const RelationshipTriviaPage({super.key});
  @override
  State<RelationshipTriviaPage> createState() => _RelationshipTriviaPageState();
}

class _TQ {
  final String q;
  final List<String> opts;
  final int correct;
  final String explanation;
  const _TQ(
      {required this.q,
      required this.opts,
      required this.correct,
      required this.explanation});
}

const _questions = [
  _TQ(
    q: 'What is Zero Two\'s squad number?',
    opts: ['002', '015', '016', '056'],
    correct: 0,
    explanation:
        'Zero Two\'s codename is 002, which is how she got her nickname!',
  ),
  _TQ(
    q: 'What species is Zero Two?',
    opts: ['Human', 'Klaxosaur hybrid', 'Android', 'FRANXX'],
    correct: 1,
    explanation:
        'Zero Two is a human-Klaxosaur hybrid, descended from the Klaxosaur Princess.',
  ),
  _TQ(
    q: 'What does Zero Two call her partner?',
    opts: ['Partner', 'Pilot', 'Darling', 'Love'],
    correct: 2,
    explanation:
        'Zero Two famously calls Hiro "Darling" — her term of endearment!',
  ),
  _TQ(
    q: 'What is the name of the FranXX piloted by Zero Two and Hiro?',
    opts: ['Argentea', 'Strelizia', 'Genista', 'Chlorophytum'],
    correct: 1,
    explanation:
        'Strelizia is their FranXX, named after the bird-of-paradise flower.',
  ),
  _TQ(
    q: 'What color are Zero Two\'s horns?',
    opts: ['Red', 'Pink', 'White', 'Black'],
    correct: 0,
    explanation:
        'Zero Two has distinctive red/pink horns that she\'s often self-conscious about.',
  ),
  _TQ(
    q: 'What book shares a special connection between Zero Two and Hiro?',
    opts: [
      'The Little Mermaid',
      'Alice in Wonderland',
      'The Little Prince',
      'Beauty and the Beast'
    ],
    correct: 2,
    explanation:
        '"The Little Prince" mirrors their story — she is the "monster who needs to become human" through love.',
  ),
  _TQ(
    q: 'Who created Zero Two?',
    opts: ['Papa', 'APE organization', 'Dr. Franxx', 'The Klaxosaur Queen'],
    correct: 2,
    explanation:
        'Dr. FRANXX created and experimented on Zero Two to develop the FranXX system.',
  ),
  _TQ(
    q: 'What is the name of the group that controls the world in DITF?',
    opts: ['NITRO', 'APE', 'NTR Squad', 'Plantation'],
    correct: 1,
    explanation:
        'APE (Aristocracy of Primates and Elites) is the ruling organization that controls the Plantations.',
  ),
  _TQ(
    q: 'What do Zero Two\'s horns and tail signify?',
    opts: [
      'Her strength level',
      'Her Klaxosaur heritage',
      'Her rank in APE',
      'Her FranXX sync rate'
    ],
    correct: 1,
    explanation:
        'Her horns and tail are physical manifestations of her Klaxosaur genetic heritage.',
  ),
  _TQ(
    q: 'What happens to partners who ride with Zero Two too many times?',
    opts: [
      'They gain power',
      'They become FranXX pilots',
      'They die',
      'They evolve'
    ],
    correct: 2,
    explanation:
        'Zero Two\'s partners always died after a few rides — she was called the "Partner Killer" before Hiro.',
  ),
];

class _RelationshipTriviaPageState extends State<RelationshipTriviaPage> {
  int _qIdx = 0;
  int? _chosen;
  bool _answered = false;
  int _score = 0;
  bool _done = false;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('game_scores')
          .doc(user.uid)
          .collection('trivia')
          .doc('best')
          .get();
      if (doc.exists) {
        setState(() => _highScore = (doc['score'] as int? ?? 0));
      }
    } catch (_) {}
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('game_scores')
        .doc(user.uid)
        .collection('trivia');
    // Save run
    await ref.add({
      'score': _score,
      'total': _questions.length,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Update best
    if (_score > _highScore) {
      await ref.doc('best').set({'score': _score});
      setState(() => _highScore = _score);
    }
  }

  void _choose(int idx) {
    if (_answered) return;
    final correct = idx == _questions[_qIdx].correct;
    if (correct) {
      GameSoundsService.instance.playCorrect();
    } else {
      GameSoundsService.instance.playWrong();
    }
    setState(() {
      _chosen = idx;
      _answered = true;
      if (correct) {
        _score++;
      }
    });
  }

  void _next() {
    if (_qIdx < _questions.length - 1) {
      setState(() {
        _qIdx++;
        _chosen = null;
        _answered = false;
      });
    } else {
      setState(() => _done = true);
      final xp = _score * 5;
      AffectionService.instance.addPoints(xp);
      _saveScore();
    }
  }

  void _restart() => setState(() {
        _qIdx = 0;
        _chosen = null;
        _answered = false;
        _score = 0;
        _done = false;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('DARLING TRIVIA',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        centerTitle: true,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                  child: Text(_done ? '✅' : '${_qIdx + 1}/${_questions.length}',
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 12)))),
        ],
      ),
      body: _done ? _buildResult() : _buildQuestion(),
    );
  }

  Widget _buildResult() {
    final pct = _score / _questions.length;
    String msg;
    String emoji;
    if (pct == 1.0) {
      msg = 'Perfect! You know me so well, Darling~';
      emoji = '🌸💯';
    } else if (pct >= 0.7) {
      msg = 'Not bad, Darling! You\'ve been paying attention~';
      emoji = '💕';
    } else if (pct >= 0.4) {
      msg = 'You\'re still learning about me~ I\'ll forgive you!';
      emoji = '😏';
    } else {
      msg = 'We need to watch more DITF together, Darling!';
      emoji = '😤';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text('$_score / ${_questions.length}',
              style: GoogleFonts.outfit(
                  color: Colors.pinkAccent,
                  fontSize: 52,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Best: $_highScore/${_questions.length}',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          Text(msg,
              style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 15,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('+${_score * 5} XP earned!',
              style: GoogleFonts.outfit(
                  color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Play Again',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_qIdx];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progress
        LinearProgressIndicator(
          value: (_qIdx + 1) / _questions.length,
          backgroundColor: Colors.white12,
          valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 24),
        // Question card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
                colors: [Color(0xFF1A0A2E), Color(0xFF0A1020)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            border:
                Border.all(color: Colors.pinkAccent.withValues(alpha: 0.25)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🌸', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text(q.q,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.4)),
          ]),
        ),
        const SizedBox(height: 20),
        // Options
        ...q.opts.asMap().entries.map((e) {
          final idx = e.key;
          final text = e.value;
          Color borderColor = Colors.white.withValues(alpha: 0.12);
          Color bgColor = Colors.white.withValues(alpha: 0.04);
          Color textColor = Colors.white70;
          if (_answered) {
            if (idx == q.correct) {
              borderColor = Colors.greenAccent;
              bgColor = Colors.greenAccent.withValues(alpha: 0.12);
              textColor = Colors.greenAccent;
            } else if (idx == _chosen) {
              borderColor = Colors.redAccent;
              bgColor = Colors.redAccent.withValues(alpha: 0.12);
              textColor = Colors.redAccent;
            }
          } else if (_chosen == idx) {
            borderColor = Colors.pinkAccent;
            bgColor = Colors.pinkAccent.withValues(alpha: 0.12);
            textColor = Colors.pinkAccent;
          }
          return GestureDetector(
            onTap: () => _choose(idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: bgColor,
                border: Border.all(color: borderColor),
              ),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                    color: bgColor,
                  ),
                  child: Center(
                      child: Text(['A', 'B', 'C', 'D'][idx],
                          style: GoogleFonts.outfit(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11))),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(text,
                        style: GoogleFonts.outfit(
                            color: textColor, fontSize: 14))),
                if (_answered && idx == q.correct)
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.greenAccent, size: 20),
                if (_answered && idx == _chosen && idx != q.correct)
                  const Icon(Icons.cancel_rounded,
                      color: Colors.redAccent, size: 20),
              ]),
            ),
          );
        }),
        // Explanation
        if (_answered) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.amberAccent.withValues(alpha: 0.07),
              border:
                  Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(q.explanation,
                      style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontSize: 13,
                          height: 1.4))),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                  _qIdx < _questions.length - 1
                      ? 'Next Question →'
                      : 'See Results',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ]),
    );
  }
}
