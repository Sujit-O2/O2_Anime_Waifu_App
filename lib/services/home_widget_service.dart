import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'affection_service.dart';

// Background callback when a widget button is clicked and the app is dead
@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? data) async {
  if (data?.host == 'action') {
    debugPrint('Widget action clicked: ${data?.pathSegments.first}');
  }
}

/// All 5 new widget provider class names on the Android side
const _allProviders = [
  'WaifuDashboardWidgetProvider',
  'WaifuStatusMonitorWidgetProvider',
  'WaifuWeatherTimeWidgetProvider',
  'WaifuActionsHubWidgetProvider',
  'WaifuQuoteBannerWidgetProvider',
];

class HomeWidgetService {
  static const String appGroupId = '<YOUR_APP_GROUP_ID>'; // iOS only
  static const String androidProviderName = 'WaifuDashboardWidgetProvider';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.registerInteractivityCallback(interactiveCallback);
  }

  /// Save a key-value pair and trigger all widgets to refresh
  static Future<void> _save<T>(String key, T value) async {
    await HomeWidget.saveWidgetData<T>(key, value);
  }

  /// Trigger all 5 widget providers to redraw
  static Future<void> _triggerAll() async {
    for (final provider in _allProviders) {
      try {
        await HomeWidget.updateWidget(androidName: provider);
      } catch (_) {}
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
      await HomeWidget.updateWidget(
          androidName: 'WaifuDashboardWidgetProvider');
    } catch (e) {
      debugPrint('Error updating latest message: $e');
    }
  }

  /// Pushes weather data to the Weather widget
  static Future<void> updateWeather(String temp, String description) async {
    try {
      await _save<String>('weather_temp', temp);
      await _save<String>('weather_desc', description);
      await HomeWidget.updateWidget(
          androidName: 'WaifuWeatherTimeWidgetProvider');
    } catch (e) {
      debugPrint('Error updating Weather Widget: $e');
    }
  }

  /// Force-refresh all 5 widgets
  static Future<void> forceUpdateAll() async {
    await _triggerAll();
  }
}
