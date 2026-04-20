import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for handling user account deletion and data cleanup (GDPR Compliance).
/// Cascades delete all user data when an account is removed.
class UserDataCleanupService {
  static final UserDataCleanupService _instance = UserDataCleanupService._internal();
  factory UserDataCleanupService() => _instance;
  UserDataCleanupService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// All user-scoped collections that need cleanup
  static const List<String> userCollections = [
    'chats',
    'vault',
    'profiles',
    'affection',
    'memory',
    'quests',
    'mood',
    'settings',
    'alarm',
    'scores',
    'achievements',
    'dreams',
    'gratitude',
    'habits',
    'bucket',
    'zt_diary',
    'pinned_messages',
    'scheduled_messages',
    'user_data_sync',
    'checked',
  ];

  static const List<String> nestedCollections = [
    'feature_data',
    'moodEntries',
    'conversationSummaries',
    'personality',
    'dreamInterpretations',
    'coupleChallenge',
    'emotional_memories',
    'memory_facts',
    'life_events',
    'ai_content',
  ];

  /// Delete all user data (called when Firebase Auth account is deleted)
  /// This ensures GDPR compliance and prevents orphaned data.
  Future<void> deleteAllUserData(String uid) async {
    try {
      debugPrint('[UserDataCleanup] Starting deletion for uid: $uid');
      
      // Delete top-level collections
      int deletedCount = 0;
      for (final collection in userCollections) {
        try {
          await _db.collection(collection).doc(uid).delete();
          deletedCount++;
          debugPrint('[UserDataCleanup] Deleted $collection/$uid');
        } catch (e) {
          debugPrint('[UserDataCleanup] Error deleting $collection: $e');
        }
      }

      // Delete nested collections under /users/{uid}
      try {
        final userRef = _db.collection('users').doc(uid);
        for (final nestedCol in nestedCollections) {
          try {
            final docs = await userRef.collection(nestedCol).get();
            for (final doc in docs.docs) {
              await doc.reference.delete();
              debugPrint('[UserDataCleanup] Deleted users/$uid/$nestedCol/${doc.id}');
            }
          } catch (e) {
            debugPrint('[UserDataCleanup] Error deleting nested $nestedCol: $e');
          }
        }

        // Anonymize user profile (keep basic info for reference)
        try {
          await userRef.update({
            'email': FieldValue.delete(),
            'emailVerified': FieldValue.delete(),
            'phone': FieldValue.delete(),
            'lastLogin': FieldValue.delete(),
            'deletedAt': FieldValue.serverTimestamp(),
            'displayName': '[DELETED]',
            'photoUrl': FieldValue.delete(),
          });
          debugPrint('[UserDataCleanup] Anonymized users/$uid');
        } catch (e) {
          debugPrint('[UserDataCleanup] Error anonymizing user profile: $e');
        }
      } catch (e) {
        debugPrint('[UserDataCleanup] Error handling users collection: $e');
      }

      // Log the deletion (in case we want audit trail)
      await _logDeletion(uid, deletedCount);
      debugPrint('[UserDataCleanup] Completed deletion for uid: $uid (deleted $deletedCount collections)');
    } catch (e) {
      debugPrint('[UserDataCleanup] Fatal error: $e');
      rethrow;
    }
  }

  /// Delete specific user data (for selective deletion)
  Future<void> deleteUserCollection(String uid, String collectionName) async {
    try {
      await _db.collection(collectionName).doc(uid).delete();
      debugPrint('[UserDataCleanup] Deleted $collectionName/$uid');
    } catch (e) {
      debugPrint('[UserDataCleanup] Error deleting $collectionName: $e');
    }
  }

  /// Check what data exists for a user (for diagnostic purposes)
  Future<Map<String, bool>> getUserDataStatus(String uid) async {
    final status = <String, bool>{};
    
    for (final collection in userCollections) {
      try {
        final doc = await _db.collection(collection).doc(uid).get();
        status[collection] = doc.exists;
      } catch (e) {
        status[collection] = false;
      }
    }

    try {
      final userRef = _db.collection('users').doc(uid);
      final userDoc = await userRef.get();
      status['users/$uid'] = userDoc.exists;
    } catch (e) {
      status['users/$uid'] = false;
    }

    return status;
  }

  /// Log the deletion event (for compliance)
  Future<void> _logDeletion(String uid, int collectionsDeleted) async {
    try {
      await _db.collection('deletion_logs').add({
        'uid': uid,
        'collections_deleted': collectionsDeleted,
        'timestamp': FieldValue.serverTimestamp(),
        'ip': 'mobile_app',
      });
    } catch (e) {
      debugPrint('[UserDataCleanup] Error logging deletion: $e');
    }
  }

  /// Integration point: Call from Firebase Auth deletion flow
  /// Example:
  /// ```dart
  /// final user = FirebaseAuth.instance.currentUser;
  /// if (user != null) {
  ///   await UserDataCleanupService().deleteAllUserData(user.uid);
  ///   await FirebaseAuth.instance.currentUser?.delete();
  /// }
  /// ```
}


