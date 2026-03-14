import 'dart:math';
import 'package:flutter/material.dart';

// ── MusicVisualizer ───────────────────────────────────────────────────────────
// 7-bar spectrum-analyser style visualizer that animates in the background
// when music is playing. Each bar has an independent AnimationController
// with a randomised loop period so the bars feel organic and rhythmic.
// Fades in/out based on [isPlaying].
// ─────────────────────────────────────────────────────────────────────────────

class MusicVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final int barCount;
  final double opacity;

  const MusicVisualizer({
    super.key,
    required this.isPlaying,
    this.color = const Color(0xFFFF4D8D),
    this.barCount = 7,
    this.opacity = 0.18,
  });

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _barCtrls;
  late List<Animation<double>> _barAnims;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut));

    _barCtrls = List.generate(widget.barCount, (i) {
      final period = 300 + _rng.nextInt(400); // 300–700 ms
      return AnimationController(
          vsync: this, duration: Duration(milliseconds: period))
        ..repeat(reverse: true);
    });

    _barAnims = _barCtrls.map((c) {
      final minH = 0.1 + _rng.nextDouble() * 0.15;
      final maxH = 0.5 + _rng.nextDouble() * 0.4;
      return Tween<double>(begin: minH, end: maxH)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeInOutSine));
    }).toList();

    if (widget.isPlaying) _fadeCtrl.forward();
  }

  @override
  void didUpdateWidget(MusicVisualizer old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _fadeCtrl.forward();
      } else {
        _fadeCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in _barCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedBuilder(
        animation: Listenable.merge(_barCtrls),
        builder: (_, __) => CustomPaint(
          painter: _VisualizerPainter(
            heights: _barAnims.map((a) => a.value).toList(),
            color: widget.color,
            opacity: widget.opacity,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final List<double> heights;
  final Color color;
  final double opacity;

  _VisualizerPainter(
      {required this.heights, required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = heights.length;
    final barW = (size.width / barCount) * 0.55;
    final gap = size.width / barCount;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (int i = 0; i < barCount; i++) {
      final barH = heights[i] * size.height * 0.7;
      final left = gap * i + (gap - barW) / 2;
      final top = size.height - barH;
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barW, barH),
          const Radius.circular(6));

      // Gradient per bar
      paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.3),
        ],
      ).createShader(Rect.fromLTWH(left, top, barW, barH));

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter old) =>
      old.heights != heights || old.opacity != opacity;
}
