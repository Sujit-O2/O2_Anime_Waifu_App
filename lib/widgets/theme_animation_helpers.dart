import 'dart:math';

import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// THEME ANIMATION HELPERS - Makes themes look SEXY with smooth animations
/// ════════════════════════════════════════════════════════════════════════════

/// Pulsing glow animation widget
class PulsingGlowWidget extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final Duration duration;
  final Curve curve;

  const PulsingGlowWidget({
    super.key,
    required this.child,
    required this.glowColor,
    this.glowRadius = 20,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeInOut,
  });

  @override
  State<PulsingGlowWidget> createState() => _PulsingGlowWidgetState();
}

class _PulsingGlowWidgetState extends State<PulsingGlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: 0.3 + (_animation.value * 0.4),
                ),
                blurRadius: widget.glowRadius * (0.5 + _animation.value),
                spreadRadius: _animation.value * 4,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Smoothly flowing color gradient animation
class FlowingGradientWidget extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const FlowingGradientWidget({
    super.key,
    required this.child,
    required this.colors,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<FlowingGradientWidget> createState() => _FlowingGradientWidgetState();
}

class _FlowingGradientWidgetState extends State<FlowingGradientWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 - _animation.value * 2, -1),
              end: Alignment(1 + _animation.value, 1),
              colors: widget.colors,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmering effect for ethereal themes
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color shimmerColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    required this.shimmerColor,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment(_animation.value - 1, 0),
                    end: Alignment(_animation.value, 0),
                    colors: [
                      Colors.transparent,
                      widget.shimmerColor.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ).createShader(bounds);
                },
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bouncing animation effect
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double bounceHeight;

  const BouncingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.bounceHeight = 10,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = sin(_animation.value * 3.14) * widget.bounceHeight;
        return Transform.translate(
          offset: Offset(0, -offset),
          child: widget.child,
        );
      },
    );
  }
}

/// Spinning animation effect
class SpinningWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double angle;

  const SpinningWidget({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 4),
    this.angle = 360,
  });

  @override
  State<SpinningWidget> createState() => _SpinningWidgetState();
}

class _SpinningWidgetState extends State<SpinningWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: widget.angle).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: (_animation.value * 3.14159) / 180,
          child: widget.child,
        );
      },
    );
  }
}

/// Ripple effect animation
class RippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color rippleColor;

  const RippleEffect({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor = Colors.white,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _radiusAnimation = Tween<double>(begin: 0, end: 200).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    _tapPosition = details.globalPosition;
    _controller.forward().then((_) {
      _controller.reset();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: Stack(
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _radiusAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: RipplePainter(
                  radius: _radiusAnimation.value,
                  tapPosition: _tapPosition,
                  rippleColor: widget.rippleColor,
                  progress: _controller.value,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final double radius;
  final Offset tapPosition;
  final Color rippleColor;
  final double progress;

  RipplePainter({
    required this.radius,
    required this.tapPosition,
    required this.rippleColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = rippleColor.withValues(alpha: (1 - progress) * 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(tapPosition, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}


