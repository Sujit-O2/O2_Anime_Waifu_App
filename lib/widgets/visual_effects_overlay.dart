import 'dart:math' as math;

import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/material.dart';

class VisualEffectsOverlay extends StatefulWidget {
  final Widget child;
  final AppThemeMode themeMode;

  const VisualEffectsOverlay({
    super.key,
    required this.child,
    required this.themeMode,
  });

  @override
  State<VisualEffectsOverlay> createState() => _VisualEffectsOverlayState();
}

class _VisualEffectsOverlayState extends State<VisualEffectsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _effectController;

  @override
  void initState() {
    super.initState();
    _effectController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _effectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _effectController,
              builder: (context, _) {
                final intensity =
                    AppThemes.getEdgeGlowIntensity(widget.themeMode);
                if (intensity <= 0) return const SizedBox.shrink();

                final theme = AppThemes.getTheme(widget.themeMode);
                final pulse =
                    0.5 + 0.5 * math.sin(_effectController.value * 2 * math.pi);

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.primaryColor
                          .withOpacity(intensity * pulse * 0.15),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor
                            .withOpacity(intensity * pulse * 0.2),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _effectController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CinemaPainter(
                    widget.themeMode,
                    _effectController.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CinemaPainter extends CustomPainter {
  final AppThemeMode mode;
  final double animation;

  _CinemaPainter(this.mode, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random();

    final grainIntensity = AppThemes.getGrainIntensity(mode);
    if (grainIntensity > 0) {
      for (int i = 0; i < 1000; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final op = random.nextDouble() * grainIntensity;
        paint.color = Colors.white.withOpacity(op);
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }

    if (AppThemes.hasScanlines(mode)) {
      paint.color = Colors.black.withOpacity(0.05);
      paint.strokeWidth = 1.0;
      final scroll = animation * 8.0;
      for (double y = scroll; y < size.height; y += 4.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CinemaPainter oldDelegate) => true;
}
