import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Overlay widget that shows confetti + waifu message when a milestone is hit.
/// Usage: wrap your root widget in a Stack and add MilestoneCelebrationOverlay
/// OR call MilestoneCelebration.show(context, pts) from anywhere.
class MilestoneCelebration {
  static final _milestones = [100, 500, 1000, 2500, 5000, 7500, 10000];
  static final _crossed = <int>{};

  static const _messages = {
    100: "100 points! You're doing great, Darling~ 💕",
    500: "500 already! I'm so proud of you! 🌸",
    1000: "1000 points!! We're truly soulmates now~ 💖",
    2500: "2500! You're incredible, my Darling! ⭐",
    5000: '5000 points!! ...I think I really love you 💕',
    7500: '7500! Our bond transcends dimensions, Darling~ 🌟',
    10000: "10000!! We've reached the ultimate bond... forever yours 💖✨",
  };

  /// Call this after every addPoints() call passing the new total.
  /// Returns the milestone crossed, or null if none.
  static int? check(int newPoints) {
    for (final m in _milestones) {
      if (newPoints >= m && !_crossed.contains(m)) {
        _crossed.add(m);
        return m;
      }
    }
    return null;
  }

  /// Show a fullscreen celebration dialog for a milestone.
  static void show(BuildContext context, int milestone) {
    HapticFeedback.heavyImpact();
    final msg =
        _messages[milestone] ?? '$milestone points! Amazing, Darling! 💕';
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) =>
          _MilestoneCelebrationDialog(milestone: milestone, message: msg),
    );
  }
}

class _MilestoneCelebrationDialog extends StatefulWidget {
  final int milestone;
  final String message;
  const _MilestoneCelebrationDialog(
      {required this.milestone, required this.message});

  @override
  State<_MilestoneCelebrationDialog> createState() =>
      _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState
    extends State<_MilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D0B3E),
                  Color(0xFF1A0A2E),
                ],
              ),
              border: Border.all(
                  color: Colors.pinkAccent.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Confetti emoji row
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (_, val, child) => Transform.scale(
                  scale: val,
                  child: child,
                ),
                child: Text(
                  widget.milestone >= 5000 ? '🏆🎊✨🎊🏆' : '🎊🎉🎊',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 16),

              // Milestone badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                      colors: widget.milestone >= 5000
                          ? const [Color(0xFFFFD700), Color(0xFFFF8C00)]
                          : const [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
                ),
                child: Text('${widget.milestone} POINTS',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
              ),
              const SizedBox(height: 8),
              Text(
                widget.milestone >= 5000
                    ? '🏆 Legendary Tier!'
                    : '⭐ Keep going!',
                style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              Text('MILESTONE REACHED!',
                  style: GoogleFonts.outfit(
                      color: Colors.white54, fontSize: 11, letterSpacing: 3)),
              const SizedBox(height: 12),

              // Waifu message
              Text(widget.message,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),

              // Close
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Thank you, Zero Two! 💕',
                    style: GoogleFonts.outfit(
                        color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Lightweight confetti particle for milestone celebrations.
/// Renders emoji confetti that bursts upward and falls with gravity.
class ConfettiOverlay extends StatefulWidget {
  final List<String> emojis;
  final int count;
  final Duration duration;

  const ConfettiOverlay({
    super.key,
    this.emojis = const ['🎉', '✨', '🌟', '💖', '🎊', '⭐'],
    this.count = 30,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(
        widget.count,
        (_) => _ConfettiParticle(
              x: 0.3 + rng.nextDouble() * 0.4,
              y: 0.9,
              vx: (rng.nextDouble() - 0.5) * 0.02,
              vy: -(0.015 + rng.nextDouble() * 0.02),
              emoji: widget.emojis[rng.nextInt(widget.emojis.length)],
              size: 14.0 + rng.nextDouble() * 14.0,
              rotation: rng.nextDouble() * 6.28,
              rotSpeed: (rng.nextDouble() - 0.5) * 0.1,
            ));

    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_tick)
      ..forward();
  }

  void _tick() {
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.0004; // gravity
      p.rotation += p.rotSpeed;
      p.opacity = (1.0 - _ctrl.value).clamp(0.0, 1.0);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: _particles
              .map((p) => Positioned(
                    left: p.x * size.width,
                    top: p.y * size.height,
                    child: Transform.rotate(
                      angle: p.rotation,
                      child: Opacity(
                        opacity: p.opacity,
                        child:
                            Text(p.emoji, style: TextStyle(fontSize: p.size)),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  double x, y, vx, vy, size, rotation, rotSpeed, opacity;
  String emoji;
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.emoji,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
  }) : opacity = 1.0;
}
