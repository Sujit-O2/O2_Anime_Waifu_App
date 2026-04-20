import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Email Scheduler Service - Schedule emails to send at specific times
class EmailSchedulerService {
  static final EmailSchedulerService _instance =
      EmailSchedulerService._internal();
  factory EmailSchedulerService() => _instance;
  EmailSchedulerService._internal();

  static const String _scheduledEmailsKey = 'scheduled_emails';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Schedule an email to send at a specific time
  Future<String?> scheduleEmail(ScheduledEmail email) async {
    try {
      final id = _generateId();
      final emailWithId = email.copyWith(id: id);

      final scheduled = _prefs.getString(_scheduledEmailsKey) ?? '{}';
      final scheduledMap = jsonDecode(scheduled) as Map<String, dynamic>;
      scheduledMap[id] = emailWithId.toJson();

      await _prefs.setString(_scheduledEmailsKey, jsonEncode(scheduledMap));
      debugPrint('✅ Email scheduled with ID: $id at ${email.scheduledTime}');
      return id;
    } catch (e) {
      debugPrint('❌ Error scheduling email: $e');
      return null;
    }
  }

  /// Get all scheduled emails
  Future<List<ScheduledEmail>> getAllScheduledEmails() async {
    try {
      final scheduled = _prefs.getString(_scheduledEmailsKey) ?? '{}';
      final scheduledMap = jsonDecode(scheduled) as Map<String, dynamic>;
      return scheduledMap.values
          .cast<Map<String, dynamic>>()
          .map((json) => ScheduledEmail.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading scheduled emails: $e');
      return [];
    }
  }

  /// Get scheduled email by ID
  Future<ScheduledEmail?> getScheduledEmail(String id) async {
    try {
      final scheduled = _prefs.getString(_scheduledEmailsKey) ?? '{}';
      final scheduledMap = jsonDecode(scheduled) as Map<String, dynamic>;
      if (scheduledMap.containsKey(id)) {
        return ScheduledEmail.fromJson(scheduledMap[id]);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting scheduled email: $e');
      return null;
    }
  }

  /// Cancel scheduled email
  Future<bool> cancelScheduledEmail(String id) async {
    try {
      final scheduled = _prefs.getString(_scheduledEmailsKey) ?? '{}';
      final scheduledMap = jsonDecode(scheduled) as Map<String, dynamic>;
      scheduledMap.remove(id);
      await _prefs.setString(_scheduledEmailsKey, jsonEncode(scheduledMap));
      debugPrint('✅ Scheduled email cancelled: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling scheduled email: $e');
      return false;
    }
  }

  /// Get pending emails (not yet sent)
  Future<List<ScheduledEmail>> getPendingEmails() async {
    try {
      final all = await getAllScheduledEmails();
      return all.where((e) => !e.isSent).toList();
    } catch (e) {
      debugPrint('❌ Error getting pending emails: $e');
      return [];
    }
  }

  /// Get emails ready to send (scheduled time has passed)
  Future<List<ScheduledEmail>> getReadyToSendEmails() async {
    try {
      final pending = await getPendingEmails();
      final now = DateTime.now();
      return pending.where((e) => e.scheduledTime.isBefore(now)).toList();
    } catch (e) {
      debugPrint('❌ Error getting ready-to-send emails: $e');
      return [];
    }
  }

  /// Mark email as sent
  Future<bool> markAsSent(String id) async {
    try {
      final email = await getScheduledEmail(id);
      if (email == null) return false;

      final updatedEmail = email.copyWith(
        isSent: true,
        sentAt: DateTime.now(),
      );
      return await _updateScheduledEmail(updatedEmail);
    } catch (e) {
      debugPrint('❌ Error marking email as sent: $e');
      return false;
    }
  }

  /// Mark email as failed
  Future<bool> markAsFailed(String id, String error) async {
    try {
      final email = await getScheduledEmail(id);
      if (email == null) return false;

      final updatedEmail = email.copyWith(
        isSent: false,
        lastError: error,
        retryCount: (email.retryCount ?? 0) + 1,
      );
      return await _updateScheduledEmail(updatedEmail);
    } catch (e) {
      debugPrint('❌ Error marking email as failed: $e');
      return false;
    }
  }

  /// Get email stats
  Future<EmailScheduleStats> getEmailStats() async {
    try {
      final all = await getAllScheduledEmails();
      final sent = all.where((e) => e.isSent).length;
      final pending = all.where((e) => !e.isSent).length;
      final failed = all.where((e) => (e.lastError ?? '').isNotEmpty).length;

      return EmailScheduleStats(
        totalScheduled: all.length,
        totalSent: sent,
        totalPending: pending,
        totalFailed: failed,
      );
    } catch (e) {
      debugPrint('❌ Error getting email stats: $e');
      return EmailScheduleStats(
        totalScheduled: 0,
        totalSent: 0,
        totalPending: 0,
        totalFailed: 0,
      );
    }
  }

  Future<bool> _updateScheduledEmail(ScheduledEmail email) async {
    try {
      final scheduled = _prefs.getString(_scheduledEmailsKey) ?? '{}';
      final scheduledMap = jsonDecode(scheduled) as Map<String, dynamic>;
      scheduledMap[email.id] = email.toJson();
      await _prefs.setString(_scheduledEmailsKey, jsonEncode(scheduledMap));
      return true;
    } catch (e) {
      debugPrint('❌ Error updating scheduled email: $e');
      return false;
    }
  }

  String _generateId() {
    return 'sched_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Scheduled Email Model
class ScheduledEmail {
  final String id;
  final String toEmail;
  final String subject;
  final String body;
  final DateTime scheduledTime;
  final bool isSent;
  final DateTime? sentAt;
  final String? lastError;
  final int? retryCount;
  final bool isRecurring;
  final String? recurringPattern; // daily, weekly, monthly

  ScheduledEmail({
    required this.id,
    required this.toEmail,
    required this.subject,
    required this.body,
    required this.scheduledTime,
    this.isSent = false,
    this.sentAt,
    this.lastError,
    this.retryCount = 0,
    this.isRecurring = false,
    this.recurringPattern,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'toEmail': toEmail,
        'subject': subject,
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
        'isSent': isSent,
        'sentAt': sentAt?.toIso8601String(),
        'lastError': lastError,
        'retryCount': retryCount,
        'isRecurring': isRecurring,
        'recurringPattern': recurringPattern,
      };

  factory ScheduledEmail.fromJson(Map<String, dynamic> json) => ScheduledEmail(
        id: json['id'],
        toEmail: json['toEmail'],
        subject: json['subject'],
        body: json['body'],
        scheduledTime: DateTime.parse(json['scheduledTime']),
        isSent: json['isSent'] ?? false,
        sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
        lastError: json['lastError'],
        retryCount: json['retryCount'],
        isRecurring: json['isRecurring'] ?? false,
        recurringPattern: json['recurringPattern'],
      );

  ScheduledEmail copyWith({
    String? id,
    String? toEmail,
    String? subject,
    String? body,
    DateTime? scheduledTime,
    bool? isSent,
    DateTime? sentAt,
    String? lastError,
    int? retryCount,
    bool? isRecurring,
    String? recurringPattern,
  }) =>
      ScheduledEmail(
        id: id ?? this.id,
        toEmail: toEmail ?? this.toEmail,
        subject: subject ?? this.subject,
        body: body ?? this.body,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        isSent: isSent ?? this.isSent,
        sentAt: sentAt ?? this.sentAt,
        lastError: lastError ?? this.lastError,
        retryCount: retryCount ?? this.retryCount,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringPattern: recurringPattern ?? this.recurringPattern,
      );
}

/// Email Schedule Statistics
class EmailScheduleStats {
  final int totalScheduled;
  final int totalSent;
  final int totalPending;
  final int totalFailed;

  EmailScheduleStats({
    required this.totalScheduled,
    required this.totalSent,
    required this.totalPending,
    required this.totalFailed,
  });

  @override
  String toString() =>
      'EmailScheduleStats(scheduled: $totalScheduled, sent: $totalSent, pending: $totalPending, failed: $totalFailed)';
}

/// Global instance
final emailSchedulerService = EmailSchedulerService();


