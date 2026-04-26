import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Visual effects service: Neumorphism, micro-interactions, animations
class VisualEffectsService {
  static final VisualEffectsService _instance =
      VisualEffectsService._internal();
  factory VisualEffectsService() => _instance;
  VisualEffectsService._internal();

  // ── Neumorphism Effects ──────────────────────────────────────────────────

  /// Neumorphic pressed effect (soft 3D inset)
  static BoxDecoration neomorphismPressed({
    Color backgroundColor = const Color(0xFFE0E5EC),
    double elevation = 8,
  }) {
    final shadowColor = Colors.black.withValues(alpha: 0.15);
    final highlightColor = Colors.white.withValues(alpha: 0.7);

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: elevation,
          spreadRadius: -elevation / 2,
          offset: Offset(elevation / 2, elevation / 2),
        ),
        BoxShadow(
          color: highlightColor,
          blurRadius: elevation,
          spreadRadius: -elevation / 2,
          offset: Offset(-elevation / 2, -elevation / 2),
        ),
      ],
    );
  }

  /// Neumorphic raised effect (soft emboss)
  static BoxDecoration neomorphismRaised({
    Color backgroundColor = const Color(0xFFE0E5EC),
    double elevation = 8,
  }) {
    final shadowColor = Colors.black.withValues(alpha: 0.1);
    const highlightColor = Colors.white;

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: elevation * 1.5,
          offset: Offset(elevation, elevation),
        ),
        BoxShadow(
          color: highlightColor,
          blurRadius: elevation,
          offset: Offset(-elevation / 2, -elevation / 2),
        ),
      ],
    );
  }

  // ── Micro-interactions ───────────────────────────────────────────────────

  /// Bounce animation on button tap
  /// Usage: Use in AnimatedBuilder with controller
  static Animation<double> bounceTween(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// Rotate + scale on success
  /// Usage: Use in AnimatedBuilder with controller
  static Animation<double> successRotationTween(AnimationController controller) {
    return Tween<double>(begin: 0, end: 360)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutBack));
  }

  /// Shake animation (for errors)
  /// Usage: Use in AnimatedBuilder with controller
  static Animation<Offset> shakeAnimation(AnimationController controller) {
    const duration = 100.0; // ms
    return TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(10, 0)), weight: duration),
      TweenSequenceItem(tween: Tween(begin: const Offset(10, 0), end: const Offset(-10, 0)), weight: duration),
      TweenSequenceItem(tween: Tween(begin: const Offset(-10, 0), end: Offset.zero), weight: duration),
    ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  // ── Gradient Effects ─────────────────────────────────────────────────────

  /// Animated gradient shimmer
  static Gradient shimmerGradient(double animationValue) {
    return LinearGradient(
      begin: Alignment(-1.0 - animationValue, 0),
      end: Alignment(1.0 + animationValue, 0),
      colors: [
        Colors.grey.shade300,
        Colors.grey.shade100,
        Colors.grey.shade300,
      ],
    );
  }

  /// Animated glow effect
  static List<BoxShadow> getGlowShadow({
    required Color color,
    required double intensity,
    required double blur,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: blur,
        spreadRadius: blur / 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: intensity * 0.5),
        blurRadius: blur * 2,
        spreadRadius: blur,
      ),
    ];
  }

  // ── Glass Morphism Enhancements ────────────────────────────────────────

  /// Enhanced glassmorphic container with blur
  static Widget glassmorphicContainer({
    required Widget child,
    double blur = 10,
    double opacity = 0.1,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Parallax Effects ─────────────────────────────────────────────────────

  /// Calculate parallax offset based on scroll
  static Offset calculateParallaxOffset(
    double scrollOffset, {
    double strength = 0.5,
  }) {
    return Offset(0, scrollOffset * strength);
  }

  // ── Floating Action Button Enhancement ───────────────────────────────────

  /// Get enhanced FAB decoration with glow
  static BoxDecoration getEnhancedFabDecoration({
    required Color color,
    required bool isPressed,
  }) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: isPressed ? 8 : 16,
          spreadRadius: isPressed ? 2 : 4,
        ),
      ],
    );
  }
}

// ── Micro-interaction Widget ─────────────────────────────────────────────

/// Button with micro-interactions (bounce + haptic)
class MicroInteractionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final Duration animationDuration;

  const MicroInteractionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = Colors.pinkAccent,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<MicroInteractionButton> createState() =>
      _MicroInteractionButtonState();
}

class _MicroInteractionButtonState extends State<MicroInteractionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation =
        VisualEffectsService.bounceTween(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward().then((_) {
      _controller.reset();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: VisualEffectsService.getGlowShadow(
              color: widget.backgroundColor,
              intensity: 0.3,
              blur: 12,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Shimmer Loading Widget ──────────────────────────────────────────────

/// Enhanced shimmer loading with gradient animation
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
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
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: VisualEffectsService.shimmerGradient(_controller.value),
          ),
        );
      },
    );
  }
}



