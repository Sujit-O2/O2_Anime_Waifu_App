import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/config/optimized_performance.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// OPTIMIZED ANIMATED BACKGROUND — 60 FPS Performance
/// ═══════════════════════════════════════════════════════════════════════════

class OptimizedAnimatedBackground extends StatefulWidget {
  final Widget child;
  final AppThemeMode themeMode;
  final bool enableParticles;

  const OptimizedAnimatedBackground({
    super.key,
    required this.child,
    required this.themeMode,
    this.enableParticles = true,
  });

  @override
  State<OptimizedAnimatedBackground> createState() =>
      _OptimizedAnimatedBackgroundState();
}

class _OptimizedAnimatedBackgroundState
    extends State<OptimizedAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _initializeParticles();
  }

  void _initializeParticles() {
    final particleCount =
        PerformanceConfig.getAdaptiveParticleCount(context);
    final particleType = AppThemes.getParticleType(widget.themeMode);

    _particles = List.generate(
      particleCount,
      (index) => Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 2,
        speed: _random.nextDouble() * 0.5 + 0.3,
        opacity: _random.nextDouble() * 0.4 + 0.2,
        type: particleType,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppThemes.getGradient(widget.themeMode),
              ),
            ),
          ),
        ),

        // Particles (if enabled)
        if (widget.enableParticles && PerformanceConfig.enableParticles)
          Positioned.fill(
            child: OptimizedRepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: ParticlePainter(
                      particles: _particles,
                      progress: _controller.value,
                      themeMode: widget.themeMode,
                    ),
                  );
                },
              ),
            ),
          ),

        // Content
        widget.child,
      ],
    );
  }
}

/// Particle data class
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final ParticleType type;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.type,
  });
}

/// Optimized particle painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final AppThemeMode themeMode;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.themeMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final theme = AppThemes.getRawTheme(themeMode);
    final primaryColor = theme.colorScheme.primary;

    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = ((particle.y + progress * particle.speed) % 1.0) * size.height;

      final paint = Paint()
        ..color = primaryColor.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      switch (particle.type) {
        case ParticleType.circles:
          canvas.drawCircle(
            Offset(x, y),
            particle.size,
            paint,
          );
          break;

        case ParticleType.squares:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(x, y),
              width: particle.size * 2,
              height: particle.size * 2,
            ),
            paint,
          );
          break;

        case ParticleType.lines:
          paint.strokeWidth = particle.size * 0.5;
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(x, y),
            Offset(x, y + particle.size * 4),
            paint,
          );
          break;

        case ParticleType.stars:
          _drawStar(canvas, Offset(x, y), particle.size, paint);
          break;

        case ParticleType.sakura:
          _drawSakura(canvas, Offset(x, y), particle.size, paint);
          break;

        case ParticleType.embers:
          paint.color = Colors.orange.withValues(alpha: particle.opacity);
          canvas.drawCircle(Offset(x, y), particle.size, paint);
          // Glow effect
          paint.color = Colors.orange.withValues(alpha: particle.opacity * 0.3);
          canvas.drawCircle(Offset(x, y), particle.size * 2, paint);
          break;

        case ParticleType.snow:
          paint.color = Colors.white.withValues(alpha: particle.opacity);
          canvas.drawCircle(Offset(x, y), particle.size, paint);
          break;

        case ParticleType.bubbles:
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 1;
          canvas.drawCircle(Offset(x, y), particle.size, paint);
          break;

        case ParticleType.leaves:
          _drawLeaf(canvas, Offset(x, y), particle.size, paint);
          break;

        case ParticleType.rain:
          paint.strokeWidth = particle.size * 0.3;
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(x, y),
            Offset(x - particle.size, y + particle.size * 6),
            paint,
          );
          break;
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 5;

      final outerX = center.dx + outerRadius * math.cos(outerAngle);
      final outerY = center.dy + outerRadius * math.sin(outerAngle);
      final innerX = center.dx + innerRadius * math.cos(innerAngle);
      final innerY = center.dy + innerRadius * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSakura(Canvas canvas, Offset center, double size, Paint paint) {
    paint.color = Colors.pink.withValues(alpha: paint.color.a);
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5);
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      canvas.drawCircle(Offset(x, y), size * 0.5, paint);
    }
    canvas.drawCircle(center, size * 0.3, paint);
  }

  void _drawLeaf(Canvas canvas, Offset center, double size, Paint paint) {
    paint.color = Colors.green.withValues(alpha: paint.color.a);
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(
      center.dx + size,
      center.dy,
      center.dx,
      center.dy + size,
    );
    path.quadraticBezierTo(
      center.dx - size,
      center.dy,
      center.dx,
      center.dy - size,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                tokens.panelMuted,
                tokens.panelElevated,
                tokens.panelMuted,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for lists
class SkeletonLoader extends StatelessWidget {
  final int itemCount;

  const SkeletonLoader({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const ShimmerLoading(width: 50, height: 50, borderRadius: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                      width: MediaQuery.sizeOf(context).width * 0.6,
                      height: 12,
                      borderRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
