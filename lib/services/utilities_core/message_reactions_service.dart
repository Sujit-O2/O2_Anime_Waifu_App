import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 💕 Message Reactions Service
/// 
/// Long-press any message to add emoji reactions.
/// Track which messages you loved most.
class MessageReactionsService {
  MessageReactionsService._();
  static final MessageReactionsService instance = MessageReactionsService._();

  final Map<String, MessageReaction> _reactions = {};
  
  static const String _storageKey = 'message_reactions_v1';
  static const List<String> availableReactions = [
    '❤️', '😂', '😮', '😢', '🔥', '👏', '💕', '✨', 
    '🥰', '😍', '💖', '🎉', '👍', '💯', '🌟', '💋'
  ];

  Future<void> initialize() async {
    await _loadReactions();
    if (kDebugMode) debugPrint('[Reactions] Initialized with ${_reactions.length} reactions');
  }

  /// Add or update reaction to a message
  Future<void> addReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final key = '$messageId:$userId';
    
    _reactions[key] = MessageReaction(
      messageId: messageId,
      emoji: emoji,
      userId: userId,
      timestamp: DateTime.now(),
    );

    await _saveReactions();
    if (kDebugMode) debugPrint('[Reactions] Added $emoji to message $messageId');
  }

  /// Remove reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String userId,
  }) async {
    final key = '$messageId:$userId';
    _reactions.remove(key);
    await _saveReactions();
    if (kDebugMode) debugPrint('[Reactions] Removed reaction from message $messageId');
  }

  /// Toggle reaction (add if not exists, remove if exists)
  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final key = '$messageId:$userId';
    
    if (_reactions.containsKey(key) && _reactions[key]!.emoji == emoji) {
      await removeReaction(messageId: messageId, userId: userId);
    } else {
      await addReaction(messageId: messageId, emoji: emoji, userId: userId);
    }
  }

  /// Get reaction for a specific message by user
  MessageReaction? getReaction({
    required String messageId,
    required String userId,
  }) {
    final key = '$messageId:$userId';
    return _reactions[key];
  }

  /// Get all reactions for a message
  List<MessageReaction> getReactionsForMessage(String messageId) {
    return _reactions.values
        .where((r) => r.messageId == messageId)
        .toList();
  }

  /// Get reaction counts for a message
  Map<String, int> getReactionCounts(String messageId) {
    final counts = <String, int>{};
    
    for (final reaction in _reactions.values) {
      if (reaction.messageId == messageId) {
        counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// Get most used reactions
  List<ReactionStat> getMostUsedReactions({int limit = 5}) {
    final counts = <String, int>{};
    
    for (final reaction in _reactions.values) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }

    final stats = counts.entries
        .map((e) => ReactionStat(emoji: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return stats.take(limit).toList();
  }

  /// Get favorite messages (most reacted)
  List<String> getFavoriteMessages({int limit = 10}) {
    final messageCounts = <String, int>{};
    
    for (final reaction in _reactions.values) {
      messageCounts[reaction.messageId] = 
          (messageCounts[reaction.messageId] ?? 0) + 1;
    }

    final sorted = messageCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get reaction statistics
  Map<String, dynamic> getStatistics() {
    final totalReactions = _reactions.length;
    final uniqueMessages = _reactions.values
        .map((r) => r.messageId)
        .toSet()
        .length;

    final mostUsed = getMostUsedReactions(limit: 3);

    return {
      'total_reactions': totalReactions,
      'unique_messages': uniqueMessages,
      'most_used': mostUsed.map((s) => {
        'emoji': s.emoji,
        'count': s.count,
      }).toList(),
      'favorite_emoji': mostUsed.isNotEmpty ? mostUsed.first.emoji : null,
    };
  }

  /// Get insights text
  String getInsightsText() {
    if (_reactions.isEmpty) {
      return 'Start reacting to messages to see your patterns! 💕';
    }

    final stats = getStatistics();
    final mostUsed = getMostUsedReactions(limit: 3);

    final buffer = StringBuffer();
    buffer.writeln('💕 Your Reaction Patterns\n');
    buffer.writeln('Total reactions: ${stats['total_reactions']}');
    buffer.writeln('Messages reacted to: ${stats['unique_messages']}\n');

    if (mostUsed.isNotEmpty) {
      buffer.writeln('Most used reactions:');
      for (int i = 0; i < mostUsed.length; i++) {
        buffer.writeln('  ${i + 1}. ${mostUsed[i].emoji} - ${mostUsed[i].count} times');
      }
    }

    return buffer.toString();
  }

  Future<void> _saveReactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonMap = _reactions.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_storageKey, jsonEncode(jsonMap));
    } catch (e) {
      if (kDebugMode) debugPrint('[Reactions] Save error: $e');
    }
  }

  Future<void> _loadReactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        _reactions.clear();
        jsonMap.forEach((k, v) {
          _reactions[k] = MessageReaction.fromJson(v as Map<String, dynamic>);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Reactions] Load error: $e');
    }
  }

  /// Clear all reactions
  Future<void> clearAll() async {
    _reactions.clear();
    await _saveReactions();
  }
}

class MessageReaction {
  final String messageId;
  final String emoji;
  final String userId;
  final DateTime timestamp;

  const MessageReaction({
    required this.messageId,
    required this.emoji,
    required this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'emoji': emoji,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MessageReaction.fromJson(Map<String, dynamic> json) => MessageReaction(
    messageId: json['messageId'] as String,
    emoji: json['emoji'] as String,
    userId: json['userId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class ReactionStat {
  final String emoji;
  final int count;

  const ReactionStat({
    required this.emoji,
    required this.count,
  });
}
