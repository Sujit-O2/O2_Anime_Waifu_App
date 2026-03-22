import 'package:flutter/material.dart';

/// Neural Aura Glow - soft breathing light around AI avatar.
/// Breathes at 0.5Hz during idle, intensifies when speaking,
/// harmonizes with theme's primary accent color.
class NeuralAura extends StatefulWidget {
  final bool isSpeaking;
  final Color color;
  final double size;

  const NeuralAura({
    super.key,
    required this.isSpeaking,
    required this.color,
    this.size = 80,
  });

  @override
  State<NeuralAura> createState() => _NeuralAuraState();
}

class _NeuralAuraState extends State<NeuralAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 0.5Hz breathing = 2 second duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
        final intensity = widget.isSpeaking ? 0.6 : 0.3;
        final scale = 1.0 + (_controller.value * 0.15);
        final glowRadius = widget.isSpeaking ? 25.0 : 15.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color
                      .withValues(alpha: intensity * _controller.value),
                  blurRadius: glowRadius,
                  spreadRadius: glowRadius * 0.5,
                ),
                BoxShadow(
                  color: widget.color
                      .withValues(alpha: intensity * 0.5 * _controller.value),
                  blurRadius: glowRadius * 2,
                  spreadRadius: glowRadius,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: widget.size / 2,
              backgroundColor:
                  widget.color.withValues(alpha: 0.2),
              child: Icon(
                Icons.favorite,
                color: widget.color,
                size: widget.size * 0.4,
              ),
            ),
          ),
        );
      },
    );
  }
}
