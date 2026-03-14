import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Microsoft Launcher–inspired animated clock + date widget.
///
/// - Digits flip via [AnimatedSwitcher] with a vertical slide on each second.
/// - Floats gently via an external [Animation<double>] (reuse `_floatController`
///   from main.dart) or falls back to its own internal gentle sway.
/// - Displays date line below with a shimmer gradient on the day name.
/// - Weather string is optional; slides in when non-null.
class LauncherClockWidget extends StatefulWidget {
  /// Optional external float animation value (0.0–1.0, reverse-repeating).
  /// Pass `_floatController.value` from main.dart to sync with the character.
  final double? externalFloatValue;

  /// Optional weather summary e.g. "28°C ☀ Sunny". Slides in when provided.
  final String? weatherSummary;

  final Color primaryColor;
  final Color secondaryColor;

  const LauncherClockWidget({
    super.key,
    this.externalFloatValue,
    this.weatherSummary,
    this.primaryColor = const Color(0xFFFF4D8D),
    this.secondaryColor = const Color(0xFF9B59B6),
  });

  @override
  State<LauncherClockWidget> createState() => _LauncherClockWidgetState();
}

class _LauncherClockWidgetState extends State<LauncherClockWidget>
    with SingleTickerProviderStateMixin {
  late Timer _ticker;
  DateTime _now = DateTime.now();

  // Internal float fallback
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutSine),
    );

    // Tick every second
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _floatCtrl.dispose();
    super.dispose();
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final hStr = _pad(_now.hour);
    final mStr = _pad(_now.minute);
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dayName = dayNames[_now.weekday - 1];
    final dateStr = '$dayName, ${_now.day} ${monthNames[_now.month - 1]}';

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (context, child) {
          final floatVal = widget.externalFloatValue ?? _floatAnim.value;
          final floatY = -4.0 + floatVal * 8.0; // range: -4 to +4 px
          return Transform.translate(
            offset: Offset(0, floatY),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Time Row ───────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _FlipDigits(value: hStr, color: widget.primaryColor),
                _ColonBlink(color: widget.primaryColor),
                _FlipDigits(value: mStr, color: widget.primaryColor),
              ],
            ),

            const SizedBox(height: 4),

            // ── Date Row ───────────────────────────────────────────────
            _ShimmerText(
              text: dateStr,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              fontSize: 13,
            ),

            // ── Weather Row (slides in) ────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: widget.weatherSummary != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.primaryColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            widget.weatherSummary!,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Flip Digits ────────────────────────────────────────────────────────────

class _FlipDigits extends StatelessWidget {
  final String value;
  final Color color;

  const _FlipDigits({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        value,
        key: ValueKey(value),
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.w800,
          height: 1.0,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blinking Colon ─────────────────────────────────────────────────────────

class _ColonBlink extends StatefulWidget {
  final Color color;
  const _ColonBlink({required this.color});

  @override
  State<_ColonBlink> createState() => _ColonBlinkState();
}

class _ColonBlinkState extends State<_ColonBlink>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          ':',
          style: GoogleFonts.outfit(
            color: widget.color.withValues(alpha: 0.5 + _ctrl.value * 0.5),
            fontSize: 44,
            fontWeight: FontWeight.w300,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ── Shimmer Text ───────────────────────────────────────────────────────────

/// Sweeps a bright highlight across text using a ShaderMask.
/// Zero extra animation controllers — share any existing 0→1 animation.
class _ShimmerText extends StatefulWidget {
  final String text;
  final Color primaryColor;
  final Color secondaryColor;
  final double fontSize;

  const _ShimmerText({
    required this.text,
    required this.primaryColor,
    required this.secondaryColor,
    this.fontSize = 14,
  });

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _anim = Tween<double>(begin: -0.3, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final shimPos = _anim.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              widget.primaryColor,
              Colors.white,
              widget.primaryColor,
            ],
            stops: [
              (shimPos - 0.25).clamp(0.0, 1.0),
              shimPos.clamp(0.0, 1.0),
              (shimPos + 0.25).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child!,
        );
      },
      child: Text(
        widget.text,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Public re-export so other widgets can use ShimmerText easily.
class ShimmerLabel extends StatelessWidget {
  final String text;
  final Color primaryColor;
  final Color? secondaryColor;
  final double fontSize;
  final FontWeight fontWeight;

  const ShimmerLabel({
    super.key,
    required this.text,
    required this.primaryColor,
    this.secondaryColor,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerText(
      text: text,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor ?? primaryColor.withValues(alpha: 0.6),
      fontSize: fontSize,
    );
  }
}
