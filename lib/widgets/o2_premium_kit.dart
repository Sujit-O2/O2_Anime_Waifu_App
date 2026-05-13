// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// O2 PREMIUM UI KIT — v11.0.2
/// Ultra-premium glassmorphism, neon glow, shimmer, depth effects
/// All widgets are RepaintBoundary-wrapped and GPU-friendly.
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Palette ────────────────────────────────────────────────────────────────
class O2Colors {
  static const neonPink = Color(0xFFFF0057);
  static const neonCyan = Color(0xFF00D1FF);
  static const neonPurple = Color(0xFFBF00FF);
  static const neonGold = Color(0xFFFFD700);
  static const deepVoid = Color(0xFF0A0010);
  static const glassSurface = Color(0x1AFFFFFF);
  static const glassEdge = Color(0x33FFFFFF);
  static const glassEdgeDim = Color(0x1AFFFFFF);
}

// ─── NeumorphicCard ──────────────────────────────────────────────────────────
/// Soft-UI card with inset/outset depth and optional neon glow ring.
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glowColor;
  final bool inset;
  final VoidCallback? onTap;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.glowColor,
    this.inset = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final light = Color.lerp(bg, Colors.white, 0.12)!;
    final dark = Color.lerp(bg, Colors.black, 0.35)!;
    final glow = glowColor ?? O2Colors.neonPink;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: inset
            ? [
                BoxShadow(
                    color: dark, blurRadius: 8, offset: const Offset(3, 3)),
                BoxShadow(
                    color: light, blurRadius: 8, offset: const Offset(-3, -3)),
              ]
            : [
                BoxShadow(
                    color: dark, blurRadius: 16, offset: const Offset(6, 6)),
                BoxShadow(
                    color: light, blurRadius: 16, offset: const Offset(-6, -6)),
                BoxShadow(
                    color: glow.withValues(alpha: 0.18),
                    blurRadius: 24,
                    spreadRadius: -4),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: card,
      );
    }
    return card;
  }
}

// ─── NeonGlowBorder ──────────────────────────────────────────────────────────
/// Animated neon border that pulses with a breathing glow.
class NeonGlowBorder extends StatefulWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final bool animate;

  const NeonGlowBorder({
    super.key,
    required this.child,
    this.color = O2Colors.neonPink,
    this.radius = 20,
    this.strokeWidth = 1.5,
    this.animate = true,
  });

  @override
  State<NeonGlowBorder> createState() => _NeonGlowBorderState();
}

class _NeonGlowBorderState extends State<NeonGlowBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildBorder(1.0);
    }
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => _buildBorder(_glow.value),
    );
  }

  Widget _buildBorder(double intensity) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.6 * intensity),
            blurRadius: 12 * intensity,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: widget.color.withValues(alpha: 0.3 * intensity),
            blurRadius: 24 * intensity,
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: widget.color.withValues(alpha: 0.5 + 0.5 * intensity),
          width: widget.strokeWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius - widget.strokeWidth),
        child: widget.child,
      ),
    );
  }
}

// ─── HolographicShimmer ──────────────────────────────────────────────────────
/// GPU-friendly shimmer that sweeps a rainbow gradient across any widget.
class HolographicShimmer extends StatefulWidget {
  final Widget child;
  final bool active;

  const HolographicShimmer({super.key, required this.child, this.active = true});

  @override
  State<HolographicShimmer> createState() => _HolographicShimmerState();
}

class _HolographicShimmerState extends State<HolographicShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _ctrl.value;
            return LinearGradient(
              begin: Alignment(-1.5 + t * 3, -0.5),
              end: Alignment(-0.5 + t * 3, 0.5),
              colors: const [
                Colors.transparent,
                Color(0x55FF0057),
                Color(0x55FF00FF),
                Color(0x5500D1FF),
                Color(0x5500FF88),
                Colors.transparent,
              ],
              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─── PulseRing ───────────────────────────────────────────────────────────────
/// Expanding ring pulse — used for location pins, avatar aura, mic active.
class PulseRing extends StatefulWidget {
  final Color color;
  final double size;
  final int rings;
  final Widget? child;

  const PulseRing({
    super.key,
    this.color = O2Colors.neonPink,
    this.size = 60,
    this.rings = 3,
    this.child,
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _scales = [];
  final List<Animation<double>> _opacities = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.rings; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat();
      // Stagger each ring
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) ctrl.forward();
      });
      _ctrls.add(ctrl);
      _scales.add(Tween<double>(begin: 0.5, end: 1.8).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeOut)));
      _opacities.add(Tween<double>(begin: 0.7, end: 0.0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeOut)));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < widget.rings; i++)
            AnimatedBuilder(
              animation: _ctrls[i],
              builder: (_, __) => Transform.scale(
                scale: _scales[i].value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: _opacities[i].value),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

// ─── FloatingActionChip ──────────────────────────────────────────────────────
/// Pill-shaped floating chip with icon, label, and spring-in animation.
class FloatingActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool active;

  const FloatingActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  @override
  State<FloatingActionChip> createState() => _FloatingActionChipState();
}

class _FloatingActionChipState extends State<FloatingActionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: widget.active
                  ? [widget.color, widget.color.withValues(alpha: 0.7)]
                  : [
                      widget.color.withValues(alpha: 0.15),
                      widget.color.withValues(alpha: 0.08)
                    ],
            ),
            border: Border.all(
              color: widget.color.withValues(alpha: widget.active ? 0.8 : 0.4),
            ),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: -2)
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 16,
                  color: widget.active ? Colors.white : widget.color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.active ? Colors.white : widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── GlassPanel ──────────────────────────────────────────────────────────────
/// Frosted glass panel with depth gradient and optional header accent line.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accentColor;
  final bool showTopAccent;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.accentColor,
    this.showTopAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? O2Colors.neonPink;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x22FFFFFF),
                Color(0x0AFFFFFF),
              ],
            ),
            border: Border.all(
              color: showTopAccent ? accent : O2Colors.glassEdge,
              width: showTopAccent ? 1.5 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── NeonText ────────────────────────────────────────────────────────────────
/// Text with animated neon glow effect.
class NeonText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;
  final bool animate;

  const NeonText(
    this.text, {
    super.key,
    this.style,
    this.glowColor = O2Colors.neonPink,
    this.animate = true,
  });

  @override
  State<NeonText> createState() => _NeonTextState();
}

class _NeonTextState extends State<NeonText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _intensity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _intensity = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildText(1.0);
    }
    return AnimatedBuilder(
      animation: _intensity,
      builder: (_, __) => _buildText(_intensity.value),
    );
  }

  Widget _buildText(double intensity) {
    final base = widget.style ?? const TextStyle(fontSize: 16);
    return Text(
      widget.text,
      style: base.copyWith(
        color: widget.glowColor,
        shadows: [
          Shadow(
              color: widget.glowColor.withValues(alpha: 0.9 * intensity),
              blurRadius: 8 * intensity),
          Shadow(
              color: widget.glowColor.withValues(alpha: 0.5 * intensity),
              blurRadius: 20 * intensity),
          Shadow(
              color: widget.glowColor.withValues(alpha: 0.2 * intensity),
              blurRadius: 40 * intensity),
        ],
      ),
    );
  }
}

// ─── DepthCard ───────────────────────────────────────────────────────────────
/// Card with parallax-style depth layers for a 3D feel.
class DepthCard extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final double radius;

  const DepthCard({
    super.key,
    required this.child,
    required this.baseColor,
    this.radius = 20,
  });

  @override
  State<DepthCard> createState() => _DepthCardState();
}

class _DepthCardState extends State<DepthCard> {
  Offset _tilt = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) {
        setState(() {
          _tilt = Offset(
            (_tilt.dx + d.delta.dx * 0.01).clamp(-0.1, 0.1),
            (_tilt.dy + d.delta.dy * 0.01).clamp(-0.1, 0.1),
          );
        });
      },
      onPanEnd: (_) {
        setState(() => _tilt = Offset.zero);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-_tilt.dy)
          ..rotateY(_tilt.dx),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + _tilt.dx * 2, -1 + _tilt.dy * 2),
            end: Alignment(1 + _tilt.dx * 2, 1 + _tilt.dy * 2),
            colors: [
              Color.lerp(widget.baseColor, Colors.white, 0.15)!,
              widget.baseColor,
              Color.lerp(widget.baseColor, Colors.black, 0.2)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.baseColor.withValues(alpha: 0.4),
              blurRadius: 20 + _tilt.distance * 100,
              offset: Offset(_tilt.dx * 20, _tilt.dy * 20 + 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── O2StatBadge ─────────────────────────────────────────────────────────────
/// Compact stat badge with icon, value, and animated count-up.
class O2StatBadge extends StatefulWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const O2StatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  State<O2StatBadge> createState() => _O2StatBadgeState();
}

class _O2StatBadgeState extends State<O2StatBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _count;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _count = IntTween(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      accentColor: widget.color,
      showTopAccent: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: widget.color, size: 20),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _count,
            builder: (_, __) => Text(
              '${_count.value}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: widget.color,
              ),
            ),
          ),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AuroraGradient ──────────────────────────────────────────────────────────
/// Animated aurora-style gradient background for any container.
class AuroraGradient extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;

  const AuroraGradient({super.key, required this.child, this.colors});

  @override
  State<AuroraGradient> createState() => _AuroraGradientState();
}

class _AuroraGradientState extends State<AuroraGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        [
          O2Colors.neonPink,
          O2Colors.neonPurple,
          O2Colors.neonCyan,
          O2Colors.neonPink,
        ];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        return CustomPaint(
          painter: _AuroraPainter(t, colors),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final List<Color> colors;

  _AuroraPainter(this.t, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < colors.length - 1; i++) {
      final phase = t + i * 0.25;
      final y = size.height * (0.3 + 0.4 * math.sin(phase * math.pi * 2));
      final rect = Rect.fromLTWH(0, y - 80, size.width, 160);
      paint.shader = RadialGradient(
        center: Alignment(math.cos(phase * math.pi * 2) * 0.5, 0),
        radius: 1.2,
        colors: [
          colors[i].withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}
