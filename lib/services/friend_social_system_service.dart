import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Friend & Social System Service
/// Multiplayer features, leaderboards, achievements, friend interactions
class FriendSocialSystemService {
  static final FriendSocialSystemService _instance = FriendSocialSystemService._internal();

  factory FriendSocialSystemService() {
    return _instance;
  }

  FriendSocialSystemService._internal();

  late SharedPreferences _prefs;
  final Map<String, Friend> _friends = {};
  final List<SocialActivity> _socialFeed = [];
  final Map<String, LeaderboardEntry> _leaderboards = {};
  final List<Challenge> _activeChallenges = [];
  final Map<String, Notification> _notifications = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFriendsData();
    await _loadLeaderboards();
    debugPrint('[Social] Service initialized');
  }

  // ===== FRIEND MANAGEMENT =====
  /// Add friend
  Future<void> addFriend({
    required String userId,
    required String username,
    String? avatarUrl,
  }) async {
    final friend = Friend(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      addedDate: DateTime.now(),
      status: 'online',
      lastSeen: DateTime.now(),
      isBestFriend: false,
    );

    _friends[userId] = friend;
    await _saveFriendsData();

    // Create notification
    await _addNotification(
      userId,
      'New Friend',
      'You added $username as a friend!',
      'friend',
    );

    debugPrint('[Social] Friend added: $username');
  }

  /// Remove friend
  Future<void> removeFriend(String userId) async {
    _friends.remove(userId);
    await _saveFriendsData();
  }

  /// Mark as best friend
  Future<void> setBestFriend(String userId, bool isBest) async {
    if (_friends.containsKey(userId)) {
      _friends[userId]!.isBestFriend = isBest;
      await _saveFriendsData();
    }
  }

  /// Get friends list
  Future<List<Friend>> getFriends({String? status}) async {
    var friends = _friends.values.toList();
    if (status != null) {
      friends = friends.where((f) => f.status == status).toList();
    }
    friends.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return friends;
  }

  /// Update friend status
  Future<void> updateFriendStatus(String userId, String status) async {
    if (_friends.containsKey(userId)) {
      _friends[userId]!.status = status;
      _friends[userId]!.lastSeen = DateTime.now();
      await _saveFriendsData();
    }
  }

  // ===== SOCIAL FEED =====
  /// Post activity on social feed
  Future<void> postActivity({
    required String userId,
    required String username,
    required String activityType, // 'achievement', 'milestone', 'action'
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final activity = SocialActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      username: username,
      activityType: activityType,
      description: description,
      timestamp: DateTime.now(),
      likes: [],
      comments: [],
      metadata: metadata ?? {},
    );

    _socialFeed.add(activity);

    // Keep last 500 activities
    if (_socialFeed.length > 500) {
      _socialFeed.removeAt(0);
    }

    await _saveSocialFeed();
    debugPrint('[Social] Activity posted: $activityType');
  }

  /// Like activity
  Future<void> likeActivity(String activityId, String userId) async {
    final activity = _socialFeed.firstWhere(
      (a) => a.id == activityId,
      orElse: () => SocialActivity(
        id: '', userId: '', username: '', activityType: '', description: '', timestamp: DateTime.now(),
        likes: [], comments: [], metadata: {},
      ),
    );

    if (activity.id.isNotEmpty && !activity.likes.contains(userId)) {
      activity.likes.add(userId);
      await _saveSocialFeed();
    }
  }

  /// Get social feed
  Future<List<SocialActivity>> getSocialFeed({int limit = 50}) async {
    return _socialFeed.reversed.take(limit).toList();
  }

  /// Get trending activities
  Future<List<SocialActivity>> getTrendingActivities({int limit = 10}) async {
    final sorted = _socialFeed.toList()
      ..sort((a, b) => b.likes.length.compareTo(a.likes.length));
    return sorted.take(limit).toList();
  }

  // ===== LEADERBOARDS =====
  /// Update leaderboard entry
  Future<void> updateLeaderboard({
    required String leaderboardId, // 'anime_lovers', 'top_chatters', etc
    required String userId,
    required String username,
    required int score,
    String? avatarUrl,
  }) async {
    final key = '$leaderboardId:$userId';
    
    _leaderboards[key] = LeaderboardEntry(
      userId: userId,
      username: username,
      score: score,
      rank: 0,
      avatarUrl: avatarUrl,
      streak: 0,
      level: score ~/ 100,
    );

    // Recalculate ranks
    await _recalculateRanks(leaderboardId);
    await _saveLeaderboards();
  }

  /// Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(String leaderboardId, {int limit = 50}) async {
    final entries = _leaderboards.values
        .where((e) => _leaderboards.keys
            .firstWhere((k) => k == '$leaderboardId:${e.userId}', orElse: () => '')
            .isNotEmpty)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return entries.take(limit).toList();
  }

  /// Get user rank
  Future<int?> getUserRank(String leaderboardId, String userId) async {
    final key = '$leaderboardId:$userId';
    return _leaderboards[key]?.rank;
  }

  /// Get available leaderboards
  Future<List<String>> getAvailableLeaderboards() async {
    return ['anime_lovers', 'top_chatters', 'achievement_hunters', 'theme_collectors', 'waifu_enthusiasts'];
  }

  // ===== CHALLENGES & EVENTS =====
  /// Create challenge
  Future<void> createChallenge({
    required String title,
    required String description,
    required int duration, // days
    required String type, // 'daily', 'weekly', 'seasonal'
    required int rewardCoins,
  }) async {
    final challenge = Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: duration)),
      type: type,
      participants: [],
      rewardCoins: rewardCoins,
      isActive: true,
    );

    _activeChallenges.add(challenge);
    await _saveChallenges();
    debugPrint('[Social] Challenge created: $title');
  }

  /// Join challenge
  Future<bool> joinChallenge(String challengeId, String userId) async {
    final challenge = _activeChallenges.firstWhere(
      (c) => c.id == challengeId,
      orElse: () => Challenge(
        id: '', title: '', description: '', startDate: DateTime.now(),
        endDate: DateTime.now(), type: '', participants: [],
        rewardCoins: 0, isActive: false,
      ),
    );

    if (challenge.id.isNotEmpty && !challenge.participants.contains(userId)) {
      challenge.participants.add(userId);
      await _saveChallenges();
      return true;
    }
    return false;
  }

  /// Get active challenges
  Future<List<Challenge>> getActiveChallenges() async {
    final now = DateTime.now();
    return _activeChallenges
        .where((c) => c.isActive && c.endDate.isAfter(now))
        .toList();
  }

  /// Complete challenge
  Future<void> completeChallengeTask(String challengeId, String userId) async {
    debugPrint('[Social] Challenge task completed: $challengeId by $userId');
  }

  // ===== NOTIFICATIONS =====
  Future<void> _addNotification(String recipientId, String title, String message, String type) async {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      recipientId: recipientId,
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notifications[notification.id] = notification;
    debugPrint('[Social] Notification: $title');
  }

  /// Get notifications
  Future<List<Notification>> getNotifications(String userId, {bool unreadOnly = false}) async {
    var notifs = _notifications.values
        .where((n) => n.recipientId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (unreadOnly) {
      notifs = notifs.where((n) => !n.isRead).toList();
    }

    return notifs;
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    if (_notifications.containsKey(notificationId)) {
      _notifications[notificationId]!.isRead = true;
    }
  }

  // ===== STATISTICS =====
  Future<SocialStatistics> getSocialStatistics(String userId) async {
    final userFriends = await getFriends();
    final userActivities = _socialFeed.where((a) => a.userId == userId).toList();
    final likes = userActivities.fold<int>(0, (sum, a) => sum + a.likes.length);

    return SocialStatistics(
      friendsCount: userFriends.length,
      activitiesPosted: userActivities.length,
      totalLikesReceived: likes,
      leaderboardRanks: {},
      challengesCompleted: 0,
      generatedAt: DateTime.now(),
    );
  }

  // ===== INTERNAL HELPERS =====
  Future<void> _recalculateRanks(String leaderboardId) async {
    final entries = _leaderboards.values
        .where((e) => _leaderboards.keys
            .firstWhere((k) => k == '$leaderboardId:${e.userId}', orElse: () => '')
            .isNotEmpty)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    for (int i = 0; i < entries.length; i++) {
      entries[i].rank = i + 1;
    }
  }

  Future<void> _saveFriendsData() async {
    final data = _friends.values.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs.setStringList('friends_data', data);
  }

  Future<void> _loadFriendsData() async {
    final data = _prefs.getStringList('friends_data') ?? [];
    for (final item in data) {
      try {
        final friend = Friend.fromJson(jsonDecode(item));
        _friends[friend.userId] = friend;
      } catch (e) {
        debugPrint('[Social] Error loading friend: $e');
      }
    }
  }

  Future<void> _saveSocialFeed() async {
    final data = _socialFeed.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList('social_feed', data);
  }

  Future<void> _saveLeaderboards() async {
    final data = _leaderboards.values.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('leaderboards', data);
  }

  Future<void> _loadLeaderboards() async {
    final data = _prefs.getStringList('leaderboards') ?? [];
    for (final item in data) {
      try {
        final entry = LeaderboardEntry.fromJson(jsonDecode(item));
        _leaderboards[entry.userId] = entry;
      } catch (e) {
        debugPrint('[Social] Error loading leaderboard: $e');
      }
    }
  }

  Future<void> _saveChallenges() async {
    final data = _activeChallenges.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList('active_challenges', data);
  }
}

// ===== DATA MODELS =====

class Friend {
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime addedDate;
  String status; // 'online', 'offline', 'busy'
  DateTime lastSeen;
  bool isBestFriend;

  Friend({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.addedDate,
    required this.status,
    required this.lastSeen,
    required this.isBestFriend,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'avatar': avatarUrl,
    'addedDate': addedDate.toIso8601String(),
    'status': status,
    'lastSeen': lastSeen.toIso8601String(),
    'isBestFriend': isBestFriend,
  };

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar'] as String?,
      addedDate: DateTime.parse(json['addedDate'] as String),
      status: json['status'] as String,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      isBestFriend: json['isBestFriend'] as bool? ?? false,
    );
  }
}

class SocialActivity {
  final String id;
  final String userId;
  final String username;
  final String activityType;
  final String description;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> comments;
  final Map<String, dynamic> metadata;

  SocialActivity({
    required this.id,
    required this.userId,
    required this.username,
    required this.activityType,
    required this.description,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'username': username,
    'type': activityType,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'likes': likes,
    'comments': comments,
    'metadata': metadata,
  };

  factory SocialActivity.fromJson(Map<String, dynamic> json) {
    return SocialActivity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      activityType: json['type'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      likes: List<String>.from(json['likes'] as List? ?? []),
      comments: List<String>.from(json['comments'] as List? ?? []),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final int score;
  int rank;
  final String? avatarUrl;
  int streak;
  int level;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.score,
    required this.rank,
    this.avatarUrl,
    required this.streak,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'score': score,
    'rank': rank,
    'avatar': avatarUrl,
    'streak': streak,
    'level': level,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      score: json['score'] as int,
      rank: json['rank'] as int? ?? 0,
      avatarUrl: json['avatar'] as String?,
      streak: json['streak'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
    );
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final List<String> participants;
  final int rewardCoins;
  bool isActive;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.participants,
    required this.rewardCoins,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'type': type,
    'participants': participants,
    'reward': rewardCoins,
    'isActive': isActive,
  };

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      type: json['type'] as String,
      participants: List<String>.from(json['participants'] as List? ?? []),
      rewardCoins: json['reward'] as int,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class Notification {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  bool isRead;

  Notification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });
}

class SocialStatistics {
  final int friendsCount;
  final int activitiesPosted;
  final int totalLikesReceived;
  final Map<String, int> leaderboardRanks;
  int challengesCompleted;
  final DateTime generatedAt;

  SocialStatistics({
    required this.friendsCount,
    required this.activitiesPosted,
    required this.totalLikesReceived,
    required this.leaderboardRanks,
    required this.challengesCompleted,
    required this.generatedAt,
  });
}
