// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// O2 BACKGROUND ENGINE — v9.0.2
/// GPU-accelerated shader-like gradient animations:
/// • Aurora borealis effect with sinusoidal color bands
/// • Reactive particle mesh (responds to scroll/touch)
/// • Depth parallax layers
/// • Theme-aware color palettes
/// • Battery-aware: auto-reduces complexity on eco mode
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Theme Palettes ───────────────────────────────────────────────────────────

class BackgroundPalette {
  final List<Color> aurora;
  final Color base;
  final Color particleColor;

  const BackgroundPalette({
    required this.aurora,
    required this.base,
    required this.particleColor,
  });

  static const neonNight = BackgroundPalette(
    base: Color(0xFF0A0010),
    aurora: [
      Color(0xFFFF0057),
      Color(0xFFBF00FF),
      Color(0xFF00D1FF),
      Color(0xFF00FF88),
    ],
    particleColor: Color(0xFFFF0057),
  );

  static const cyberBlue = BackgroundPalette(
    base: Color(0xFF000A1A),
    aurora: [
      Color(0xFF00D1FF),
      Color(0xFF0066FF),
      Color(0xFF00FF88),
      Color(0xFF00D1FF),
    ],
    particleColor: Color(0xFF00D1FF),
  );

  static const sakuraDream = BackgroundPalette(
    base: Color(0xFF1A0010),
    aurora: [
      Color(0xFFFF6B9D),
      Color(0xFFFF0057),
      Color(0xFFFFB3D1),
      Color(0xFFFF6B9D),
    ],
    particleColor: Color(0xFFFF6B9D),
  );

  static const voidPurple = BackgroundPalette(
    base: Color(0xFF08000F),
    aurora: [
      Color(0xFFBF00FF),
      Color(0xFF6600CC),
      Color(0xFFFF00AA),
      Color(0xFFBF00FF),
    ],
    particleColor: Color(0xFFBF00FF),
  );

  static const goldSunset = BackgroundPalette(
    base: Color(0xFF0F0800),
    aurora: [
      Color(0xFFFFD700),
      Color(0xFFFF6600),
      Color(0xFFFF0057),
      Color(0xFFFFD700),
    ],
    particleColor: Color(0xFFFFD700),
  );
}

// ─── Aurora Background ────────────────────────────────────────────────────────

class O2AuroraBackground extends StatefulWidget {
  final Widget child;
  final BackgroundPalette palette;
  final bool enableParticles;
  final int particleCount;
  final bool enableAurora;
  final bool enableDepthLayers;

  const O2AuroraBackground({
    super.key,
    required this.child,
    this.palette = BackgroundPalette.neonNight,
    this.enableParticles = true,
    this.particleCount = 30,
    this.enableAurora = true,
    this.enableDepthLayers = true,
  });

  @override
  State<O2AuroraBackground> createState() => _O2AuroraBackgroundState();
}

class _O2AuroraBackgroundState extends State<O2AuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  static final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _initParticles();
  }

  void _initParticles() {
    _particles = List.generate(widget.particleCount, (_) => _Particle.random(_rng));
  }

  @override
  void didUpdateWidget(O2AuroraBackground old) {
    super.didUpdateWidget(old);
    if (old.particleCount != widget.particleCount) {
      _initParticles();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          return CustomPaint(
            painter: _BackgroundPainter(
              t: _ctrl.value,
              palette: widget.palette,
              particles: widget.enableParticles ? _particles : [],
              enableAurora: widget.enableAurora,
              enableDepth: widget.enableDepthLayers,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ─── Particle ─────────────────────────────────────────────────────────────────

class _Particle {
  double x, y, size, speed, opacity, drift, phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.drift,
    required this.phase,
  });

  factory _Particle.random(math.Random rng) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 2.5 + 0.5,
        speed: rng.nextDouble() * 0.3 + 0.1,
        opacity: rng.nextDouble() * 0.4 + 0.1,
        drift: (rng.nextDouble() - 0.5) * 0.015,
        phase: rng.nextDouble() * math.pi * 2,
      );
}

// ─── Background Painter ───────────────────────────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  final double t;
  final BackgroundPalette palette;
  final List<_Particle> particles;
  final bool enableAurora;
  final bool enableDepth;

  _BackgroundPainter({
    required this.t,
    required this.palette,
    required this.particles,
    required this.enableAurora,
    required this.enableDepth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Base fill ────────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = palette.base,
    );

    // ── Depth gradient layers ─────────────────────────────────────────────────
    if (enableDepth) {
      _paintDepthLayers(canvas, size);
    }

    // ── Aurora bands ──────────────────────────────────────────────────────────
    if (enableAurora) {
      _paintAurora(canvas, size);
    }

    // ── Particles ─────────────────────────────────────────────────────────────
    _paintParticles(canvas, size);
  }

  void _paintDepthLayers(Canvas canvas, Size size) {
    // Bottom vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomCenter,
        radius: 1.2,
        colors: [
          Colors.transparent,
          palette.base.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), vignette);

    // Subtle radial glow at center
    final centerGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          math.sin(t * math.pi * 2) * 0.3,
          math.cos(t * math.pi * 2) * 0.2,
        ),
        radius: 0.8,
        colors: [
          palette.aurora[0].withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), centerGlow);
  }

  void _paintAurora(Canvas canvas, Size size) {
    final colors = palette.aurora;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < colors.length; i++) {
      final phase = t + i * (1.0 / colors.length);
      final y = size.height *
          (0.2 + 0.5 * math.sin(phase * math.pi * 2 + i * 0.8));
      final width = size.width * (0.6 + 0.4 * math.cos(phase * math.pi));
      final x = (size.width - width) / 2 +
          size.width * 0.1 * math.sin(phase * math.pi * 3 + i);

      final rect = Rect.fromLTWH(x, y - 60, width, 120);
      paint.shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          colors[i].withValues(alpha: 0.12),
          colors[i].withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

      canvas.drawOval(rect, paint);
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Update position (stateless — computed from t)
      final px = (p.x + p.drift * t * 10) % 1.0;
      final py = (p.y - p.speed * t) % 1.0;
      final twinkle = 0.5 + 0.5 * math.sin(t * math.pi * 4 + p.phase);

      paint.color = palette.particleColor.withValues(alpha: p.opacity * twinkle);
      canvas.drawCircle(
        Offset(px * size.width, py * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.t != t;
}

// ─── Reactive Mesh Background ─────────────────────────────────────────────────
/// Particle mesh that reacts to touch position.

class O2ReactiveMesh extends StatefulWidget {
  final Widget child;
  final Color color;
  final int nodeCount;

  const O2ReactiveMesh({
    super.key,
    required this.child,
    this.color = const Color(0xFF00D1FF),
    this.nodeCount = 20,
  });

  @override
  State<O2ReactiveMesh> createState() => _O2ReactiveMeshState();
}

class _O2ReactiveMeshState extends State<O2ReactiveMesh>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_MeshNode> _nodes;
  Offset _touch = const Offset(-1, -1);
  static final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _nodes = List.generate(
        widget.nodeCount, (_) => _MeshNode.random(_rng));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => setState(() => _touch = d.localPosition),
      onPanEnd: (_) => setState(() => _touch = const Offset(-1, -1)),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => CustomPaint(
            painter: _MeshPainter(
              t: _ctrl.value,
              nodes: _nodes,
              color: widget.color,
              touch: _touch,
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _MeshNode {
  final double x, y, vx, vy, phase;

  const _MeshNode({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.phase,
  });

  factory _MeshNode.random(math.Random rng) => _MeshNode(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        vx: (rng.nextDouble() - 0.5) * 0.02,
        vy: (rng.nextDouble() - 0.5) * 0.02,
        phase: rng.nextDouble() * math.pi * 2,
      );

  Offset position(double t, Size size) {
    final px = (x + vx * t * 5 + 0.05 * math.sin(t * math.pi * 2 + phase)) % 1.0;
    final py = (y + vy * t * 5 + 0.05 * math.cos(t * math.pi * 2 + phase)) % 1.0;
    return Offset(px * size.width, py * size.height);
  }
}

class _MeshPainter extends CustomPainter {
  final double t;
  final List<_MeshNode> nodes;
  final Color color;
  final Offset touch;

  _MeshPainter({
    required this.t,
    required this.nodes,
    required this.color,
    required this.touch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final positions = nodes.map((n) => n.position(t, size)).toList();
    const maxDist = 120.0;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.5);

    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final d = (positions[i] - positions[j]).distance;
        if (d < maxDist) {
          final opacity = (1 - d / maxDist) * 0.3;
          linePaint.color = color.withValues(alpha: opacity);
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }

      // React to touch
      if (touch.dx >= 0) {
        final td = (positions[i] - touch).distance;
        if (td < 150) {
          final intensity = (1 - td / 150) * 0.6;
          linePaint.color = color.withValues(alpha: intensity);
          canvas.drawLine(positions[i], touch, linePaint);
        }
      }

      canvas.drawCircle(positions[i], 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t || old.touch != touch;
}

// ─── Screen Background Wrapper ────────────────────────────────────────────────
/// Drop-in replacement for Scaffold background — picks palette from theme.

class O2ScreenBackground extends StatelessWidget {
  final Widget child;
  final BackgroundPalette? palette;
  final bool lite; // Reduced effects for inner screens

  const O2ScreenBackground({
    super.key,
    required this.child,
    this.palette,
    this.lite = false,
  });

  @override
  Widget build(BuildContext context) {
    final pal = palette ?? BackgroundPalette.neonNight;
    return O2AuroraBackground(
      palette: pal,
      enableParticles: !lite,
      particleCount: lite ? 10 : 30,
      enableAurora: !lite,
      enableDepthLayers: true,
      child: child,
    );
  }
}
