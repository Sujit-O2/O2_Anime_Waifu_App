import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeUsageStats {
  final String themeName;
  final int usageCount;
  final Duration totalUsageTime;
  final DateTime lastUsed;

  ThemeUsageStats({
    required this.themeName,
    required this.usageCount,
    required this.totalUsageTime,
    required this.lastUsed,
  });

  factory ThemeUsageStats.fromMap(Map<String, dynamic> map) {
    return ThemeUsageStats(
      themeName: map['themeName'] ?? 'default',
      usageCount: map['usageCount'] ?? 0,
      totalUsageTime: Duration(
        milliseconds: map['totalUsageTimeMs'] ?? 0,
      ),
      lastUsed: map['lastUsed']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeName': themeName,
      'usageCount': usageCount,
      'totalUsageTimeMs': totalUsageTime.inMilliseconds,
      'lastUsed': lastUsed,
    };
  }
}

/// Service for tracking theme usage analytics
class ThemeUsageAnalyticsService {
  static final ThemeUsageAnalyticsService _instance =
      ThemeUsageAnalyticsService._internal();

  factory ThemeUsageAnalyticsService() {
    return _instance;
  }

  ThemeUsageAnalyticsService._internal();

  final _firestore = FirebaseFirestore.instance;

  /// Record theme selection
  Future<void> recordThemeUsage(String themeName) async {
    try {
      await _firestore.collection('theme_analytics').add({
        'themeName': themeName,
        'usedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get theme usage statistics
  Future<List<ThemeUsageStats>> getThemeStats() async {
    try {
      final snapshot = await _firestore.collection('theme_analytics').get();
      
      final themeMap = <String, List<DocumentSnapshot>>{};
      for (final doc in snapshot.docs) {
        final theme = doc['themeName'] ?? 'unknown';
        themeMap.putIfAbsent(theme, () => []).add(doc);
      }

      return themeMap.entries.map((entry) {
        return ThemeUsageStats(
          themeName: entry.key,
          usageCount: entry.value.length,
          totalUsageTime: Duration(minutes: entry.value.length),
          lastUsed: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
