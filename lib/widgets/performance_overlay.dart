import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

/// A debug-only FPS and performance overlay that shows real-time
/// frame rate information. Only visible in debug mode.
///
/// Usage: Place at the top of your widget tree stack:
/// ```dart
/// Stack(children: [
///   YourApp(),
///   if (kDebugMode) const PerformanceOverlay(),
/// ])
/// ```
class PerformanceOverlay extends StatefulWidget {
  const PerformanceOverlay({super.key});

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final List<double> _frameTimes = [];
  DateTime _lastFrame = DateTime.now();
  Timer? _updateTimer;
  double _fps = 0;
  double _avgFrameTime = 0;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    if (!kDebugMode) return;

    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_frameTimes.isEmpty) return;
      setState(() {
        _fps = _frameTimes.length.toDouble();
        _avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
        _frameTimes.clear();
      });
    });
  }

  void _onFrame(Duration _) {
    if (!mounted) return;
    final now = DateTime.now();
    final delta = now.difference(_lastFrame).inMicroseconds / 1000.0;
    _lastFrame = now;
    if (delta > 0 && delta < 200) {
      _frameTimes.add(delta);
    }
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Color get _fpsColor {
    if (_fps >= 55) return Colors.greenAccent;
    if (_fps >= 40) return Colors.amberAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 4,
      right: 8,
      child: GestureDetector(
        onTap: () => setState(() => _visible = !_visible),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _visible ? 0.85 : 0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _fpsColor.withValues(alpha: 0.3)),
            ),
            child: _visible
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed_rounded, color: _fpsColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${_fps.toInt()} FPS',
                        style: GoogleFonts.firaCode(
                          color: _fpsColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_avgFrameTime.toStringAsFixed(1)}ms',
                        style: GoogleFonts.firaCode(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  )
                : Icon(Icons.speed_rounded, color: _fpsColor, size: 12),
          ),
        ),
      ),
    );
  }
}
