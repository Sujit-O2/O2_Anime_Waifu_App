import 'dart:math' as math;
import 'dart:ui';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/main.dart' show themeNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Particle {
  double x, y, vx, vy, radius, speed, theta;
  double opacity;
  final ParticleType type;

  Particle(Size size, this.type)
      : x = math.Random().nextDouble() * size.width,
        y = math.Random().nextDouble() * size.height,
        vx = 0,
        vy = 0,
        radius = math.Random().nextDouble() * 2.5 + 0.5,
        speed = math.Random().nextDouble() * 0.4 + 0.1,
        theta = math.Random().nextDouble() * 2 * math.pi,
        opacity = math.Random().nextDouble() * 0.5 + 0.1;

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
        opacity = 0.3 + 0.5 * math.Random().nextDouble(); // Flickering
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

  ParticlePainter(
      this.particles, this.animationValue, this.themeColor, this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = themeColor.withOpacity(p.opacity);

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
          // Premium Sakura petal shape
          final path = Path();
          final r = p.radius;
          path.moveTo(p.x, p.y - r * 1.5);
          path.cubicTo(
              p.x + r * 1.2, p.y - r * 1.5, p.x + r, p.y + r, p.x, p.y + r * 2);
          path.cubicTo(p.x - r, p.y + r, p.x - r * 1.2, p.y - r * 1.5, p.x,
              p.y - r * 1.5);
          path.close();
          canvas.drawPath(path, paint);
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
      paint.color = themeColor.withOpacity(p.opacity * 0.2);
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
              particles = List.generate(
                60,
                (_) => Particle(
                    Size(constraints.maxWidth, constraints.maxHeight), pType),
              );
            }
            final theme = AppThemes.getTheme(mode);
            final primary = theme.primaryColor;
            final accent = theme.colorScheme.tertiary;
            final gradientColors = AppThemes.getGradient(mode);

            return GestureDetector(
              onPanUpdate: (details) {
                setState(() => interactionPoint = details.localPosition);
              },
              onPanEnd: (_) => setState(() => interactionPoint = null),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  for (var p in particles) {
                    p.update(Size(constraints.maxWidth, constraints.maxHeight),
                        interactionPoint);
                  }

                  final t = _controller.value;
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  return Stack(
                    children: [
                      // LAYER 1: Deep cinematic gradient base (diagonal)
                      Container(
                        width: w,
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                        ),
                      ),

                      // LAYER 2: Crepuscular god-rays — slow rotating beams from above
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CrepuscularPainter(
                            primary: primary,
                            accent: accent,
                            t: (t * 0.014) % 1.0, // full rotation every ~72s
                          ),
                        ),
                      ),

                      // LAYER 3: Particles on top
                      CustomPaint(
                        painter: ParticlePainter(particles, t, primary, pType),
                        size: Size.infinite,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// Cinematic crepuscular god-rays from above screen, slow 72s rotation.
class _CrepuscularPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final double t;

  const _CrepuscularPainter({
    required this.primary,
    required this.accent,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int rayCount = 10;
    final double cx = size.width * 0.5;
    final double cy = -size.height * 0.38;
    final double maxR = size.height * 1.9;
    final double base = t * 2 * math.pi;

    for (int i = 0; i < rayCount; i++) {
      final double angle = base + (i / rayCount) * 2 * math.pi;
      final double hw = (0.025 + 0.018 * math.sin(i * 1.4)) * math.pi;
      final double op = 0.045 + 0.020 * math.sin(i * 0.8 + 1.0);
      final Color c = (i % 3 == 0) ? accent : primary;

      final double p1x = cx + maxR * math.cos(angle - hw);
      final double p1y = cy + maxR * math.sin(angle - hw);
      final double p2x = cx + maxR * math.cos(angle + hw);
      final double p2y = cy + maxR * math.sin(angle + hw);

      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(p1x, p1y)
        ..lineTo(p2x, p2y)
        ..close();

      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.5),
          radius: 1.15,
          colors: [c.withOpacity(op), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CrepuscularPainter o) => true;
}
