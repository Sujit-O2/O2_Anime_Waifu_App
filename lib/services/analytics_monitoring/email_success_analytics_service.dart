import 'package:cloud_firestore/cloud_firestore.dart';

class EmailSuccessMetrics {
  final int totalSent;
  final int successCount;
  final double successRate;
  final DateTime lastUpdated;

  EmailSuccessMetrics({
    required this.totalSent,
    required this.successCount,
    required this.successRate,
    required this.lastUpdated,
  });

  factory EmailSuccessMetrics.fromMap(Map<String, dynamic> map) {
    return EmailSuccessMetrics(
      totalSent: map['totalSent'] ?? 0,
      successCount: map['successCount'] ?? 0,
      successRate: (map['successRate'] ?? 0.0).toDouble(),
      lastUpdated: map['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSent': totalSent,
      'successCount': successCount,
      'successRate': successRate,
      'lastUpdated': lastUpdated,
    };
  }
}

/// Service for tracking email sending success rates and analytics
class EmailSuccessAnalyticsService {
  static final EmailSuccessAnalyticsService _instance =
      EmailSuccessAnalyticsService._internal();

  factory EmailSuccessAnalyticsService() {
    return _instance;
  }

  EmailSuccessAnalyticsService._internal();

  final _firestore = FirebaseFirestore.instance;

  /// Record email sent
  Future<void> recordEmailSent({required bool success}) async {
    try {
      await _firestore.collection('email_analytics').add({
        'success': success,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get email success metrics
  Future<EmailSuccessMetrics> getMetrics() async {
    try {
      final snapshot = await _firestore.collection('email_analytics').get();
      
      final totalSent = snapshot.docs.length;
      final successCount = snapshot.docs
          .where((doc) => doc['success'] == true)
          .length;
      final successRate = totalSent > 0
          ? (successCount / totalSent).toDouble()
          : 0.0;

      return EmailSuccessMetrics(
        totalSent: totalSent,
        successCount: successCount,
        successRate: successRate,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return EmailSuccessMetrics(
        totalSent: 0,
        successCount: 0,
        successRate: 0.0,
        lastUpdated: DateTime.now(),
      );
    }
  }
}
