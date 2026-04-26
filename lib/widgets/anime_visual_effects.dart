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

  void _onPanEnd(DragEndDetails _) => _reset();
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
/// Animated glowing border that cycles through colors — great for premium cards
class GlowingBorderCard extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final double borderWidth;
  final BorderRadius borderRadius;
  final Duration duration;

  const GlowingBorderCard({
    super.key,
    required this.child,
    this.colors = const [Color(0xFFFF4FA8), Color(0xFFBB52FF), Color(0xFF5FE2FF)],
    this.borderWidth = 1.5,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<GlowingBorderCard> createState() => _GlowingBorderCardState();
}

class _GlowingBorderCardState extends State<GlowingBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        // Shift gradient alignment smoothly
        final begin = Alignment(
          cos(t * 2 * pi) * 1.0,
          sin(t * 2 * pi) * 1.0,
        );
        final end = Alignment(
          cos((t + 0.5) * 2 * pi) * 1.0,
          sin((t + 0.5) * 2 * pi) * 1.0,
        );
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: widget.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first.withValues(alpha: 0.2 + t * 0.15),
                blurRadius: 16,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(widget.borderWidth),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              color: const Color(0xFF0D0D1A),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Breathing dot — a simple pulsing circle used as status indicators
class BreathingDot extends StatefulWidget {
  final Color color;
  final double size;
  
  const BreathingDot({
    super.key,
    this.color = Colors.greenAccent,
    this.size = 8,
  });
  
  @override
  State<BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<BreathingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeInOutSine.transform(_ctrl.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.6 + t * 0.4),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3 + t * 0.4),
                blurRadius: 4 + t * 6,
                spreadRadius: t * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated number counter — counts from 0 to target for stat displays
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, val, __) {
        return Text(
          '$prefix${val.toInt()}$suffix',
          style: style ?? const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        );
      },
    );
  }
}

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

/// Radial pulse ring — expanding circle that fades out.
/// Great for "sending" / "loading" feedback animations.
class RadialPulse extends StatefulWidget {
  final Color color;
  final double maxRadius;
  final Duration duration;

  const RadialPulse({
    super.key,
    this.color = Colors.pinkAccent,
    this.maxRadius = 60,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<RadialPulse> createState() => _RadialPulseState();
}

class _RadialPulseState extends State<RadialPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return CustomPaint(
          size: Size(widget.maxRadius * 2, widget.maxRadius * 2),
          painter: _PulsePainter(
            progress: t,
            color: widget.color,
            maxRadius: widget.maxRadius,
          ),
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double maxRadius;

  _PulsePainter({
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw 3 concentric rings at different phases
    for (int i = 0; i < 3; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final radius = phase * maxRadius;
      final opacity = (1.0 - phase).clamp(0.0, 0.6);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1.0 - phase),
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.progress != progress;
}

/// Shimmer text — text that has a moving highlight shine effect.
/// Perfect for premium labels and titles.
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Color shimmerColor;

  const ShimmerText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 2000),
    this.shimmerColor = Colors.white,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ??
        const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              baseStyle.color ?? Colors.white,
              widget.shimmerColor.withValues(alpha: 0.8),
              baseStyle.color ?? Colors.white,
            ],
            stops: [
              (_ctrl.value - 0.3).clamp(0.0, 1.0),
              _ctrl.value,
              (_ctrl.value + 0.3).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: Text(text, style: baseStyle),
        );
      },
    );
  }

  String get text => widget.text;
}

/// Slide-and-fade entrance animation — wraps a child with staggered entrance.
/// Automatically animates when first built.
class SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;

  const SlideInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.beginOffset = const Offset(0, 0.15),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _position = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(curved);

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _position,
        child: widget.child,
      ),
    );
  }
}

