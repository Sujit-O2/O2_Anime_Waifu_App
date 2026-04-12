import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-First Database Service
/// Progressive sync, local-first architecture with cloud synchronization
class OfflineFirstDatabaseService {
  static final OfflineFirstDatabaseService _instance = OfflineFirstDatabaseService._internal();

  factory OfflineFirstDatabaseService() {
    return _instance;
  }

  OfflineFirstDatabaseService._internal();

  late SharedPreferences _prefs;
  final Map<String, LocalRecord> _localStore = {};
  final List<SyncRecord> _pendingSyncs = [];
  bool _isOnline = true;
  DateTime _lastSyncTime = DateTime.now();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLocalData();
    debugPrint('[OfflineDB] Service initialized');
  }

  // ===== ONLINE/OFFLINE STATUS =====
  Future<void> setOnlineStatus(bool isOnline) async {
    _isOnline = isOnline;
    if (isOnline && _pendingSyncs.isNotEmpty) {
      await syncPendingData();
    }
    debugPrint('[OfflineDB] Online status: $_isOnline');
  }

  bool getOnlineStatus() => _isOnline;

  // ===== LOCAL STORAGE =====
  /// Store data locally (works offline)
  Future<void> setLocal<T>({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final record = LocalRecord(
      collection: collection,
      docId: docId,
      data: data,
      timestamp: DateTime.now(),
      isSynced: false,
      syncAttempts: 0,
    );

    _localStore['$collection/$docId'] = record;
    await _saveLocalData();

    // Queue for sync if online
    if (_isOnline) {
      await _addPendingSync(record);
    } else {
      debugPrint('[OfflineDB] Queued offline: $collection/$docId');
    }
  }

  /// Retrieve local data
  Future<Map<String, dynamic>?> getLocal({
    required String collection,
    required String docId,
  }) async {
    final key = '$collection/$docId';
    return _localStore[key]?.data;
  }

  /// Query local collection
  Future<List<Map<String, dynamic>>> queryLocal({
    required String collection,
    Map<String, dynamic>? where,
  }) async {
    return _localStore.values
        .where((r) => r.collection == collection)
        .map((r) => r.data)
        .toList();
  }

  /// Delete local record
  Future<void> deleteLocal({
    required String collection,
    required String docId,
  }) async {
    final key = '$collection/$docId';
    _localStore.remove(key);
    await _saveLocalData();

    // Queue delete sync
    await _addPendingSync(
      LocalRecord(
        collection: collection,
        docId: docId,
        data: {'_deleted': true},
        timestamp: DateTime.now(),
        isSynced: false,
        operation: 'delete',
      ),
    );
  }

  // ===== SYNC MANAGEMENT =====
  /// Manually trigger sync when online
  Future<SyncResult> syncPendingData() async {
    if (!_isOnline) {
      return SyncResult(
        success: false,
        synced: 0,
        failed: _pendingSyncs.length,
        errors: ['Device is offline'],
      );
    }

    var result = SyncResult(
      success: true,
      synced: 0,
      failed: 0,
      errors: [],
    );

    for (final sync in _pendingSyncs) {
      try {
        // Simulate cloud sync operation
        await _simulateCloudSync(sync);
        sync.isSynced = true;
        result = SyncResult(
          success: result.success,
          synced: result.synced + 1,
          failed: result.failed,
          errors: result.errors,
        );
        debugPrint('[OfflineDB] Synced: ${sync.collection}/${sync.docId}');
      } catch (e) {
        sync.syncAttempts++;
        result = SyncResult(
          success: result.success,
          synced: result.synced,
          failed: result.failed + 1,
          errors: [...result.errors, '$e'],
        );
        debugPrint('[OfflineDB] Sync failed for ${sync.docId}: $e');

        // Remove after 5 failed attempts
        if (sync.syncAttempts >= 5) {
          _pendingSyncs.remove(sync);
        }
      }
    }

    _pendingSyncs.removeWhere((s) => s.isSynced);
    _lastSyncTime = DateTime.now();
    await _savePendingSyncs();

    return result;
  }

  /// Get sync status
  Future<SyncStatus> getSyncStatus() async {
    return SyncStatus(
      isOnline: _isOnline,
      pendingCount: _pendingSyncs.length,
      lastSyncTime: _lastSyncTime,
      localRecordsCount: _localStore.length,
    );
  }

  // ===== DATA MIGRATION =====
  /// Export all local data (for backup/migration)
  Future<String> exportLocalData() async {
    final data = {
      'version': 1,
      'exportTime': DateTime.now().toIso8601String(),
      'records': _localStore.values
          .map((r) => {
            'collection': r.collection,
            'docId': r.docId,
            'data': r.data,
            'timestamp': r.timestamp.toIso8601String(),
          })
          .toList(),
    };

    return jsonEncode(data);
  }

  /// Import data from export
  Future<void> importLocalData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final records = data['records'] as List;

      for (final record in records) {
        final localRecord = LocalRecord(
          collection: record['collection'] as String,
          docId: record['docId'] as String,
          data: record['data'] as Map<String, dynamic>,
          timestamp: DateTime.parse(record['timestamp'] as String),
          isSynced: false,
        );

        _localStore['${localRecord.collection}/${localRecord.docId}'] = localRecord;
      }

      await _saveLocalData();
      debugPrint('[OfflineDB] Imported ${records.length} records');
    } catch (e) {
      debugPrint('[OfflineDB] Import failed: $e');
    }
  }

  // ===== BATCH OPERATIONS =====
  /// Batch write operations
  Future<void> batchWrite(List<BatchOperation> operations) async {
    for (final op in operations) {
      if (op.type == 'set') {
        await setLocal(
          collection: op.collection,
          docId: op.docId,
          data: op.data ?? {},
        );
      } else if (op.type == 'delete') {
        await deleteLocal(
          collection: op.collection,
          docId: op.docId,
        );
      }
    }
    debugPrint('[OfflineDB] Batch operation completed: ${operations.length} items');
  }

  // ===== INTERNAL HELPERS =====
  Future<void> _addPendingSync(LocalRecord record) async {
    _pendingSyncs.add(record as SyncRecord);
    await _savePendingSyncs();
  }

  Future<void> _simulateCloudSync(LocalRecord record) async {
    // Simulate network delay (100-500ms)
    await Future.delayed(
      Duration(milliseconds: 100 + (DateTime.now().millisecond % 400)),
    );

    // In real implementation, would call Firebase/backend here
    // For now, just mark as synced
    record.isSynced = true;
  }

  Future<void> _saveLocalData() async {
    final data = _localStore.entries
        .map((e) => jsonEncode({
          'key': e.key,
          'value': e.value.toJson(),
        }))
        .toList();
    await _prefs.setStringList('local_store', data);
  }

  Future<void> _loadLocalData() async {
    final data = _prefs.getStringList('local_store') ?? [];
    _localStore.clear();
    for (final item in data) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final record = LocalRecord.fromJson(decoded['value'] as Map<String, dynamic>);
        _localStore[decoded['key'] as String] = record;
      } catch (e) {
        debugPrint('[OfflineDB] Error loading record: $e');
      }
    }
  }

  Future<void> _savePendingSyncs() async {
    final data = _pendingSyncs
        .map((s) => jsonEncode(s.toJson()))
        .toList();
    await _prefs.setStringList('pending_syncs', data);
  }

  // Future<void> _loadPendingSyncs() async {
  //   // Placeholder for pending syncs load
  //   final data = _prefs.getStringList('pending_syncs') ?? [];
  //   _pendingSyncs.clear();
  //   for (final item in data) {
  //     try {
  //       _pendingSyncs.add(SyncRecord.fromJson(jsonDecode(item)));
  //     } catch (e) {
  //       debugPrint('[OfflineDB] Error loading sync: $e');
  //     }
  //   }
  // }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    return {
      'local_records': _localStore.length,
      'pending_syncs': _pendingSyncs.length,
      'is_online': _isOnline,
      'last_sync_time': _lastSyncTime.toIso8601String(),
      'collections': _localStore.values.map((r) => r.collection).toSet().toList(),
    };
  }
}

// ===== DATA MODELS =====

class LocalRecord {
  final String collection;
  final String docId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  bool isSynced;
  int syncAttempts;
  final String operation; // 'set' or 'delete'

  LocalRecord({
    required this.collection,
    required this.docId,
    required this.data,
    required this.timestamp,
    this.isSynced = false,
    this.syncAttempts = 0,
    this.operation = 'set',
  });

  Map<String, dynamic> toJson() => {
    'collection': collection,
    'docId': docId,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'isSynced': isSynced,
    'attempts': syncAttempts,
    'operation': operation,
  };

  factory LocalRecord.fromJson(Map<String, dynamic> json) {
    return LocalRecord(
      collection: json['collection'] as String,
      docId: json['docId'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      syncAttempts: json['attempts'] as int? ?? 0,
      operation: json['operation'] as String? ?? 'set',
    );
  }
}

class SyncRecord extends LocalRecord {
  SyncRecord({
    required super.collection,
    required super.docId,
    required super.data,
    required super.timestamp,
    super.isSynced,
    super.syncAttempts,
    super.operation,
  });

  factory SyncRecord.fromJson(Map<String, dynamic> json) {
    return SyncRecord(
      collection: json['collection'] as String,
      docId: json['docId'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      syncAttempts: json['attempts'] as int? ?? 0,
      operation: json['operation'] as String? ?? 'set',
    );
  }
}

class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.synced,
    required this.failed,
    required this.errors,
  });

  String getSummary() {
    return 'Sync Result: $synced synced, $failed failed${errors.isNotEmpty ? ', ${errors.length} errors' : ''}';
  }
}

class SyncStatus {
  final bool isOnline;
  final int pendingCount;
  final DateTime lastSyncTime;
  final int localRecordsCount;

  SyncStatus({
    required this.isOnline,
    required this.pendingCount,
    required this.lastSyncTime,
    required this.localRecordsCount,
  });

  String getStatusSummary() {
    return '''
Sync Status:
- Online: $isOnline
- Pending: $pendingCount
- Local Records: $localRecordsCount
- Last Sync: $lastSyncTime
''';
  }
}

class BatchOperation {
  final String type; // 'set', 'delete'
  final String collection;
  final String docId;
  final Map<String, dynamic>? data;

  BatchOperation({
    required this.type,
    required this.collection,
    required this.docId,
    this.data,
  });
}


