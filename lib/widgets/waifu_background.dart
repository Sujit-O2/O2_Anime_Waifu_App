import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── Waifu Background Widget ──────────────────────────────────────────────────
// Uses waifu.pics API to show random waifu images/gifs as page backgrounds.
// Falls back gracefully to a gradient if no network.

enum WaifuBgType { sfw, action, waifuGif }

class WaifuBackground extends StatefulWidget {
  final Widget child;
  final WaifuBgType type;
  final double opacity;
  final Color tint;

  const WaifuBackground({
    super.key,
    required this.child,
    this.type = WaifuBgType.sfw,
    this.opacity = 0.22, // was 0.13 — now more vivid
    this.tint = Colors.black,
  });

  @override
  State<WaifuBackground> createState() => _WaifuBackgroundState();
}

class _WaifuBackgroundState extends State<WaifuBackground>
    with SingleTickerProviderStateMixin {
  String? _imageUrl;
  bool _loaded = false;
  late AnimationController _pulseCtrl;

  static const _fallbackUrls = [
    'https://i.waifu.pics/s0TF6gn.jpg',
    'https://i.waifu.pics/YbGFLj0.jpg',
    'https://i.waifu.pics/j7kqSvT.jpg',
    'https://i.waifu.pics/b2VNwkU.jpg',
    'https://i.waifu.pics/lxlKnIT.jpg',
    'https://i.waifu.pics/0d6YXVs.jpg',
  ];

  static const _sfwCategories = [
    'waifu',
    'neko',
    'shinobu',
    'megumin',
    'bully',
    'cuddle',
    'cry',
    'hug',
    'kiss',
    'lick',
    'pat',
    'smug',
    'bonk',
    'blush',
    'smile',
    'wave',
    'bite',
    'glomp',
    'happy',
    'wink',
    'poke',
    'dance',
    'cringe',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _fetchWaifu();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWaifu() async {
    try {
      final category = _sfwCategories[Random().nextInt(_sfwCategories.length)];
      final endpoint = widget.type == WaifuBgType.waifuGif
          ? 'https://api.waifu.pics/sfw/$category'
          : 'https://api.waifu.pics/sfw/waifu';
      final res = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final url = data['url'] as String?;
        if (url != null && mounted) {
          setState(() => _imageUrl = url);
        }
      } else {
        _useFallback();
      }
    } catch (_) {
      _useFallback();
    }
  }

  void _useFallback() {
    if (!mounted) return;
    setState(() {
      _imageUrl = _fallbackUrls[Random().nextInt(_fallbackUrls.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Deep space background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D0826), // deep purple
                Color(0xFF100A22),
                Color(0xFF070D1E), // deep blue-black
              ],
            ),
          ),
        ),

        // Ambient moving pink/purple radial glow (always on)
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final v = _pulseCtrl.value;
            return Positioned(
              top: -60 + v * 30,
              right: -80 + v * 20,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF4D8D).withOpacity(0.12 + v * 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final v = 1.0 - _pulseCtrl.value;
            return Positioned(
              bottom: -40 + v * 20,
              left: -60 + v * 15,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF9B59B6).withOpacity(0.10 + v * 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Waifu image (loaded from waifu.pics or fallback)
        if (_imageUrl != null)
          Positioned.fill(
            child: Opacity(
              opacity: widget.opacity,
              child: _imageUrl!.endsWith('.gif')
                  ? Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )
                  : Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_loaded) {
                              setState(() => _loaded = true);
                            }
                          });
                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 900),
                            opacity: _loaded ? 1.0 : 0.0,
                            child: child,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
            ),
          ),

        // Gradient overlay — bottom-heavy for text readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.tint.withOpacity(0.65),
                  widget.tint.withOpacity(0.45),
                  widget.tint.withOpacity(0.78),
                ],
              ),
            ),
          ),
        ),

        // Main content
        widget.child,
      ],
    );
  }
}
