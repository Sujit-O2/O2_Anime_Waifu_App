import 'dart:math';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/material.dart';

enum WaifuBgType { sfw, action, waifuGif }

class WaifuBackground extends StatefulWidget {
  const WaifuBackground({
    super.key,
    required this.child,
    this.type = WaifuBgType.sfw,
    this.opacity = 0.12,
    this.tint = Colors.black,
    this.animated = false,
  });

  final Widget child;
  final WaifuBgType type;
  final double opacity;
  final Color tint;
  final bool animated;

  @override
  State<WaifuBackground> createState() => _WaifuBackgroundState();
}

class _WaifuBackgroundState extends State<WaifuBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseCtrl;
  late final String _assetPath;

  static const List<String> _sfwAssets = [
    'assets/img/bg.jpg',
    'assets/img/bg2.jpg',
    'assets/img/z2s.jpg',
    'assets/img/z12.jpg',
  ];

  static const List<String> _actionAssets = [
    'assets/img/bll.jpg',
    'assets/img/front.png',
    'assets/img/bg2.jpg',
  ];

  static const List<String> _gifAssets = [
    'assets/gif/background_of_about_section_blurry.gif',
    'assets/gif/sidebar_bg.gif',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 16),
      )..repeat(reverse: true);
    }
    _assetPath = _pickAsset();
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  String _pickAsset() {
    final random = Random();
    final pool = switch (widget.type) {
      WaifuBgType.action => _actionAssets,
      WaifuBgType.waifuGif => _gifAssets,
      WaifuBgType.sfw => _sfwAssets,
    };
    return pool[random.nextInt(pool.length)];
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animated || _pulseCtrl == null) {
      return _buildScene(context, 0.5);
    }
    return AnimatedBuilder(
      animation: _pulseCtrl!,
      builder: (context, _) => _buildScene(context, _pulseCtrl!.value),
    );
  }

  Widget _buildScene(BuildContext context, double wave) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: tokens.heroGradient),
        ),
        Positioned(
          top: -80 + wave * 28,
          right: -50 + wave * 18,
          child: _Orb(
            size: 260,
            colors: [
              theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              Colors.transparent,
            ],
          ),
        ),
        Positioned(
          left: -70 + (1 - wave) * 18,
          bottom: -60 + (1 - wave) * 22,
          child: _Orb(
            size: 240,
            colors: [
              theme.colorScheme.tertiary
                  .withValues(alpha: isDark ? 0.16 : 0.08),
              Colors.transparent,
            ],
          ),
        ),
        Positioned(
          top: 80 - wave * 12,
          left: 40 + wave * 10,
          child: _Orb(
            size: 180,
            colors: [
              theme.colorScheme.secondary
                  .withValues(alpha: isDark ? 0.10 : 0.06),
              Colors.transparent,
            ],
          ),
        ),
        Positioned.fill(
          child: RepaintBoundary(
            child: Opacity(
              opacity: widget.opacity,
              child: Image.asset(
                _assetPath,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.05),
                cacheWidth: 720,
                filterQuality: FilterQuality.low,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.tint.withValues(alpha: isDark ? 0.72 : 0.28),
                  widget.tint.withValues(alpha: isDark ? 0.52 : 0.10),
                  widget.tint.withValues(alpha: isDark ? 0.82 : 0.36),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.onSurface
                        .withValues(alpha: isDark ? 0.03 : 0.02),
                    Colors.transparent,
                    theme.colorScheme.shadow
                        .withValues(alpha: isDark ? 0.12 : 0.04),
                  ],
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
