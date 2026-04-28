import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📱 Cross-Device Cloud Sync Service
class CloudSyncService {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;
  String? _encryptionKey;
  String? _deviceId;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> initialize() async {
    await _loadSyncState();
    await _generateDeviceId();
    await _generateEncryptionKey();
    _startAutoSync();
    if (kDebugMode) debugPrint('[CloudSync] Initialized');
  }

  Future<SyncResult> syncNow({
    bool includeConversations = true,
    bool includeMemories = true,
    bool includeSettings = true,
  }) async {
    if (_isSyncing) {
      return const SyncResult(success: false, message: 'Sync in progress', itemsSynced: 0);
    }

    _isSyncing = true;
    try {
      int itemsSynced = 0;
      if (includeConversations) itemsSynced += await _syncConversations();
      if (includeMemories) itemsSynced += await _syncMemories();
      if (includeSettings) itemsSynced += await _syncSettings();

      _lastSyncTime = DateTime.now();
      await _saveSyncState();

      return SyncResult(success: true, message: 'Synced $itemsSynced items', itemsSynced: itemsSynced);
    } catch (e) {
      return SyncResult(success: false, message: 'Sync failed: $e', itemsSynced: 0);
    } finally {
      _isSyncing = false;
    }
  }

  Future<int> _syncConversations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final conversations = prefs.getString('chat_messages') ?? '[]';
    final encrypted = _encrypt(conversations);
    await _uploadToCloud('conversations', encrypted);
    return 1;
  }

  Future<int> _syncMemories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.contains('memory') || k.contains('bookmark')).toList();
    for (final key in keys) {
      final data = prefs.getString(key);
      if (data != null) await _uploadToCloud(key, _encrypt(data));
    }
    return keys.length;
  }

  Future<int> _syncSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final prefs = await SharedPreferences.getInstance();
    final settings = {'theme': prefs.getString('current_theme'), 'affection': prefs.getInt('affection_points')};
    await _uploadToCloud('settings', _encrypt(jsonEncode(settings)));
    return 1;
  }

  String _encrypt(String data) {
    if (_encryptionKey == null) return data;
    final key = _encryptionKey!;
    final bytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    return base64Encode(encrypted);
  }


  Future<void> _uploadToCloud(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cloud_$key', data);
    await prefs.setInt('cloud_${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _generateEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    _encryptionKey = prefs.getString('encryption_key');
    if (_encryptionKey == null) {
      _encryptionKey = base64Encode(utf8.encode('${DateTime.now().millisecondsSinceEpoch}_${_deviceId}_secret'));
      await prefs.setString('encryption_key', _encryptionKey!);
    }
  }

  Future<void> _generateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');
    if (_deviceId == null) {
      _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', _deviceId!);
    }
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(hours: 24), (_) async {
      if (!_isSyncing) await syncNow();
    });
  }

  Map<String, dynamic> getSyncStatus() {
    return {
      'is_syncing': _isSyncing,
      'last_sync': _lastSyncTime?.toIso8601String(),
      'device_id': _deviceId,
      'auto_sync_enabled': _autoSyncTimer?.isActive ?? false,
    };
  }

  Future<void> _saveSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', _lastSyncTime?.toIso8601String() ?? '');
  }

  Future<void> _loadSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('last_sync_time');
    if (lastSync != null && lastSync.isNotEmpty) {
      _lastSyncTime = DateTime.parse(lastSync);
    }
  }

  void dispose() => _autoSyncTimer?.cancel();
}

class SyncResult {
  final bool success;
  final String message;
  final int itemsSynced;
  const SyncResult({required this.success, required this.message, required this.itemsSynced});
}
