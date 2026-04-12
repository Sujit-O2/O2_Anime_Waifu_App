import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Advanced notification service for anime_waifu app
/// Provides access to all 10 notification features with theme color support
class AdvancedNotificationService {
  static const platform = MethodChannel('anime_waifu/assistant_mode');

  /// 1. Show a progress notification (e.g., for downloads)
  static Future<void> showProgressNotification({
    required String title,
    required int progress, // 0-100
    int notificationId = 3001,
    String channelId = 'assistant_status_channel_v2',
  }) async {
    try {
      await platform.invokeMethod('showProgressNotification', {
        'title': title,
        'progress': progress,
        'notifId': notificationId,
        'channelId': channelId,
      });
    } on PlatformException catch (e) {
      debugPrint('❌ Error showing progress notification: ${e.message}');
    }
  }

  /// 2. Show an interactive notification with action buttons
  static Future<void> showInteractiveNotification({
    required String title,
    required String message,
    required List<String> actions, // e.g., ['Reply', 'Snooze', 'Open']
    int notificationId = 3002,
    String channelId = 'assistant_wake_event_channel_alert_v4',
  }) async {
    try {
      await platform.invokeMethod('showInteractiveNotification', {
        'title': title,
        'message': message,
        'actions': actions,
        'notifId': notificationId,
        'channelId': channelId,
      });
    } on PlatformException catch (e) {
      debugPrint('❌ Error showing interactive notification: ${e.message}');
    }
  }

  /// 3. Show a grouped notification
  static Future<void> showGroupedNotification({
    required String title,
    required String message,
    required String groupKey, // Groups messages with same key
    int notificationId = 3003,
    String channelId = 'assistant_status_channel_v2',
  }) async {
    try {
      await platform.invokeMethod('showGroupedNotification', {
        'title': title,
        'message': message,
        'groupKey': groupKey,
        'notifId': notificationId,
        'channelId': channelId,
      });
    } on PlatformException catch (e) {
      debugPrint('❌ Error showing grouped notification: ${e.message}');
    }
  }

  /// 4. Show an inbox-style notification (for multiple messages)
  static Future<void> showInboxNotification({
    required String title,
    required List<String> messages, // Up to 5 messages displayed
    int notificationId = 3004,
    String channelId = 'assistant_wake_event_channel_alert_v4',
  }) async {
    try {
      await platform.invokeMethod('showInboxNotification', {
        'title': title,
        'messages': messages,
        'notifId': notificationId,
        'channelId': channelId,
      });
    } on PlatformException catch (e) {
      debugPrint('❌ Error showing inbox notification: ${e.message}');
    }
  }

  /// 5. Show a heads-up notification (floating alert)
  static Future<void> showHeadsUpNotification({
    required String title,
    required String message,
    int notificationId = 3005,
    String channelId = 'assistant_wake_event_channel_alert_v4',
  }) async {
    try {
      await platform.invokeMethod('showHeadsUpNotification', {
        'title': title,
        'message': message,
        'notifId': notificationId,
        'channelId': channelId,
      });
    } on PlatformException catch (e) {
      debugPrint('❌ Error showing heads-up notification: ${e.message}');
    }
  }

  /// 6. Show a message notification with colored sender
  static Future<void> showMessageNotification({
    required String sender,
    required String message,
    String? timestamp,
    int notificationId = 3006,
    String channelId = 'assistant_wake_event_channel_alert_v4',
  }) async {
    try {
      await platform.invokeMethod('showMessageNotification', {
        'sender': sender,
        'message': message,
        'timestamp': timestamp ?? DateTime.now().toString().split('.')[0],
        'notifId': notificationId,
        'channelId': channelId,
      });
    } on PlatformException catch (e) {
      debugPrint('❌ Error showing message notification: ${e.message}');
    }
  }

  /// 7. Show a big text notification (expands to show full content)
  static Future<void> showBigTextNotification({
    required String title,
    required String bigText,
    int notificationId = 3007,
    String channelId = 'assistant_status_channel_v2',
  }) async {
    try {
      await platform.invokeMethod('showBigTextNotification', {
        'title': title,
        'bigText': bigText,
        'notifId': notificationId,
        'channelId': channelId,
      });
    } on PlatformException catch (e) {
      debugPrint('❌ Error showing big text notification: ${e.message}');
    }
  }

  /// 8. Update an existing progress notification
  static Future<void> updateProgressNotification({
    required int notificationId,
    required int progress, // 0-100
  }) async {
    try {
      await platform.invokeMethod('updateNotificationProgress', {
        'notifId': notificationId,
        'progress': progress,
      });
    } on PlatformException catch (e) {
      debugPrint('❌ Error updating progress: ${e.message}');
    }
  }

  /// 9. Dismiss a specific notification
  static Future<void> dismissNotification(int notificationId) async {
    try {
      await platform.invokeMethod('dismissNotification', {
        'notifId': notificationId,
      });
    } on PlatformException catch (e) {
      debugPrint('❌ Error dismissing notification: ${e.message}');
    }
  }

  /// 10. Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      await platform.invokeMethod('clearAllNotifications');
    } on PlatformException catch (e) {
      debugPrint('❌ Error clearing notifications: ${e.message}');
    }
  }

  // ===== CONVENIENCE METHODS =====

  /// Download progress notification helper
  static Future<void> showDownloadProgress({
    required String title,
    required int progress,
  }) => showProgressNotification(title: '📥 $title', progress: progress, notificationId: 3001);

  /// Message from Zero Two
  static Future<void> showZeroTwoMessage(String message) => showMessageNotification(
    sender: '💕 Zero Two',
    message: message,
    notificationId: 3006,
  );

  /// Achievement unlock notification
  static Future<void> showAchievementUnlock(String title, String description) =>
      showHeadsUpNotification(
        title: '🏆 $title',
        message: description,
        notificationId: 3005,
      );

  /// Anime release notification
  static Future<void> showAnimeRelease(String animeTitle, String episode) =>
      showHeadsUpNotification(
        title: '📺 $animeTitle Updated',
        message: 'New episode: $episode',
        notificationId: 3005,
      );

  /// Group messages by sender
  static Future<void> showGroupedMessage(String sender, String message) =>
      showGroupedNotification(
        title: '💬 $sender',
        message: message,
        groupKey: 'messages_$sender',
      );

  /// Show multiple messages as inbox
  static Future<void> showMessageThread(String sender, List<String> messages) =>
      showInboxNotification(
        title: '💬 Messages from $sender',
        messages: messages,
        notificationId: 3004,
      );

  /// Show download with progress tracking
  static Future<void> trackDownload(
    String title,
    int progress, {
    Duration updateFrequency = const Duration(milliseconds: 500),
  }) async {
    await showProgressNotification(title: title, progress: progress);
  }
}

/// Example usage in your Flutter app:
/*
// 1. Show download progress
AdvancedNotificationService.showProgressNotification(
  title: '📥 Downloading Episode 12',
  progress: 65,
);

// 2. Show interactive notification with reply
AdvancedNotificationService.showInteractiveNotification(
  title: '💕 Zero Two',
  message: 'Are you thinking about me?',
  actions: ['Reply', 'Later'],
);

// 3. Show heads-up achievement notification
AdvancedNotificationService.showHeadsUpNotification(
  title: '🏆 Achievement Unlocked!',
  message: 'Anime Marathon Master - Watched 100+ episodes',
);

// 4. Show grouped message notification
AdvancedNotificationService.showGroupedNotification(
  title: '💬 New Message',
  message: 'Hello there!',
  groupKey: 'messages_zero_two',
);

// 5. Show message inbox
AdvancedNotificationService.showInboxNotification(
  title: '💬 5 New Messages',
  messages: [
    'Zero Two: Are you okay?',
    'Zero Two: Darling?',
    'Alarm: Time to watch anime!',
    'Achievement: Unlocked!',
    'Update: Episode released',
  ],
);

// 6. Update progress (for streaming)
for (int i = 0; i <= 100; i += 10) {
  await Future.delayed(Duration(seconds: 1));
  AdvancedNotificationService.updateProgressNotification(
    notificationId: 3001,
    progress: i,
  );
}

// 7. Dismiss notification
AdvancedNotificationService.dismissNotification(3001);

// 8. Clear all
AdvancedNotificationService.clearAllNotifications();
*/
