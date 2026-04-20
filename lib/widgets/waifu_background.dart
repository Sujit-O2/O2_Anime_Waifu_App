import 'dart:math';

import 'package:flutter/material.dart';

enum WaifuBgType { sfw, action, waifuGif }

class WaifuBackground extends StatefulWidget {
  const WaifuBackground({
    super.key,
    required this.child,
    this.type = WaifuBgType.sfw,
    this.opacity = 0.22,
    this.tint = Colors.black,
  });

  final Widget child;
  final WaifuBgType type;
  final double opacity;
  final Color tint;

  @override
  State<WaifuBackground> createState() => _WaifuBackgroundState();
}

class _WaifuBackgroundState extends State<WaifuBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
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
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _assetPath = _pickAsset();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
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
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final wave = _pulseCtrl.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF070B14),
                    Color(0xFF101827),
                    Color(0xFF1A0E21),
                    Color(0xFF06080F),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -80 + wave * 28,
              right: -50 + wave * 18,
              child: _Orb(
                size: 260,
                colors: [
                  const Color(0xFFFF5B7F).withValues(alpha: 0.18),
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
                  const Color(0xFF5FE2FF).withValues(alpha: 0.16),
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
                  const Color(0xFFFFC857).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: widget.opacity,
                child: Transform.scale(
                  scale: 1.03 + wave * 0.02,
                  child: Image.asset(
                    _assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment(0, -0.1 + wave * 0.1),
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
                      widget.tint.withValues(alpha: 0.54),
                      widget.tint.withValues(alpha: 0.26),
                      widget.tint.withValues(alpha: 0.72),
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
                        Colors.white.withValues(alpha: 0.03),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
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


