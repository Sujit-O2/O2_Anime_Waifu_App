import 'dart:async';
import 'package:flutter/foundation.dart'
    show VoidCallback, debugPrint, kDebugMode;

/// Retries an async function with exponential backoff.
/// Use for any network call that may fail transiently.
///
/// ```dart
/// final result = await retry(
///   () => http.get(Uri.parse('https://api.example.com/data')),
///   maxAttempts: 3,
///   label: 'fetchData',
/// );
/// ```
Future<T> retry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 500),
  double backoffMultiplier = 2.0,
  Duration maxDelay = const Duration(seconds: 10),
  String label = 'operation',
  bool Function(Exception)? retryIf,
}) async {
  Duration delay = initialDelay;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } on Exception catch (e) {
      // Don't retry if retryIf says no
      if (retryIf != null && !retryIf(e)) rethrow;

      if (attempt == maxAttempts) {
        if (kDebugMode) {
          debugPrint('[Retry] $label failed after $maxAttempts attempts: $e');
        }
        rethrow;
      }

      if (kDebugMode) {
        debugPrint(
          '[Retry] $label attempt $attempt/$maxAttempts failed, '
          'retrying in ${delay.inMilliseconds}ms: $e',
        );
      }

      await Future.delayed(delay);
      delay = Duration(
        milliseconds: (delay.inMilliseconds * backoffMultiplier)
            .toInt()
            .clamp(0, maxDelay.inMilliseconds),
      );
    }
  }

  // This should never be reached but satisfies the type system
  throw StateError('Retry loop exited unexpectedly');
}

/// Timeout wrapper with a friendlier error message
Future<T> withTimeout<T>(
  Future<T> Function() fn, {
  Duration timeout = const Duration(seconds: 15),
  String label = 'operation',
}) async {
  try {
    return await fn().timeout(timeout);
  } on TimeoutException {
    throw TimeoutException('$label timed out after ${timeout.inSeconds}s');
  }
}

/// Debouncer — prevents rapid-fire function calls.
/// Only executes after the specified delay with no new calls.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Run the action after the delay. Cancels any pending action.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether there's a pending action
  bool get isPending => _timer?.isActive ?? false;

  /// Clean up resources
  void dispose() {
    cancel();
  }
}

/// Throttler — ensures a function is called at most once per interval.
class Throttler {
  final Duration interval;
  DateTime? _lastRun;

  Throttler({this.interval = const Duration(milliseconds: 500)});

  /// Run the action if enough time has elapsed since the last run.
  /// Returns true if the action was executed.
  bool run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= interval) {
      _lastRun = now;
      action();
      return true;
    }
    return false;
  }

  /// Reset the throttle timer
  void reset() => _lastRun = null;
}
