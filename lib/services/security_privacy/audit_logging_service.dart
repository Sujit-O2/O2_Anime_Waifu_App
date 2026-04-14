import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service for comprehensive audit logging (Security & Compliance)
/// Tracks sensitive operations for security monitoring and GDPR compliance
class AuditLoggingService {
  static final AuditLoggingService _instance = AuditLoggingService._internal();
  factory AuditLoggingService() => _instance;
  AuditLoggingService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Event types (for standardization)
  static const String eventUserLogin = 'user_login';
  static const String eventUserLogout = 'user_logout';
  static const String eventPinSet = 'pin_set';
  static const String eventPinVerified = 'pin_verified';
  static const String eventPinFailed = 'pin_verification_failed';
  static const String eventVaultAccessed = 'vault_accessed';
  static const String eventSecretNoteCreated = 'secret_note_created';
  static const String eventSecretNoteDeleted = 'secret_note_deleted';
  static const String eventSecretNotesCleared = 'secret_notes_cleared';
  static const String eventDataExported = 'data_exported';
  static const String eventDataDeleted = 'data_deleted';
  static const String eventAccountDeleted = 'account_deleted';
  static const String eventPrivacyPolicyAccepted = 'privacy_policy_accepted';
  static const String eventDataSharingToggled = 'data_sharing_toggled';
  static const String eventSensitiveDataAccessed = 'sensitive_data_accessed';

  // Severity levels
  static const String severityLow = 'low';
  static const String severityMedium = 'medium';
  static const String severityHigh = 'high';
  static const String severityCritical = 'critical';

  /// Log an audit event with full context
  Future<void> logEvent({
    required String event,
    String? description,
    String severity = severityMedium,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final log = {
        'uid': uid,
        'event': event,
        'description': description ?? '',
        'severity': severity,
        'ipAddress': 'mobile_app',
        'userAgent': 'flutter_android', // TODO: detect actual platform
        'timestamp': FieldValue.serverTimestamp(),
        'unixTimestamp': DateTime.now().millisecondsSinceEpoch,
        if (metadata != null) 'metadata': metadata,
      };

      await _db.collection('audit_logs').add(log);
      debugPrint('[AuditLog] $event (severity: $severity)');
    } catch (e) {
      debugPrint('[AuditLog] Error logging event: $e');
    }
  }

  /// Log sensitive data access
  Future<void> logDataAccess({
    required String dataType, // 'vault', 'notes', 'profile', etc
    required String action, // 'read', 'write', 'delete'
    String? reason,
  }) async {
    await logEvent(
      event: eventSensitiveDataAccessed,
      description: 'Accessed $dataType ($action)',
      severity: severityMedium,
      metadata: {
        'data_type': dataType,
        'action': action,
        'reason': reason ?? 'user_action',
      },
    );
  }

  /// Log authentication events
  Future<void> logAuthEvent({
    required String event,
    required bool success,
    String? reason,
  }) async {
    final severity = success ? severityLow : severityHigh;
    await logEvent(
      event: event,
      description: success ? 'Successful' : 'Failed',
      severity: severity,
      metadata: {
        'success': success,
        'reason': reason,
      },
    );
  }

  /// Query audit logs for a user (for compliance review)
  Future<List<Map<String, dynamic>>> getUserAuditLogs(
    String uid, {
    DateTime? from,
    DateTime? to,
    String? eventType,
    int limit = 100,
  }) async {
    try {
      Query query = _db.collection('audit_logs').where('uid', isEqualTo: uid);

      if (from != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: from);
      }
      if (to != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: to);
      }
      if (eventType != null) {
        query = query.where('event', isEqualTo: eventType);
      }

      final snapshot = await query.orderBy('timestamp', descending: true).limit(limit).get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('[AuditLog] Error querying logs: $e');
      return [];
    }
  }

  /// Get summary statistics for audit logs
  Future<Map<String, dynamic>> getAuditSummary(String uid) async {
    try {
      final logs = await getUserAuditLogs(uid, limit: 1000);
      
      final summary = {
        'total_events': logs.length,
        'events_by_type': <String, int>{},
        'events_by_severity': <String, int>{},
        'last_event': logs.isNotEmpty ? logs.first['timestamp'] : null,
        'high_severity_count': 0,
        'critical_count': 0,
      };

      for (final log in logs) {
        final eventType = log['event'] as String?;
        final severity = log['severity'] as String?;

        if (eventType != null) {
          summary['events_by_type'][eventType] = (summary['events_by_type'][eventType] ?? 0) + 1;
        }
        if (severity != null) {
          summary['events_by_severity'][severity] = (summary['events_by_severity'][severity] ?? 0) + 1;
        }
        if (severity == severityHigh) {
          summary['high_severity_count']++;
        }
        if (severity == severityCritical) {
          summary['critical_count']++;
        }
      }

      return summary;
    } catch (e) {
      debugPrint('[AuditLog] Error generating summary: $e');
      return {};
    }
  }

  /// Purge old audit logs (data retention policy)
  /// Kept for 90 days by default (GDPR compliant)
  Future<int> purgeOldLogs({
    int daysToKeep = 90,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final query = _db
          .collection('audit_logs')
          .where('timestamp', isLessThan: cutoffDate)
          .limit(500); // Batch delete to avoid timeouts

      final snapshot = await query.get();
      int deleted = 0;

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        deleted++;
      }

      debugPrint('[AuditLog] Purged $deleted old logs');
      return deleted;
    } catch (e) {
      debugPrint('[AuditLog] Error purging logs: $e');
      return 0;
    }
  }

  /// Export audit logs for a user (GDPR data portability)
  Future<String> exportAuditLogs(String uid) async {
    try {
      final logs = await getUserAuditLogs(uid, limit: 10000);
      
      final export = {
        'exported_at': DateTime.now().toIso8601String(),
        'exported_for_uid': uid,
        'total_events': logs.length,
        'events': logs,
      };

      return export.toString(); // In production, use jsonEncode
    } catch (e) {
      debugPrint('[AuditLog] Error exporting logs: $e');
      return '{}';
    }
  }

  /// Flag suspicious activity
  Future<void> flagSuspiciousActivity({
    required String uid,
    required String reason,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _db.collection('security_alerts').add({
        'uid': uid,
        'reason': reason,
        'details': details,
        'flagged_at': FieldValue.serverTimestamp(),
        'status': 'pending_review',
      });

      debugPrint('[Security] Flagged suspicious activity: $reason');
    } catch (e) {
      debugPrint('[AuditLog] Error flagging activity: $e');
    }
  }
}


