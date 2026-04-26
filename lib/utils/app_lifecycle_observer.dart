import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/widgets.dart';

/// Manages app lifecycle transitions.
/// Saves user state when app goes to background, and refreshes when
/// returning to foreground. 
///
/// Usage in main.dart:
/// ```dart
/// final lifecycleObserver = AppLifecycleObserver(
///   onResume: () => refreshData(),
///   onPause: () => saveCurrentState(),
/// );
/// WidgetsBinding.instance.addObserver(lifecycleObserver);
/// ```
class AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback? onResume;
  final VoidCallback? onPause;
  final VoidCallback? onDetach;
  final VoidCallback? onInactive;

  DateTime? _pausedAt;
  
  /// How long the app must be in background before triggering
  /// a full refresh on resume (default 5 minutes)
  final Duration staleThreshold;

  AppLifecycleObserver({
    this.onResume,
    this.onPause,
    this.onDetach,
    this.onInactive,
    this.staleThreshold = const Duration(minutes: 5),
  });

  /// Whether the data is stale (app was backgrounded > threshold)
  bool get isStale => _pausedAt != null && 
      DateTime.now().difference(_pausedAt!) > staleThreshold;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (kDebugMode) {
          final away = _pausedAt != null
              ? DateTime.now().difference(_pausedAt!).inSeconds
              : 0;
          debugPrint('[Lifecycle] Resumed after ${away}s (stale: $isStale)');
        }
        onResume?.call();
        _pausedAt = null;
        break;

      case AppLifecycleState.paused:
        _pausedAt = DateTime.now();
        if (kDebugMode) debugPrint('[Lifecycle] Paused — saving state');
        onPause?.call();
        break;

      case AppLifecycleState.detached:
        if (kDebugMode) debugPrint('[Lifecycle] Detached');
        onDetach?.call();
        break;

      case AppLifecycleState.inactive:
        onInactive?.call();
        break;

      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Call this to clean up when no longer needed
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
