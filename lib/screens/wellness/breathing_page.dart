import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/config/app_themes.dart';
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

    if (!mounted) return;
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

    if (!mounted) return;
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

    if (!mounted) return;
    setState(() => _cyclesLeft--);

    if (_cyclesLeft > 0) {
      await _startCycle();
    } else {
      if (!mounted) return;
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
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: tokens.textSoft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.air_rounded,
                  color: Colors.lightBlueAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Text('MINDFUL BREATHING',
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5,
                )),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.lightBlueAccent.withValues(alpha: 0.08),
                    Colors.cyanAccent.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.lightBlueAccent.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightBlueAccent.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.spa_rounded,
                        color: Colors.lightBlueAccent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: Colors.lightBlueAccent, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '4-7-8 BREATHING',
                              style: GoogleFonts.outfit(
                                color: tokens.textSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _running
                              ? 'Breathing cycle in progress'
                              : 'Start a guided calming session',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Five guided cycles with a simple 4 second inhale, 7 second hold, and 8 second exhale.',
                          style: GoogleFonts.outfit(
                            color: tokens.textSoft,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _phaseColor.withValues(alpha: 0.2),
                          _phaseColor.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                        color: _phaseColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.spa_rounded, color: _phaseColor, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '${5 - _cyclesLeft}',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Done',
                          style: GoogleFonts.outfit(
                            color: tokens.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPremiumStatCard(
                    'Cycles Left',
                    '$_cyclesLeft',
                    Icons.repeat_rounded,
                    Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPremiumStatCard(
                    'Phase',
                    _phase,
                    Icons.access_time_rounded,
                    _phaseColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pinkAccent.withValues(alpha: 0.08),
                    Colors.purpleAccent.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: V2Theme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
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

  Widget _buildPremiumStatCard(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: tokens.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
