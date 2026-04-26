import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Service for implementing data retention policies (GDPR compliance)
/// Automatically purges old data based on retention periods
class RetentionPolicyService {
  static final RetentionPolicyService _instance = RetentionPolicyService._internal();
  factory RetentionPolicyService() => _instance;
  RetentionPolicyService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Retention periods (in days)
  static const int retentionAuditLogs = 90; // 3 months
  static const int retentionChatHistory = 365; // 1 year
  static const int retentionMoodEntries = 365; // 1 year
  static const int retentionDeletionLogs = 90; // 3 months
  static const int retentionDataExports = 30; // 1 month
  static const int retentionSecurityAlerts = 180; // 6 months

  /// Apply retention policy to collection
  Future<int> purgeCollection(
    String collectionName, {
    required int daysToKeep,
    required String timestampField,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      if (kDebugMode) debugPrint('[Retention] Purging $collectionName older than $daysToKeep days');

      int deletedCount = 0;
      const batchSize = 100;

      // Query in batches to avoid timeout
      Query query = _db.collection(collectionName).where(
            timestampField,
            isLessThan: cutoffDate,
          );

      while (true) {
        final snapshot = await query.limit(batchSize).get();
        if (snapshot.docs.isEmpty) break;

        // Use WriteBatch for atomic, fast bulk deletion
        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        deletedCount += snapshot.docs.length;

        if (kDebugMode) debugPrint('[Retention] Deleted batch of ${snapshot.docs.length} from $collectionName');
      }

      if (kDebugMode) debugPrint('[Retention] Purged $deletedCount documents from $collectionName');
      return deletedCount;
    } catch (e) {
      if (kDebugMode) debugPrint('[Retention] Error purging $collectionName: $e');
      return 0;
    }
  }

  /// Run all retention policies
  /// Should be called periodically (e.g., daily via Cloud Functions)
  Future<Map<String, int>> runAllRetentionPolicies() async {
    try {
      final results = <String, int>{};

      // Audit logs: keep 90 days
      results['audit_logs'] = await purgeCollection(
        'audit_logs',
        daysToKeep: retentionAuditLogs,
        timestampField: 'timestamp',
      );

      // Deletion logs: keep 90 days
      results['deletion_logs'] = await purgeCollection(
        'deletion_logs',
        daysToKeep: retentionDeletionLogs,
        timestampField: 'timestamp',
      );

      // Data exports: keep 30 days
      results['data_exports'] = await purgeCollection(
        'data_exports',
        daysToKeep: retentionDataExports,
        timestampField: 'exported_at',
      );

      // Security alerts: keep 180 days
      results['security_alerts'] = await purgeCollection(
        'security_alerts',
        daysToKeep: retentionSecurityAlerts,
        timestampField: 'flagged_at',
      );

      if (kDebugMode) debugPrint('[Retention] All policies executed: $results');
      return results;
    } catch (e) {
      if (kDebugMode) debugPrint('[Retention] Error running retention policies: $e');
      return {};
    }
  }

  /// Get retention policy info for a collection
  Future<Map<String, dynamic>> getRetentionInfo(String collectionName) async {
    const policyMap = {
      'audit_logs': retentionAuditLogs,
      'deletion_logs': retentionDeletionLogs,
      'data_exports': retentionDataExports,
      'security_alerts': retentionSecurityAlerts,
    };

    final daysToKeep = policyMap[collectionName] ?? 365;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    return {
      'collection': collectionName,
      'retention_days': daysToKeep,
      'cutoff_date': cutoffDate.toIso8601String(),
      'purge_needed': true,
    };
  }

  /// Soft delete pattern: mark as deleted but keep for retention period
  /// More GDPR-friendly than hard delete
  Future<void> softDeleteUserData(String uid, String collection) async {
    try {
      await _db.collection(collection).doc(uid).update({
        'deleted_at': DateTime.now().toIso8601String(),
        'is_deleted': true,
      });
      if (kDebugMode) debugPrint('[Retention] Soft deleted $collection/$uid');
    } catch (e) {
      if (kDebugMode) debugPrint('[Retention] Error soft deleting: $e');
    }
  }

  /// Query only non-deleted data
  Query getActiveDocumentsQuery(String collectionName) {
    return _db.collection(collectionName).where('is_deleted', isNotEqualTo: true);
  }

  /// Count documents pending hard deletion
  Future<int> countPendingDeletion(
    String collectionName, {
    required int daysSinceSoftDelete,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysSinceSoftDelete));

      final query = _db.collection(collectionName).where('is_deleted', isEqualTo: true).where(
            'deleted_at',
            isLessThan: cutoffDate.toIso8601String(),
          );

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[Retention] Error counting pending deletion: $e');
      return 0;
    }
  }

  /// Archive old data (copy to archive collection before deletion)
  /// Useful for compliance and data preservation
  Future<void> archiveBeforeDelete(
    String uid,
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection('archive_$collection').add({
        'uid': uid,
        'original_data': data,
        'archived_at': DateTime.now().toIso8601String(),
        'archive_reason': 'retention_policy',
      });
      if (kDebugMode) debugPrint('[Retention] Archived $collection/$uid');
    } catch (e) {
      if (kDebugMode) debugPrint('[Retention] Error archiving: $e');
    }
  }

  /// Generate retention compliance report
  Future<String> generateComplianceReport() async {
    try {
      final report = <String, dynamic>{
        'generated_at': DateTime.now().toIso8601String(),
        'policies': {
          'audit_logs': {
            'retention_days': retentionAuditLogs,
            'compliance_note': 'GDPR Article 5 - Data minimization (90 days)',
          },
          'deletion_logs': {
            'retention_days': retentionDeletionLogs,
            'compliance_note': 'GDPR Article 17 - Right to be forgotten',
          },
          'data_exports': {
            'retention_days': retentionDataExports,
            'compliance_note': 'GDPR Article 20 - Data portability',
          },
          'security_alerts': {
            'retention_days': retentionSecurityAlerts,
            'compliance_note': 'Security incident investigation (180 days)',
          },
        },
      };

      return report.toString();
    } catch (e) {
      if (kDebugMode) debugPrint('[Retention] Error generating report: $e');
      return '{}';
    }
  }

  /// Schedule retention policy to run periodically
  /// In production, this would be a Cloud Function trigger
  /// This is a client-side fallback
  void schedulePeriodicPurge() {
    if (kDebugMode) debugPrint('[Retention] Note: In production, use Cloud Functions for periodic purging');
    if (kDebugMode) debugPrint('[Retention] Deploy function: firebase deploy --only functions');
    if (kDebugMode) debugPrint('[Retention] Schedule: Daily at 2:00 AM UTC');
  }
}
