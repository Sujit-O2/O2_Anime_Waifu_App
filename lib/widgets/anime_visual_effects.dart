import 'dart:math';
import 'package:flutter/material.dart';

/// 3D Card Tilt — cards subtly tilt in 3D when touched.
/// Wrap any widget to give it a premium interactive look.
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt; // in radians, default ~7 degrees
  final BorderRadius borderRadius;

  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 0.12,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _rotX = 0;
  double _rotY = 0;
  bool _touching = false;

  void _onPanUpdate(DragUpdateDetails d) {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final pos = d.localPosition;

    setState(() {
      _touching = true;
      // Normalize to -1..1 range then multiply by max tilt
      _rotY = ((pos.dx / size.width) - 0.5) * 2 * widget.maxTilt;
      _rotX = -((pos.dy / size.height) - 0.5) * 2 * widget.maxTilt;
    });
  }

  void _onPanEnd(_) => _reset();
  void _onPanCancel() => _reset();

  void _reset() {
    setState(() { _rotX = 0; _rotY = 0; _touching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      child: AnimatedContainer(
        duration: Duration(milliseconds: _touching ? 50 : 300),
        curve: _touching ? Curves.linear : Curves.easeOutBack,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(_rotX)
          ..rotateY(_rotY)
          ..scale(_touching ? 1.03 : 1.0),
        child: widget.child,
      ),
    );
  }
}

/// Floating Sakura / Star particles overlay.
/// Renders particles drifting slowly across the screen.
class ParticleOverlay extends StatefulWidget {
  final int particleCount;
  final Color color;
  final String emoji; // '🌸' for sakura, '✨' for stars
  const ParticleOverlay({
    super.key,
    this.particleCount = 15,
    this.color = Colors.pinkAccent,
    this.emoji = '🌸',
  });
  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) => _randomParticle());
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_tick)
      ..repeat();
  }

  _Particle _randomParticle() => _Particle(
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    speed: 0.0003 + _rng.nextDouble() * 0.0008,
    size: 10 + _rng.nextDouble() * 12,
    drift: (_rng.nextDouble() - 0.5) * 0.0004,
    opacity: 0.3 + _rng.nextDouble() * 0.5,
  );

  void _tick() {
    for (int i = 0; i < _particles.length; i++) {
      _particles[i].y += _particles[i].speed;
      _particles[i].x += _particles[i].drift;
      if (_particles[i].y > 1.1) {
        _particles[i] = _randomParticle();
        _particles[i].y = -0.05;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ParticlePainter(_particles, widget.emoji),
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, speed, size, drift, opacity;
  _Particle({required this.x, required this.y, required this.speed,
    required this.size, required this.drift, required this.opacity});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final String emoji;
  _ParticlePainter(this.particles, this.emoji);

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final p in particles) {
      textPainter.text = TextSpan(
        text: emoji,
        style: TextStyle(fontSize: p.size, 
          color: Colors.white.withValues(alpha: p.opacity)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(p.x * size.width, p.y * size.height));
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true; // particles mutate in-place, must repaint on tick
}

/// Glassmorphic overlay — frosted glass effect for headers and cards.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.15,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Colors.white.withValues(alpha: opacity),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: blur,
              spreadRadius: -5,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
