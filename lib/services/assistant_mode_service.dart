import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AssistantModeService {
  static const MethodChannel _channel =
      MethodChannel('anime_waifu/assistant_mode');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      debugPrint("AssistantModeService.$method failed: ${e.message}");
      return null;
    }
  }

  Future<void> start({
    String? apiKey,
    String? apiUrl,
    String? model,
    int? intervalMs,
  }) async {
    await _invoke('start', {
      'apiKey': apiKey,
      'apiUrl': apiUrl,
      'model': model,
      'intervalMs': intervalMs,
    });
  }

  Future<void> stop() async {
    await _invoke('stop');
  }

  Future<bool> isRunning() async {
    final result = await _invoke<bool>('isRunning');
    return result ?? false;
  }

  Future<void> bringToFront() async {
    await _invoke('bringToFront');
  }

  Future<bool> canDrawOverlays() async {
    final result = await _invoke<bool>('canDrawOverlays');
    return result ?? false;
  }

  Future<void> requestOverlayPermission() async {
    await _invoke('requestOverlayPermission');
  }

  Future<void> showOverlay({
    required String status,
    required String transcript,
  }) async {
    await _invoke('showOverlay', {
      'status': status,
      'transcript': transcript,
    });
  }

  Future<void> updateOverlay({
    required String status,
    required String transcript,
  }) async {
    await _invoke('updateOverlay', {
      'status': status,
      'transcript': transcript,
    });
  }

  Future<void> hideOverlay() async {
    await _invoke('hideOverlay');
  }

  Future<bool> canPostNotifications() async {
    final result = await _invoke<bool>('canPostNotifications');
    return result ?? true;
  }

  Future<void> requestNotificationPermission() async {
    await _invoke('requestNotificationPermission');
  }

  Future<void> showListeningNotification({
    required String status,
    required String transcript,
    bool pulse = false,
  }) async {
    await _invoke('showListeningNotification', {
      'status': status,
      'transcript': transcript,
      'pulse': pulse,
    });
  }

  Future<void> setAssistantIdleNotification() async {
    await _invoke('setAssistantIdleNotification');
  }

  Future<void> setProactiveMode(bool enabled) async {
    await _invoke('setProactiveMode', {'enabled': enabled});
  }

  Future<void> openNotificationSettings() async {
    await _invoke('openNotificationSettings');
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    final result = await _invoke<bool>('isIgnoringBatteryOptimizations');
    return result ?? true;
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    await _invoke('requestIgnoreBatteryOptimizations');
  }
}
