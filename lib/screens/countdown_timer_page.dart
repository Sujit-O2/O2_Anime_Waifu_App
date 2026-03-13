import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../widgets/waifu_background.dart';

class CountdownTimerPage extends StatefulWidget {
  const CountdownTimerPage({super.key});
  @override
  State<CountdownTimerPage> createState() => _CountdownTimerPageState();
}

class _CountdownTimerPageState extends State<CountdownTimerPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _totalSeconds = 0;
  int _remaining = 0;
  bool _running = false;
  bool _done = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _presets = [
    {'label': '5 min', 'seconds': 300},
    {'label': '10 min', 'seconds': 600},
    {'label': '15 min', 'seconds': 900},
    {'label': '25 min', 'seconds': 1500},
    {'label': '30 min', 'seconds': 1800},
    {'label': '1 hour', 'seconds': 3600},
    {'label': 'Zero Time', 'seconds': 720}, // 12 min (02)
    {'label': 'Darling Time', 'seconds': 180}, // 3 min
  ];

  int _hours = 0, _minutes = 5, _seconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _remaining = _hours * 60 + _seconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _start() {
    _totalSeconds = _hours * 3600 + _minutes * 60 + _seconds;
    if (_totalSeconds <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _remaining = _totalSeconds;
      _running = true;
      _done = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _remaining = 0;
          _running = false;
          _done = true;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _resume() {
    if (_remaining <= 0) return;
    setState(() {
      _running = true;
      _done = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _remaining = 0;
          _running = false;
          _done = true;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = 0;
      _running = false;
      _done = false;
    });
  }

  void _applyPreset(int secs) {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _hours = secs ~/ 3600;
      _minutes = (secs % 3600) ~/ 60;
      _seconds = secs % 60;
      _remaining = 0;
      _running = false;
      _done = false;
    });
  }

  String _fmt(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _totalSeconds > 0 ? _remaining / _totalSeconds : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF08080E),
        child: SafeArea(
            child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  _timer?.cancel();
                  Navigator.pop(context);
                },
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12)),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white60, size: 16)),
              ),
              const SizedBox(width: 12),
              Text('COUNTDOWN TIMER',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ]),
          ),

          const SizedBox(height: 16),

          // Timer display
          Expanded(
            child: Column(children: [
              // Clock
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (ctx, _) => Transform.scale(
                  scale: _running ? _pulseAnim.value : 1.0,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(
                          color: (_done ? Colors.pinkAccent : Colors.cyanAccent)
                              .withOpacity(0.4),
                          width: 2),
                    ),
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: CircularProgressIndicator(
                          value: _running || _remaining > 0 ? _progress : 1.0,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation(
                              _done ? Colors.pinkAccent : Colors.cyanAccent),
                          strokeWidth: 6,
                        ),
                      ),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                _running || _remaining > 0
                                    ? _fmt(_remaining)
                                    : _fmt(_hours * 3600 +
                                        _minutes * 60 +
                                        _seconds),
                                style: GoogleFonts.outfit(
                                    color: _done
                                        ? Colors.pinkAccent
                                        : Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900)),
                            if (_done)
                              Text('Time\'s up, Darling! 💕',
                                  style: GoogleFonts.outfit(
                                      color: Colors.pinkAccent, fontSize: 12)),
                          ]),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Time pickers (only when not running)
              if (!_running && _remaining == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _picker(
                            'H', _hours, 23, (v) => setState(() => _hours = v)),
                        Text(':',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 28)),
                        _picker('M', _minutes, 59,
                            (v) => setState(() => _minutes = v)),
                        Text(':',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 28)),
                        _picker('S', _seconds, 59,
                            (v) => setState(() => _seconds = v)),
                      ]),
                ),

              const SizedBox(height: 12),

              // Control buttons
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (!_running && _remaining > 0)
                  _ctrlBtn(
                      Icons.play_arrow_rounded, Colors.greenAccent, _resume),
                if (_running)
                  _ctrlBtn(Icons.pause_rounded, Colors.amberAccent, _pause),
                if (!_running && _remaining == 0)
                  _ctrlBtn(
                      Icons.play_arrow_rounded, Colors.greenAccent, _start),
                const SizedBox(width: 16),
                _ctrlBtn(Icons.stop_rounded, Colors.redAccent, _reset),
              ]),

              const SizedBox(height: 16),

              // Presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                    children: _presets
                        .map((p) => GestureDetector(
                              onTap: () => _applyPreset(p['seconds'] as int),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.cyanAccent.withOpacity(0.08),
                                  border: Border.all(
                                      color:
                                          Colors.cyanAccent.withOpacity(0.25)),
                                ),
                                child: Text(p['label'] as String,
                                    style: GoogleFonts.outfit(
                                        color: Colors.cyanAccent,
                                        fontSize: 12)),
                              ),
                            ))
                        .toList()),
              ),
            ]),
          ),
        ])),
      ),
    );
  }

  Widget _picker(String label, int val, int max, void Function(int) onChange) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
              onTap: () => onChange((val + 1) % (max + 1)),
              child: const Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white38)),
          Text(val.toString().padLeft(2, '0'),
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900)),
          GestureDetector(
              onTap: () => onChange(val == 0 ? max : val - 1),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white38)),
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
        ],
      );

  Widget _ctrlBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.4))),
          child: Icon(icon, color: color, size: 28),
        ),
      );
}
