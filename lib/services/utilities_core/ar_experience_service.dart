import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// AR experience service: Avatar rendering, AR camera, location-based features
class ArExperienceService {
  static final ArExperienceService _instance =
      ArExperienceService._internal();
  factory ArExperienceService() => _instance;
  ArExperienceService._internal();



  // ── AR Avatar Configuration ──────────────────────────────────────────────

  /// Get AR avatar configuration for character
  static Future<Map<String, dynamic>> getAvatarArConfiguration(
    String characterId,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('characters')
          .doc(characterId)
          .collection('ar_config')
          .doc('avatar')
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      }

      // Default configuration if not set
      return {
        'modelUrl': 'assets/models/avatar_default.glb',
        'scale': 1.0,
        'rotationY': 0.0,
        'animationState': 'idle',
        'emotionState': 'neutral',
      };
    } catch (e) {
      debugPrint('Error fetching avatar config: $e');
      return {};
    }
  }

  /// Update avatar AR configuration
  static Future<void> updateAvatarConfiguration(
    String characterId, {
    required String modelUrl,
    required double scale,
    required double rotationY,
    required String animationState,
    required String emotionState,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('characters')
          .doc(characterId)
          .collection('ar_config')
          .doc('avatar')
          .set({
        'modelUrl': modelUrl,
        'scale': scale,
        'rotationY': rotationY,
        'animationState': animationState,
        'emotionState': emotionState,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating avatar config: $e');
    }
  }

  // ── AR Camera Features ───────────────────────────────────────────────────

  /// Get available AR frames for selfies
  static Future<List<Map<String, dynamic>>> getArFrames() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ar_resources')
          .doc('frames')
          .collection('available')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching AR frames: $e');
      return [];
    }
  }

  /// Log AR selfie taken
  static Future<void> logArSelfieTaken(
    String uid,
    String characterId,
    String frameId,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('ar_selfies').add({
        'uid': uid,
        'characterId': characterId,
        'frameId': frameId,
        'timestamp': FieldValue.serverTimestamp(),
        'imagePath': 'selfies/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
      });

      // Increase affection for taking selfie
      await FirebaseFirestore.instance
          .collection('affection')
          .doc(uid)
          .update({
        '$characterId.selfieCount': FieldValue.increment(1),
        '$characterId.affectionPoints': FieldValue.increment(10),
      });
    } catch (e) {
      debugPrint('Error logging AR selfie: $e');
    }
  }

  /// Get AR selfie gallery
  static Future<List<Map<String, dynamic>>> getArSelfieGallery(
    String uid, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ar_selfies')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching AR selfies: $e');
      return [];
    }
  }

  // ── Location-Based Features ──────────────────────────────────────────────

  /// Get location-based AR messages
  static Future<Map<String, dynamic>> getLocationBasedContent(
    double latitude,
    double longitude,
  ) async {
    try {
      // Query nearby AR content points
      final snapshot = await FirebaseFirestore.instance
          .collection('ar_locations')
          .where('latitude', isGreaterThan: latitude - 0.1)
          .where('latitude', isLessThan: latitude + 0.1)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'found': false, 'message': 'No AR content at this location'};
      }

      final nearestLocation = snapshot.docs.first.data();
      return {
        'found': true,
        'message': nearestLocation['message'],
        'characterId': nearestLocation['characterId'],
        'latitude': nearestLocation['latitude'],
        'longitude': nearestLocation['longitude'],
        'distance': _calculateDistance(
          latitude,
          longitude,
          nearestLocation['latitude'],
          nearestLocation['longitude'],
        ),
      };
    } catch (e) {
      debugPrint('Error getting location-based content: $e');
      return {'found': false};
    }
  }

  /// Create location-based AR message
  static Future<void> createLocationMessage(
    String characterId,
    String message,
    double latitude,
    double longitude,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('ar_locations').add({
        'characterId': characterId,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'radius': 0.01, // ~1km radius
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating location message: $e');
    }
  }

  /// Calculate distance between two coordinates (approximately)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Simplified distance calculation
    final latDiff = (lat1 - lat2).abs();
    final lonDiff = (lon1 - lon2).abs();
    return (latDiff + lonDiff) * 111000; // Approximate meters
  }

  // ── AR Avatar Animations ─────────────────────────────────────────────────

  /// Trigger avatar animation
  static Future<void> triggerAvatarAnimation(
    String characterId,
    String animationName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('characters')
          .doc(characterId)
          .collection('ar_config')
          .doc('avatar')
          .update({
        'animationState': animationName,
        'animationTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error triggering animation: $e');
    }
  }

  /// Set avatar emotion
  static Future<void> setAvatarEmotion(
    String characterId,
    String emotionState,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('characters')
          .doc(characterId)
          .collection('ar_config')
          .doc('avatar')
          .update({
        'emotionState': emotionState,
        'emotionTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting emotion: $e');
    }
  }

  /// Get available animations
  static Future<List<String>> getAvailableAnimations(
    String characterId,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('characters')
          .doc(characterId)
          .collection('ar_config')
          .doc('animations')
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        return List<String>.from(data['list'] ?? []);
      }

      // Default animations
      return [
        'idle',
        'wave',
        'dance',
        'jump',
        'cry',
        'laugh',
        'blush',
        'wink',
      ];
    } catch (e) {
      debugPrint('Error fetching animations: $e');
      return [];
    }
  }

  // ── AR Statistics ────────────────────────────────────────────────────────

  /// Get AR usage statistics
  static Future<Map<String, dynamic>> getArStatistics(String uid) async {
    try {
      final selfiesSnapshot = await FirebaseFirestore.instance
          .collection('ar_selfies')
          .where('uid', isEqualTo: uid)
          .count()
          .get();

      final locationsSnapshot = await FirebaseFirestore.instance
          .collection('ar_locations_visited')
          .where('uid', isEqualTo: uid)
          .count()
          .get();

      return {
        'selfiesTaken': selfiesSnapshot.count ?? 0,
        'locationsVisited': locationsSnapshot.count ?? 0,
        'totalArTime': 0, // TODO: Calculate from sessions
        'favoriteFrame': null, // TODO: Get most used frame
      };
    } catch (e) {
      debugPrint('Error getting AR statistics: $e');
      return {};
    }
  }

  /// Log location visit
  static Future<void> logLocationVisit(
    String uid,
    double latitude,
    double longitude,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('ar_locations_visited')
          .add({
        'uid': uid,
        'latitude': latitude,
        'longitude': longitude,
        'visitedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging location visit: $e');
    }
  }
}


