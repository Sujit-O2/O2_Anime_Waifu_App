import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({super.key});
  @override
  State<StudyTimerPage> createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage> with TickerProviderStateMixin {
  static const int _studyMins = 25;
  static const int _breakMins = 5;

  int _secondsLeft = _studyMins * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _sessionsCompleted = 0;
  int _totalStudyMins = 0;
  Timer? _timer;
  late AnimationController _ringCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;

  final _quotes = [
    'Darling, focus! I\'m watching over you~ 💕',
    'You\'re doing great! Keep going, my love~ 🌸',
    'Take a break and I\'ll be right here~ ☕',
    'Study hard! I believe in you, Darling~ ✨',
    'Almost there! Don\'t give up now~ 💪',
  ];
  int _quoteIdx = 0;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: _studyMins * 60));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _loadStats();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<void> _loadStats() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(_uid).collection('studySessions').doc('stats').get();
      if (snap.exists && mounted) {
        setState(() {
          _sessionsCompleted = (snap['sessionsCompleted'] as int?) ?? 0;
          _totalStudyMins = (snap['totalStudyMins'] as int?) ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveStats() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).collection('studySessions').doc('stats').set({
        'sessionsCompleted': _sessionsCompleted,
        'totalStudyMins': _totalStudyMins,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _toggle() {
    if (_isRunning) {
      _timer?.cancel();
      _ringCtrl.stop();
      setState(() { _isRunning = false; });
    } else {
      setState(() { _isRunning = true; _quoteIdx = Random().nextInt(_quotes.length); });
      _ringCtrl.forward(from: _ringCtrl.value);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft <= 0) {
          _onPhaseEnd();
        } else {
          setState(() => _secondsLeft--);
        }
      });
    }
  }

  void _onPhaseEnd() {
    _timer?.cancel();
    setState(() { _isRunning = false; });
    if (!_isBreak) {
      _sessionsCompleted++;
      _totalStudyMins += _studyMins;
      _saveStats();
      setState(() { _isBreak = true; _secondsLeft = _breakMins * 60; });
      _ringCtrl.duration = const Duration(seconds: _breakMins * 60);
      _ringCtrl.reset();
    } else {
      setState(() { _isBreak = false; _secondsLeft = _studyMins * 60; });
      _ringCtrl.duration = const Duration(seconds: _studyMins * 60);
      _ringCtrl.reset();
    }
    _quoteIdx = Random().nextInt(_quotes.length);
  }

  void _reset() {
    _timer?.cancel();
    _ringCtrl.reset();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _secondsLeft = _studyMins * 60;
    });
  }

  String get _timeStr {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = (_isBreak ? _breakMins : _studyMins) * 60;
    final progress = 1.0 - _secondsLeft / total;
    final accent = _isBreak ? Colors.greenAccent : Colors.pinkAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20), onPressed: () { _timer?.cancel(); Navigator.pop(context); }),
            const Spacer(),
            Text('📚 Study With Me', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            const SizedBox(width: 44),
          ]),
        ),
        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _statChip('Sessions', '$_sessionsCompleted', Colors.pinkAccent),
            const SizedBox(width: 12),
            _statChip('Total', '${_totalStudyMins}m', Colors.cyanAccent),
          ]),
        ),
        // Mode chip
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Text(_isBreak ? '☕ Break Time' : '📖 Study Time',
              style: GoogleFonts.outfit(color: accent, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        // Ring timer
        AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -8 * _floatCtrl.value),
            child: child,
          ),
          child: SizedBox(
            width: 220, height: 220,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 220, height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  valueColor: AlwaysStoppedAnimation(accent),
                  strokeCap: StrokeCap.round,
                ),
              ),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 170, height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: _isRunning ? 0.06 + 0.04 * _pulseCtrl.value : 0.04),
                    boxShadow: _isRunning ? [BoxShadow(color: accent.withValues(alpha: 0.3 * _pulseCtrl.value), blurRadius: 40, spreadRadius: 5)] : null,
                  ),
                ),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_timeStr, style: GoogleFonts.outfit(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: -2)),
                Text(_isBreak ? 'rest' : 'focus', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13, letterSpacing: 2)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        // Quote
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(_quotes[_quoteIdx], key: ValueKey(_quoteIdx), textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic)),
          ),
        ),
        const Spacer(),
        // Controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 22),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _isRunning ? [Colors.orange, Colors.red] : [Colors.pinkAccent, Colors.deepPurple]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: (_isRunning ? Colors.orange : Colors.pinkAccent).withValues(alpha: 0.5), blurRadius: 24, spreadRadius: 2)],
              ),
              child: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _onPhaseEnd,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.skip_next_rounded, color: Colors.white54, size: 22),
            ),
          ),
        ]),
        const SizedBox(height: 32),
      ])),
    );
  }

  Widget _statChip(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Column(children: [
      Text(value, style: GoogleFonts.outfit(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10)),
    ]),
  );
}
