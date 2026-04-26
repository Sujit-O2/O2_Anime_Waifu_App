import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium styled tooltip that matches the O2-WAIFU dark theme.
/// Use instead of default Flutter Tooltip for consistent styling.
///
/// ```dart
/// O2Tooltip(
///   message: 'Copy to clipboard',
///   child: IconButton(icon: Icon(Icons.copy), onPressed: copy),
/// )
/// ```
class O2Tooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final bool preferBelow;

  const O2Tooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      textStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE6161625),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: child,
    );
  }
}
