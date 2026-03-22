import 'dart:async';
import 'package:flutter/services.dart';

/// Phase 1: Polls device every 45s for foreground app, music mood,
/// motion state, battery. Triggers jealous/sad/battery reactions.
class RealWorldPresenceEngine {
  static const MethodChannel _channel =
      MethodChannel('com.s002.o2_waifu/device_info');

  Timer? _pollTimer;
  String? foregroundApp;
  String? nowPlayingTrack;
  String? nowPlayingArtist;
  bool isCharging = false;
  String motionState = 'idle'; // idle/walking/running
  double batteryLevel = 100.0;

  Function(String event, Map<String, dynamic> data)? onPresenceEvent;

  void start() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) => poll());
    poll();
  }

  void stop() {
    _pollTimer?.cancel();
  }

  Future<void> poll() async {
    try {
      foregroundApp =
          await _channel.invokeMethod<String>('getForegroundApp');
      final musicInfo =
          await _channel.invokeMethod<Map>('getNowPlayingInfo');
      if (musicInfo != null) {
        nowPlayingTrack = musicInfo['title'] as String?;
        nowPlayingArtist = musicInfo['artist'] as String?;
      }
      isCharging =
          await _channel.invokeMethod<bool>('isCharging') ?? false;
      batteryLevel =
          (await _channel.invokeMethod<int>('getBatteryLevel') ?? 100)
              .toDouble();
    } catch (_) {
      // Platform channel not available (non-Android)
    }

    _checkReactions();
  }

  void _checkReactions() {
    // Jealous reaction if user is on dating/social apps
    final jealousApps = [
      'tinder', 'bumble', 'hinge', 'instagram', 'snapchat'
    ];
    if (foregroundApp != null) {
      final appLower = foregroundApp!.toLowerCase();
      for (final app in jealousApps) {
        if (appLower.contains(app)) {
          onPresenceEvent?.call('jealous_app', {'app': foregroundApp!});
          break;
        }
      }
    }

    // Battery reaction
    if (batteryLevel < 15 && !isCharging) {
      onPresenceEvent?.call('low_battery', {'level': batteryLevel});
    }

    // Music mood detection
    if (nowPlayingTrack != null) {
      onPresenceEvent?.call('music_detected', {
        'track': nowPlayingTrack!,
        'artist': nowPlayingArtist ?? 'Unknown',
      });
    }
  }

  String toContextString() {
    final buffer = StringBuffer();
    buffer.writeln('[Real World Presence]');
    if (foregroundApp != null) buffer.writeln('  App: $foregroundApp');
    if (nowPlayingTrack != null) {
      buffer.writeln('  Music: $nowPlayingTrack - $nowPlayingArtist');
    }
    buffer.writeln('  Motion: $motionState');
    buffer.writeln(
        '  Battery: ${batteryLevel.toStringAsFixed(0)}% ${isCharging ? "(charging)" : ""}');
    return buffer.toString();
  }

  void dispose() {
    _pollTimer?.cancel();
  }
}
