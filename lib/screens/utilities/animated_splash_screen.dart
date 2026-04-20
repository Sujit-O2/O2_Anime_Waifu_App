import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({
    super.key,
    required this.nextScreen,
  });

  final Widget nextScreen;

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _particles = List<_SplashParticle>.generate(
      30,
      (_) => _SplashParticle(
        angle: _rng.nextDouble() * 2 * pi,
        speed: 50 + _rng.nextDouble() * 150,
        size: 4 + _rng.nextDouble() * 8,
        color: <Color>[
          V2Theme.primaryColor,
          V2Theme.secondaryColor,
          V2Theme.accentColor,
          Colors.white,
          const Color(0xFF6C63FF),
        ][_rng.nextInt(5)],
      ),
    );

    _logoCtrl.forward();
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _particleCtrl.forward();
      }
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    });

    Future<void>.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) {
        return;
      }
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.pushReplacement(
        context,
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
      backgroundColor: V2Theme.surfaceDark,
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: <Color>[
                  V2Theme.primaryColor.withValues(alpha: 0.18),
                  V2Theme.surfaceDark,
                ],
              ),
            ),
          ),
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
          Center(
            child: AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: V2Theme.primaryGradient,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: V2Theme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) =>
                              V2Theme.primaryGradient.createShader(bounds),
                          child: const Text(
                            'Anime Waifu',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Text(
                          'Your companion in every arc',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
  const _SplashParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });

  final double angle;
  final double speed;
  final double size;
  final Color color;
}

class _SplashParticlePainter extends CustomPainter {
  _SplashParticlePainter({
    required this.particles,
    required this.progress,
    required this.center,
  });

  final List<_SplashParticle> particles;
  final double progress;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _SplashParticle particle in particles) {
      final double dist = particle.speed * progress;
      final double x = center.dx + cos(particle.angle) * dist;
      final double y = center.dy + sin(particle.angle) * dist;
      final double opacity = (1.0 - progress).clamp(0.0, 1.0);
      final Paint paint = Paint()
        ..color = particle.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



