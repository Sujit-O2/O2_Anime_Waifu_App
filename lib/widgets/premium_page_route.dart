import 'package:flutter/material.dart';

/// Premium page route transition with fade + slide + scale.
/// Use instead of MaterialPageRoute for a premium feel:
/// ```dart
/// Navigator.push(context, PremiumPageRoute(child: MyPage()));
/// ```
class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration animDuration;
  final RouteTransitionStyle style;

  PremiumPageRoute({
    required this.child,
    this.animDuration = const Duration(milliseconds: 350),
    this.style = RouteTransitionStyle.fadeSlide,
    super.settings,
  }) : super(
          transitionDuration: animDuration,
          reverseTransitionDuration: animDuration,
          pageBuilder: (_, __, ___) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(style, animation, secondaryAnimation, child);
          },
        );

  static Widget _buildTransition(
    RouteTransitionStyle style,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    switch (style) {
      case RouteTransitionStyle.fadeSlide:
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );

      case RouteTransitionStyle.fadeScale:
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );

      case RouteTransitionStyle.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );

      case RouteTransitionStyle.fade:
        return FadeTransition(
          opacity: curved,
          child: child,
        );

      case RouteTransitionStyle.sharedAxis:
        // Shared axis Z (depth) transition
        final exitAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.1).animate(exitAnimation),
              child: child,
            ),
          ),
        );
    }
  }
}

enum RouteTransitionStyle {
  fadeSlide,
  fadeScale,
  slideUp,
  fade,
  sharedAxis,
}

/// Hero-compatible page route with custom animation
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  HeroPageRoute({
    required this.child,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => child,
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: child,
            );
          },
        );
}
