import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/widgets/premium_ui_kit.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM DIALOGS & MODALS
/// ═══════════════════════════════════════════════════════════════════════════

class PremiumDialogs {
  /// Show confirmation dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          PremiumButton(
            text: cancelText,
            isSecondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(width: 8),
          PremiumButton(
            text: confirmText,
            isDestructive: isDestructive,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  /// Show info dialog
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          PremiumButton(
            text: buttonText,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  static Future<void> showError({
    required BuildContext context,
    String title = 'Error',
    required String message,
    String buttonText = 'OK',
  }) {
    final theme = Theme.of(context);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: theme.colorScheme.error, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          PremiumButton(
            text: buttonText,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Show success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    String title = 'Success',
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          PremiumButton(
            text: buttonText,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Show loading dialog
  static void showLoading({
    required BuildContext context,
    String message = 'Loading...',
  }) {
    final tokens = context.appTokens;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(strokeWidth: 2.5),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.outfit(
                    color: tokens.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show input dialog
  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String? message,
    String? hintText,
    String? initialValue,
    String confirmText = 'Submit',
    String cancelText = 'Cancel',
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(
                message,
                style: GoogleFonts.outfit(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            PremiumTextField(
              controller: controller,
              hintText: hintText,
              keyboardType: keyboardType,
              maxLines: maxLines,
            ),
          ],
        ),
        actions: [
          PremiumButton(
            text: cancelText,
            isSecondary: true,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          PremiumButton(
            text: confirmText,
            onPressed: () => Navigator.pop(context, controller.text),
          ),
        ],
      ),
    );
  }

  /// Show bottom sheet picker
  static Future<T?> showPicker<T>({
    required BuildContext context,
    required String title,
    required List<PickerItem<T>> items,
    T? selectedValue,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        child: GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const PremiumDivider(hasGradient: true),
              ...items.map((item) {
                final isSelected = item.value == selectedValue;
                return PremiumListTile(
                  leadingIcon: item.icon,
                  title: item.label,
                  subtitle: item.subtitle,
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                          color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, item.value),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Show action sheet
  static Future<T?> showActionSheet<T>({
    required BuildContext context,
    required String title,
    String? message,
    required List<ActionSheetItem<T>> actions,
    bool showCancel = true,
  }) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassCard(
              margin: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (message != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: tokens.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const PremiumDivider(hasGradient: true),
                  ...actions.map((action) {
                    return PremiumListTile(
                      leadingIcon: action.icon,
                      title: action.label,
                      iconColor: action.isDestructive
                          ? theme.colorScheme.error
                          : null,
                      onTap: () => Navigator.pop(context, action.value),
                    );
                  }),
                ],
              ),
            ),
            if (showCancel) ...[
              const SizedBox(height: 12),
              GlassCard(
                margin: EdgeInsets.zero,
                child: PremiumListTile(
                  title: 'Cancel',
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Picker item model
class PickerItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  PickerItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });
}

/// Action sheet item model
class ActionSheetItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool isDestructive;

  ActionSheetItem({
    required this.value,
    required this.label,
    this.icon,
    this.isDestructive = false,
  });
}

/// Custom modal bottom sheet
class PremiumBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const PremiumBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PremiumBottomSheet(
        title: title,
        actions: actions,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const PremiumDivider(hasGradient: true),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
            if (actions != null) ...[
              const PremiumDivider(hasGradient: true),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
