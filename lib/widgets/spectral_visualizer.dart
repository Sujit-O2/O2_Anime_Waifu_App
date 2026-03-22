import 'dart:math';
import 'package:flutter/material.dart';

/// Dynamic Spectral Analyzer - 16 independent frequency bars
/// that dance in real-time when voice is detected.
class SpectralVisualizer extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;

  const SpectralVisualizer({
    super.key,
    required this.isActive,
    required this.color,
    this.size = 60,
  });

  @override
  State<SpectralVisualizer> createState() => _SpectralVisualizerState();
}

class _SpectralVisualizerState extends State<SpectralVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static final Random _random = Random();
  final List<double> _bars = List.generate(16, (_) => 0.2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (widget.isActive) {
            for (int i = 0; i < _bars.length; i++) {
              _bars[i] = 0.2 + _random.nextDouble() * 0.8;
            }
          } else {
            for (int i = 0; i < _bars.length; i++) {
              _bars[i] = (_bars[i] * 0.9).clamp(0.05, 1.0);
            }
          }

          return SizedBox(
            width: widget.size,
            height: widget.size * 0.6,
            child: CustomPaint(
              painter: _SpectralPainter(
                bars: _bars,
                color: widget.color,
                isActive: widget.isActive,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpectralPainter extends CustomPainter {
  final List<double> bars;
  final Color color;
  final bool isActive;

  _SpectralPainter({
    required this.bars,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (bars.length * 1.5);
    final gap = barWidth * 0.5;

    for (int i = 0; i < bars.length; i++) {
      final x = i * (barWidth + gap);
      final barHeight = bars[i] * size.height;
      final y = size.height - barHeight;

      final paint = Paint()
        ..color = color.withValues(alpha: isActive ? 0.8 : 0.3)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, paint);

      if (isActive) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawRRect(rect, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpectralPainter oldDelegate) => true;
}
