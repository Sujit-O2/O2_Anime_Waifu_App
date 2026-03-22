import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_waifu/api_call.dart';

class TwentyQuestionsPage extends StatefulWidget {
  const TwentyQuestionsPage({super.key});
  @override
  State<TwentyQuestionsPage> createState() => _TwentyQuestionsPageState();
}

class _TwentyQuestionsPageState extends State<TwentyQuestionsPage> with SingleTickerProviderStateMixin {
  List<Map<String, String>> _history = [];
  int _questionsLeft = 20;
  bool _gameOver = false;
  bool _loading = false;
  String _topic = '';
  final _topicCtrl = TextEditingController();
  int _wins = 0, _zerotwoWins = 0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _loadStats();
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<void> _loadStats() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(_uid).collection('twentyQStats').doc('record').get();
      if (snap.exists && mounted) {
        setState(() {
          _wins = (snap['wins'] as int?) ?? 0;
          _zerotwoWins = (snap['zerotwoWins'] as int?) ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveStats() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).collection('twentyQStats').doc('record')
          .set({'wins': _wins, 'zerotwoWins': _zerotwoWins, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  Future<void> _startGame(String topic) async {
    if (topic.trim().isEmpty) return;
    _topic = topic.trim();
    setState(() { _history = []; _questionsLeft = 20; _gameOver = false; _loading = true; });
    await _askQuestion();
  }

  Future<void> _askQuestion() async {
    if (_questionsLeft <= 0 || _gameOver) return;
    setState(() => _loading = true);
    try {
      final ctx = _history.map((e) => '${e['q']}: ${e['a']}').join('\n');
      final prompt = _history.isEmpty
          ? 'You are Zero Two playing 20 questions. The human is thinking of: "$_topic". Ask a clever yes/no question to narrow it down. Respond with ONLY the question itself, nothing else.'
          : 'You are playing 20 questions. Hidden word: "$_topic". Previous Q&A:\n$ctx\n\nAsk ONE more yes/no question (${_questionsLeft - 1} left). If you\'re very confident, say "Is it $_topic?" Only respond with the question.';
      final q = (await ApiService().sendConversation([{'role': 'user', 'content': prompt}])).trim();
      if (mounted) {
        setState(() {
          _history.add({'q': q, 'a': '?', 'idx': '${20 - _questionsLeft + 1}'});
          _questionsLeft--;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _answer(String answer) async {
    if (_history.isEmpty || _loading) return;
    HapticFeedback.lightImpact();
    final last = Map<String, String>.from(_history.last);
    last['a'] = answer;
    setState(() => _history[_history.length - 1] = last);

    if (last['q']!.toLowerCase().contains('is it')) {
      if (answer == 'Yes') {
        _zerotwoWins++;
        setState(() { _gameOver = true; });
        _saveStats();
        return;
      } else if (_questionsLeft <= 0) {
        _wins++;
        setState(() { _gameOver = true; });
        _saveStats();
        return;
      }
    }

    if (_questionsLeft > 0) {
      await _askQuestion();
    } else {
      _wins++;
      setState(() { _gameOver = true; });
      _saveStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08090F),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context)),
            const Spacer(),
            Text('❓ 20 Questions', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            Row(children: [
              Text('You: $_wins', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 12)),
              const SizedBox(width: 8),
              Text('ZT: $_zerotwoWins', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 12)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        if (_topic.isEmpty) ...[
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Think of anything~', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('I\'ll try to guess it in 20 questions!', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 32),
              TextField(
                controller: _topicCtrl,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your secret word...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _startGame(_topicCtrl.text),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.4), blurRadius: 20)],
                  ),
                  child: Text("Let's Play!", textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          )),
        ] else ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Questions left: $_questionsLeft', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
              Text('Your word: "$_topic"', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12, fontStyle: FontStyle.italic)),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _history.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _history.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      const Text('🌸', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Row(children: List.generate(3, (j) => Container(
                          width: 7, height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.pinkAccent.withValues(alpha: 0.4 + 0.6 * ((j == 0 ? _pulseCtrl.value : j == 1 ? 1 - _pulseCtrl.value : _pulseCtrl.value)))),
                        ))),
                      ),
                    ]),
                  );
                }
                final entry = _history[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('🌸', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
                        ),
                        child: Text(entry['q']!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                      )),
                    ]),
                    if (entry['a'] == '?') ...[
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        _ansBtn('Yes ✅'),
                        const SizedBox(width: 8),
                        _ansBtn('No ❌'),
                        const SizedBox(width: 8),
                        _ansBtn('Maybe 🤔'),
                      ]),
                    ] else
                      Align(alignment: Alignment.centerRight, child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 4),
                        child: Text(entry['a']!, style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                      )),
                  ]),
                );
              },
            ),
          ),
          if (_gameOver) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.pinkAccent.withValues(alpha: 0.2), Colors.deepPurple.withValues(alpha: 0.2)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4)),
              ),
              child: Column(children: [
                Text(_zerotwoWins > _wins ? 'Fufu~ I guessed it! 🎉' : 'You win! I couldn\'t guess it~ 😤',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () { _topicCtrl.clear(); setState(() { _topic = ''; _history = []; _questionsLeft = 20; _gameOver = false; }); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]), borderRadius: BorderRadius.circular(20)),
                    child: Text('Play Again 🔄', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ])),
    );
  }

  Widget _ansBtn(String label) => GestureDetector(
    onTap: () => _answer(label.split(' ').first),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
    ),
  );
}
