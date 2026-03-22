import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

/// A vibrant Zero Two welcome card with floating hearts animation.
/// Drop this anywhere in the app to add life and personality.
class ZeroTwoWelcomeCard extends StatefulWidget {
  final String? greeting;
  final String? subtitle;
  final bool compact;

  const ZeroTwoWelcomeCard({
    super.key,
    this.greeting,
    this.subtitle,
    this.compact = false,
  });

  @override
  State<ZeroTwoWelcomeCard> createState() => _ZeroTwoWelcomeCardState();
}

class _ZeroTwoWelcomeCardState extends State<ZeroTwoWelcomeCard>
    with TickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  final _rng = Random(42);
  late List<_HeartParticle> _hearts;

  String get _greeting {
    if (widget.greeting != null) return widget.greeting!;
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still awake, Darling? 🌙';
    if (hour < 12) return 'Good morning, Darling~ ☀️';
    if (hour < 17) return 'Hello there, Darling! 💕';
    if (hour < 21) return 'Good evening, Darling~ 🌸';
    return 'Good night... Darling 💤';
  }

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _hearts = List.generate(12, (i) => _HeartParticle(rng: _rng));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildFull() {
    return AnimatedBuilder(
      animation: Listenable.merge([_heartCtrl, _glowCtrl, _floatCtrl]),
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Floating avatar with hearts ──────────────────────────────
              SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Ambient glow ring
                    Transform.scale(
                      scale: 1.0 + _glowCtrl.value * 0.06,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF4D8D).withOpacity(0.25 + _glowCtrl.value * 0.12),
                              const Color(0xFF9B59B6).withOpacity(0.10),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Avatar circle
                    Transform.translate(
                      offset: Offset(0, -4 + _floatCtrl.value * 6),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4D8D), Color(0xFF9B59B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4D8D).withOpacity(0.4 + _glowCtrl.value * 0.2),
                              blurRadius: 20 + _glowCtrl.value * 10,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/img/bg.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Floating hearts
                    ..._hearts.map((h) {
                      final t = (_heartCtrl.value + h.offset) % 1.0;
                      final x = h.x * 160 - 80;
                      final y = 60 - t * 160;
                      final opacity = t < 0.3
                          ? t / 0.3
                          : t > 0.7
                              ? (1.0 - t) / 0.3
                              : 1.0;
                      return Positioned(
                        left: 90 + x,
                        top: 90 + y,
                        child: Opacity(
                          opacity: (opacity * h.alpha).clamp(0.0, 1.0),
                          child: Text(
                            h.emoji,
                            style: TextStyle(fontSize: h.size),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Greeting text ────────────────────────────────────────────
              Text(
                _greeting,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFF4D8D).withOpacity(0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Subtitle ─────────────────────────────────────────────────
              Text(
                widget.subtitle ??
                    'Say something, Darling~\nI\'m always here for you 💕',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // ── Quick action pills ───────────────────────────────────────
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill('💬 Chat', const Color(0xFFFF4D8D)),
                  _pill('🎯 Daily', const Color(0xFF9B59B6)),
                  _pill('🎮 Games', const Color(0xFF3498DB)),
                  _pill('🎵 Music', const Color(0xFF1abc9c)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompact() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF4D8D).withOpacity(0.10),
                const Color(0xFF9B59B6).withOpacity(0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF4D8D).withOpacity(0.25 + _glowCtrl.value * 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D8D).withOpacity(0.06 + _glowCtrl.value * 0.04),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Text('🌸', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.subtitle ?? 'Zero Two is ready, Darling~',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeartParticle {
  final double x;
  final double offset;
  final double size;
  final double alpha;
  final String emoji;

  _HeartParticle({required Random rng})
      : x = rng.nextDouble(),
        offset = rng.nextDouble(),
        size = 8 + rng.nextDouble() * 10,
        alpha = 0.4 + rng.nextDouble() * 0.5,
        emoji = ['❤️', '💕', '💗', '🌸', '✨', '💖'][rng.nextInt(6)];
}
