import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Focus Mode — Productivity booster that detects distraction and helps stay focused.
class FocusModePage extends StatefulWidget {
  const FocusModePage({super.key});
  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends State<FocusModePage> {
  bool _active = false;
  int _minutes = 25;
  int _secondsLeft = 0;
  bool _running = false;

  void _startFocus() {
    setState(() { _active = true; _secondsLeft = _minutes * 60; _running = true; });
    _tick();
  }

  void _tick() {
    if (!_running || _secondsLeft <= 0) { setState(() => _running = false); return; }
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _running) { setState(() => _secondsLeft--); _tick(); }
    });
  }

  String get _timeDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('FOCUS MODE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)), centerTitle: true),
      body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (!_active) ...[
          const Text('🎯', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Focus Mode', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          Text('"Bro focus… put the phone down 😑"', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic)),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [15, 25, 45, 60].map((m) => GestureDetector(
            onTap: () => setState(() => _minutes = m),
            child: Container(margin: const EdgeInsets.symmetric(horizontal: 6), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: (_minutes == m ? Colors.cyanAccent : Colors.white12).withValues(alpha: _minutes == m ? 0.15 : 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: (_minutes == m ? Colors.cyanAccent : Colors.white24).withValues(alpha: 0.5))),
              child: Text('${m}m', style: GoogleFonts.outfit(color: _minutes == m ? Colors.cyanAccent : Colors.white54, fontSize: 14, fontWeight: FontWeight.w700))),
          )).toList()),
          const SizedBox(height: 24),
          GestureDetector(onTap: _startFocus, child: Container(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.3), blurRadius: 16)]),
            child: Text('START FOCUS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)))),
        ] else ...[
          Text(_timeDisplay, style: GoogleFonts.sourceCodePro(color: _secondsLeft < 60 ? Colors.redAccent : Colors.cyanAccent, fontSize: 64, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text(_running ? 'Stay focused, Darling~ 💕' : '✨ Great job! You did it!', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_running) GestureDetector(onTap: () => setState(() => _running = false), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5))), child: Text('STOP', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w700)))),
            if (!_running) GestureDetector(onTap: () => setState(() => _active = false), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5))), child: Text('NEW SESSION', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.w700)))),
          ]),
        ],
      ]))),
    );
  }
}
