import 'dart:async';
import 'package:flutter/services.dart';

/// Porcupine FFI Bridge for wake word detection.
/// Includes a Watchdog Loop that monitors microphone health every 4 seconds.
class WakeWordService {
  static const MethodChannel _channel =
      MethodChannel('com.s002.o2_waifu/wake_word');

  bool _isActive = false;
  Timer? _watchdogTimer;
  Function()? onWakeWordDetected;

  bool get isActive => _isActive;

  Future<void> start() async {
    if (_isActive) return;

    try {
      await _channel.invokeMethod('startWakeWord');
      _isActive = true;
      _startWatchdog();

      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onWakeWordDetected') {
          onWakeWordDetected?.call();
        }
      });
    } catch (e) {
      _isActive = false;
    }
  }

  Future<void> stop() async {
    _watchdogTimer?.cancel();
    _isActive = false;
    try {
      await _channel.invokeMethod('stopWakeWord');
    } catch (_) {}
  }

  /// Silent health check every 4 seconds:
  /// 1. Is the Porcupine engine instance null?
  /// 2. Is the AudioRecord state STATE_INITIALIZED?
  /// 3. If any check fails, perform a "Hot Reload"
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!_isActive) return;
      try {
        final isHealthy =
            await _channel.invokeMethod<bool>('checkHealth') ?? false;
        if (!isHealthy) {
          await _channel.invokeMethod('stopWakeWord');
          await _channel.invokeMethod('startWakeWord');
        }
      } catch (_) {
        // Silently recover
      }
    });
  }

  void dispose() {
    _watchdogTimer?.cancel();
    stop();
  }
}
