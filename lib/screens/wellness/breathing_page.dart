import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Color _phaseColor = V2Theme.primaryColor;

  static const int _inhale = 4;
  static const int _hold = 7;
  static const int _exhale = 8;

  static const List<String> _messages = <String>[
    'Breathe with me. I am right here with you.',
    'In through your nose, slowly and steadily.',
    'Let the tension go on the exhale.',
    'You are doing well. Keep the pace gentle.',
    'Every cycle is helping your body settle down.',
  ];

  String get _waifuMsg => _messages[DateTime.now().second % _messages.length];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _inhale + _hold + _exhale),
    );
    _expand = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
        _phaseColor = V2Theme.primaryColor;
      });
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _running = true);

    setState(() {
      _phase = 'Inhale';
      _instruction = 'Breathe in slowly through your nose.';
      _phaseColor = V2Theme.secondaryColor;
    });
    _ctrl.duration = const Duration(seconds: _inhale);
    await _ctrl.forward(from: 0);
    if (!mounted) {
      return;
    }

    setState(() {
      _phase = 'Hold';
      _instruction = 'Hold the breath and keep your shoulders relaxed.';
      _phaseColor = V2Theme.primaryColor;
    });
    _ctrl.stop();
    await Future.delayed(const Duration(seconds: _hold));
    if (!mounted) {
      return;
    }

    setState(() {
      _phase = 'Exhale';
      _instruction = 'Exhale slowly and let the circle shrink.';
      _phaseColor = Colors.deepPurpleAccent;
    });
    _ctrl.duration = const Duration(seconds: _exhale);
    await _ctrl.reverse();
    if (!mounted) {
      return;
    }

    setState(() => _cyclesLeft--);

    if (_cyclesLeft > 0) {
      await _startCycle();
    } else {
      setState(() {
        _phase = 'Complete';
        _instruction = 'Well done. Your body should feel calmer now.';
        _phaseColor = Colors.lightGreenAccent;
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BREATHING',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: WaifuBackground(
        opacity: 0.08,
        tint: const Color(0xFF0A0A14),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            GlassCard(
              margin: EdgeInsets.zero,
              glow: true,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '4-7-8 reset',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _running
                              ? 'Breathing cycle in progress'
                              : 'Start a guided calming session',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Five guided cycles with a simple 4 second inhale, 7 second hold, and 8 second exhale.',
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ProgressRing(
                    progress: (5 - _cyclesLeft).clamp(0, 5) / 5,
                    foreground: _phaseColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.spa_rounded, color: _phaseColor, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          '${5 - _cyclesLeft}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Done',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Cycles Left',
                    value: '$_cyclesLeft',
                    icon: Icons.repeat_rounded,
                    color: V2Theme.primaryColor,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Phase',
                    value: _phase,
                    icon: Icons.timelapse_rounded,
                    color: V2Theme.secondaryColor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Inhale',
                    value: '${_inhale}s',
                    icon: Icons.north_rounded,
                    color: Colors.lightGreenAccent,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Exhale',
                    value: '${_exhale}s',
                    icon: Icons.south_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  const Icon(Icons.favorite_border_rounded,
                      color: V2Theme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _waifuMsg,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    '4 - 7 - 8 Breathing',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _running ? null : _startCycle,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (i) {
                          return AnimatedBuilder(
                            animation: _expand,
                            builder: (_, __) => Container(
                              width: 160 + (i * 30) + (_expand.value * 40),
                              height: 160 + (i * 30) + (_expand.value * 40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _phaseColor.withValues(
                                    alpha: 0.04 - (i * 0.01)),
                              ),
                            ),
                          );
                        }),
                        AnimatedBuilder(
                          animation: _expand,
                          builder: (_, __) => Container(
                            width: 150 + (_expand.value * 40),
                            height: 150 + (_expand.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _phaseColor.withValues(alpha: 0.4),
                                  _phaseColor.withValues(alpha: 0.1),
                                ],
                              ),
                              border: Border.all(
                                color: _phaseColor.withValues(alpha: 0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _phaseColor.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _phase,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                if (!_running)
                                  Text(
                                    'Tap to start',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _instruction,
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_cyclesLeft cycles remaining',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



