import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/widgets/premium_ui_kit.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM LOADING & ERROR STATES
/// ═══════════════════════════════════════════════════════════════════════════

/// Full-screen loading indicator
class PremiumLoadingScreen extends StatelessWidget {
  final String? message;

  const PremiumLoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message!,
                style: GoogleFonts.outfit(
                  color: tokens.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline loading indicator
class PremiumLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const PremiumLoadingIndicator({
    super.key,
    this.message,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.outfit(
                color: tokens.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error screen with retry
class PremiumErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const PremiumErrorScreen({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'An error occurred. Please try again.',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.error.withValues(alpha: 0.2),
                        theme.colorScheme.error.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: tokens.textMuted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 32),
                  PremiumButton(
                    text: 'Try Again',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error widget
class PremiumErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const PremiumErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: tokens.textMuted,
                fontSize: 14,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              PremiumButton(
                text: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success screen
class PremiumSuccessScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onContinue;
  final String? continueText;

  const PremiumSuccessScreen({
    super.key,
    required this.title,
    required this.message,
    this.onContinue,
    this.continueText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.2),
                        Colors.green.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: tokens.textMuted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                if (onContinue != null) ...[
                  const SizedBox(height: 32),
                  PremiumButton(
                    text: continueText ?? 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onContinue,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Network error widget
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'No Internet Connection',
      subtitle: 'Please check your connection and try again',
      actionText: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}

/// Timeout error widget
class TimeoutErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const TimeoutErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyState(
      icon: Icons.access_time_rounded,
      title: 'Request Timeout',
      subtitle: 'The request took too long. Please try again.',
      actionText: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}

/// Permission denied widget
class PermissionDeniedWidget extends StatelessWidget {
  final String permissionName;
  final VoidCallback? onOpenSettings;

  const PermissionDeniedWidget({
    super.key,
    required this.permissionName,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyState(
      icon: Icons.block_rounded,
      title: 'Permission Required',
      subtitle: 'Please grant $permissionName permission to continue',
      actionText: onOpenSettings != null ? 'Open Settings' : null,
      onAction: onOpenSettings,
    );
  }
}

/// Maintenance mode screen
class MaintenanceScreen extends StatelessWidget {
  final String? message;

  const MaintenanceScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.orange.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    size: 48,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Under Maintenance',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message ??
                      'We\'re currently performing maintenance. Please check back soon.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: tokens.textMuted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Coming soon widget
class ComingSoonWidget extends StatelessWidget {
  final String? featureName;

  const ComingSoonWidget({super.key, this.featureName});

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyState(
      icon: Icons.rocket_launch_rounded,
      title: 'Coming Soon',
      subtitle: featureName != null
          ? '$featureName is coming soon!'
          : 'This feature is coming soon!',
    );
  }
}
