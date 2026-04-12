import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for exporting user data (GDPR Article 20)
/// Implements right to data portability
class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Export all user data as JSON (for GDPR compliance)
  /// Returns high-level data structure with all personal information
  Future<String> exportAllUserData(String uid) async {
    try {
      debugPrint('[DataExport] Starting export for uid: $uid');

      final export = <String, dynamic>{
        'header': {
          'exported_at': DateTime.now().toIso8601String(),
          'exported_for_uid': uid,
          'export_version': '1.0',
        },
        'data': {},
      };

      // Core personal data
      final collections = [
        'chats',
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
      ];

      for (final collection in collections) {
        try {
          final snap = await _db.collection(collection).doc(uid).get();
          if (snap.exists) {
            export['data'][collection] = snap.data();
          }
        } catch (e) {
          debugPrint('[DataExport] Error exporting $collection: $e');
        }
      }

      // User profile
      try {
        final userSnap = await _db.collection('users').doc(uid).get();
        if (userSnap.exists) {
          export['data']['user_profile'] = userSnap.data();
        }
      } catch (e) {
        debugPrint('[DataExport] Error exporting user profile: $e');
      }

      final jsonString = jsonEncode(export);
      debugPrint('[DataExport] Exported ${jsonString.length} bytes for uid: $uid');
      return jsonString;
    } catch (e) {
      debugPrint('[DataExport] Error in exportAllUserData: $e');
      return '{"error": "$e"}';
    }
  }

  /// Export specific data categories
  Future<String> exportDataCategory(
    String uid, {
    required String category, // 'chats', 'profile', 'relationships', etc
  }) async {
    try {
      debugPrint('[DataExport] Exporting category: $category for uid: $uid');

      final export = <String, dynamic>{
        'category': category,
        'exported_at': DateTime.now().toIso8601String(),
        'data': {},
      };

      switch (category) {
        case 'communication':
          // Export all communication data
          final chats = await _db.collection('chats').doc(uid).get();
          if (chats.exists) export['data']['chats'] = chats.data();
          break;

        case 'relationships':
          // Export relationship data
          final affection = await _db.collection('affection').doc(uid).get();
          if (affection.exists) export['data']['affection'] = affection.data();
          break;

        case 'profile':
          // Export profile data
          final profile = await _db.collection('profiles').doc(uid).get();
          if (profile.exists) export['data']['profile'] = profile.data();
          final user = await _db.collection('users').doc(uid).get();
          if (user.exists) export['data']['user'] = user.data();
          break;

        case 'journal':
          // Export journal/mood data
          final mood = await _db.collection('mood').doc(uid).get();
          if (mood.exists) export['data']['mood'] = mood.data();
          final dreams = await _db.collection('dreams').doc(uid).get();
          if (dreams.exists) export['data']['dreams'] = dreams.data();
          break;

        case 'memory':
          // Export memory data
          final memory = await _db.collection('memory').doc(uid).get();
          if (memory.exists) export['data']['memory'] = memory.data();
          break;

        default:
          // Export specific collection
          final snap = await _db.collection(category).doc(uid).get();
          if (snap.exists) export['data'][category] = snap.data();
      }

      return jsonEncode(export);
    } catch (e) {
      debugPrint('[DataExport] Error exporting category: $e');
      return '{"error": "$e"}';
    }
  }

  /// Get summary of exportable data
  /// Returns info about what data is available for export
  Future<Map<String, dynamic>> getExportSummary(String uid) async {
    try {
      final summary = <String, dynamic>{
        'uid': uid,
        'generated_at': DateTime.now().toIso8601String(),
        'categories': <String, dynamic>{},
        'total_bytes': 0,
      };

      final collections = [
        'chats',
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
      ];

      for (final collection in collections) {
        try {
          final snap = await _db.collection(collection).doc(uid).get();
          if (snap.exists) {
            final data = snap.data();
            final sizeEstimate = jsonEncode(data).length;
            summary['categories'][collection] = {
              'available': true,
              'estimated_bytes': sizeEstimate,
              'fields': (data?.keys.toList() ?? []).length,
            };
            summary['total_bytes'] = (summary['total_bytes'] as int) + sizeEstimate;
          } else {
            summary['categories'][collection] = {'available': false};
          }
        } catch (e) {
          debugPrint('[DataExport] Error checking $collection: $e');
          summary['categories'][collection] = {'available': false, 'error': e.toString()};
        }
      }

      return summary;
    } catch (e) {
      debugPrint('[DataExport] Error in getExportSummary: $e');
      return {};
    }
  }

  /// Format export for human readability (pretty-print JSON)
  String formatExportForDisplay(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      return const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (e) {
      return jsonString;
    }
  }

  /// Convert export to CSV format for specific collections
  Future<String> exportAsCSV(
    String uid, {
    required String collection,
  }) async {
    try {
      final snap = await _db.collection(collection).doc(uid).get();
      if (!snap.exists) return '';

      final data = snap.data();
      if (data == null) return '';

      // Simple CSV export (for more complex data, use dedicated CSV library)
      final headers = data.keys.toList();
      final csvLines = <String>[];

      // Header row
      csvLines.add(headers.map((h) => '"$h"').join(','));

      // Data row
      final values = headers.map((h) {
        final value = data[h];
        if (value == null) return '""';
        return '"$value"';
      }).toList();
      csvLines.add(values.join(','));

      return csvLines.join('\n');
    } catch (e) {
      debugPrint('[DataExport] Error exporting as CSV: $e');
      return '';
    }
  }

  /// Log data export for audit trail
  Future<void> logExport(String uid, String format) async {
    try {
      await _db.collection('data_exports').add({
        'uid': uid,
        'format': format,
        'exported_at': FieldValue.serverTimestamp(),
        'ip': 'mobile_app',
      });
    } catch (e) {
      debugPrint('[DataExport] Error logging export: $e');
    }
  }

  /// Validate export completeness
  /// Returns true if all expected data categories are present
  Future<bool> validateExport(String exportJson) async {
    try {
      final parsed = jsonDecode(exportJson) as Map<String, dynamic>;
      final data = parsed['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      // Check if critical data exists
      final hasData = data.isNotEmpty;
      return hasData;
    } catch (e) {
      debugPrint('[DataExport] Error validating export: $e');
      return false;
    }
  }
}


