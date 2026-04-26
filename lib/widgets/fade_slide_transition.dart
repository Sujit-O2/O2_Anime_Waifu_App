import 'dart:async';
import 'package:flutter/material.dart';

/// A staggered fade+slide entrance animation widget.
///
/// Drop-in replacement for manual Timer+AnimatedOpacity+AnimatedSlide patterns
/// that appear throughout the app. Significantly cleaner than the current
/// approach in AnimatedEntry (v2_upgrade_kit) because it uses a proper
/// AnimationController with configurable curve instead of implicit animations.
///
/// ```dart
/// FadeSlideTransition(
///   delay: Duration(milliseconds: 100),
///   child: MyWidget(),
/// )
/// ```
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideBegin;
  final Curve curve;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.slideBegin = const Offset(0, 0.05),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(begin: widget.slideBegin, end: Offset.zero)
        .animate(curved);

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Helper extension for easily creating staggered lists of FadeSlideTransitions
extension StaggeredListBuilder on List<Widget> {
  /// Wraps each widget in a FadeSlideTransition with a staggered delay.
  List<Widget> staggered({
    Duration interval = const Duration(milliseconds: 60),
    Duration duration = const Duration(milliseconds: 400),
    Offset slideBegin = const Offset(0, 0.05),
  }) {
    return asMap()
        .map((i, child) => MapEntry(
              i,
              FadeSlideTransition(
                delay: interval * i,
                duration: duration,
                slideBegin: slideBegin,
                child: child,
              ),
            ))
        .values
        .toList();
  }
}
