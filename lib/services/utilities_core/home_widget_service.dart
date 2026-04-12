import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';

// Background callback when a widget button is clicked and the app is dead
@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? data) async {
  if (data?.host == 'action') {
    debugPrint('Widget action clicked: ${data?.pathSegments.first}');
  }
}

/// All 5 widget provider class names on the Android side
const _allProviders = [
  'WaifuDashboardWidgetProvider',
  'WaifuStatusMonitorWidgetProvider',
  'WaifuWeatherTimeWidgetProvider',
  'WaifuActionsHubWidgetProvider',
  'WaifuQuoteBannerWidgetProvider',
];

class HomeWidgetService {
  // Android: use package name as the group identifier
  static const String appGroupId = 'com.example.anime_waifu';
  static const String androidProviderName = 'WaifuDashboardWidgetProvider';

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {}
    try {
      await HomeWidget.registerInteractivityCallback(interactiveCallback);
    } catch (_) {}
  }

  /// Save a key-value pair
  static Future<void> _save<T>(String key, T value) async {
    try {
      await HomeWidget.saveWidgetData<T>(key, value);
    } catch (e) {
      debugPrint('HomeWidget save error for $key: $e');
    }
  }

  /// Trigger all widget providers to redraw — failures are swallowed individually
  static Future<void> _triggerAll() async {
    for (final provider in _allProviders) {
      try {
        await HomeWidget.updateWidget(androidName: provider);
      } catch (e) {
        debugPrint('HomeWidget update error for $provider: $e');
      }
    }
  }

  /// Pushes the current relationship status to all widgets
  static Future<void> updateAffectionWidget() async {
    try {
      final svc = AffectionService.instance;
      await _save<String>('affection_level', svc.levelName);
      await _save<int>('affection_points', svc.points);
      await _save<int>('affection_progress', (svc.levelProgress * 100).toInt());
      await _triggerAll();
    } catch (e) {
      debugPrint('Error updating Affection Widget: $e');
    }
  }

  /// Pushes a new quote string to the Quote Banner widget
  static Future<void> updateQuoteWidget(String quote) async {
    try {
      await _save<String>('daily_quote', quote);
      await _triggerAll();
    } catch (e) {
      debugPrint('Error updating Quote Widget: $e');
    }
  }

  /// Pushes latest chat message to the Dashboard widget
  static Future<void> updateLatestMessage(String message) async {
    try {
      await _save<String>('latest_chat', message);
      await HomeWidget.updateWidget(androidName: 'WaifuDashboardWidgetProvider');
    } catch (e) {
      debugPrint('Error updating latest message: $e');
    }
  }

  /// Pushes weather data to the Weather widget
  static Future<void> updateWeather(String temp, String description) async {
    try {
      await _save<String>('weather_temp', temp);
      await _save<String>('weather_desc', description);
      await HomeWidget.updateWidget(androidName: 'WaifuWeatherTimeWidgetProvider');
    } catch (e) {
      debugPrint('Error updating Weather Widget: $e');
    }
  }

  /// Pushes music player state to the Dashboard widget
  static Future<void> updateMusicWidget({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    try {
      await _save<String>('music_title', title);
      await _save<String>('music_artist', artist);
      await _save<bool>('music_playing', isPlaying);
      await HomeWidget.updateWidget(androidName: 'WaifuDashboardWidgetProvider');
    } catch (e) {
      debugPrint('Error updating Music Widget: $e');
    }
  }

  /// Update Anime of the Day widget
  static Future<void> updateAnimeOfDay(String title, String imageUrl) async {
    try {
      await _save<String>('anime_of_day_title', title);
      await _save<String>('anime_of_day_image', imageUrl);
      await HomeWidget.updateWidget(androidName: 'WaifuDashboardWidgetProvider');
    } catch (e) {
      debugPrint('Error updating Anime of Day Widget: $e');
    }
  }

  /// Update Streak and Mood widget (Home Screen)
  static Future<void> updateStreakAndMood(int streak, String moodName, String moodEmoji) async {
    try {
      await _save<int>('user_login_streak', streak);
      await _save<String>('waifu_mood_name', moodName);
      await _save<String>('waifu_mood_emoji', moodEmoji);
      await HomeWidget.updateWidget(androidName: 'WaifuStatusMonitorWidgetProvider');
    } catch (e) {
      debugPrint('Error updating Streak/Mood Widget: $e');
    }
  }

  /// Lock Screen Live Activity: Update currently watching anime progress
  static Future<void> updateLockScreenWatchProgress(String animeTitle, int currentEp, int totalEps, double progressPercent) async {
    try {
      // For iOS Live Activities / Android Media Style notifications
      await _save<String>('lock_anime_title', animeTitle);
      await _save<int>('lock_current_ep', currentEp);
      await _save<int>('lock_total_eps', totalEps);
      await _save<double>('lock_progress_pct', progressPercent);
      
      // Trigger a specific update for the lock screen activity provider
      await HomeWidget.updateWidget(
        androidName: 'WaifuWatchProgressWidgetProvider', 
        iOSName: 'WaifuWatchProgressActivity'
      );
    } catch (e) {
      debugPrint('Error updating Lock Screen Watch Progress: $e');
    }
  }

  /// Force-refresh all widgets
  static Future<void> forceUpdateAll() async {
    await _triggerAll();
  }
}


