import 'dart:math';
import 'package:flutter/material.dart';

// ──────────────────────── Parallax Scroll Card ────────────────────────────────

/// A card that shifts its cover image as the user scrolls, creating
/// a 3D parallax depth effect. Uses a ScrollController to calculate offset.
class ParallaxCard extends StatelessWidget {
  final Widget child;
  final double parallaxOffset;
  const ParallaxCard({super.key, required this.child, this.parallaxOffset = 0.0});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Transform.translate(
        offset: Offset(0, parallaxOffset * 0.3),
        child: child,
      ),
    );
  }
}

/// Calculates parallax offset for an item based on its position in scroll view.
double calculateParallax(BuildContext context, GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return 0.0;
  final pos = box.localToGlobal(Offset.zero);
  final screenH = MediaQuery.of(context).size.height;
  final center = screenH / 2;
  final itemCenter = pos.dy + box.size.height / 2;
  return (itemCenter - center) / screenH;
}

// ──────────────────────── Animated Favorite Heart Burst ──────────────────────

/// Shows a burst of hearts when user favorites an anime.
/// Call `HeartBurstOverlay.show(context)` to trigger.
class HeartBurstOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context, {Offset? position}) {
    _entry?.remove();
    final pos = position ?? Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    _entry = OverlayEntry(builder: (_) => _HeartBurstWidget(
      position: pos,
      onDone: () {
        _entry?.remove();
        _entry = null;
      },
    ));
    Overlay.of(context).insert(_entry!);
  }
}

class _HeartBurstWidget extends StatefulWidget {
  final Offset position;
  final VoidCallback onDone;
  const _HeartBurstWidget({required this.position, required this.onDone});
  @override
  State<_HeartBurstWidget> createState() => _HeartBurstWidgetState();
}

class _HeartBurstWidgetState extends State<_HeartBurstWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_HeartParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(12, (i) => _HeartParticle(
      angle: (i / 12) * 2 * pi + rng.nextDouble() * 0.5,
      speed: 80 + rng.nextDouble() * 120,
      size: 14 + rng.nextDouble() * 14,
      rotationSpeed: (rng.nextDouble() - 0.5) * 4,
      emoji: ['❤️', '💖', '💗', '💕', '✨', '🌸'][rng.nextInt(6)],
    ));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })..forward();
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
      builder: (_, __) {
        return Stack(
          children: _particles.map((p) {
            final t = _ctrl.value;
            final dx = cos(p.angle) * p.speed * t;
            final dy = sin(p.angle) * p.speed * t - 40 * t; // slight upward bias
            final opacity = (1 - t).clamp(0.0, 1.0);
            final scale = 1.0 + t * 0.5;

            return Positioned(
              left: widget.position.dx + dx - p.size / 2,
              top: widget.position.dy + dy - p.size / 2,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: p.rotationSpeed * t,
                    child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HeartParticle {
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;
  final String emoji;
  const _HeartParticle({
    required this.angle, required this.speed, required this.size,
    required this.rotationSpeed, required this.emoji,
  });
}

// ──────────────────────── Quiz Confetti Burst ────────────────────────────────

/// Shows confetti when user gets a quiz streak. 
/// Call `ConfettiBurst.show(context)` to trigger.
class ConfettiBurst {
  static OverlayEntry? _entry;

  static void show(BuildContext context) {
    _entry?.remove();
    _entry = OverlayEntry(builder: (_) => _ConfettiWidget(
      onDone: () {
        _entry?.remove();
        _entry = null;
      },
    ));
    Overlay.of(context).insert(_entry!);
  }
}

class _ConfettiWidget extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiWidget({required this.onDone});
  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _pieces = List.generate(30, (_) => _ConfettiPiece(
      x: rng.nextDouble(),
      speed: 200 + rng.nextDouble() * 300,
      wobble: rng.nextDouble() * 3,
      size: 8 + rng.nextDouble() * 8,
      color: [Colors.red, Colors.blue, Colors.green, Colors.yellow,
              Colors.purple, Colors.orange, Colors.pink, Colors.cyan]
          [rng.nextInt(8)],
    ));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          children: _pieces.map((p) {
            final t = _ctrl.value;
            final x = p.x * size.width + sin(t * p.wobble * pi) * 30;
            final y = -20 + t * p.speed;
            final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);
            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: t * p.wobble * 2,
                  child: Container(
                    width: p.size,
                    height: p.size * 0.6,
                    decoration: BoxDecoration(
                      color: p.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ConfettiPiece {
  final double x, speed, wobble, size;
  final Color color;
  const _ConfettiPiece({
    required this.x, required this.speed, required this.wobble,
    required this.size, required this.color,
  });
}


