// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:anime_waifu/services/utilities_core/geo_intelligence_service.dart';
import 'package:anime_waifu/widgets/o2_premium_kit.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// O2 MAP WIDGET — v10.0.2
/// Premium animated map with location heatmap, geo-fence rings,
/// travel path visualization, and place cluster labels.
/// Pure Flutter CustomPainter — no external map SDK required.
/// ═══════════════════════════════════════════════════════════════════════════

class O2MapWidget extends StatefulWidget {
  final double height;
  final bool showHeatmap;
  final bool showPath;
  final bool showFences;
  final bool showClusters;

  const O2MapWidget({
    super.key,
    this.height = 300,
    this.showHeatmap = true,
    this.showPath = true,
    this.showFences = true,
    this.showClusters = true,
  });

  @override
  State<O2MapWidget> createState() => _O2MapWidgetState();
}

class _O2MapWidgetState extends State<O2MapWidget>
    with TickerProviderStateMixin {
  final _geo = GeoIntelligenceService();
  late AnimationController _pulseCtrl;
  late AnimationController _pathCtrl;
  late Animation<double> _pulse;
  late Animation<double> _pathProgress;

  // Viewport state
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pathCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _pulse = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pathProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pathCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: 24,
      accentColor: O2Colors.neonCyan,
      showTopAccent: true,
      child: SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Dark grid background
              CustomPaint(
                painter: _GridPainter(),
                size: Size.infinite,
              ),
              // Main map content
              GestureDetector(
                onScaleStart: (d) => _lastFocalPoint = d.focalPoint,
                onScaleUpdate: (d) {
                  setState(() {
                    _scale = (_scale * d.scale).clamp(0.5, 5.0);
                    if (_lastFocalPoint != null) {
                      _offset += d.focalPoint - _lastFocalPoint!;
                      _lastFocalPoint = d.focalPoint;
                    }
                  });
                },
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _pathProgress]),
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _MapPainter(
                        heatmap: widget.showHeatmap
                            ? _geo.getHeatmapData()
                            : [],
                        path: widget.showPath
                            ? _geo.getTravelPath(maxPoints: 80)
                            : [],
                        fences: widget.showFences ? _geo.fences : [],
                        clusters: widget.showClusters ? _geo.clusters : [],
                        currentPos: _geo.lastPosition != null
                            ? {
                                'lat': _geo.lastPosition!.latitude,
                                'lng': _geo.lastPosition!.longitude,
                              }
                            : null,
                        pulse: _pulse.value,
                        pathProgress: _pathProgress.value,
                        scale: _scale,
                        offset: _offset,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
              // Overlay: stats bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildStatsBar(),
              ),
              // Overlay: controls
              Positioned(
                top: 8,
                right: 8,
                child: _buildControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final clusters = _geo.clusters;
    final history = _geo.history;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.black.withValues(alpha: 0.4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(Icons.place, '${clusters.length}', 'Places'),
              _statItem(Icons.route, '${history.length}', 'Points'),
              _statItem(Icons.fence, '${_geo.fences.length}', 'Fences'),
              _statItem(
                Icons.thermostat,
                _geo.getCurrentContextLabel() ?? '—',
                'Context',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: O2Colors.neonCyan, size: 14),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 9)),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        _mapBtn(Icons.add, () => setState(() => _scale = (_scale * 1.3).clamp(0.5, 5.0))),
        const SizedBox(height: 4),
        _mapBtn(Icons.remove, () => setState(() => _scale = (_scale / 1.3).clamp(0.5, 5.0))),
        const SizedBox(height: 4),
        _mapBtn(Icons.my_location, () => setState(() {
              _scale = 1.0;
              _offset = Offset.zero;
            })),
      ],
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: O2Colors.neonCyan.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: O2Colors.neonCyan, size: 16),
      ),
    );
  }
}

// ─── Grid Painter ─────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D1FF).withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ─── Map Painter ──────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  final List<Map<String, double>> heatmap;
  final List<Map<String, double>> path;
  final List<GeoFence> fences;
  final List<PlaceCluster> clusters;
  final Map<String, double>? currentPos;
  final double pulse;
  final double pathProgress;
  final double scale;
  final Offset offset;

  _MapPainter({
    required this.heatmap,
    required this.path,
    required this.fences,
    required this.clusters,
    required this.currentPos,
    required this.pulse,
    required this.pathProgress,
    required this.scale,
    required this.offset,
  });

  // Project geo coords to canvas coords
  Offset _project(double lat, double lng, Size size,
      double centerLat, double centerLng, double metersPerPixel) {
    final x = (lng - centerLng) / metersPerPixel * 111320 * math.cos(_rad(centerLat));
    final y = -(lat - centerLat) / metersPerPixel * 111320;
    return Offset(
      size.width / 2 + x * scale + offset.dx,
      size.height / 2 + y * scale + offset.dy,
    );
  }

  double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    // Determine center
    double centerLat = 0, centerLng = 0;
    if (currentPos != null) {
      centerLat = currentPos!['lat']!;
      centerLng = currentPos!['lng']!;
    } else if (clusters.isNotEmpty) {
      centerLat = clusters.first.lat;
      centerLng = clusters.first.lng;
    } else if (path.isNotEmpty) {
      centerLat = path.last['lat']!;
      centerLng = path.last['lng']!;
    } else {
      _drawNoData(canvas, size);
      return;
    }

    const metersPerPixel = 0.0001; // zoom level

    // ── Heatmap ──────────────────────────────────────────────────────────────
    for (final h in heatmap) {
      final pos = _project(h['lat']!, h['lng']!, size, centerLat, centerLng, metersPerPixel);
      final intensity = h['intensity']!;
      final radius = 20.0 + intensity * 40;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(const Color(0xFF00D1FF), const Color(0xFFFF0057), intensity)!
                .withValues(alpha: 0.5 * intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: radius));
      canvas.drawCircle(pos, radius, paint);
    }

    // ── Travel Path ───────────────────────────────────────────────────────────
    if (path.length >= 2) {
      final pathPaint = Paint()
        ..color = const Color(0xFF00D1FF).withValues(alpha: 0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final pathObj = Path();
      final visibleCount = (path.length * pathProgress).round().clamp(1, path.length);
      final first = _project(path[0]['lat']!, path[0]['lng']!, size, centerLat, centerLng, metersPerPixel);
      pathObj.moveTo(first.dx, first.dy);
      for (int i = 1; i < visibleCount; i++) {
        final p = _project(path[i]['lat']!, path[i]['lng']!, size, centerLat, centerLng, metersPerPixel);
        pathObj.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(pathObj, pathPaint);
    }

    // ── Geo-Fence Rings ───────────────────────────────────────────────────────
    for (final fence in fences) {
      final pos = _project(fence.lat, fence.lng, size, centerLat, centerLng, metersPerPixel);
      final r = fence.radiusMeters * scale * 0.01;

      // Animated ring
      final ringPaint = Paint()
        ..color = const Color(0xFFBF00FF).withValues(alpha: 0.3 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(pos, r * pulse, ringPaint);

      // Solid inner ring
      final innerPaint = Paint()
        ..color = const Color(0xFFBF00FF).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, r * 0.8, innerPaint);

      // Label
      _drawLabel(canvas, pos + Offset(0, -r - 8), fence.name,
          const Color(0xFFBF00FF));
    }

    // ── Cluster Pins ──────────────────────────────────────────────────────────
    for (final cluster in clusters) {
      final pos = _project(cluster.lat, cluster.lng, size, centerLat, centerLng, metersPerPixel);
      final r = 6.0 + cluster.heatIntensity * 10;

      final pinPaint = Paint()
        ..color = Color.lerp(
            const Color(0xFF00D1FF), const Color(0xFFFF0057), cluster.heatIntensity)!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, r, pinPaint);

      // Glow
      final glowPaint = Paint()
        ..color = pinPaint.color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos, r * 1.5, glowPaint);

      if (cluster.inferredLabel != null) {
        _drawLabel(canvas, pos + Offset(0, -r - 6), cluster.inferredLabel!,
            pinPaint.color);
      }
    }

    // ── Current Position ──────────────────────────────────────────────────────
    if (currentPos != null) {
      final pos = _project(currentPos!['lat']!, currentPos!['lng']!, size,
          centerLat, centerLng, metersPerPixel);

      // Pulse ring
      final pulsePaint = Paint()
        ..color = const Color(0xFFFF0057).withValues(alpha: 0.4 * (2 - pulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(pos, 16 * pulse, pulsePaint);

      // Dot
      canvas.drawCircle(
          pos,
          8,
          Paint()
            ..color = const Color(0xFFFF0057)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          pos,
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
    }
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawNoData(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(
        text: '📍 No location data yet\nEnable location to see your map',
        style: TextStyle(
          color: Color(0x8800D1FF),
          fontSize: 13,
          height: 1.6,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);
    tp.paint(
        canvas,
        Offset(
            (size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.pulse != pulse ||
      old.pathProgress != pathProgress ||
      old.scale != scale ||
      old.offset != offset ||
      old.heatmap.length != heatmap.length;
}

// ─── GeoFence Creator Widget ──────────────────────────────────────────────────

class GeoFenceCreator extends StatefulWidget {
  final Function(GeoFence) onCreated;

  const GeoFenceCreator({super.key, required this.onCreated});

  @override
  State<GeoFenceCreator> createState() => _GeoFenceCreatorState();
}

class _GeoFenceCreatorState extends State<GeoFenceCreator> {
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  double _radius = 200;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      accentColor: O2Colors.neonPurple,
      showTopAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NeonText('Add Geo-Fence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              glowColor: O2Colors.neonPurple),
          const SizedBox(height: 12),
          _field(_nameCtrl, 'Place name (e.g. Home, Work)'),
          const SizedBox(height: 8),
          _field(_msgCtrl, 'Message when you arrive'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Radius: ', style: TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: _radius,
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  activeColor: O2Colors.neonPurple,
                  label: '${_radius.round()}m',
                  onChanged: (v) => setState(() => _radius = v),
                ),
              ),
              Text('${_radius.round()}m',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FloatingActionChip(
              icon: Icons.add_location,
              label: 'Create Fence',
              color: O2Colors.neonPurple,
              active: true,
              onTap: _create,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: O2Colors.neonPurple.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: O2Colors.neonPurple.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: O2Colors.neonPurple),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  void _create() {
    if (_nameCtrl.text.isEmpty) return;
    final geo = GeoIntelligenceService();
    final pos = geo.lastPosition;
    if (pos == null) return;

    final fence = GeoFence(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      lat: pos.latitude,
      lng: pos.longitude,
      radiusMeters: _radius,
      triggerMessage: _msgCtrl.text.isNotEmpty
          ? _msgCtrl.text
          : 'Welcome to ${_nameCtrl.text}, darling~ 💕',
      createdAt: DateTime.now(),
    );
    geo.addFence(fence);
    widget.onCreated(fence);
    _nameCtrl.clear();
    _msgCtrl.clear();
  }
}
