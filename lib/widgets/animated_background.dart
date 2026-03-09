import 'dart:math' as math;
import 'dart:ui';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/main.dart'
    show themeNotifier, customBackgroundUrlNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Particle {
  double x, y, vx, vy, radius, speed, theta;
  double opacity;
  final ParticleType type;

  static final _random = math.Random();

  Particle(Size size, this.type)
      : x = _random.nextDouble() * size.width,
        y = _random.nextDouble() * size.height,
        vx = 0,
        vy = 0,
        radius = _random.nextDouble() * 2.5 + 0.5,
        speed = _random.nextDouble() * 0.4 + 0.1,
        theta = _random.nextDouble() * 2 * math.pi,
        opacity = _random.nextDouble() * 0.5 + 0.1;

  void update(Size size, Offset? interactionPoint) {
    theta += 0.002;

    // Natural movement
    double targetVx = math.cos(theta) * speed;
    double targetVy = math.sin(theta) * speed;

    // Type-specific physics
    switch (type) {
      case ParticleType.snow:
        targetVy = speed * 1.5; // Falling
        targetVx = math.cos(theta) * speed * 0.5; // Swaying
        break;
      case ParticleType.rain:
        targetVy = 8.0; // Fast falling
        targetVx = 0.5; // Wind
        break;
      case ParticleType.embers:
        targetVy = -speed * 2.0; // Rising
        targetVx = math.cos(theta) * speed * 0.8; // Swaying
        opacity =
            0.35 + 0.25 * (0.5 + 0.5 * math.sin(theta * 4.0)); // Flickering
        break;
      case ParticleType.stars:
        targetVx = 0;
        targetVy = 0; // Fixed
        opacity = 0.2 + 0.6 * (0.5 + 0.5 * math.sin(theta * 5)); // Twinkling
        break;
      case ParticleType.bubbles:
        targetVy = -speed * 1.2;
        targetVx = math.cos(theta * 2) * speed * 0.3;
        break;
      default:
        break;
    }

    // Interaction physics (Repulsion)
    if (interactionPoint != null) {
      double dx = x - interactionPoint.dx;
      double dy = y - interactionPoint.dy;
      double distSq = dx * dx + dy * dy;
      double dist = math.sqrt(distSq);

      if (dist < 100) {
        double force = (100 - dist) / 100;
        vx += (dx / dist) * force * 2.5;
        vy += (dy / dist) * force * 2.5;
      }
    }

    // Velocity smoothing / Friction
    vx = lerpDouble(vx, targetVx, 0.05)!;
    vy = lerpDouble(vy, targetVy, 0.05)!;

    x += vx;
    y += vy;

    if (x < 0) x = size.width;
    if (x > size.width) x = 0;
    if (y < 0) y = size.height;
    if (y > size.height) y = 0;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color themeColor;
  final ParticleType type;

  static Path? _sakuraPathCache;

  ParticlePainter(
      this.particles, this.animationValue, this.themeColor, this.type);

  void _drawSakura(Canvas canvas, double x, double y, double r, Paint paint) {
    if (_sakuraPathCache == null) {
      final path = Path();
      path.moveTo(0, -1.5);
      path.cubicTo(1.2, -1.5, 1, 1, 0, 2);
      path.cubicTo(-1, 1, -1.2, -1.5, 0, -1.5);
      path.close();
      _sakuraPathCache = path;
    }
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(r);
    canvas.drawPath(_sakuraPathCache!, paint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = themeColor.withValues(alpha: p.opacity);

      switch (type) {
        case ParticleType.circles:
          canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
          break;
        case ParticleType.squares:
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset(p.x, p.y),
                  width: p.radius * 2,
                  height: p.radius * 2),
              paint);
          break;
        case ParticleType.lines:
          canvas.drawLine(
              Offset(p.x, p.y),
              Offset(p.x + p.radius * 2, p.y + p.radius * 2),
              paint..strokeWidth = 1.0);
          break;
        case ParticleType.sakura:
          _drawSakura(canvas, p.x, p.y, p.radius, paint);
          break;
        case ParticleType.embers:
          final r = p.radius;
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset(p.x, p.y), width: r * 1.5, height: r * 1.5),
              paint);
          break;
        case ParticleType.bubbles:
          canvas.drawCircle(
              Offset(p.x, p.y),
              p.radius,
              paint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.5);
          break;
        case ParticleType.leaves:
          final r = p.radius;
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(p.x, p.y), width: r * 2.5, height: r * 1.2),
              paint);
          break;
        case ParticleType.snow:
          canvas.drawCircle(Offset(p.x, p.y), p.radius * 0.8, paint);
          break;
        case ParticleType.stars:
          final r = p.radius * (0.8 + 0.4 * math.sin(animationValue * 10));
          canvas.drawCircle(Offset(p.x, p.y), r, paint);
          break;
        case ParticleType.rain:
          canvas.drawLine(Offset(p.x, p.y), Offset(p.x, p.y + 10),
              paint..strokeWidth = 0.5);
          break;
      }

      // Subtle glow
      paint.style = PaintingStyle.fill;
      paint.color = themeColor.withValues(alpha: p.opacity * 0.2);
      if (type == ParticleType.sakura || type == ParticleType.embers) {
        canvas.drawCircle(Offset(p.x, p.y), p.radius * 3, paint);
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.radius * 2.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedBackground extends StatefulWidget {
  final ScrollController? controller;
  const AnimatedBackground({super.key, this.controller});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  Offset? interactionPoint;
  AppThemeMode? _lastMode;

  int _particleCountForTheme(AppThemeMode mode) {
    switch (AppThemes.getParticleType(mode)) {
      case ParticleType.rain:
      case ParticleType.snow:
        return 18;
      case ParticleType.stars:
      case ParticleType.bubbles:
        return 20;
      default:
        return 24;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    widget.controller?.addListener(_onScroll);
    particles = [];
  }

  void _onScroll() {
    if (widget.controller == null || !widget.controller!.hasClients) return;
    final speed = widget.controller!.position.userScrollDirection ==
            ScrollDirection.reverse
        ? -1.2
        : 1.2;
    for (var p in particles) {
      p.vy += speed * (p.radius / 2.0);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<AppThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, _) {
            final pType = AppThemes.getParticleType(mode);
            if (_lastMode == null || _lastMode != mode || particles.isEmpty) {
              _lastMode = mode;
              final count = _particleCountForTheme(mode);
              particles = List.generate(
                count,
                (_) => Particle(
                    Size(constraints.maxWidth, constraints.maxHeight), pType),
              );
            }
            final theme = AppThemes.getTheme(mode);
            final primary = theme.primaryColor;

            return GestureDetector(
              onPanUpdate: (details) {
                setState(() => interactionPoint = details.localPosition);
              },
              onPanEnd: (_) => setState(() => interactionPoint = null),
              child: Stack(
                children: [
                  // LAYER 1: Deep cinematic gradient base OR Custom Image Pack (STATIC, OUTSIDE ANIMATION LOOP)
                  const Positioned.fill(
                    child: RepaintBoundary(child: _StaticBackgroundLayer()),
                  ),

                  // LAYER 2: Particles on top (ONLY layer that rebuilds 60fps)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          for (var p in particles) {
                            p.update(
                                Size(constraints.maxWidth,
                                    constraints.maxHeight),
                                interactionPoint);
                          }

                          return CustomPaint(
                            painter: ParticlePainter(
                                particles, _controller.value, primary, pType),
                            size: Size.infinite,
                            isComplex: false,
                            willChange: true,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StaticBackgroundLayer extends StatelessWidget {
  const _StaticBackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final gradientColors = AppThemes.getGradient(mode);
        return ValueListenableBuilder<String?>(
          valueListenable: customBackgroundUrlNotifier,
          builder: (context, bgUrl, _) {
            if (bgUrl != null && bgUrl.isNotEmpty) {
              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: bgUrl.startsWith('http')
                    ? Image.network(bgUrl, fit: BoxFit.cover)
                    : bgUrl.startsWith('assets/')
                        ? Image.asset(bgUrl, fit: BoxFit.cover)
                        : Image.network(
                            bgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.asset(
                              'assets/zero_two_dance.gif',
                              fit: BoxFit.cover,
                            ),
                          ),
              );
            }

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Removed _CrepuscularPainter to save CPU payload.
