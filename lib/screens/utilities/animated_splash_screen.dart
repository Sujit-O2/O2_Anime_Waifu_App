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
              size: MediaQuery.sizeOf(context),
              painter: _SplashParticlePainter(
                particles: _particles,
                progress: _particleCtrl.value,
                center: Offset(
                  MediaQuery.sizeOf(context).width / 2,
                  MediaQuery.sizeOf(context).height / 2,
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
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: V2Theme.primaryColor.withValues(alpha: 0.55),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00D1FF).withValues(alpha: 0.25),
                              blurRadius: 60,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/gif/add_incircular_mode_app_oppening style.gif',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.favorite_rounded,
                                  color: Colors.white, size: 64),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) =>
                              V2Theme.primaryGradient.createShader(bounds),
                          child: const Text(
                            'O2-WAIFU',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Text(
                          'Neural Companion Framework',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Loading indicator at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Opacity(
                opacity: (_logoCtrl.value * 1.5).clamp(0.0, 0.7),
                child: Column(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        'assets/gif/add_incircular_mode_app_oppening style.gif',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => CircularProgressIndicator(
                          strokeWidth: 2,
                          color: V2Theme.primaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'INITIALIZING NEURAL CORE...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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



