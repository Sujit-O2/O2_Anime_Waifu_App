import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/affection_service.dart';

class WordPuzzlePage extends StatefulWidget {
  const WordPuzzlePage({super.key});
  @override
  State<WordPuzzlePage> createState() => _WordPuzzlePageState();
}

class _WordItem {
  final String word, hint;
  const _WordItem(this.word, this.hint);
}

class _WordPuzzlePageState extends State<WordPuzzlePage> {
  static const _wordList = [
    _WordItem('DARLING', 'What Zero Two always calls you'),
    _WordItem('STRELIZIA', 'Zero Two\'s FranXX name'),
    _WordItem('HIRO', 'Zero Two\'s pilot partner'),
    _WordItem('PLANTATION', 'Where the Parasites live'),
    _WordItem('KLAXOSAUR', 'The enemies they fight'),
    _WordItem('AFFECTION', 'Your connection score in this app'),
    _WordItem('PARASITE', 'What the children pilots are called'),
    _WordItem('FRANXX', 'The mechs they pilot'),
    _WordItem('ICHIGO', 'Squad 13 leader, Code 015'),
    _WordItem('GORO', 'Ichigo\'s loyal partner'),
    _WordItem('MITSURU', 'The cold one, Code 326 (later 326)'),
    _WordItem('KOKORO', 'The gentle one who loves flowers'),
    _WordItem('FUTOSHI', 'Kokoro\'s devoted partner'),
    _WordItem('NANA', 'The adults\' handler'),
    _WordItem('PAPA', 'Leader of APE, mysterious figure'),
    _WordItem('WAIFU', 'What this app is about'),
  ];

  late _WordItem _current;
  List<String> _guessedLetters = [];
  int _wrongGuesses = 0;
  static const _maxWrong = 6;
  String _message = '';
  bool _won = false;
  bool _lost = false;
  int _streak = 0;

  final _keyboard = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  @override
  void initState() {
    super.initState();
    _newWord();
  }

  void _newWord() {
    final rng = Random();
    _current = _wordList[rng.nextInt(_wordList.length)];
    setState(() {
      _guessedLetters = [];
      _wrongGuesses = 0;
      _message = '';
      _won = false;
      _lost = false;
    });
  }

  void _guess(String letter) {
    if (_guessedLetters.contains(letter) || _won || _lost) return;
    setState(() {
      _guessedLetters.add(letter);
      if (!_current.word.contains(letter)) {
        _wrongGuesses++;
        if (_wrongGuesses >= _maxWrong) {
          _lost = true;
          _streak = 0;
          _message = 'Oh no, Darling... The word was "${_current.word}" 😢';
        }
      } else {
        final allGuessed =
            _current.word.split('').every((c) => _guessedLetters.contains(c));
        if (allGuessed) {
          _won = true;
          _streak++;
          AffectionService.instance.addPoints(5 + _streak);
          _message = 'You got it, Darling! 🎉 +${5 + _streak} XP!';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = _current.word
        .split('')
        .map((c) => _guessedLetters.contains(c) ? c : '_')
        .join(' ');
    final lives = _maxWrong - _wrongGuesses;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('WORD PUZZLE',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
                child: Text('🔥 $_streak streak',
                    style: GoogleFonts.outfit(
                        color: Colors.orangeAccent, fontSize: 12))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white12),
            ),
            child: Text('💡 Hint: ${_current.hint}',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
          ),
          const SizedBox(height: 16),

          // Hangman visual
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    _lost
                        ? '💀'
                        : _won
                            ? '🎉'
                            : '❤️' * lives,
                    style: TextStyle(fontSize: _won || _lost ? 36 : 18)),
                const SizedBox(height: 4),
                Text('$lives / $_maxWrong lives',
                    style: GoogleFonts.outfit(
                        color: lives <= 2 ? Colors.redAccent : Colors.white38,
                        fontSize: 12)),
                if (_wrongGuesses > 0)
                  Text(
                    'Wrong: ${_guessedLetters.where((l) => !_current.word.contains(l)).join(", ")}',
                    style: GoogleFonts.outfit(
                        color: Colors.redAccent.withValues(alpha: 0.7),
                        fontSize: 11),
                  ),
              ],
            )),
          ),
          const SizedBox(height: 20),

          // Word display
          Text(word,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8)),
          const SizedBox(height: 8),

          // Message
          if (_message.isNotEmpty)
            Text(_message,
                style: GoogleFonts.outfit(
                    color: _won ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),

          const SizedBox(height: 16),

          // Next / Keyboard
          if (_won || _lost)
            ElevatedButton(
              onPressed: _newWord,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Next Word →',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.1),
                itemCount: _keyboard.length,
                itemBuilder: (ctx, i) {
                  final l = _keyboard[i];
                  final guessed = _guessedLetters.contains(l);
                  final correct = guessed && _current.word.contains(l);
                  final wrong = guessed && !_current.word.contains(l);
                  return GestureDetector(
                    onTap: guessed ? null : () => _guess(l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: correct
                            ? Colors.greenAccent.withValues(alpha: 0.2)
                            : wrong
                                ? Colors.redAccent.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                            color: correct
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : wrong
                                    ? Colors.redAccent.withValues(alpha: 0.3)
                                    : Colors.white12),
                      ),
                      child: Center(
                          child: Text(l,
                              style: GoogleFonts.outfit(
                                  color:
                                      guessed ? Colors.white24 : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold))),
                    ),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}
