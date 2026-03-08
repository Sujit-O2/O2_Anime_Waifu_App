import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'affection_service.dart';

// Background callback when a widget button is clicked and the app is dead
@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? data) async {
  if (data?.host == 'action') {
    debugPrint('Widget action clicked: \${data?.pathSegments.first}');
    // Logic for background tasks (like toggling DND or Flashlight)
    // Usually deferred to MainActivity via AndroidIntent in a real implementation
  }
}

class HomeWidgetService {
  static const String appGroupId = '<YOUR_APP_GROUP_ID>'; // Used mostly for iOS
  static const String androidProviderName = 'WaifuWidgetProvider';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.registerInteractivityCallback(interactiveCallback);
  }

  /// Pushes the current relationship status to the Affection Widget
  static Future<void> updateAffectionWidget() async {
    try {
      final affectionSvc = AffectionService.instance;
      await HomeWidget.saveWidgetData<String>(
          'affection_level', affectionSvc.levelName);
      await HomeWidget.saveWidgetData<int>(
          'affection_points', affectionSvc.points);
      await HomeWidget.saveWidgetData<int>(
          'affection_progress', (affectionSvc.levelProgress * 100).toInt());

      await HomeWidget.updateWidget(
        androidName: androidProviderName,
      );
    } catch (e) {
      debugPrint('Error updating Affection Widget: \$e');
    }
  }

  /// Pushes a new quote string to the Daily Quote Widget
  static Future<void> updateQuoteWidget(String quote) async {
    try {
      await HomeWidget.saveWidgetData<String>('daily_quote', quote);
      await HomeWidget.updateWidget(
        androidName: androidProviderName,
      );
    } catch (e) {
      debugPrint('Error updating Quote Widget: \$e');
    }
  }

  /// General update meant to trigger all other static/time-based widgets to redraw
  static Future<void> forceUpdateAll() async {
    try {
      await HomeWidget.updateWidget(androidName: androidProviderName);
    } catch (e) {
      debugPrint('Error forcefully updating widgets: \$e');
    }
  }
}
