import 'dart:async';

import 'package:flutter/foundation.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SERVICE SYNC ORCHESTRATOR
/// Manages synchronization, state sharing, and real-time updates across services
/// ════════════════════════════════════════════════════════════════════════════

/// Service sync status
enum SyncStatus {
  idle,       /// No sync in progress
  syncing,    /// Currently syncing
  success,    /// Last sync succeeded
  error,      /// Last sync failed
  offline,    /// No connection
}

/// Service sync event
class SyncEvent {
  final String serviceName;
  final SyncStatus status;
  final DateTime timestamp;
  final String? message;
  final dynamic data;

  SyncEvent({
    required this.serviceName,
    required this.status,
    required this.timestamp,
    this.message,
    this.data,
  });

  @override
  String toString() =>
      'SyncEvent($serviceName: $status at ${timestamp.toIso8601String()})';
}

/// Main service sync orchestrator
class ServiceSyncOrchestrator {
  static final ServiceSyncOrchestrator _instance =
      ServiceSyncOrchestrator._internal();

  factory ServiceSyncOrchestrator() => _instance;
  ServiceSyncOrchestrator._internal();

  final Map<String, SyncStatus> _serviceStatus = {};
  final _syncStreamController = StreamController<SyncEvent>.broadcast();
  final Map<String, StreamSubscription> _subscriptions = {};
  Timer? _syncTimer;
  Duration _syncInterval = const Duration(seconds: 30);
  bool _isOnline = true;

  /// Get sync status stream
  Stream<SyncEvent> get syncEvents => _syncStreamController.stream;

  /// Get current status of a service
  SyncStatus getServiceStatus(String serviceName) {
    return _serviceStatus[serviceName] ?? SyncStatus.idle;
  }

  /// Get overall sync status
  SyncStatus getOverallStatus() {
    if (_serviceStatus.isEmpty) return SyncStatus.idle;
    if (!_isOnline) return SyncStatus.offline;
    if (_serviceStatus.values.any((s) => s == SyncStatus.syncing)) {
      return SyncStatus.syncing;
    }
    if (_serviceStatus.values.any((s) => s == SyncStatus.error)) {
      return SyncStatus.error;
    }
    return SyncStatus.success;
  }

  /// Initialize sync orchestrator
  Future<void> initialize({
    Duration syncInterval = const Duration(seconds: 30),
  }) async {
    try {
      _syncInterval = syncInterval;
      debugPrint('🔄 Service Sync Orchestrator initializing...');
      
      // Start periodic sync
      _startPeriodicSync();
      
      debugPrint('✅ Service Sync Orchestrator initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Service Sync: $e');
      rethrow;
    }
  }

  /// Register a service for syncing
  Future<void> registerService(
    String serviceName,
    Future<void> Function() syncFunction,
  ) async {
    try {
      _serviceStatus[serviceName] = SyncStatus.idle;
      debugPrint('📌 Registered service: $serviceName');
    } catch (e) {
      debugPrint('❌ Error registering service $serviceName: $e');
    }
  }

  /// Manually trigger sync for a specific service
  Future<void> syncService(
    String serviceName,
    Future<void> Function() syncFunction,
  ) async {
    try {
      _updateStatus(serviceName, SyncStatus.syncing);

      await Future.delayed(const Duration(milliseconds: 100));
      await syncFunction();

      _updateStatus(serviceName, SyncStatus.success,
          message: 'Sync completed successfully');

      debugPrint('✅ $serviceName synced successfully');
    } on TimeoutException {
      _updateStatus(serviceName, SyncStatus.offline,
          message: 'Sync timeout - offline');
      debugPrint('⚠️ $serviceName sync timeout');
    } catch (e) {
      _updateStatus(serviceName, SyncStatus.error, message: 'Error: $e');
      debugPrint('❌ $serviceName sync error: $e');
    }
  }

  /// Sync all registered services
  Future<void> syncAll(
    Map<String, Future<void> Function()> syncFunctions,
  ) async {
    try {
      debugPrint('🔄 Starting full system sync...');
      
      final futures = syncFunctions.entries.map((entry) {
        return syncService(entry.key, entry.value).catchError((e) {
          debugPrint('Error syncing ${entry.key}: $e');
        });
      }).toList();

      await Future.wait(futures);
      debugPrint('✅ Full system sync completed');
    } catch (e) {
      debugPrint('❌ Error in full sync: $e');
    }
  }

  /// Set online/offline status
  void setConnectivity(bool isOnline) {
    _isOnline = isOnline;
    if (isOnline) {
      debugPrint('📱 Online - resuming sync');
      _startPeriodicSync();
    } else {
      debugPrint('📵 Offline - pausing sync');
      _syncTimer?.cancel();
    }
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isOnline && _serviceStatus.isNotEmpty) {
        debugPrint('🔄 Periodic sync triggered');
      }
    });
  }

  /// Update service status
  void _updateStatus(
    String serviceName,
    SyncStatus status, {
    String? message,
    dynamic data,
  }) {
    _serviceStatus[serviceName] = status;
    _syncStreamController.add(
      SyncEvent(
        serviceName: serviceName,
        status: status,
        timestamp: DateTime.now(),
        message: message,
        data: data,
      ),
    );
  }

  /// Get sync statistics
  Map<String, dynamic> getStats() {
    return {
      'totalServices': _serviceStatus.length,
      'syncingServices': _serviceStatus.values.where((s) => s == SyncStatus.syncing).length,
      'successfulServices': _serviceStatus.values.where((s) => s == SyncStatus.success).length,
      'failedServices': _serviceStatus.values.where((s) => s == SyncStatus.error).length,
      'offlineServices': _serviceStatus.values.where((s) => s == SyncStatus.offline).length,
      'isOnline': _isOnline,
      'overallStatus': getOverallStatus().toString(),
      'serviceStatuses': _serviceStatus,
    };
  }

  /// Cleanup and dispose
  Future<void> dispose() async {
    try {
      _syncTimer?.cancel();
      await _syncStreamController.close();
      
      for (var subscription in _subscriptions.values) {
        await subscription.cancel();
      }
      _subscriptions.clear();
      
      debugPrint('✅ Service Sync Orchestrator disposed');
    } catch (e) {
      debugPrint('❌ Error disposing Service Sync: $e');
    }
  }
}

/// Global orchestrator instance
final syncOrchestrator = ServiceSyncOrchestrator();

/// Mixin for services that support syncing
mixin SyncableService {
  String get serviceName;

  Future<void> sync();

  Future<void> registerSync() async {
    await syncOrchestrator.registerService(serviceName, sync);
  }

  Future<void> triggerSync() async {
    await syncOrchestrator.syncService(serviceName, sync);
  }
}

/// Sync state management
class SyncState {
  final Set<String> syncingServices = {};
  final Map<String, DateTime> lastSyncTimes = {};
  final Map<String, Exception?> lastErrors = {};

  bool get isSyncing => syncingServices.isNotEmpty;
  
  bool get hasErrors => lastErrors.values.any((e) => e != null);

  void markSyncing(String serviceName) {
    syncingServices.add(serviceName);
  }

  void markSyncDone(String serviceName) {
    syncingServices.remove(serviceName);
    lastSyncTimes[serviceName] = DateTime.now();
  }

  void recordError(String serviceName, Exception error) {
    lastErrors[serviceName] = error;
  }

  void clearError(String serviceName) {
    lastErrors[serviceName] = null;
  }

  bool isServiceSyncing(String serviceName) {
    return syncingServices.contains(serviceName);
  }

  Duration? timeSinceLastSync(String serviceName) {
    final lastTime = lastSyncTimes[serviceName];
    if (lastTime == null) return null;
    return DateTime.now().difference(lastTime);
  }

  Map<String, dynamic> getStatus() {
    return {
      'isSyncing': isSyncing,
      'hasErrors': hasErrors,
      'syncingServices': syncingServices.toList(),
      'lastSyncTimes': lastSyncTimes.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
      'errors': lastErrors.map(
        (k, v) => MapEntry(k, v?.toString()),
      ),
    };
  }
}

/// Global sync state
final syncState = SyncState();


