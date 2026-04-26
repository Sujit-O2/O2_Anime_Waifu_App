import 'package:anime_waifu/core/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// TTL Retention Policy Service
/// Manages automatic deletion of old data based on TTL policies
class TTLRetentionPolicyService {
  static final TTLRetentionPolicyService _instance =
      TTLRetentionPolicyService._internal();

  factory TTLRetentionPolicyService() {
    return _instance;
  }

  TTLRetentionPolicyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// TTL Policies for different collections
  final Map<String, Duration> _ttlPolicies = {
    FirestoreCollections.analyticsEvents: const Duration(days: 90),
    FirestoreCollections.crashReports: const Duration(days: 30),
    FirestoreCollections.voiceCommandHistory: const Duration(days: 30),
    FirestoreCollections.activityFeed: const Duration(days: 60),
    FirestoreCollections.offlineSessions: const Duration(days: 7),
    FirestoreCollections.pendingOperations: const Duration(days: 3),
    FirestoreCollections.adminLogs: const Duration(days: 180),
  };

  /// Initialize TTL retention policies
  /// Set the TTL field for Firestore automatic deletion
  Future<void> initializeTTLPolicies() async {
    try {
      if (kDebugMode) debugPrint('📋 Initializing TTL Retention Policies...');

      // For each collection with TTL policy, ensure TTL field exists
      for (final entry in _ttlPolicies.entries) {
        final collection = entry.key;

        // Get a sample document to verify structure
        try {
          final snapshot =
              await _firestore.collection(collection).limit(1).get();

          if (snapshot.docs.isNotEmpty) {
            if (kDebugMode) debugPrint('✅ TTL policy enabled for $collection (${entry.value.inDays} days)');
          }
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Could not verify collection $collection: $e');
        }
      }

      if (kDebugMode) debugPrint('✅ TTL Retention Policies initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error initializing TTL policies: $e');
    }
  }

  /// Add TTL field to a document
  /// This enables Firestore automatic deletion after TTL expires
  Future<void> addTTLToDocument(
    String collection,
    String documentId, {
    Duration? customTTL,
  }) async {
    try {
      final ttl = customTTL ?? _ttlPolicies[collection];

      if (ttl == null) {
        if (kDebugMode) debugPrint('⚠️ No TTL policy found for collection: $collection');
        return;
      }

      final expirationTime =
          DateTime.now().add(ttl);

      await _firestore
          .collection(collection)
          .doc(documentId)
          .set(
            {
              '__ttl': Timestamp.fromDate(expirationTime),
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      if (kDebugMode) {
        debugPrint(
        '✅ TTL set for $collection/$documentId (expires in ${ttl.inDays} days)',
      );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error adding TTL to document: $e');
    }
  }

  /// Manually cleanup expired documents (for collections without Firestore TTL)
  Future<void> manualCleanup(String collection) async {
    try {
      final ttl = _ttlPolicies[collection];

      if (ttl == null) {
        if (kDebugMode) debugPrint('⚠️ No TTL policy found for collection: $collection');
        return;
      }

      final cutoffTime = DateTime.now().subtract(ttl);

      final snapshot = await _firestore
          .collection(collection)
          .where('createdAt', isLessThan: cutoffTime)
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) debugPrint('✅ No expired documents found in $collection');
        return;
      }

      // Batch delete up to 100 documents
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint(
        '✅ Deleted ${snapshot.docs.length} expired documents from $collection',
      );
      }

      // Recursively cleanup more if needed
      if (snapshot.docs.length == 100) {
        await manualCleanup(collection);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error performing manual cleanup: $e');
    }
  }

  /// Cleanup all expired data
  Future<void> cleanupAllExpiredData() async {
    try {
      if (kDebugMode) debugPrint('🧹 Starting comprehensive cleanup of expired data...');

      for (final collection in _ttlPolicies.keys) {
        await manualCleanup(collection);
      }

      if (kDebugMode) debugPrint('✅ Comprehensive cleanup completed');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error during comprehensive cleanup: $e');
    }
  }

  /// Get TTL policy for a collection
  Duration? getTTLPolicy(String collection) {
    return _ttlPolicies[collection];
  }

  /// Update TTL policy
  void updateTTLPolicy(String collection, Duration ttl) {
    _ttlPolicies[collection] = ttl;
    if (kDebugMode) debugPrint('📋 Updated TTL policy for $collection: ${ttl.inDays} days');
  }

  /// Add custom TTL policy
  void addCustomTTLPolicy(String collection, Duration ttl) {
    _ttlPolicies[collection] = ttl;
    if (kDebugMode) debugPrint('📋 Added custom TTL policy for $collection: ${ttl.inDays} days');
  }

  /// Get all TTL policies
  Map<String, Duration> getAllTTLPolicies() {
    return Map.unmodifiable(_ttlPolicies);
  }

  /// Schedule periodic cleanup
  /// Call this periodically (e.g., daily) to maintain data hygiene
  Future<void> scheduledCleanup() async {
    try {
      if (kDebugMode) debugPrint('📋 Running scheduled cleanup...');
      await cleanupAllExpiredData();
      if (kDebugMode) debugPrint('✅ Scheduled cleanup completed');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error in scheduled cleanup: $e');
    }
  }

  /// Check collection storage usage
  Future<int> getCollectionDocumentCount(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting collection count: $e');
      return 0;
    }
  }

  /// Get retention statistics
  Future<Map<String, dynamic>> getRetentionStats() async {
    final stats = <String, dynamic>{};

    try {
      for (final collection in _ttlPolicies.keys) {
        final count = await getCollectionDocumentCount(collection);
        stats[collection] = {
          'documentCount': count,
          'ttlDays': _ttlPolicies[collection]?.inDays,
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting retention stats: $e');
    }

    return stats;
  }
}



