import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── GestureShortcutOverlay ────────────────────────────────────────────────────
// Invisible overlay over the home screen.
// User draws a shape → matched to a registered shortcut → action fired.
//
// Supported shapes:
//   ○  Circle    → Camera
//   Z  Z-stroke  → Music player
//   V  V-stroke  → Phone (call log)
//   L  L-stroke  → Last app
//   ↑  Fast up   → App Drawer (already done via SwipeUp, kept for consistency)
// ─────────────────────────────────────────────────────────────────────────────

typedef GestureAction = void Function(BuildContext context);

enum GestureShape { circle, zStroke, vStroke, lStroke }

class GestureShortcutOverlay extends StatefulWidget {
  final Widget child;
  final Color primaryColor;
  final Map<GestureShape, GestureAction> actions;

  const GestureShortcutOverlay({
    super.key,
    required this.child,
    required this.primaryColor,
    this.actions = const {},
  });

  @override
  State<GestureShortcutOverlay> createState() => _GestureShortcutOverlayState();
}

class _GestureShortcutOverlayState extends State<GestureShortcutOverlay>
    with SingleTickerProviderStateMixin {
  final List<Offset> _points = [];
  bool _drawing = false;
  String? _label;
  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackFade;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _feedbackFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _feedbackCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ── Recognition ──────────────────────────────────────────────────────────────

  GestureShape? _recognize(List<Offset> pts) {
    if (pts.length < 8) return null;
    if (_isCircle(pts)) return GestureShape.circle;
    if (_isZ(pts)) return GestureShape.zStroke;
    if (_isV(pts)) return GestureShape.vStroke;
    if (_isL(pts)) return GestureShape.lStroke;
    return null;
  }

  bool _isCircle(List<Offset> pts) {
    final cx = pts.map((p) => p.dx).reduce((a, b) => a + b) / pts.length;
    final cy = pts.map((p) => p.dy).reduce((a, b) => a + b) / pts.length;
    final radii = pts.map((p) => (p - Offset(cx, cy)).distance).toList();
    final avg = radii.reduce((a, b) => a + b) / radii.length;
    final variance = radii.map((r) => (r - avg).abs()).reduce((a, b) => a + b) / radii.length;
    final startEnd = (pts.first - pts.last).distance;
    return avg > 30 && variance / avg < 0.35 && startEnd < avg * 0.8;
  }

  bool _isZ(List<Offset> pts) {
    // Z: right → down-left → right
    if (pts.length < 12) return false;
    final third = pts.length ~/ 3;
    final seg1 = pts.sublist(0, third);
    final seg2 = pts.sublist(third, 2 * third);
    final seg3 = pts.sublist(2 * third);
    final d1 = seg1.last.dx - seg1.first.dx;
    final d2y = seg2.last.dy - seg2.first.dy;
    final d2x = seg2.last.dx - seg2.first.dx;
    final d3 = seg3.last.dx - seg3.first.dx;
    return d1 > 30 && d2y > 20 && d2x < -10 && d3 > 30;
  }

  bool _isV(List<Offset> pts) {
    final mid = pts[pts.length ~/ 2];
    final top = pts.fold(pts.first, (a, b) => a.dy < b.dy ? a : b);
    return (mid.dy - top.dy) > 40 &&
        (pts.first - mid).distance > 30 &&
        (pts.last - mid).distance > 30;
  }

  bool _isL(List<Offset> pts) {
    final half = pts.length ~/ 2;
    final firstDown = pts[half].dy - pts.first.dy;
    final secondRight = pts.last.dx - pts[half].dx;
    return firstDown > 40 && secondRight > 30;
  }

  String _shapeName(GestureShape s) {
    switch (s) {
      case GestureShape.circle: return '○ Camera';
      case GestureShape.zStroke: return 'Z Music';
      case GestureShape.vStroke: return 'V Call';
      case GestureShape.lStroke: return 'L Last App';
    }
  }

  void _onDragEnd() {
    if (!_drawing) return;
    _drawing = false;
    final shape = _recognize(_points);
    if (shape != null) {
      setState(() {
        _label = _shapeName(shape);
      });
      _feedbackCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _label = null);
      });
      widget.actions[shape]?.call(context);
    } else {
      setState(() => _points.clear());
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Gesture capture layer (3-finger touch to activate drawing mode)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: (_) {
              setState(() { _drawing = true; _points.clear(); _label = null; });
            },
            onLongPressMoveUpdate: (details) {
              if (_drawing) setState(() => _points.add(details.localPosition));
            },
            onLongPressEnd: (_) => _onDragEnd(),
            child: CustomPaint(
              painter: _GhostTrailPainter(
                  points: _drawing ? _points : [],
                  color: widget.primaryColor),
            ),
          ),
        ),
        // Recognition feedback label
        if (_label != null)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.42,
            left: 0, right: 0,
            child: FadeTransition(
              opacity: _feedbackFade,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.4), blurRadius: 20)],
                  ),
                  child: Text(
                    _label!,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GhostTrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  _GhostTrailPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) path.lineTo(p.dx, p.dy);
    canvas.drawPath(path, paint);
    // Glow
    canvas.drawPath(path, paint..color = color.withValues(alpha: 0.15) ..strokeWidth = 10 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  @override
  bool shouldRepaint(_GhostTrailPainter old) => old.points != points;
}
