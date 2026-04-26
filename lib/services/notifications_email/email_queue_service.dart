import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Email Queue Service - Queue and manage email sending
class EmailQueueService {
  static final EmailQueueService _instance = EmailQueueService._internal();
  factory EmailQueueService() => _instance;
  EmailQueueService._internal();

  static const String _queueKey = 'email_queue';
  static const String _configKey = 'queue_config';
  static const int _defaultMaxRetries = 3;
  static const Duration _defaultRetryDelay = Duration(seconds: 30);

  late SharedPreferences _prefs;
  Timer? _queueProcessor;
  final _processingStream = StreamController<QueueEvent>.broadcast();

  Stream<QueueEvent> get processingEvents => _processingStream.stream;

  Future<void> initialize({
    int maxRetries = _defaultMaxRetries,
    Duration retryDelay = _defaultRetryDelay,
  }) async {
    _prefs = await SharedPreferences.getInstance();

    // Store config
    await _prefs.setString(
      _configKey,
      jsonEncode({
        'maxRetries': maxRetries,
        'retryDelay': retryDelay.inSeconds,
      }),
    );

    if (kDebugMode) debugPrint('✅ Email queue service initialized');
  }

  /// Add email to queue
  Future<String?> addToQueue(QueuedEmail email) async {
    try {
      final id = _generateId();
      final emailWithId = email.copyWith(id: id);

      final queue = _prefs.getString(_queueKey) ?? '{}';
      final queueMap = jsonDecode(queue) as Map<String, dynamic>;
      queueMap[id] = emailWithId.toJson();

      await _prefs.setString(_queueKey, jsonEncode(queueMap));
      _processingStream.add(
        QueueEvent(type: 'added', emailId: id, message: 'Email added to queue'),
      );
      if (kDebugMode) debugPrint('✅ Email added to queue: $id');
      return id;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error adding to queue: $e');
      return null;
    }
  }

  /// Get all queued emails
  Future<List<QueuedEmail>> getAllQueued() async {
    try {
      final queue = _prefs.getString(_queueKey) ?? '{}';
      final queueMap = jsonDecode(queue) as Map<String, dynamic>;
      return queueMap.values
          .cast<Map<String, dynamic>>()
          .map((json) => QueuedEmail.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading queue: $e');
      return [];
    }
  }

  /// Get pending emails (not yet processed)
  Future<List<QueuedEmail>> getPendingEmails() async {
    try {
      final all = await getAllQueued();
      return all.where((e) => e.status == 'pending').toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting pending emails: $e');
      return [];
    }
  }

  /// Mark email as sent
  Future<bool> markAsSent(String emailId) async {
    try {
      final queue = _prefs.getString(_queueKey) ?? '{}';
      final queueMap = jsonDecode(queue) as Map<String, dynamic>;

      if (queueMap.containsKey(emailId)) {
        final email = QueuedEmail.fromJson(queueMap[emailId]);
        final updated = email.copyWith(
          status: 'sent',
          sentAt: DateTime.now(),
        );
        queueMap[emailId] = updated.toJson();
        await _prefs.setString(_queueKey, jsonEncode(queueMap));

        _processingStream.add(
          QueueEvent(type: 'sent', emailId: emailId, message: 'Email sent'),
        );
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error marking as sent: $e');
      return false;
    }
  }

  /// Mark email as failed (with retry logic)
  Future<bool> markAsFailed(String emailId, String error) async {
    try {
      final config = _getConfig();
      final maxRetries = config['maxRetries'] as int;

      final queue = _prefs.getString(_queueKey) ?? '{}';
      final queueMap = jsonDecode(queue) as Map<String, dynamic>;

      if (queueMap.containsKey(emailId)) {
        final email = QueuedEmail.fromJson(queueMap[emailId]);
        final newRetryCount = (email.retryCount ?? 0) + 1;

        if (newRetryCount >= maxRetries) {
          // Max retries exceeded
          final updated = email.copyWith(
            status: 'failed',
            lastError: error,
            retryCount: newRetryCount,
          );
          queueMap[emailId] = updated.toJson();

          _processingStream.add(
            QueueEvent(
              type: 'failed',
              emailId: emailId,
              message: 'Max retries exceeded: $error',
            ),
          );
        } else {
          // Retry later
          final updated = email.copyWith(
            status: 'pending',
            lastError: error,
            retryCount: newRetryCount,
            nextRetryTime: DateTime.now().add(_defaultRetryDelay),
          );
          queueMap[emailId] = updated.toJson();

          _processingStream.add(
            QueueEvent(
              type: 'retry',
              emailId: emailId,
              message: 'Will retry (attempt ${newRetryCount + 1}/$maxRetries)',
            ),
          );
        }

        await _prefs.setString(_queueKey, jsonEncode(queueMap));
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error marking as failed: $e');
      return false;
    }
  }

  /// Remove email from queue
  Future<bool> removeFromQueue(String emailId) async {
    try {
      final queue = _prefs.getString(_queueKey) ?? '{}';
      final queueMap = jsonDecode(queue) as Map<String, dynamic>;
      queueMap.remove(emailId);
      await _prefs.setString(_queueKey, jsonEncode(queueMap));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error removing from queue: $e');
      return false;
    }
  }

  /// Get queue statistics
  Future<QueueStats> getQueueStats() async {
    try {
      final all = await getAllQueued();
      final pending = all.where((e) => e.status == 'pending').length;
      final sent = all.where((e) => e.status == 'sent').length;
      final failed = all.where((e) => e.status == 'failed').length;

      return QueueStats(
        totalInQueue: all.length,
        pendingCount: pending,
        sentCount: sent,
        failedCount: failed,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting queue stats: $e');
      return QueueStats(
        totalInQueue: 0,
        pendingCount: 0,
        sentCount: 0,
        failedCount: 0,
      );
    }
  }

  /// Clear queue
  Future<void> clearQueue() async {
    try {
      await _prefs.remove(_queueKey);
      _processingStream.add(
        QueueEvent(type: 'cleared', emailId: '', message: 'Queue cleared'),
      );
      if (kDebugMode) debugPrint('✅ Queue cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearing queue: $e');
    }
  }

  Map<String, dynamic> _getConfig() {
    try {
      final config = _prefs.getString(_configKey) ?? '{}';
      return jsonDecode(config) as Map<String, dynamic>;
    } catch (e) {
      return {
        'maxRetries': _defaultMaxRetries,
        'retryDelay': _defaultRetryDelay.inSeconds,
      };
    }
  }

  String _generateId() {
    return 'q_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _queueProcessor?.cancel();
    _processingStream.close();
  }
}

/// Queued Email Model
class QueuedEmail {
  final String id;
  final String toEmail;
  final String subject;
  final String body;
  final String? templateId;
  final String status; // pending, sent, failed
  final int? retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? nextRetryTime;

  QueuedEmail({
    required this.id,
    required this.toEmail,
    required this.subject,
    required this.body,
    this.templateId,
    this.status = 'pending',
    this.retryCount = 0,
    this.lastError,
    DateTime? createdAt,
    this.sentAt,
    this.nextRetryTime,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'toEmail': toEmail,
        'subject': subject,
        'body': body,
        'templateId': templateId,
        'status': status,
        'retryCount': retryCount,
        'lastError': lastError,
        'createdAt': createdAt.toIso8601String(),
        'sentAt': sentAt?.toIso8601String(),
        'nextRetryTime': nextRetryTime?.toIso8601String(),
      };

  factory QueuedEmail.fromJson(Map<String, dynamic> json) => QueuedEmail(
        id: json['id'],
        toEmail: json['toEmail'],
        subject: json['subject'],
        body: json['body'],
        templateId: json['templateId'],
        status: json['status'] ?? 'pending',
        retryCount: json['retryCount'],
        lastError: json['lastError'],
        createdAt: DateTime.parse(json['createdAt']),
        sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
        nextRetryTime: json['nextRetryTime'] != null
            ? DateTime.parse(json['nextRetryTime'])
            : null,
      );

  QueuedEmail copyWith({
    String? id,
    String? toEmail,
    String? subject,
    String? body,
    String? templateId,
    String? status,
    int? retryCount,
    String? lastError,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? nextRetryTime,
  }) =>
      QueuedEmail(
        id: id ?? this.id,
        toEmail: toEmail ?? this.toEmail,
        subject: subject ?? this.subject,
        body: body ?? this.body,
        templateId: templateId ?? this.templateId,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError ?? this.lastError,
        createdAt: createdAt ?? this.createdAt,
        sentAt: sentAt ?? this.sentAt,
        nextRetryTime: nextRetryTime ?? this.nextRetryTime,
      );
}

/// Queue Statistics
class QueueStats {
  final int totalInQueue;
  final int pendingCount;
  final int sentCount;
  final int failedCount;

  QueueStats({
    required this.totalInQueue,
    required this.pendingCount,
    required this.sentCount,
    required this.failedCount,
  });

  @override
  String toString() =>
      'QueueStats(total: $totalInQueue, pending: $pendingCount, sent: $sentCount, failed: $failedCount)';
}

/// Queue Event for stream
class QueueEvent {
  final String type; // added, sent, failed, retry, cleared
  final String emailId;
  final String message;

  QueueEvent({
    required this.type,
    required this.emailId,
    required this.message,
  });

  @override
  String toString() => 'QueueEvent($type: $message)';
}

/// Global instance
final emailQueueService = EmailQueueService();


