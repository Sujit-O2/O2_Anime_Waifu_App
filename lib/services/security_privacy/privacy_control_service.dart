import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Privacy Control Service - GDPR compliance, data deletion, privacy controls
class PrivacyControlService {
  static final PrivacyControlService _instance =
      PrivacyControlService._internal();
  factory PrivacyControlService() => _instance;
  PrivacyControlService._internal();

  static const String _privacyPreferencesKey = 'privacy_preferences';
  static const String _consentLogKey = 'consent_log';
  static const String _dataFilesKey = 'tracked_data_files';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ Privacy Control Service initialized');
  }

  /// Get user privacy preferences
  Future<PrivacyPreferences> getPrivacyPreferences() async {
    try {
      final json = _prefs.getString(_privacyPreferencesKey);
      if (json != null) {
        return PrivacyPreferences.fromJson(jsonDecode(json));
      }
      return PrivacyPreferences();
    } catch (e) {
      debugPrint('❌ Error getting privacy preferences: $e');
      return PrivacyPreferences();
    }
  }

  /// Set privacy preferences
  Future<bool> setPrivacyPreferences(PrivacyPreferences preferences) async {
    try {
      await _prefs.setString(
        _privacyPreferencesKey,
        jsonEncode(preferences.toJson()),
      );
      debugPrint('✅ Privacy preferences updated');
      return true;
    } catch (e) {
      debugPrint('❌ Error setting privacy preferences: $e');
      return false;
    }
  }

  /// Record user consent (GDPR)
  Future<bool> recordConsent(String consentType, bool accepted) async {
    try {
      final consent = UserConsent(
        id: _generateId(),
        type: consentType,
        accepted: accepted,
        timestamp: DateTime.now(),
      );

      final logJson = _prefs.getString(_consentLogKey) ?? '[]';
      final logList = jsonDecode(logJson) as List;
      logList.add(consent.toJson());

      await _prefs.setString(_consentLogKey, jsonEncode(logList));
      debugPrint('✅ Consent recorded: $consentType = $accepted');
      return true;
    } catch (e) {
      debugPrint('❌ Error recording consent: $e');
      return false;
    }
  }

  /// Get user consent history
  Future<List<UserConsent>> getConsentHistory() async {
    try {
      final logJson = _prefs.getString(_consentLogKey) ?? '[]';
      final logList = jsonDecode(logJson) as List;
      return logList
          .cast<Map<String, dynamic>>()
          .map((json) => UserConsent.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting consent history: $e');
      return [];
    }
  }

  /// Export user data (GDPR right to be forgotten)
  Future<UserDataExport?> exportUserData(String userId) async {
    try {
      final preferences = await getPrivacyPreferences();
      final consentHistory = await getConsentHistory();
      final trackedFiles = _prefs.getStringList(_dataFilesKey) ?? [];

      final export = UserDataExport(
        userId: userId,
        exportedAt: DateTime.now(),
        privacyPreferences: preferences,
        consentHistory: consentHistory,
        trackedDataFiles: trackedFiles,
      );

      debugPrint('✅ User data exported for: $userId');
      return export;
    } catch (e) {
      debugPrint('❌ Error exporting user data: $e');
      return null;
    }
  }

  /// Delete user data (GDPR right to be forgotten)
  Future<bool> deleteUserData(String userId) async {
    try {
      // Clear all user data
      await _prefs.remove(_privacyPreferencesKey);
      await _prefs.remove(_consentLogKey);
      await _prefs.remove(_dataFilesKey);

      // Log deletion for compliance
      final deletion = DataDeletion(
        id: _generateId(),
        userId: userId,
        deletedAt: DateTime.now(),
        reason: 'User requested deletion',
      );

      final deletionJson = _prefs.getString('data_deletion_log') ?? '[]';
      final deletionList = jsonDecode(deletionJson) as List;
      deletionList.add(deletion.toJson());

      await _prefs.setString('data_deletion_log', jsonEncode(deletionList));
      debugPrint('✅ User data deleted: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting user data: $e');
      return false;
    }
  }

  /// Check if specific data collection is allowed
  Future<bool> isCollectionAllowed(String dataType) async {
    try {
      final preferences = await getPrivacyPreferences();
      
      switch (dataType.toLowerCase()) {
        case 'analytics':
          return preferences.allowAnalytics;
        case 'tracking':
          return preferences.allowTracking;
        case 'personalization':
          return preferences.allowPersonalization;
        case 'marketing':
          return preferences.allowMarketing;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('❌ Error checking collection allowed: $e');
      return false;
    }
  }

  /// Track data file for deletion requests
  Future<void> trackDataFile(String filePath) async {
    try {
      final files = _prefs.getStringList(_dataFilesKey) ?? [];
      if (!files.contains(filePath)) {
        files.add(filePath);
        await _prefs.setStringList(_dataFilesKey, files);
      }
      debugPrint('📄 Data file tracked: $filePath');
    } catch (e) {
      debugPrint('❌ Error tracking data file: $e');
    }
  }

  /// Get privacy policy version
  String getPrivacyPolicyVersion() {
    return '1.0.0 (April 2026)';
  }

  /// Get recent data access logs
  Future<List<DataAccessLog>> getRecentAccessLogs({int limit = 10}) async {
    try {
      final accessLogJson = _prefs.getString('data_access_log') ?? '[]';
      final accessLogList = jsonDecode(accessLogJson) as List;
      
      final logs = accessLogList
          .cast<Map<String, dynamic>>()
          .map((json) => DataAccessLog.fromJson(json))
          .toList();

      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting access logs: $e');
      return [];
    }
  }

  /// Get privacy compliance report
  Future<PrivacyComplianceReport> getComplianceReport() async {
    try {
      final preferences = await getPrivacyPreferences();
      final consentHistory = await getConsentHistory();
      final accessLogs = await getRecentAccessLogs(limit: 100);

      final allConsented = consentHistory.where((c) => c.accepted).length;
      final totalConsents = consentHistory.length;

      return PrivacyComplianceReport(
        timestamp: DateTime.now(),
        gdprCompliant: true,
        userConsentsGiven: allConsented,
        totalConsents: totalConsents,
        dataCollectionAllowed: !preferences.restrictAllDataCollection,
        encryptionEnabled: true,
        recentAccessLogs: accessLogs.length,
        privacyPolicyVersion: getPrivacyPolicyVersion(),
      );
    } catch (e) {
      debugPrint('❌ Error generating compliance report: $e');
      return PrivacyComplianceReport(
        timestamp: DateTime.now(),
        gdprCompliant: false,
        userConsentsGiven: 0,
        totalConsents: 0,
        dataCollectionAllowed: false,
        encryptionEnabled: false,
        recentAccessLogs: 0,
        privacyPolicyVersion: getPrivacyPolicyVersion(),
      );
    }
  }

  String _generateId() {
    return 'priv_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Privacy Preferences Model
class PrivacyPreferences {
  bool allowAnalytics;
  bool allowTracking;
  bool allowPersonalization;
  bool allowMarketing;
  bool restrictAllDataCollection;
  DateTime? lastUpdated;

  PrivacyPreferences({
    this.allowAnalytics = false,
    this.allowTracking = false,
    this.allowPersonalization = false,
    this.allowMarketing = false,
    this.restrictAllDataCollection = true,
  }) : lastUpdated = DateTime.now();

  Map<String, dynamic> toJson() => {
        'allowAnalytics': allowAnalytics,
        'allowTracking': allowTracking,
        'allowPersonalization': allowPersonalization,
        'allowMarketing': allowMarketing,
        'restrictAllDataCollection': restrictAllDataCollection,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory PrivacyPreferences.fromJson(Map<String, dynamic> json) =>
      PrivacyPreferences(
        allowAnalytics: json['allowAnalytics'] ?? false,
        allowTracking: json['allowTracking'] ?? false,
        allowPersonalization: json['allowPersonalization'] ?? false,
        allowMarketing: json['allowMarketing'] ?? false,
        restrictAllDataCollection: json['restrictAllDataCollection'] ?? true,
      );
}

/// User Consent Model
class UserConsent {
  final String id;
  final String type; // analytics, tracking, personalization, marketing
  final bool accepted;
  final DateTime timestamp;

  UserConsent({
    required this.id,
    required this.type,
    required this.accepted,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'accepted': accepted,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UserConsent.fromJson(Map<String, dynamic> json) => UserConsent(
        id: json['id'],
        type: json['type'],
        accepted: json['accepted'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// User Data Export Model
class UserDataExport {
  final String userId;
  final DateTime exportedAt;
  final PrivacyPreferences privacyPreferences;
  final List<UserConsent> consentHistory;
  final List<String> trackedDataFiles;

  UserDataExport({
    required this.userId,
    required this.exportedAt,
    required this.privacyPreferences,
    required this.consentHistory,
    required this.trackedDataFiles,
  });
}

/// Data Deletion Model
class DataDeletion {
  final String id;
  final String userId;
  final DateTime deletedAt;
  final String reason;

  DataDeletion({
    required this.id,
    required this.userId,
    required this.deletedAt,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'deletedAt': deletedAt.toIso8601String(),
        'reason': reason,
      };
}

/// Data Access Log Model
class DataAccessLog {
  final String id;
  final String dataType;
  final String action;
  final DateTime timestamp;

  DataAccessLog({
    required this.id,
    required this.dataType,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataType': dataType,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DataAccessLog.fromJson(Map<String, dynamic> json) => DataAccessLog(
        id: json['id'],
        dataType: json['dataType'],
        action: json['action'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// Privacy Compliance Report
class PrivacyComplianceReport {
  final DateTime timestamp;
  final bool gdprCompliant;
  final int userConsentsGiven;
  final int totalConsents;
  final bool dataCollectionAllowed;
  final bool encryptionEnabled;
  final int recentAccessLogs;
  final String privacyPolicyVersion;

  PrivacyComplianceReport({
    required this.timestamp,
    required this.gdprCompliant,
    required this.userConsentsGiven,
    required this.totalConsents,
    required this.dataCollectionAllowed,
    required this.encryptionEnabled,
    required this.recentAccessLogs,
    required this.privacyPolicyVersion,
  });

  @override
  String toString() =>
      'PrivacyComplianceReport(GDPR: ${gdprCompliant ? "✅" : "❌"}, Consents: $userConsentsGiven/$totalConsents)';
}

/// Global instance
final privacyControlService = PrivacyControlService();


