import 'package:flutter/services.dart';

/// Utilizes Android Intent filters to resolve fuzzy app names
/// into precise package launch commands.
class OpenAppService {
  static const MethodChannel _channel =
      MethodChannel('com.s002.o2_waifu/app_launcher');

  static const Map<String, String> _appAliases = {
    'twitter': 'com.twitter.android',
    'x': 'com.twitter.android',
    'blue bird': 'com.twitter.android',
    'instagram': 'com.instagram.android',
    'insta': 'com.instagram.android',
    'whatsapp': 'com.whatsapp',
    'youtube': 'com.google.android.youtube',
    'yt': 'com.google.android.youtube',
    'spotify': 'com.spotify.music',
    'chrome': 'com.android.chrome',
    'browser': 'com.android.chrome',
    'gmail': 'com.google.android.gm',
    'maps': 'com.google.android.apps.maps',
    'camera': 'com.android.camera2',
    'settings': 'com.android.settings',
    'telegram': 'org.telegram.messenger',
    'snapchat': 'com.snapchat.android',
    'facebook': 'com.facebook.katana',
    'fb': 'com.facebook.katana',
    'tiktok': 'com.zhiliaoapp.musically',
    'discord': 'com.discord',
    'reddit': 'com.reddit.frontpage',
    'netflix': 'com.netflix.mediaclient',
    'amazon': 'com.amazon.mShop.android.shopping',
  };

  Future<bool> openApp(String appName) async {
    final normalizedName = appName.toLowerCase().trim();
    final packageName = _appAliases[normalizedName];

    try {
      final result = await _channel.invokeMethod<bool>('openApp', {
        'packageName': packageName,
        'appName': normalizedName,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openUrl(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('openUrl', {
        'url': url,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
