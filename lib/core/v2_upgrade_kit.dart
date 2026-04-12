import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/widgets/waifu_background.dart';
export '../widgets/waifu_background.dart';

class V2Storage {
  V2Storage._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
          'V2Storage.init() must be awaited before accessing prefs.');
    }
    return prefs;
  }

  static Map<String, dynamic>? getMap(String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (mapKey, value) => MapEntry(mapKey.toString(), value),
        );
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static Future<void> setMap(String key, Map<String, dynamic> value) {
    return prefs.setString(key, jsonEncode(value));
  }

  static List<String> getList(String key) {
    return prefs.getStringList(key) ?? <String>[];
  }

  static Future<void> setList(String key, List<String> value) {
    return prefs.setStringList(key, value);
  }
}

class V2Theme {
  V2Theme._();

  static const Color primaryColor = Color(0xFFFF5B7F);
  static const Color secondaryColor = Color(0xFF5FE2FF);
  static const Color accentColor = Color(0xFFFFC857);
  static const Color surfaceDark = Color(0xFF090F18);
  static const Color surfaceLight = Color(0xFF141E2D);
  static const Color darkGlass = Color(0x66202A3D);
  static const Color borderGlow = Color(0x33FFFFFF);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFF5B7F),
      Color(0xFFFF8E53),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF5FE2FF),
      Color(0xFF83F7B6),
    ],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0x38FFFFFF),
      Color(0x0DFFFFFF),
      Color(0x05FFFFFF),
    ],
  );

  static final BoxDecoration glassDecoration = BoxDecoration(
    gradient: glassGradient,
    color: darkGlass,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: borderGlow),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 36,
        offset: const Offset(0, 18),
      ),
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.08),
        blurRadius: 32,
        spreadRadius: -8,
      ),
    ],
  );
}

extension LinearGradientScaleX on LinearGradient {
  LinearGradient scale(double factor) {
    return LinearGradient(
      begin: begin,
      end: end,
      tileMode: tileMode,
      transform: transform,
      colors: colors
          .map((color) => color.withValues(alpha: color.a * factor))
          .toList(),
      stops: stops,
    );
  }
}

void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: V2Theme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: V2Theme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}

void showUndoSnackbar(
  BuildContext context,
  String message,
  VoidCallback onUndo,
) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: V2Theme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          textColor: V2Theme.secondaryColor,
          onPressed: onUndo,
        ),
      ),
    );
}

class AnimatedEntry extends StatefulWidget {
  const AnimatedEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 0.06),
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final int index;
  final Offset offset;
  final Duration duration;

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      Duration(milliseconds: 70 * widget.index),
      () {
        if (mounted) {
          setState(() => _visible = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : widget.offset,
        child: widget.child,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final decoration = V2Theme.glassDecoration.copyWith(
      boxShadow: <BoxShadow>[
        ...?V2Theme.glassDecoration.boxShadow,
        if (glow)
          BoxShadow(
            color: V2Theme.primaryColor.withValues(alpha: 0.18),
            blurRadius: 36,
            spreadRadius: -2,
          ),
      ],
    );

    final cardBody = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: decoration,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.32),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        V2Theme.secondaryColor.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: margin,
      child: cardBody,
    );

    if (onTap == null) {
      return content;
    }

    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: cardBody,
        ),
      ),
    );
  }
}

bool _useCompactTopSectionLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.height < 820;
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 120,
    this.strokeWidth = 10,
    this.foreground = V2Theme.primaryColor,
    this.background = const Color(0x1FFFFFFF),
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color foreground;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clamped),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _ProgressRingPainter(
              progress: value,
              strokeWidth: strokeWidth,
              foreground: foreground,
              background: background,
            ),
            child: Center(child: child),
          );
        },
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.foreground,
    required this.background,
  });

  final double progress;
  final double strokeWidth;
  final Color foreground;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - strokeWidth) / 2;

    final basePaint = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[V2Theme.primaryColor, V2Theme.secondaryColor],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.28318 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.foreground != foreground ||
        oldDelegate.background != background;
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 12),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class WaifuCommentary extends StatelessWidget {
  const WaifuCommentary({
    super.key,
    this.mood = 'neutral',
    this.text,
    this.themeColor,
  });

  final String mood;
  final String? text;
  final Color? themeColor;

  @override
  Widget build(BuildContext context) {
    var config = _commentary[mood] ?? _commentary['neutral']!;
    if (text != null) {
      config = _CommentaryConfig(
        icon: config.icon,
        title: config.title,
        message: text!,
        gradient: themeColor != null
            ? LinearGradient(colors: <Color>[
                themeColor!,
                themeColor!.withValues(alpha: 0.7)
              ])
            : config.gradient,
      );
    }
    final compact = _useCompactTopSectionLayout(context);
    return GlassCard(
      glow: true,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: compact ? 42 : 52,
            height: compact ? 42 : 52,
            decoration: BoxDecoration(
              gradient: config.gradient,
              borderRadius: BorderRadius.circular(compact ? 14 : 18),
            ),
            child:
                Icon(config.icon, color: Colors.white, size: compact ? 20 : 24),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  config.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 14 : 16,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  config.message,
                  maxLines: compact ? 2 : null,
                  overflow:
                      compact ? TextOverflow.ellipsis : TextOverflow.visible,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    height: 1.35,
                    fontSize: compact ? 12.5 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final Map<String, _CommentaryConfig> _commentary =
      <String, _CommentaryConfig>{
    'achievement': const _CommentaryConfig(
      icon: Icons.workspace_premium,
      title: 'Zero Two Is Proud',
      message:
          'You have real momentum right now, darling. Keep stacking wins while the spark is hot.',
      gradient: V2Theme.primaryGradient,
    ),
    'motivated': const _CommentaryConfig(
      icon: Icons.flash_on,
      title: 'Locked In',
      message:
          'Your focus is sharp. Protect this flow and let the distractions bounce off.',
      gradient: V2Theme.accentGradient,
    ),
    'relaxed': const _CommentaryConfig(
      icon: Icons.self_improvement,
      title: 'Soft Reset',
      message:
          'A slower day is still part of the journey. Recover well and come back stronger.',
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF6DD5ED), Color(0xFF2193B0)],
      ),
    ),
    'neutral': const _CommentaryConfig(
      icon: Icons.favorite,
      title: 'Tiny Steps Count',
      message:
          'You do not need a perfect streak to be improving. One thoughtful action already changes the day.',
      gradient: LinearGradient(
        colors: <Color>[Color(0xFFFF5B7F), Color(0xFFFF8E53)],
      ),
    ),
  };
}

class _CommentaryConfig {
  const _CommentaryConfig({
    required this.icon,
    required this.title,
    required this.message,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String message;
  final Gradient gradient;
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: V2Theme.accentGradient.scale(0.85),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: V2Theme.secondaryColor.withValues(alpha: 0.18),
                    blurRadius: 26,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
            ),
            if (buttonText != null && onButtonPressed != null) ...<Widget>[
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: V2Theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: onButtonPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final compact = _useCompactTopSectionLayout(context);
    return GlassCard(
      margin: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 8,
        vertical: compact ? 4 : 8,
      ),
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: compact ? 36 : 42,
            height: compact ? 36 : 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
            ),
            child: Icon(icon, color: color, size: compact ? 18 : 22),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class V2FloatingActionButton extends StatelessWidget {
  const V2FloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.label,
    this.heroTag,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: V2Theme.primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(icon),
        label: Text(label!),
      );
    }

    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: V2Theme.primaryColor,
      foregroundColor: Colors.white,
      child: Icon(icon),
    );
  }
}

class V2SearchBar extends StatelessWidget {
  const V2SearchBar({
    super.key,
    required this.hintText,
    this.controller,
    this.initialValue,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = _useCompactTopSectionLayout(context);
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      style: TextStyle(
        color: Colors.white,
        fontSize: compact ? 13 : 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.42),
          fontSize: compact ? 13 : 14,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white54,
          size: compact ? 18 : 22,
        ),
        filled: true,
        fillColor: V2Theme.darkGlass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          borderSide: BorderSide.none,
        ),
        isDense: compact,
        contentPadding: EdgeInsets.symmetric(vertical: compact ? 13 : 16),
      ),
    );
  }
}

class SwipeToDismissItem extends StatelessWidget {
  const SwipeToDismissItem({
    super.key,
    required this.child,
    required this.onDismissed,
    this.dismissText = 'Delete',
    this.dismissColor = Colors.redAccent,
  });

  final Widget child;
  final VoidCallback onDismissed;
  final String dismissText;
  final Color dismissColor;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<String>('dismiss_${dismissText}_${child.hashCode}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: V2Theme.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Confirm action',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'This will remove the item from the list.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: dismissColor,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(dismissText),
              ),
            ],
          );
        },
      ),
      onDismissed: (_) => onDismissed(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: dismissColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: dismissColor.withValues(alpha: 0.32)),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(Icons.delete_outline, color: dismissColor),
            const SizedBox(width: 8),
            Text(
              dismissText,
              style: TextStyle(
                color: dismissColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}

class FeaturePageV2 extends StatelessWidget {
  const FeaturePageV2({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    required this.content,
    this.actions,
    this.bottomBar,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget content;
  final List<Widget>? actions;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: bottomBar,
      body: WaifuBackground(
        opacity: 0.10,
        tint: V2Theme.surfaceDark,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white60,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
              // Content
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}



