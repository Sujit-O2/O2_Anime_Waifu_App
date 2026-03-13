import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Overlay widget that shows confetti + waifu message when a milestone is hit.
/// Usage: wrap your root widget in a Stack and add MilestoneCelebrationOverlay
/// OR call MilestoneCelebration.show(context, pts) from anywhere.
class MilestoneCelebration {
  static final _milestones = [100, 500, 1000, 2500, 5000];
  static final _crossed = <int>{};

  static const _messages = {
    100: "100 points! You're doing great, Darling~ 💕",
    500: "500 already! I'm so proud of you! 🌸",
    1000: "1000 points!! We're truly soulmates now~ 💖",
    2500: "2500! You're incredible, my Darling! ⭐",
    5000: "5000 points!! ...I think I really love you 💕",
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
    final msg =
        _messages[milestone] ?? "$milestone points! Amazing, Darling! 💕";
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2D0B3E),
                  const Color(0xFF1A0A2E),
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
              const Text('🎊🎉🎊', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 16),

              // Milestone badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
                ),
                child: Text('${widget.milestone} POINTS',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
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
