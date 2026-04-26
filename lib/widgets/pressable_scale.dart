import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A universal press-scale wrapper that makes any widget feel tactile and premium.
///
/// Wraps a child widget with a subtle scale-down animation on press and
/// optional haptic feedback. Use this for buttons, cards, list items, etc.
///
/// ```dart
/// PressableScale(
///   onTap: () => doSomething(),
///   child: MyCard(...),
/// )
/// ```
class PressableScale extends StatefulWidget {
  /// The child widget to wrap with press-scale behavior.
  final Widget child;

  /// Called when the widget is tapped.
  final VoidCallback? onTap;

  /// Called when the widget is long-pressed.
  final VoidCallback? onLongPress;

  /// The scale factor when pressed (0.0 - 1.0). Default: 0.96
  final double pressedScale;

  /// Duration of the scale animation. Default: 100ms
  final Duration animationDuration;

  /// Whether to trigger haptic feedback on press. Default: false
  final bool hapticFeedback;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.animationDuration = const Duration(milliseconds: 100),
    this.hapticFeedback = false,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.animationDuration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: widget.animationDuration,
          child: widget.child,
        ),
      ),
    );
  }
}
