import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// A premium glass-morphism card with optional animated gradient border.
/// Features frosted glass effect, subtle border glow, and depth shadow.
///
/// ```dart
/// FrostedGlassCard(
///   animatedBorder: true,
///   child: Text('Premium Content'),
/// )
/// ```
class FrostedGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool animatedBorder;
  final Color? glowColor;
  final double blurAmount;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.animatedBorder = false,
    this.glowColor,
    this.blurAmount = 12,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<FrostedGlassCard> createState() => _FrostedGlassCardState();
}

class _FrostedGlassCardState extends State<FrostedGlassCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _borderCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.animatedBorder) {
      _borderCtrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _borderCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? Colors.pinkAccent;
    final borderR = BorderRadius.circular(widget.borderRadius);

    Widget card = ClipRRect(
      borderRadius: borderR,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurAmount,
          sigmaY: widget.blurAmount,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: borderR,
            color: Colors.white.withValues(alpha: 0.05),
            border: widget.animatedBorder
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: glow.withValues(alpha: 0.05),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    // Wrap with animated gradient border
    if (widget.animatedBorder && _borderCtrl != null) {
      card = AnimatedBuilder(
        animation: _borderCtrl!,
        builder: (context, child) {
          return CustomPaint(
            painter: _GradientBorderPainter(
              progress: _borderCtrl!.value,
              borderRadius: widget.borderRadius,
              colors: [
                glow.withValues(alpha: 0.6),
                Colors.purpleAccent.withValues(alpha: 0.4),
                Colors.cyanAccent.withValues(alpha: 0.3),
                glow.withValues(alpha: 0.6),
              ],
              strokeWidth: 1.5,
            ),
            child: child,
          );
        },
        child: card,
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: card,
      );
    }

    return card;
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final List<Color> colors;
  final double strokeWidth;

  _GradientBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.colors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: colors,
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A simple pulsing dot indicator for "online" / "active" status
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = Colors.greenAccent,
    this.size = 10,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3 + _ctrl.value * 0.4),
              blurRadius: 4 + _ctrl.value * 6,
              spreadRadius: _ctrl.value * 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated number that counts up from 0 to target value
class AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, val, __) => Text(
        '$prefix${val.toInt()}$suffix',
        style: style,
      ),
    );
  }
}
