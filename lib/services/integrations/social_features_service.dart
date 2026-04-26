import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Social features service: Achievement sharing, challenges, social sync
class SocialFeaturesService {
  static final SocialFeaturesService _instance =
      SocialFeaturesService._internal();
  factory SocialFeaturesService() => _instance;
  SocialFeaturesService._internal();

  // ── Achievement Sharing ──────────────────────────────────────────────────

  /// Share achievement with friends
  static Future<void> shareAchievement({
    required String uid,
    required String achievementId,
    required String achievementName,
    required String characterId,
  }) async {
    try {
      // Create share record
      await FirebaseFirestore.instance.collection('achievement_shares').add({
        'uid': uid,
        'achievementId': achievementId,
        'achievementName': achievementName,
        'characterId': characterId,
        'sharedAt': FieldValue.serverTimestamp(),
      });

      // Notify friends
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('friends')
          .where('userId1', isEqualTo: uid)
          .get();

      for (var doc in friendsSnapshot.docs) {
        final friendId = doc.get('userId2');
        await FirebaseFirestore.instance.collection('notifications').add({
          'uid': friendId,
          'type': 'achievement_shared',
          'fromUid': uid,
          'achievementId': achievementId,
          'achievementName': achievementName,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      // Increase affection for sharing
      await FirebaseFirestore.instance.collection('affection').doc(uid).update({
        '$characterId.sharingCount': FieldValue.increment(1),
        '$characterId.affectionPoints': FieldValue.increment(5),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error sharing achievement: $e');
    }
  }

  /// Get shared achievements from friends
  static Future<List<Map<String, dynamic>>> getFriendsAchievements(
    String uid, {
    int limit = 20,
  }) async {
    try {
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('friends')
          .where('userId1', isEqualTo: uid)
          .get();

      final friendIds =
          friendsSnapshot.docs.map((doc) => doc.get('userId2')).toList();

      if (friendIds.isEmpty) {
        return [];
      }

      final sharesSnapshot = await FirebaseFirestore.instance
          .collection('achievement_shares')
          .where('uid', whereIn: friendIds)
          .orderBy('sharedAt', descending: true)
          .limit(limit)
          .get();

      return sharesSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching friends achievements: $e');
      return [];
    }
  }

  // ── Leaderboard Management ───────────────────────────────────────────────

  /// Get global leaderboard
  static Future<List<Map<String, dynamic>>> getGlobalLeaderboard({
    String sortBy = 'affectionPoints',
    int limit = 50,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy(sortBy, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Get character-specific leaderboard
  static Future<List<Map<String, dynamic>>> getCharacterLeaderboard(
    String characterId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .where('characterId', isEqualTo: characterId)
          .orderBy('characterAffection', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching character leaderboard: $e');
      return [];
    }
  }

  /// Get user's leaderboard rank
  static Future<Map<String, dynamic>> getUserLeaderboardRank(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'rank': 'unranked'};
      }

      final doc = snapshot.docs.first.data();
      return doc;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching user rank: $e');
      return {'rank': 'unranked'};
    }
  }

  /// Update leaderboard entry
  static Future<void> updateLeaderboardEntry(
    String uid, {
    required int totalAffection,
    required int characterAffection,
    required String characterId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('leaderboard').doc(uid).set({
        'uid': uid,
        'totalAffection': totalAffection,
        'characterAffection': characterAffection,
        'characterId': characterId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating leaderboard: $e');
    }
  }

  // ── Co-op Challenges ─────────────────────────────────────────────────────

  /// Get available co-op challenges
  static Future<List<Map<String, dynamic>>> getAvailableChallenges({
    int limit = 10,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('global_quests')
          .where('type', isEqualTo: 'coop')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching challenges: $e');
      return [];
    }
  }

  /// Join co-op challenge
  static Future<void> joinChallenge({
    required String uid,
    required String challengeId,
    required String characterId,
  }) async {
    try {
      // Add user to challenge
      await FirebaseFirestore.instance
          .collection('global_quests')
          .doc(challengeId)
          .collection('participants')
          .doc(uid)
          .set({
        'uid': uid,
        'characterId': characterId,
        'joinedAt': FieldValue.serverTimestamp(),
        'progress': 0,
        'completed': false,
      });

      // Increment participant count
      await FirebaseFirestore.instance
          .collection('global_quests')
          .doc(challengeId)
          .update({
        'participantCount': FieldValue.increment(1),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error joining challenge: $e');
    }
  }

  /// Update challenge progress
  static Future<void> updateChallengeProgress(
    String challengeId,
    String uid,
    int progress,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('global_quests')
          .doc(challengeId)
          .collection('participants')
          .doc(uid)
          .update({
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating challenge progress: $e');
    }
  }

  /// Complete challenge
  static Future<void> completeChallenge(
    String challengeId,
    String uid,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('global_quests')
          .doc(challengeId)
          .collection('participants')
          .doc(uid)
          .update({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Increment completion count
      await FirebaseFirestore.instance
          .collection('global_quests')
          .doc(challengeId)
          .update({
        'completionCount': FieldValue.increment(1),
      });

      // Award reward
      final challengeDoc = await FirebaseFirestore.instance
          .collection('global_quests')
          .doc(challengeId)
          .get();

      if (challengeDoc.exists) {
        final reward = challengeDoc.get('reward') ?? 0;
        await FirebaseFirestore.instance
            .collection('affection')
            .doc(uid)
            .update({
          'totalPoints': FieldValue.increment(reward),
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error completing challenge: $e');
    }
  }

  /// Get challenge leaderboard
  static Future<List<Map<String, dynamic>>> getChallengeLeaderboard(
    String challengeId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('global_quests')
          .doc(challengeId)
          .collection('participants')
          .orderBy('progress', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching challenge leaderboard: $e');
      return [];
    }
  }

  // ── Social Statistics ────────────────────────────────────────────────────

  /// Get social statistics for user
  static Future<Map<String, dynamic>> getSocialStatistics(String uid) async {
    try {
      final friendsCount = await FirebaseFirestore.instance
          .collection('friends')
          .where('userId1', isEqualTo: uid)
          .count()
          .get();

      final sharesCount = await FirebaseFirestore.instance
          .collection('achievement_shares')
          .where('uid', isEqualTo: uid)
          .count()
          .get();

      final challengesCount = await FirebaseFirestore.instance
          .collection('global_quests')
          .where('participants', arrayContains: uid)
          .count()
          .get();

      return {
        'friendsList': friendsCount.count ?? 0,
        'achievementsShared': sharesCount.count ?? 0,
        'challengesParticipated': challengesCount.count ?? 0,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting social statistics: $e');
      return {};
    }
  }

  /// Get activity feed
  static Future<List<Map<String, dynamic>>> getActivityFeed(
    String uid, {
    int limit = 30,
  }) async {
    try {
      // Get friends list
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('friends')
          .where('userId1', isEqualTo: uid)
          .get();

      final friendIds =
          friendsSnapshot.docs.map((doc) => doc.get('userId2')).toList();

      if (friendIds.isEmpty) {
        return [];
      }

      // Get their activity
      final activitySnapshot = await FirebaseFirestore.instance
          .collection('achievement_shares')
          .where('uid', whereIn: friendIds)
          .orderBy('sharedAt', descending: true)
          .limit(limit)
          .get();

      return activitySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching activity feed: $e');
      return [];
    }
  }
}
