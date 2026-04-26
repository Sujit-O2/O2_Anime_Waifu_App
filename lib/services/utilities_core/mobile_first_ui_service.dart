import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mobile-first UI service: Haptic feedback, responsive layouts, dark mode
class MobileFirstUiService {
  static final MobileFirstUiService _instance =
      MobileFirstUiService._internal();
  factory MobileFirstUiService() => _instance;
  MobileFirstUiService._internal();

  // ── Haptic Feedback ──────────────────────────────────────────────────────

  /// Light tap feedback (common for buttons)
  static Future<void> lightTap() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium feedback (for confirmations)
  static Future<void> mediumTap() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy feedback (for important actions)
  static Future<void> heavyTap() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Success vibration pattern (short patterns)
  static Future<void> success() async {
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Error vibration pattern
  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Selection vibration
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  // ── Responsive Layout Helpers ────────────────────────────────────────────

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// Check if device is tablet (width > 600)
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 600;
  }

  /// Get optimal column count for grid
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return 2;
    if (width < 600) return 3;
    if (width < 900) return 4;
    return 5;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return const EdgeInsets.all(12);
    if (width < 600) return const EdgeInsets.all(16);
    return const EdgeInsets.all(24);
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobileSize = 14,
    double tabletSize = 16,
    double desktopSize = 18,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return mobileSize;
    if (width < 900) return tabletSize;
    return desktopSize;
  }

  // ── Dark Mode Support ────────────────────────────────────────────────────

  /// Get optimal text color based on background brightness
  static Color getOptimalTextColor(Color backgroundColor) {
    final brightness =
        ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.light
        ? Colors.black87
        : Colors.white;
  }

  /// Get high-contrast text for visibility
  static TextStyle getAccessibleTextStyle(
    TextStyle baseStyle,
    Color backgroundColor,
  ) {
    final textColor = getOptimalTextColor(backgroundColor);
    return baseStyle.copyWith(
      color: textColor,
      shadows: [
        Shadow(
          color:
              textColor == Colors.white ? Colors.black : Colors.white,
          blurRadius: 2,
        ),
      ],
    );
  }

  // ── Safe Area Helpers ────────────────────────────────────────────────────

  /// Get safe area padding for notched devices
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  /// Check if device has notch
  static bool hasNotch(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.top > 30 || mediaQuery.padding.bottom > 30;
  }
}

// ── Responsive Widget ────────────────────────────────────────────────────

/// Widget that adapts to portrait/landscape
class ResponsiveLayout extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;
  final Widget? tablet;

  const ResponsiveLayout({
    super.key,
    required this.portrait,
    required this.landscape,
    this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTabletDevice = MediaQuery.sizeOf(context).width > 600;

    if (isTabletDevice && !isLandscape && tablet != null) {
      return tablet!;
    }

    return isLandscape ? landscape : portrait;
  }
}

// ── Haptic Button Widget ─────────────────────────────────────────────────

/// Button with haptic feedback built-in
class HapticButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final HapticFeedbackType feedbackType;

  const HapticButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.feedbackType = HapticFeedbackType.light,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        switch (feedbackType) {
          case HapticFeedbackType.light:
            await MobileFirstUiService.lightTap();
          case HapticFeedbackType.medium:
            await MobileFirstUiService.mediumTap();
          case HapticFeedbackType.heavy:
            await MobileFirstUiService.heavyTap();
          case HapticFeedbackType.success:
            await MobileFirstUiService.success();
        }
        onPressed();
      },
      child: child,
    );
  }
}

enum HapticFeedbackType { light, medium, heavy, success }


