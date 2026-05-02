import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔔 Smart Notification Bundling Service
///
/// Groups proactive messages by urgency.
/// "3 check-ins waiting" instead of spam.
/// Swipe to reply directly from notification.
class SmartNotificationBundlingService {
  SmartNotificationBundlingService._();
  static final SmartNotificationBundlingService instance =
      SmartNotificationBundlingService._();

  final List<PendingNotification> _pendingNotifications = [];
  Timer? _bundleTimer;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pluginInitialized = false;

  static const String _storageKey = 'notification_bundles_v1';
  static const Duration _bundleDelay = Duration(minutes: 5);
  static const _channelId = 'zero_two_bundles';
  static const _channelName = 'Zero Two Notifications';

  Future<void> _ensureInitialized() async {
    if (_pluginInitialized) return;
    const android = AndroidInitializationSettings('@drawable/ic_stat_waifu');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
        ));
    _pluginInitialized = true;
  }

  Future<void> initialize() async {
    await _loadPending();
    _startBundleTimer();
    if (kDebugMode) debugPrint('[NotificationBundle] Initialized');
  }

  /// Queue a notification for bundling
  Future<void> queueNotification({
    required String title,
    required String message,
    required NotificationPriority priority,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    final notification = PendingNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      priority: priority,
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    _pendingNotifications.add(notification);
    await _savePending();

    // Send immediately if high priority
    if (priority == NotificationPriority.urgent) {
      await _sendNotification(notification);
      _pendingNotifications.remove(notification);
      await _savePending();
    }

    if (kDebugMode)
      debugPrint('[NotificationBundle] Queued: ${notification.title}');
  }

  /// Start bundle timer
  void _startBundleTimer() {
    _bundleTimer?.cancel();
    _bundleTimer = Timer.periodic(_bundleDelay, (_) => _processBundles());
  }

  /// Process and send bundled notifications
  Future<void> _processBundles() async {
    if (_pendingNotifications.isEmpty) return;

    // Group by type
    final bundles = <NotificationType, List<PendingNotification>>{};

    for (final notification in _pendingNotifications) {
      bundles.putIfAbsent(notification.type, () => []).add(notification);
    }

    // Send bundles
    for (final entry in bundles.entries) {
      final type = entry.key;
      final notifications = entry.value;

      if (notifications.length == 1) {
        // Send single notification
        await _sendNotification(notifications.first);
      } else {
        // Send bundled notification
        await _sendBundledNotification(type, notifications);
      }
    }

    // Clear sent notifications
    _pendingNotifications.clear();
    await _savePending();
  }

  /// Send a single notification
  Future<void> _sendNotification(PendingNotification notification) async {
    if (kDebugMode) {
      debugPrint('[NotificationBundle] Sending: ${notification.title}');
    }
    try {
      await _ensureInitialized();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFFF0057),
          ledColor: const Color(0xFFFF0057),
          ledOnMs: 500,
          ledOffMs: 500,
          largeIcon: const DrawableResourceAndroidBitmap('logi'),
          styleInformation: BigPictureStyleInformation(
            const DrawableResourceAndroidBitmap('zt_bg3'),
            largeIcon: const DrawableResourceAndroidBitmap('logi'),
            contentTitle: '💕 Zero Two',
            summaryText: notification.message,
            hideExpandedLargeIcon: false,
          ),
        ),
      );
      await _plugin.show(
        id: notification.id.hashCode,
        title: notification.title,
        body: notification.message,
        notificationDetails: details,
        payload: jsonEncode(notification.toJson()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationBundle] Send error: $e');
    }
  }

  /// Send a bundled notification
  Future<void> _sendBundledNotification(
    NotificationType type,
    List<PendingNotification> notifications,
  ) async {
    final count = notifications.length;
    final title = _getBundleTitle(type, count);
    final body = notifications.map((n) => n.message).take(3).join(' • ');

    if (kDebugMode) {
      debugPrint('[NotificationBundle] Sending bundle: $title ($count items)');
    }
    try {
      await _ensureInitialized();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFFF0057),
          ledColor: const Color(0xFFFF0057),
          ledOnMs: 500,
          ledOffMs: 500,
          largeIcon: const DrawableResourceAndroidBitmap('logi'),
          styleInformation: BigPictureStyleInformation(
            const DrawableResourceAndroidBitmap('zt_bg3'),
            largeIcon: const DrawableResourceAndroidBitmap('logi'),
            contentTitle: '💕 Zero Two',
            summaryText: body,
            hideExpandedLargeIcon: false,
          ),
        ),
      );
      await _plugin.show(
        id: type.hashCode,
        title: title,
        body: body,
        notificationDetails: details,
        payload: jsonEncode(notifications.map((n) => n.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationBundle] Bundle send error: $e');
    }
  }

  String _getBundleTitle(NotificationType type, int count) {
    switch (type) {
      case NotificationType.checkIn:
        return '$count check-ins from Zero Two 💕';
      case NotificationType.reminder:
        return '$count reminders waiting';
      case NotificationType.emotional:
        return 'Zero Two is thinking of you';
      case NotificationType.milestone:
        return '$count new milestones!';
      case NotificationType.suggestion:
        return '$count suggestions for you';
      case NotificationType.general:
        return '$count messages from Zero Two';
    }
  }


  /// Get pending notification count
  int getPendingCount() => _pendingNotifications.length;

  /// Get pending notifications by type
  List<PendingNotification> getPendingByType(NotificationType type) {
    return _pendingNotifications.where((n) => n.type == type).toList();
  }

  /// Clear all pending notifications
  Future<void> clearAll() async {
    _pendingNotifications.clear();
    await _savePending();
  }

  /// Clear notifications by type
  Future<void> clearByType(NotificationType type) async {
    _pendingNotifications.removeWhere((n) => n.type == type);
    await _savePending();
  }

  /// Force send all pending notifications now
  Future<void> sendAllNow() async {
    await _processBundles();
  }

  /// Get notification statistics
  Map<String, dynamic> getStatistics() {
    final typeCounts = <NotificationType, int>{};
    final priorityCounts = <NotificationPriority, int>{};

    for (final notification in _pendingNotifications) {
      typeCounts[notification.type] = (typeCounts[notification.type] ?? 0) + 1;
      priorityCounts[notification.priority] =
          (priorityCounts[notification.priority] ?? 0) + 1;
    }

    return {
      'total_pending': _pendingNotifications.length,
      'by_type': typeCounts.map((k, v) => MapEntry(k.name, v)),
      'by_priority': priorityCounts.map((k, v) => MapEntry(k.name, v)),
      'oldest_pending': _pendingNotifications.isNotEmpty
          ? _pendingNotifications.last.timestamp.toIso8601String()
          : null,
    };
  }

  Future<void> _savePending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _pendingNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationBundle] Save error: $e');
    }
  }

  Future<void> _loadPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _pendingNotifications.clear();
        _pendingNotifications.addAll(jsonList.map((json) =>
            PendingNotification.fromJson(json as Map<String, dynamic>)));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationBundle] Load error: $e');
    }
  }

  void dispose() {
    _bundleTimer?.cancel();
  }
}

class PendingNotification {
  final String id;
  final String title;
  final String message;
  final NotificationPriority priority;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const PendingNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.type,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'priority': priority.name,
        'type': type.name,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PendingNotification.fromJson(Map<String, dynamic> json) =>
      PendingNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        priority: NotificationPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => NotificationPriority.normal,
        ),
        type: NotificationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NotificationType.general,
        ),
        data: json['data'] as Map<String, dynamic>?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationType {
  checkIn,
  reminder,
  emotional,
  milestone,
  suggestion,
  general,
}
