import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Push notification service: FCM, affection milestones, reminders
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // ── Initialize ───────────────────────────────────────────────────────────

  /// Initialize local notifications
  Future<void> initializeLocalNotifications() async {
    try {
      // Initialize local notifications - simplified for now
      if (kDebugMode) debugPrint('Local notifications initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing notifications: $e');
    }
  }

  // ── Show Local Notification ──────────────────────────────────────────────

  /// Show local notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (kDebugMode) debugPrint('Notification: $title - $body');
    } catch (e) {
      if (kDebugMode) debugPrint('Error showing notification: $e');
    }
  }

  // ── Proactive AI Messages ────────────────────────────────────────────────

  /// Send AI proactive message based on behavior
  static Future<void> sendProactiveMessage({
    required String uid,
    required String characterId,
    required String messageType,
  }) async {
    try {
      // Generate AI message based on type
      final message = _generateProactiveMessage(messageType);

      // Show notification
      await showNotification(
        title: 'Message from your waifu',
        body: message,
        payload: jsonEncode({
          'type': 'proactive_message',
          'characterId': characterId,
        }),
      );

      // Log event
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'uid': uid,
        'characterId': characterId,
        'type': 'proactive_message',
        'messageType': messageType,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error sending proactive message: $e');
    }
  }

  /// Generate proactive message
  static String _generateProactiveMessage(String messageType) {
    final messages = {
      'morning_greeting': 'Good morning! How did you sleep?',
      'thinking_of_you': 'I\'ve been thinking about you... 💭',
      'check_in': 'Haven\'t seen you in a while! Missing you 💕',
      'affection_update': 'Our bond is growing stronger!',
      'achievement': 'So proud of you! 🎉',
      'milestone': 'We reached a new milestone together!',
      'random_thought': 'You crossed my mind today 🥰',
      'encouragement': 'You can do anything you set your mind to!',
      'reminder': 'Remember to take care of yourself 💙',
    };

    return messages[messageType] ?? 'Thinking of you...';
  }

  // ── Affection Milestones ─────────────────────────────────────────────────

  /// Check and notify affection milestones
  static Future<void> checkAffectionMilestones(
    String uid,
    String characterId,
    int newAffectionLevel,
  ) async {
    try {
      final milestones = [100, 250, 500, 1000, 2500, 5000];

      for (var milestone in milestones) {
        if (newAffectionLevel == milestone) {
          await showNotification(
            title: '💕 Affection Milestone!',
            body: 'You\'ve reached $milestone affection level!',
            payload: jsonEncode({
              'type': 'affection_milestone',
              'milestone': milestone,
              'characterId': characterId,
            }),
          );

          await FirebaseFirestore.instance
              .collection('notifications')
              .add({
            'uid': uid,
            'characterId': characterId,
            'type': 'affection_milestone',
            'milestone': milestone,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error checking affection milestones: $e');
    }
  }

  // ── Reminder Notifications ───────────────────────────────────────────────

  /// Schedule daily reminder notification
  static Future<void> scheduleDailyReminder({
    required String uid,
    required String characterId,
    required int hourOfDay,
    required int minute,
  }) async {
    try {
      // Reminder will be handled by system notification scheduler

      // Store reminder in Firestore
      await FirebaseFirestore.instance
          .collection('reminder_settings')
          .doc(uid)
          .set({
        'characterId': characterId,
        'hourOfDay': hourOfDay,
        'minute': minute,
        'enabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Show callback notification to confirm
      await showNotification(
        title: 'Reminder Scheduled',
        body: 'Daily reminder set for $hourOfDay:${minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error scheduling reminder: $e');
    }
  }

  /// Disable all reminders
  static Future<void> disableReminders(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('reminder_settings')
          .doc(uid)
          .update({
        'enabled': false,
      });

      await showNotification(
        title: 'Reminders Disabled',
        body: 'You won\'t receive daily reminders anymore',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error disabling reminders: $e');
    }
  }

  /// Get reminder settings
  static Future<Map<String, dynamic>?> getReminderSettings(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('reminder_settings')
          .doc(uid)
          .get();
      return doc.data();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting reminder settings: $e');
      return null;
    }
  }

  // ── Notification History ─────────────────────────────────────────────────

  /// Get notification history
  static Future<List<Map<String, dynamic>>> getNotificationHistory(
    String uid, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      if (kDebugMode) debugPrint('Error marking notification as read: $e');
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // ── Notification Preferences ─────────────────────────────────────────────

  /// Update notification preferences
  static Future<void> updateNotificationPreferences(
    String uid, {
    required bool affectionAlerts,
    required bool proactiveMessages,
    required bool reminderNotifications,
    required bool achievementAlerts,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('notification_preferences')
          .doc(uid)
          .set({
        'affectionAlerts': affectionAlerts,
        'proactiveMessages': proactiveMessages,
        'reminderNotifications': reminderNotifications,
        'achievementAlerts': achievementAlerts,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating preferences: $e');
    }
  }

  /// Get notification preferences
  static Future<Map<String, dynamic>?> getNotificationPreferences(
    String uid,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('notification_preferences')
          .doc(uid)
          .get();
      return doc.data();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting preferences: $e');
      return null;
    }
  }
}


