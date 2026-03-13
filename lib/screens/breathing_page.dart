import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BreathingExercisePage extends StatefulWidget {
  const BreathingExercisePage({super.key});

  @override
  State<BreathingExercisePage> createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<BreathingExercisePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _expand;

  bool _running = false;
  int _cyclesLeft = 5;
  String _phase = 'Ready';
  String _instruction = 'Tap to start';
  Color _phaseColor = Colors.pinkAccent;

  // 4-7-8 breathing pattern (in seconds)
  static const _inhale = 4;
  static const _hold = 7;
  static const _exhale = 8;

  // Waifu messages
  static const _messages = [
    "Breathe with me, Darling~ I'm right here 💕",
    "In through your nose… gently~ 🌸",
    "Let it go, Darling. You're safe with me ✨",
    "You're doing amazing, close your eyes if you want 💖",
    "Every breath makes you calmer~ 🌺",
  ];

  String get _waifuMsg => _messages[DateTime.now().second % _messages.length];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: _inhale + _hold + _exhale));
    _expand = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _startCycle() async {
    if (_cyclesLeft <= 0) {
      setState(() {
        _cyclesLeft = 5;
        _phase = 'Ready';
        _instruction = 'Tap to start';
        _running = false;
      });
      return;
    }

    setState(() => _running = true);

    // INHALE (4s)
    setState(() {
      _phase = 'INHALE';
      _instruction = 'Breathe in slowly through your nose…';
      _phaseColor = Colors.cyanAccent;
    });
    _ctrl.duration = const Duration(seconds: _inhale);
    await _ctrl.forward(from: 0);
    if (!mounted) return;

    // HOLD (7s)
    setState(() {
      _phase = 'HOLD';
      _instruction = 'Hold your breath…';
      _phaseColor = Colors.pinkAccent;
    });
    _ctrl.duration = const Duration(seconds: _hold);
    _ctrl.stop();
    await Future.delayed(const Duration(seconds: _hold));
    if (!mounted) return;

    // EXHALE (8s)
    setState(() {
      _phase = 'EXHALE';
      _instruction = 'Breathe out slowly through your mouth…';
      _phaseColor = Colors.deepPurpleAccent;
    });
    _ctrl.duration = const Duration(seconds: _exhale);
    await _ctrl.reverse();
    if (!mounted) return;

    setState(() => _cyclesLeft--);

    if (_cyclesLeft > 0) {
      await _startCycle();
    } else {
      setState(() {
        _phase = '🌸 Complete!';
        _instruction = 'Well done, Darling. You\'re so calm now~';
        _phaseColor = Colors.greenAccent;
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('BREATHING',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Waifu message
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _phaseColor.withValues(alpha: 0.08),
              border: Border.all(color: _phaseColor.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Text('🌸', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(_waifuMsg,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 12))),
            ]),
          ),
        ),

        Expanded(
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Technique label
              Text('4 - 7 - 8 Breathing',
                  style: GoogleFonts.outfit(
                      color: Colors.white38, fontSize: 13, letterSpacing: 1)),
              const SizedBox(height: 32),

              // Animated circle
              GestureDetector(
                onTap: _running ? null : _startCycle,
                child: Stack(alignment: Alignment.center, children: [
                  // Outer glow rings
                  ...List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _expand,
                      builder: (_, __) => Container(
                        width: 160 + (i * 30) + (_expand.value * 40),
                        height: 160 + (i * 30) + (_expand.value * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _phaseColor.withValues(alpha: 0.04 - (i * 0.01)),
                        ),
                      ),
                    );
                  }),

                  // Main circle
                  AnimatedBuilder(
                    animation: _expand,
                    builder: (_, __) => Container(
                      width: 150 + (_expand.value * 40),
                      height: 150 + (_expand.value * 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          _phaseColor.withValues(alpha: 0.4),
                          _phaseColor.withValues(alpha: 0.1),
                        ]),
                        border: Border.all(
                            color: _phaseColor.withValues(alpha: 0.6),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _phaseColor.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_phase,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                )),
                            if (!_running)
                              Text('Tap to start',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white54, fontSize: 11)),
                          ]),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 32),
              Text(_instruction,
                  style:
                      GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),

              // Cycles remaining
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      5,
                      (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _cyclesLeft
                                  ? _phaseColor
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ))),
              const SizedBox(height: 8),
              Text('$_cyclesLeft cycles remaining',
                  style:
                      GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }
}
