import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Cloud Settings Synchronization Service
/// Backup, restore, and sync settings across devices
class CloudSettingsSyncService {
  static final CloudSettingsSyncService _instance =
      CloudSettingsSyncService._internal();

  factory CloudSettingsSyncService() => _instance;
  CloudSettingsSyncService._internal();

  late SharedPreferences _prefs;
  late FirebaseFirestore _db;
  bool _syncEnabled = false;
  DateTime? _lastSyncTime;
  // final Map<String, dynamic> _cachedSettings = {};

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _db = FirebaseFirestore.instance;
      _syncEnabled = _prefs.getBool('cloud_sync_enabled') ?? false;
      _lastSyncTime = _getLastSyncTime();
      if (kDebugMode)
        debugPrint('[Cloud Settings Sync] Initialized (Sync: $_syncEnabled)');
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Error: $e');
    }
  }

  // ===== SYNC MANAGEMENT =====
  Future<bool> enableCloudSync(String userId) async {
    try {
      _syncEnabled = true;
      await _prefs.setBool('cloud_sync_enabled', true);
      await _prefs.setString('cloud_sync_user_id', userId);

      // Perform initial full backup
      await backupSettingsToCloud(userId);

      if (kDebugMode) debugPrint('✅ Cloud sync enabled for user: $userId');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Enable error: $e');
      return false;
    }
  }

  Future<bool> disableCloudSync() async {
    try {
      _syncEnabled = false;
      await _prefs.setBool('cloud_sync_enabled', false);
      if (kDebugMode) debugPrint('✅ Cloud sync disabled');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Disable error: $e');
      return false;
    }
  }

  bool get isSyncEnabled => _syncEnabled;

  DateTime? get lastSyncTime => _lastSyncTime;

  // ===== BACKUP & RESTORE =====
  Future<void> backupSettingsToCloud(String userId) async {
    if (!_syncEnabled) return;

    try {
      final allSettings = _collectAllSettings();

      await _db.collection('user_settings_backup').doc(userId).set({
        'userId': userId,
        'settings': allSettings,
        'backupVersion': 1,
        'backupTimestamp': DateTime.now().toIso8601String(),
        'deviceInfo': {
          'platform': defaultTargetPlatform.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
        'checksum': _calculateChecksum(allSettings),
      }, SetOptions(merge: true));

      _lastSyncTime = DateTime.now();
      await _prefs.setString(
          'cloud_settings_last_backup', _lastSyncTime!.toIso8601String());

      if (kDebugMode) debugPrint('✅ Settings backed up to cloud');
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Backup error: $e');
    }
  }

  Future<Map<String, dynamic>?> restoreSettingsFromCloud(String userId) async {
    try {
      final doc =
          await _db.collection('user_settings_backup').doc(userId).get();

      if (!doc.exists) {
        if (kDebugMode) debugPrint('⚠️ No backup found for user: $userId');
        return null;
      }

      final data = doc.data()!;
      final settings = data['settings'] as Map<String, dynamic>;
      final checksum = data['checksum'];

      // Verify integrity
      if (!_verifyChecksum(settings, checksum)) {
        if (kDebugMode)
          debugPrint('⚠️ Checksum mismatch - backup may be corrupted');
        return null;
      }

      // Apply restored settings
      await _applySettings(settings);

      _lastSyncTime = DateTime.now();
      await _prefs.setString(
          'cloud_settings_last_restore', _lastSyncTime!.toIso8601String());

      if (kDebugMode) debugPrint('✅ Settings restored from cloud');
      return settings;
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Restore error: $e');
      return null;
    }
  }

  // ===== SELECTIVE SYNC =====
  Future<void> syncSpecificSetting(
      String userId, String settingKey, dynamic value) async {
    if (!_syncEnabled) return;

    try {
      await _db.collection('user_settings_sync').doc(userId).update({
        'settings.$settingKey': value,
        'lastUpdate': DateTime.now().toIso8601String(),
      }).catchError((_) async {
        // Create if doesn't exist
        await _db.collection('user_settings_sync').doc(userId).set({
          'userId': userId,
          'settings': {settingKey: value},
          'lastUpdate': DateTime.now().toIso8601String(),
        });
      });

      if (kDebugMode) debugPrint('✅ Setting synced: $settingKey');
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Sync error: $e');
    }
  }

  Future<dynamic> fetchSyncedSetting(String userId, String settingKey) async {
    try {
      final doc = await _db.collection('user_settings_sync').doc(userId).get();
      if (!doc.exists) return null;

      final settings = doc['settings'] as Map<String, dynamic>;
      return settings[settingKey];
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Fetch error: $e');
      return null;
    }
  }

  // ===== MULTI-DEVICE SYNC =====
  Future<List<SyncConflict>> detectConflicts(String userId) async {
    try {
      final localSettings = _collectAllSettings();
      final cloudSettings = await restoreSettingsFromCloud(userId);

      if (cloudSettings == null) return [];

      final conflicts = <SyncConflict>[];

      for (final key in localSettings.keys) {
        if (cloudSettings.containsKey(key) &&
            localSettings[key] != cloudSettings[key]) {
          conflicts.add(SyncConflict(
            key: key,
            localValue: localSettings[key],
            cloudValue: cloudSettings[key],
            timestamp: DateTime.now(),
          ));
        }
      }

      return conflicts;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[Cloud Settings Sync] Conflict detection error: $e');
      return [];
    }
  }

  Future<void> resolveSyncConflict(String userId, SyncConflict conflict,
      {required bool useLocal}) async {
    try {
      final value = useLocal ? conflict.localValue : conflict.cloudValue;

      // Update cloud
      await _db.collection('user_settings_sync').doc(userId).update({
        'settings.${conflict.key}': value,
      });

      // Update local
      final key = 'setting_${conflict.key}';
      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      }

      if (kDebugMode)
        debugPrint(
            '✅ Conflict resolved: ${conflict.key} (using ${useLocal ? 'local' : 'cloud'})');
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Resolution error: $e');
    }
  }

  // ===== DEVICE MANAGEMENT =====
  Future<List<BackupDevice>> getLinkedDevices(String userId) async {
    try {
      final doc = await _db.collection('user_devices').doc(userId).get();
      if (!doc.exists) return [];

      final devices = (doc['devices'] as List<dynamic>? ?? [])
          .map((d) => BackupDevice.fromJson(d as Map<String, dynamic>))
          .toList();

      return devices;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[Cloud Settings Sync] Device fetch error: $e');
      return [];
    }
  }

  Future<void> registerDevice(String userId, String deviceName) async {
    try {
      final device = BackupDevice(
        deviceId: _generateDeviceId(),
        deviceName: deviceName,
        os: defaultTargetPlatform.toString(),
        lastSyncTime: DateTime.now(),
        isActive: true,
      );

      await _db.collection('user_devices').doc(userId).update({
        'devices': FieldValue.arrayUnion([device.toJson()]),
      }).catchError((_) async {
        await _db.collection('user_devices').doc(userId).set({
          'userId': userId,
          'devices': [device.toJson()],
        });
      });

      if (kDebugMode) debugPrint('✅ Device registered: $deviceName');
    } catch (e) {
      if (kDebugMode)
        debugPrint('[Cloud Settings Sync] Device registration error: $e');
    }
  }

  // ===== EXPORT & IMPORT =====
  Future<String> exportSettingsAsJson() async {
    try {
      final settings = _collectAllSettings();
      settings['exportedAt'] = DateTime.now().toIso8601String();
      settings['format'] = 'json';
      return jsonEncode(settings);
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Export error: $e');
      return '{}';
    }
  }

  Future<bool> importSettingsFromJson(String jsonData) async {
    try {
      final settings = jsonDecode(jsonData) as Map<String, dynamic>;
      settings.remove('exportedAt');
      settings.remove('format');

      await _applySettings(settings);
      if (kDebugMode) debugPrint('✅ Settings imported from JSON');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Cloud Settings Sync] Import error: $e');
      return false;
    }
  }

  // ===== INTERNAL HELPERS =====
  Map<String, dynamic> _collectAllSettings() {
    final settings = <String, dynamic>{};

    // Collect all preferences
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith('_internal_')) {
        settings[key] = _prefs.get(key);
      }
    }

    return settings;
  }

  Future<void> _applySettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      if (entry.value is bool) {
        await _prefs.setBool(entry.key, entry.value);
      } else if (entry.value is int) {
        await _prefs.setInt(entry.key, entry.value);
      } else if (entry.value is double) {
        await _prefs.setDouble(entry.key, entry.value);
      } else if (entry.value is String) {
        await _prefs.setString(entry.key, entry.value);
      }
    }
  }

  String _calculateChecksum(Map<String, dynamic> data) {
    final json = jsonEncode(data);
    return json.hashCode.toString();
  }

  bool _verifyChecksum(Map<String, dynamic> data, dynamic checksum) {
    return _calculateChecksum(data).toString() == checksum.toString();
  }

  DateTime? _getLastSyncTime() {
    final stored = _prefs.getString('cloud_settings_last_backup');
    if (stored != null) {
      return DateTime.tryParse(stored);
    }
    return null;
  }

  String _generateDeviceId() {
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// ===== DATA MODELS =====

class SyncConflict {
  final String key;
  final dynamic localValue;
  final dynamic cloudValue;
  final DateTime timestamp;

  SyncConflict({
    required this.key,
    required this.localValue,
    required this.cloudValue,
    required this.timestamp,
  });
}

class BackupDevice {
  final String deviceId;
  final String deviceName;
  final String os;
  final DateTime lastSyncTime;
  final bool isActive;

  BackupDevice({
    required this.deviceId,
    required this.deviceName,
    required this.os,
    required this.lastSyncTime,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'os': os,
        'lastSyncTime': lastSyncTime.toIso8601String(),
        'isActive': isActive,
      };

  factory BackupDevice.fromJson(Map<String, dynamic> json) => BackupDevice(
        deviceId: json['deviceId'],
        deviceName: json['deviceName'],
        os: json['os'],
        lastSyncTime: DateTime.parse(json['lastSyncTime']),
        isActive: json['isActive'],
      );
}
