import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_waifu/api_call.dart';

class WordAssociationPage extends StatefulWidget {
  const WordAssociationPage({super.key});
  @override
  State<WordAssociationPage> createState() => _WordAssociationPageState();
}

class _WordAssociationPageState extends State<WordAssociationPage> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, String>> _chain = [];
  bool _waitingAI = false;
  bool _gameOver = false;
  int _longestStreak = 0;
  late AnimationController _bgCtrl;

  final _starterWords = ['Love', 'Star', 'Heart', 'Dream', 'Zero', 'Moon', 'Fire', 'Night'];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _loadStreak();
    _startGame();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<void> _loadStreak() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(_uid).collection('wordGame').doc('stats').get();
      if (snap.exists && mounted) setState(() => _longestStreak = (snap['longestStreak'] as int?) ?? 0);
    } catch (_) {}
  }

  Future<void> _saveStreak(int streak) async {
    try {
      if (streak > _longestStreak) {
        await FirebaseFirestore.instance.collection('users').doc(_uid).collection('wordGame').doc('stats')
            .set({'longestStreak': streak, 'updatedAt': FieldValue.serverTimestamp()});
        setState(() => _longestStreak = streak);
      }
    } catch (_) {}
  }

  void _startGame() {
    final starter = _starterWords[Random().nextInt(_starterWords.length)];
    setState(() {
      _chain = [{'word': starter, 'by': 'Zero Two'}];
      _gameOver = false;
    });
  }

  Future<void> _playerWord() async {
    final word = _ctrl.text.trim();
    if (word.isEmpty || _waitingAI || _gameOver) return;
    HapticFeedback.lightImpact();
    final lastWord = _chain.last['word']!;
    // Simple same-last-letter check
    if (word.toLowerCase()[0] != lastWord.toLowerCase()[lastWord.length - 1]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Must start with "${lastWord[lastWord.length - 1].toUpperCase()}"!',
            style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 2)));
      return;
    }
    setState(() {
      _chain.add({'word': word, 'by': 'You'});
      _ctrl.clear();
      _waitingAI = true;
    });
    _scrollDown();
    // AI responds
    try {
      final prompt = 'Word association game: give exactly ONE single English word that starts with the last letter of "$word". Only respond with the word itself, nothing else.';
      final aiWord = (await ApiService().sendConversation([{'role': 'user', 'content': prompt}])).trim().split(' ').first;
      if (mounted) {
        setState(() {
          _chain.add({'word': aiWord, 'by': 'Zero Two'});
          _waitingAI = false;
        });
        _scrollDown();
        await _saveStreak(_chain.length);
      }
    } catch (_) {
      if (mounted) setState(() { _gameOver = true; _waitingAI = false; });
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      resizeToAvoidBottomInset: true,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20), onPressed: () => Navigator.pop(context)),
            const Spacer(),
            Text('🔤 Word Association', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.tealAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text('Best: $_longestStreak', style: GoogleFonts.outfit(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        // Rules chip
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text('Each word must start with the last letter of the previous word',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
        ),
        // Chain
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _chain.length + (_waitingAI ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _chain.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var j = 0; j < 3; j++) ...[
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + j * 150),
                          builder: (_, v, __) => Opacity(opacity: v, child: Container(
                            width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
                          )),
                        ),
                      ],
                    ]),
                  ),
                );
              }
              final entry = _chain[i];
              final isAI = entry['by'] == 'Zero Two';
              return TweenAnimationBuilder(
                duration: const Duration(milliseconds: 350),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (_, v, child) => Opacity(opacity: v, child: child),
                child: Align(
                  alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAI
                            ? [Colors.pinkAccent.withValues(alpha: 0.2), Colors.deepPurple.withValues(alpha: 0.2)]
                            : [Colors.cyanAccent.withValues(alpha: 0.2), Colors.blue.withValues(alpha: 0.1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: (isAI ? Colors.pinkAccent : Colors.cyanAccent).withValues(alpha: 0.3)),
                    ),
                    child: Column(crossAxisAlignment: isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                      Text(entry['word']!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(entry['by']!, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        // Input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                enabled: !_waitingAI && !_gameOver,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.outfit(color: Colors.white),
                onSubmitted: (_) => _playerWord(),
                decoration: InputDecoration(
                  hintText: _chain.isEmpty ? '' : 'Must start with "${_chain.last['word']![_chain.last['word']!.length - 1].toUpperCase()}"...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (_gameOver)
              GestureDetector(
                onTap: _startGame,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              )
            else
              GestureDetector(
                onTap: _playerWord,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
          ]),
        ),
      ])),
    );
  }
}
