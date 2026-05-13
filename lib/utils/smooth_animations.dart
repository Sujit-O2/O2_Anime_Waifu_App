import 'package:flutter/material.dart';

/// ✨ Smooth Animation Utilities
/// Provides consistent, performant animations across the app

class SmoothAnimations {
  // Animation durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  // Animation curves
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve snapCurve = Curves.easeOutExpo;
  
  /// Smooth fade-in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = smoothCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
  
  /// Smooth slide-in animation
  static Widget slideIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = smoothCurve,
    Offset begin = const Offset(0, 0.1),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value.dx * 100, value.dy * 100),
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Smooth scale animation
  static Widget scale({
    required Widget child,
    Duration duration = normal,
    Curve curve = smoothCurve,
    double begin = 0.95,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }
  
  /// Combined fade + slide animation
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = smoothCurve,
    Offset slideBegin = const Offset(0, 0.05),
  }) {
    return fadeIn(
      duration: duration,
      curve: curve,
      child: slideIn(
        duration: duration,
        curve: curve,
        begin: slideBegin,
        child: child,
      ),
    );
  }
  
  /// Staggered list animation
  static Widget staggeredItem({
    required Widget child,
    required int index,
    int maxStagger = 10,
  }) {
    final delay = Duration(milliseconds: (index * 50).clamp(0, maxStagger * 50));
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: normal + delay,
      curve: smoothCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated container with smooth transitions
class SmoothContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Duration duration;
  final Curve curve;
  
  const SmoothContainer({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.boxShadow,
    this.duration = SmoothAnimations.normal,
    this.curve = SmoothAnimations.smoothCurve,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

/// Smooth page transition
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: SmoothAnimations.normal,
          reverseTransitionDuration: SmoothAnimations.fast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.05, 0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: SmoothAnimations.smoothCurve),
            );
            final offsetAnimation = animation.drive(tween);
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: SmoothAnimations.smoothCurve,
              ),
            );
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
        );
}
