import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── PageIndicator ─────────────────────────────────────────────────────────────
// Animated dot indicator for the multi-page home screen.
// ─────────────────────────────────────────────────────────────────────────────

class PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color activeColor;

  const PageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: active
                ? activeColor
                : Colors.white.withValues(alpha: 0.25),
            boxShadow: active
                ? [BoxShadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 8)]
                : [],
          ),
        );
      }),
    );
  }
}

// ── HomePageLabel ─────────────────────────────────────────────────────────────
// Small fade-in label that shows when swiping to a new page
class HomePageLabel extends StatelessWidget {
  final String label;
  final Color color;
  const HomePageLabel({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: color.withValues(alpha: 0.7),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}
