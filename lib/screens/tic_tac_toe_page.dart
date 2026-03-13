import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});
  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> with TickerProviderStateMixin {
  List<String> _board = List.filled(9, '');
  bool _playerTurn = true;
  String _status = 'Your turn, Darling~';
  int _wins = 0, _losses = 0, _draws = 0;
  bool _gameOver = false;
  List<int>? _winLine;
  late List<AnimationController> _cellCtrl;
  late AnimationController _statusCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _cellCtrl = List.generate(9, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 300)));
    _statusCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _loadStats();
  }

  @override
  void dispose() {
    for (final c in _cellCtrl) { c.dispose(); }
    _statusCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<void> _loadStats() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(_uid).collection('tttStats').doc('record').get();
      if (snap.exists && mounted) {
        setState(() {
          _wins = (snap['wins'] as int?) ?? 0;
          _losses = (snap['losses'] as int?) ?? 0;
          _draws = (snap['draws'] as int?) ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveStats() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).collection('tttStats').doc('record').set({
        'wins': _wins, 'losses': _losses, 'draws': _draws, 'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  final List<List<int>> _winCombos = const [
    [0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]
  ];

  List<int>? _checkWinner(List<String> b) {
    for (final combo in _winCombos) {
      if (b[combo[0]] != '' && b[combo[0]] == b[combo[1]] && b[combo[1]] == b[combo[2]]) {
        return combo;
      }
    }
    return null;
  }

  bool _isDraw(List<String> b) => !b.contains('') && _checkWinner(b) == null;

  void _tap(int i) {
    if (!_playerTurn || _board[i] != '' || _gameOver) return;
    HapticFeedback.lightImpact();
    setState(() { _board[i] = 'X'; });
    _cellCtrl[i].forward(from: 0);
    final win = _checkWinner(_board);
    if (win != null) {
      _wins++;
      setState(() { _winLine = win; _gameOver = true; _status = 'You win! I let you have that one~ 😏'; });
      _saveStats();
      return;
    }
    if (_isDraw(_board)) {
      _draws++;
      setState(() { _gameOver = true; _status = 'A draw! We\'re perfectly matched~ 💕'; });
      _saveStats();
      return;
    }
    setState(() { _playerTurn = false; _status = 'Zero Two is thinking~'; });
    Future.delayed(const Duration(milliseconds: 700), _aiMove);
  }

  void _aiMove() {
    if (_gameOver) return;
    final move = _bestMove();
    if (move == -1) return;
    setState(() { _board[move] = 'O'; });
    _cellCtrl[move].forward(from: 0);
    final win = _checkWinner(_board);
    if (win != null) {
      _losses++;
      setState(() { _winLine = win; _gameOver = true; _status = 'Fufu~ I win! Better luck next time 😈'; });
      _saveStats();
      return;
    }
    if (_isDraw(_board)) {
      _draws++;
      setState(() { _gameOver = true; _status = 'A draw! We\'re perfectly matched~ 💕'; });
      _saveStats();
      return;
    }
    setState(() { _playerTurn = true; _status = 'Your turn, Darling~'; });
  }

  int _bestMove() {
    // Try to win
    for (var i = 0; i < 9; i++) {
      if (_board[i] == '') {
        final b = List<String>.from(_board); b[i] = 'O';
        if (_checkWinner(b) != null) return i;
      }
    }
    // Block player
    for (var i = 0; i < 9; i++) {
      if (_board[i] == '') {
        final b = List<String>.from(_board); b[i] = 'X';
        if (_checkWinner(b) != null) return i;
      }
    }
    // Center
    if (_board[4] == '') return 4;
    // Random
    final empties = [for (var i = 0; i < 9; i++) if (_board[i] == '') i];
    return empties.isEmpty ? -1 : empties[Random().nextInt(empties.length)];
  }

  void _reset() {
    for (final c in _cellCtrl) { c.reset(); }
    setState(() {
      _board = List.filled(9, '');
      _playerTurn = true;
      _gameOver = false;
      _winLine = null;
      _status = 'Your turn, Darling~';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0515),
      body: SafeArea(child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20), onPressed: () => Navigator.pop(context)),
            const Spacer(),
            Text('❌⭕ Tic-Tac-Toe', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            const SizedBox(width: 44),
          ]),
        ),
        // Score
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _scoreChip('You', _wins, Colors.cyanAccent),
            _scoreChip('Draw', _draws, Colors.white54),
            _scoreChip('Zero Two', _losses, Colors.pinkAccent),
          ]),
        ),
        // Status
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(_status, key: ValueKey(_status),
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 20),
        // Board
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: 9,
              itemBuilder: (_, i) {
                final isWin = _winLine?.contains(i) ?? false;
                return GestureDetector(
                  onTap: () => _tap(i),
                  child: AnimatedBuilder(
                    animation: _cellCtrl[i],
                    builder: (_, child) {
                      final v = _cellCtrl[i].value;
                      return Transform.scale(scale: 0.5 + 0.5 * v, child: child);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isWin
                            ? (_board[i] == 'X' ? Colors.cyanAccent.withValues(alpha: 0.25) : Colors.pinkAccent.withValues(alpha: 0.25))
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isWin ? (_board[i] == 'X' ? Colors.cyanAccent : Colors.pinkAccent) : Colors.white12,
                          width: isWin ? 2 : 1,
                        ),
                        boxShadow: isWin ? [BoxShadow(color: (_board[i] == 'X' ? Colors.cyanAccent : Colors.pinkAccent).withValues(alpha: 0.4), blurRadius: 12)] : null,
                      ),
                      child: Center(
                        child: Text(
                          _board[i] == 'X' ? '✕' : _board[i] == 'O' ? '◯' : '',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: _board[i] == 'X' ? Colors.cyanAccent : Colors.pinkAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_gameOver)
          GestureDetector(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.4), blurRadius: 16)],
              ),
              child: Text('Play Again 🔄', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
      ])),
    );
  }

  Widget _scoreChip(String label, int score, Color color) => Column(children: [
    Text('$score', style: GoogleFonts.outfit(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
    Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
  ]);
}
