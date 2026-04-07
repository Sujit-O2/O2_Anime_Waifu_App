import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated splash screen with logo reveal effect.
/// Shows animated logo that fades in + scales up with particle burst,
/// then navigates to main app after delay.
class AnimatedSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const AnimatedSplashScreen({super.key, required this.nextScreen});
  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textSlide;
  late List<_SplashParticle> _particles;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    // Immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Logo animation
    _logoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)));

    // Particle burst
    _particleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000));
    _particles = List.generate(30, (_) => _SplashParticle(
      angle: _rng.nextDouble() * 2 * pi,
      speed: 50 + _rng.nextDouble() * 150,
      size: 4 + _rng.nextDouble() * 8,
      color: [
        Colors.pinkAccent, Colors.purpleAccent, Colors.cyanAccent,
        Colors.amber, Colors.deepPurple,
      ][_rng.nextInt(5)],
    ));

    // Start animations
    _logoCtrl.forward();
    // Haptic feedback on logo reveal
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _particleCtrl.forward();
      // Sound + haptic on particle burst
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    });

    // Navigate after splash
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.pushReplacement(context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _particleCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.deepPurple.withValues(alpha: 0.15),
                  const Color(0xFF0A0A0A),
                ],
              ),
            ),
          ),

          // Particle burst animation
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _SplashParticlePainter(
                particles: _particles,
                progress: _particleCtrl.value,
                center: Offset(
                  MediaQuery.of(context).size.width / 2,
                  MediaQuery.of(context).size.height / 2,
                ),
              ),
            ),
          ),

          // Logo + text
          Center(
            child: AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App logo
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.pinkAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.5),
                              blurRadius: 30, spreadRadius: 5),
                          ],
                        ),
                        child: const Center(
                          child: Text('🌸', style: TextStyle(fontSize: 48)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // App title
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.pinkAccent, Colors.deepPurple, Colors.cyanAccent],
                          ).createShader(bounds),
                          child: const Text('Anime Waifu',
                            style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 2)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Text('Your Ultimate Companion ✨',
                          style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14,
                            fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  _SplashParticle({required this.angle, required this.speed,
    required this.size, required this.color});
}

class _SplashParticlePainter extends CustomPainter {
  final List<_SplashParticle> particles;
  final double progress;
  final Offset center;

  _SplashParticlePainter({required this.particles,
    required this.progress, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dist = p.speed * progress;
      final x = center.dx + cos(p.angle) * dist;
      final y = center.dy + sin(p.angle) * dist;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
