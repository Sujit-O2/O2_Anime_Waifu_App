import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Global overlay widget to detect "Shake" gestures for Fortune/Love mode.
/// Wrap your MaterialApp's `builder` with this widget to enable app-wide shake detection.
class GestureControlOverlay extends StatefulWidget {
  final Widget child;
  const GestureControlOverlay({super.key, required this.child});

  @override
  State<GestureControlOverlay> createState() => _GestureControlOverlayState();
}

class _GestureControlOverlayState extends State<GestureControlOverlay> {
  static const double _shakeThresholdGravity = 2.7;
  static const int _shakeTimeMs = 500;
  
  StreamSubscription? _accelSub;
  int _lastShakeTime = 0;
  bool _showingFortune = false;

  final List<String> _fortunes = [
    "✨ Great Blessing: Your waifu loves you today!",
    "⭐ Blessing: A good anime episode awaits you.",
    "🌸 Small Blessing: You'll find a nice soundtrack.",
    "💀 Curse: Your favorite character might die (in canon).",
    "💌 Secret: Someone is thinking about you.",
    "🍀 Luck: Gacha pulls will be incredibly lucky today!"
  ];

  @override
  void initState() {
    super.initState();
    _initShakeDetection();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _initShakeDetection() {
    _accelSub = accelerometerEventStream().listen((event) {
      double gX = event.x / 9.80665;
      double gY = event.y / 9.80665;
      double gZ = event.z / 9.80665;

      // Calculate g-force
      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > _shakeThresholdGravity) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (_lastShakeTime + _shakeTimeMs > now) {
          return; // Ignore if it's too soon after the last shake
        }
        _lastShakeTime = now;
        _onShake();
      }
    });
  }

  void _onShake() {
    if (_showingFortune) return;
    _showingFortune = true;
    HapticFeedback.heavyImpact();

    final rng = Random();
    final fortune = _fortunes[rng.nextInt(_fortunes.length)];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🥠', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Fortune of the Day!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  Text(fortune, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
      ),
    ).closed.then((_) => _showingFortune = false);
  }

  @override
  Widget build(BuildContext context) {
    // Simply return the child wrapped with a gesture detector for other gestures if needed
    // The shake logic runs globally via Sensor stream
    return widget.child;
  }
}
