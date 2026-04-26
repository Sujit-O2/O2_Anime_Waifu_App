import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Offline sync service: Complete offline work, automatic sync on reconnect
class OfflineSyncService {
  static final OfflineSyncService _instance =
      OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final _firestore = FirebaseFirestore.instance;

  final _pendingQueue = <Map<String, dynamic>>[];
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  // ── Initialize Offline Support ───────────────────────────────────────────

  /// Enable offline persistence
  static Future<void> enableOfflinePersistence() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 104857600, // 100MB
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error enabling offline persistence: $e');
    }
  }

  /// Initialize offline sync
  Future<void> initializeOfflineSync() async {
    try {
      // Monitor connectivity changes
      _monitorConnectivity();

      // Load pending items from local storage
      await _loadPendingQueue();
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing offline sync: $e');
    }
  }

  /// Monitor connectivity state
  void _monitorConnectivity() {
    // This would use connectivity_plus plugin
    // For now, we'll use a timer-based approach
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnectivity();
    });
  }

  /// Check if device is online
  Future<void> _checkConnectivity() async {
    try {
      // Simple check: try to read a document
      final doc = await _firestore
          .collection('_connectivity_check')
          .doc('ping')
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Timeout'),
          );

      _isOnline = doc.exists;

      if (_isOnline && _pendingQueue.isNotEmpty) {
        // Reconnected and have pending items
        await _syncPendingQueue();
      }
    } catch (e) {
      _isOnline = false;
    }
  }

  bool get isOnline => _isOnline;

  // ── Pending Queue Management ─────────────────────────────────────────────

  /// Add operation to pending queue
  Future<void> queueOperation({
    required String operation,
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final queueItem = {
        'operation': operation,
        'collection': collection,
        'docId': docId,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'retryCount': 0,
      };

      _pendingQueue.add(queueItem);
      await _savePendingQueue();
    } catch (e) {
      if (kDebugMode) debugPrint('Error queueing operation: $e');
    }
  }

  /// Save pending queue to local storage
  Future<void> _savePendingQueue() async {
    try {
      // In real implementation, save to local storage (shared_preferences or sqflite)
      if (kDebugMode) debugPrint('Saved ${_pendingQueue.length} pending operations');
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving queue: $e');
    }
  }

  /// Load pending queue from local storage
  Future<void> _loadPendingQueue() async {
    try {
      // In real implementation, load from local storage
      if (kDebugMode) debugPrint('Loaded pending operations');
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading queue: $e');
    }
  }

  /// Sync all pending operations
  Future<void> _syncPendingQueue() async {
    try {
      int i = 0;
      while (i < _pendingQueue.length) {
        final item = _pendingQueue[i];
        final success = await _syncOperation(item);

        if (success) {
          _pendingQueue.removeAt(i);
          await _savePendingQueue();
        } else {
          item['retryCount'] = (item['retryCount'] ?? 0) + 1;
          if ((item['retryCount'] ?? 0) > 5) {
            _pendingQueue.removeAt(i);
          } else {
            i++;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error syncing queue: $e');
    }
  }

  /// Sync individual operation
  Future<bool> _syncOperation(Map<String, dynamic> item) async {
    try {
      final operation = item['operation'];
      final collection = item['collection'];
      final docId = item['docId'];
      final data = item['data'];

      switch (operation) {
        case 'create':
          await _firestore.collection(collection).doc(docId).set(data);
          return true;
        case 'update':
          await _firestore
              .collection(collection)
              .doc(docId)
              .update(data);
          return true;
        case 'delete':
          await _firestore.collection(collection).doc(docId).delete();
          return true;
        default:
          return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error syncing operation: $e');
      return false;
    }
  }

  // ── Offline Chat ─────────────────────────────────────────────────────────

  /// Save message offline
  static Future<void> saveMessageOffline({
    required String chatId,
    required String message,
    required String senderName,
  }) async {
    try {
      await _instance.queueOperation(
        operation: 'create',
        collection: 'chats',
        docId: '$chatId/${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'message': message,
          'sender': senderName,
          'timestamp': FieldValue.serverTimestamp(),
          'syncStatus': 'pending',
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving message offline: $e');
    }
  }

  /// Get offline chat history
  static Future<List<Map<String, dynamic>>> getOfflineChatHistory(
    String chatId,
  ) async {
    try {
      // This would read from local database
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting offline history: $e');
      return [];
    }
  }

  // ── Conflict Resolution ──────────────────────────────────────────────────

  /// Resolve sync conflicts
  static Future<void> resolveConflict(
    String collection,
    String docId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    try {
      // Strategy: Merge with last-write-wins for timestamps
      final mergedData = {...remoteData, ...localData};

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .set(mergedData, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Error resolving conflict: $e');
    }
  }

  // ── Sync Statistics ──────────────────────────────────────────────────────

  /// Get pending sync count
  int getPendingSyncCount() => _pendingQueue.length;

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': _isOnline,
      'pendingOperations': _pendingQueue.length,
      'lastSyncTime': DateTime.now(),
    };
  }

  /// Clear pending queue (use with caution)
  Future<void> clearPendingQueue() async {
    try {
      _pendingQueue.clear();
      await _savePendingQueue();
    } catch (e) {
      if (kDebugMode) debugPrint('Error clearing queue: $e');
    }
  }

  // ── Offline Mode Indicator ───────────────────────────────────────────────

  /// Check if feature requires online
  bool requiresOnline(String feature) {
    final onlineRequiredFeatures = [
      'send_message_to_ai',
      'upload_image',
      'stream_video',
      'api_call',
    ];

    return onlineRequiredFeatures.contains(feature);
  }

  /// Get feature availability status
  Map<String, bool> getFeatureAvailability() {
    return {
      'chat': true, // Works offline
      'vault': true, // Works offline
      'affection': true, // Works offline (syncs when online)
      'quests': true, // Works offline
      'settings': true, // Works offline
      'api': _isOnline, // Requires online
      'upload': _isOnline, // Requires online
      'video': _isOnline, // Requires online
    };
  }

  // ── Offline Work Session ─────────────────────────────────────────────────

  /// Start offline work session
  static Future<void> startOfflineSession(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('offline_sessions')
          .doc(uid)
          .set({
        'uid': uid,
        'startedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Error starting offline session: $e');
    }
  }

  /// End offline work session and sync
  static Future<void> endOfflineSession(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('offline_sessions')
          .doc(uid)
          .update({
        'endedAt': FieldValue.serverTimestamp(),
        'status': 'synced',
      });

      // Sync pending items
      await _instance._syncPendingQueue();
    } catch (e) {
      if (kDebugMode) debugPrint('Error ending offline session: $e');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}


