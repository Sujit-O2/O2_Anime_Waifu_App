import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/material.dart';

class VisualEffectsOverlay extends StatelessWidget {
  final Widget child;
  final AppThemeMode themeMode;
  final bool isSpeaking;

  const VisualEffectsOverlay({
    super.key,
    required this.child,
    required this.themeMode,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final intensity = AppThemes.getEdgeGlowIntensity(themeMode);
    final theme = AppThemes.getTheme(themeMode);

    return Stack(
      children: [
        RepaintBoundary(child: child),
        if (intensity > 0 || isSpeaking)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSpeaking
                        ? theme.primaryColor.withValues(alpha: 0.8)
                        : theme.primaryColor
                            .withValues(alpha: intensity * 0.08),
                    width: isSpeaking ? 3.0 : 1.5,
                  ),
                  boxShadow: [
                    if (isSpeaking)
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 2,
                      )
                    else if (intensity > 0)
                      BoxShadow(
                        color: theme.primaryColor
                            .withValues(alpha: intensity * 0.12),
                        blurRadius: 14,
                        spreadRadius: -4,
                      ),
                  ],
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _CinemaPainter(themeMode),
                isComplex: false,
                willChange: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CinemaPainter extends CustomPainter {
  final AppThemeMode mode;

  _CinemaPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final grainIntensity = AppThemes.getGrainIntensity(mode);
    if (grainIntensity > 0) {
      const grainSamples = 96;
      for (int i = 0; i < grainSamples; i++) {
        final x = ((i * 57) % 997) / 997 * size.width;
        final y = ((i * 131) % 991) / 991 * size.height;
        final op = (((i * 37) % 100) / 100) * grainIntensity * 0.32;
        paint.color = Colors.white.withValues(alpha: op);
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }

    if (AppThemes.hasScanlines(mode)) {
      paint.color = Colors.black.withValues(alpha: 0.04);
      paint.strokeWidth = 1.0;
      for (double y = 0; y < size.height; y += 8.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CinemaPainter oldDelegate) =>
      oldDelegate.mode != mode;
}
