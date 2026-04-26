import 'package:flutter/services.dart';

/// Centralized haptic feedback patterns for O2-WAIFU.
/// Provides consistent, meaningful tactile feedback across the app.
///
/// Usage:
/// ```dart
/// O2Haptics.tap();       // Light tap for selections
/// O2Haptics.success();   // Medium impact for confirmations
/// O2Haptics.error();     // Heavy impact for errors
/// O2Haptics.warning();   // Double tap for warnings
/// ```
abstract final class O2Haptics {
  /// Light tap — use for item selections, toggles, tabs
  static void tap() => HapticFeedback.selectionClick();

  /// Light impact — use for button presses, menu opens
  static void light() => HapticFeedback.lightImpact();

  /// Medium impact — use for confirmations, saves, sends
  static void success() => HapticFeedback.mediumImpact();

  /// Heavy impact — use for errors, deletions, critical actions
  static void error() => HapticFeedback.heavyImpact();

  /// Double vibration pattern — use for warnings, alerts
  static Future<void> warning() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  }

  /// Triple vibration — use for achievements, milestones
  static Future<void> celebration() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.lightImpact();
  }

  /// Notification vibration — use for incoming messages
  static Future<void> notification() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.lightImpact();
  }
}
