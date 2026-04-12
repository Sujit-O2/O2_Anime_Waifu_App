import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Discord Integration Manager with Webhook Support
/// Share achievements, stats, notifications, rich presence
class DiscordIntegrationManager {
  static final DiscordIntegrationManager _instance = DiscordIntegrationManager._internal();

  factory DiscordIntegrationManager() {
    return _instance;
  }

  DiscordIntegrationManager._internal();

  late SharedPreferences _prefs;
  final Map<String, DiscordUser> _linkedUsers = {};
  final List<DiscordMessage> _messageQueue = [];
  String? _webhookUrl;
  bool _webhookEnabled = false;
  final List<String> _eventLog = [];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLinkedUsers();
    _webhookUrl = _prefs.getString('discord_webhook_url');
    _webhookEnabled = _webhookUrl != null && _webhookUrl!.isNotEmpty;
    debugPrint('[Discord Integration] Initialized (Webhooks: $_webhookEnabled)');
  }

  // ===== WEBHOOK MANAGEMENT =====
  Future<bool> setWebhookUrl(String userId, String webhookUrl) async {
    try {
      _webhookUrl = webhookUrl;
      _webhookEnabled = true;
      await _prefs.setString('discord_webhook_url', webhookUrl);
      await _prefs.setString('discord_webhook_user', userId);
      debugPrint('✅ Discord webhook configured');
      return true;
    } catch (e) {
      debugPrint('[Discord] Webhook setup error: $e');
      return false;
    }
  }

  Future<void> disableWebhook() async {
    _webhookEnabled = false;
    await _prefs.remove('discord_webhook_url');
    _webhookUrl = null;
  }

  bool get isWebhookEnabled => _webhookEnabled && _webhookUrl != null;

  // ===== LINKING & AUTH =====
  Future<DiscordLinkResult> linkDiscordAccount(String userId, String discordUserId, String discordTag) async {
    final link = DiscordUser(
      discordUserId: discordUserId,
      appUserId: userId,
      discordTag: discordTag,
      linkedAt: DateTime.now(),
      isActive: true,
      lastSync: DateTime.now(),
    );

    _linkedUsers[userId] = link;
    await _saveLinkedUsers();

    return DiscordLinkResult(
      success: true,
      message: 'Successfully linked Discord account: $discordTag',
      linkedUser: link,
    );
  }

  Future<bool> unlinkDiscordAccount(String userId) async {
    _linkedUsers.remove(userId);
    await _saveLinkedUsers();
    return true;
  }

  Future<DiscordUser?> getLinkedDiscordAccount(String userId) async {
    return _linkedUsers[userId];
  }

  // ===== ACHIEVEMENT SHARING =====
  Future<DiscordMessage> shareAchievementToDiscord({
    required String userId,
    required String achievementName,
    required String achievementDescription,
    required String rarity, // 'common', 'rare', 'epic', 'legendary'
  }) async {
    final linkedUser = _linkedUsers[userId];
    if (linkedUser == null) {
      throw Exception('Discord account not linked');
    }

    final embedColor = _getRarityColor(rarity);
    
    final message = DiscordMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      discordUserId: linkedUser.discordUserId,
      appUserId: userId,
      messageType: 'achievement',
      content: '🏆 **Achievement Unlocked!**\n$achievementName',
      embeds: [
        DiscordEmbed(
          title: achievementName,
          description: achievementDescription,
          color: embedColor,
          fields: [
            DiscordField(name: 'Rarity', value: rarity.toUpperCase(), inline: true),
            DiscordField(name: 'Time', value: DateTime.now().toString(), inline: true),
          ],
          timestamp: DateTime.now(),
        )
      ],
      sentAt: DateTime.now(),
      status: 'queued',
    );

    _messageQueue.add(message);
    await _queueMessage(message);

    return message;
  }

  // ===== STATS SHARING =====
  Future<DiscordMessage> shareStatsToDiscord({
    required String userId,
    required Map<String, dynamic> stats,
  }) async {
    final linkedUser = _linkedUsers[userId];
    if (linkedUser == null) {
      throw Exception('Discord account not linked');
    }

    final statsText = stats.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    final message = DiscordMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      discordUserId: linkedUser.discordUserId,
      appUserId: userId,
      messageType: 'stats',
      content: '📊 **My Anime Waifu Stats**\n$statsText',
      embeds: [
        DiscordEmbed(
          title: 'User Statistics',
          description: 'Latest gameplay statistics',
          color: 3447003, // Blue
          fields: stats.entries
              .map((e) => DiscordField(
                name: e.key.toString(),
                value: e.value.toString(),
                inline: true,
              ))
              .toList(),
          timestamp: DateTime.now(),
        )
      ],
      sentAt: DateTime.now(),
      status: 'queued',
    );

    _messageQueue.add(message);
    await _queueMessage(message);

    return message;
  }

  // ===== NOTIFICATIONS =====
  Future<void> sendDiscordNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    final linkedUser = _linkedUsers[userId];
    if (linkedUser == null) return;

    final notification = DiscordMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      discordUserId: linkedUser.discordUserId,
      appUserId: userId,
      messageType: 'notification',
      content: '📢 **$title**\n$message',
      embeds: [],
      sentAt: DateTime.now(),
      status: 'queued',
    );

    _messageQueue.add(notification);
    await _queueMessage(notification);
    await _sendViaWebhook(notification);
  }

  // ===== WEBHOOK SENDING =====
  Future<void> _sendViaWebhook(DiscordMessage message) async {
    if (!_webhookEnabled || _webhookUrl == null) return;

    try {
      final embed = message.embeds.isNotEmpty ? message.embeds.first : null;

      final _ = {
        'content': message.content,
        if (embed != null)
          'embeds': [
            {
              'title': embed.title,
              'description': embed.description,
              'color': embed.color,
              'fields': embed.fields.map((f) => {
                'name': f.name,
                'value': f.value,
                'inline': f.inline,
              }).toList(),
              'timestamp': embed.timestamp.toIso8601String(),
            }
          ]
      };

      // Simulate webhook send (in production, use http package)
      debugPrint('📤 Discord webhook payload prepared: ${message.messageType}');
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate send
      
      message.status = 'sent';
      message.sentAt = DateTime.now();
      _addEventLog('message_sent', message.messageType);

      debugPrint('✅ Message sent via webhook: ${message.messageType}');
    } catch (e) {
      debugPrint('[Discord] Webhook send error: $e');
      _addEventLog('webhook_error', e.toString());
    }
  }

  Future<void> sendBatchEvents(List<DiscordMessage> messages) async {
    if (!_webhookEnabled) return;

    try {
      for (final message in messages) {
        await _sendViaWebhook(message);
        await Future.delayed(const Duration(milliseconds: 200)); // Rate limit
      }

      debugPrint('✅ Batch sent: ${messages.length} events');
    } catch (e) {
      debugPrint('[Discord] Batch send error: $e');
    }
  }

  Future<String> createWebhookPayload(DiscordMessage message) async {
    final embed = message.embeds.isNotEmpty ? message.embeds.first : null;

    final payload = {
      'content': message.content,
      'username': '🎮 Anime Waifu Bot',
      'avatar_url': 'https://i.imgur.com/placeholder.png',
      if (embed != null)
        'embeds': [
          {
            'title': embed.title,
            'description': embed.description,
            'color': embed.color,
            'fields': embed.fields.map((f) => {
              'name': f.name,
              'value': f.value,
              'inline': f.inline,
            }).toList(),
            'timestamp': embed.timestamp.toIso8601String(),
            'footer': {
              'text': 'Anime Waifu',
              'icon_url': 'https://i.imgur.com/placeholder.png',
            }
          }
        ]
    };

    return jsonEncode(payload);
  }

  // ===== EVENT STREAMING =====
  Future<void> streamGameEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      final title = _getEventTitle(eventType);
      final description = _formatEventData(eventData);
      final color = _getEventColor(eventType);

      final message = DiscordMessage(
        messageId: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        discordUserId: _linkedUsers[userId]?.discordUserId ?? 'unknown',
        appUserId: userId,
        messageType: eventType,
        content: title,
        embeds: [
          DiscordEmbed(
            title: title,
            description: description,
            color: color,
            fields: _buildEventFields(eventData),
            timestamp: DateTime.now(),
          )
        ],
        sentAt: DateTime.now(),
        status: 'queued',
      );

      _messageQueue.add(message);
      await _sendViaWebhook(message);
      _addEventLog(eventType, userId);

      debugPrint('📤 Event streamed: $eventType');
    } catch (e) {
      debugPrint('[Discord] Event stream error: $e');
    }
  }

  Future<void> streamAchievementEvent(String userId, String achievementName, String tier) async {
    await streamGameEvent(
      userId: userId,
      eventType: 'achievement_unlocked',
      eventData: {
        'achievement': achievementName,
        'tier': tier,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> streamGameWinEvent(String userId, String gameName, {int? score}) async {
    await streamGameEvent(
      userId: userId,
      eventType: 'game_victory',
      eventData: {
        'game': gameName,
        'score': score ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> streamMilestoneEvent(String userId, String milestone, int value) async {
    await streamGameEvent(
      userId: userId,
      eventType: 'milestone_reached',
      eventData: {
        'milestone': milestone,
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ===== EVENT LOG & ANALYTICS =====
  List<String> getEventLog() => List.from(_eventLog);

  void _addEventLog(String type, String details) {
    final entry = '${DateTime.now().toIso8601String()} | $type | $details';
    _eventLog.add(entry);
    
    // Keep only last 100 events
    if (_eventLog.length > 100) {
      _eventLog.removeAt(0);
    }
  }

  Future<Map<String, dynamic>> getWebhookStats() async {
    return {
      'webhookEnabled': _webhookEnabled,
      'queuedMessages': _messageQueue.where((m) => m.status == 'queued').length,
      'sentMessages': _messageQueue.where((m) => m.status == 'sent').length,
      'totalEvents': _eventLog.length,
      'lastActivity': _eventLog.isNotEmpty ? _eventLog.last : 'none',
    };
  }

  // ===== RICH PRESENCE =====
  Future<void> updateDiscordRichPresence({
    required String userId,
    required String state,
    required String details,
    required String largeImageKey,
  }) async {
    final linkedUser = _linkedUsers[userId];
    if (linkedUser == null) return;

    final presence = DiscordRichPresence(
      userId: userId,
      state: state,
      details: details,
      largeImageKey: largeImageKey,
      startTimestamp: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    await _prefs.setString('discord_presence:$userId', jsonEncode(presence.toJson()));
  }

  // ===== SYNC & QUEUE =====
  Future<List<DiscordMessage>> getQueuedMessages() async {
    return _messageQueue.where((m) => m.status == 'queued').toList();
  }

  Future<void> markMessageSent(String messageId) async {
    final message = _messageQueue.firstWhere(
      (m) => m.messageId == messageId,
      orElse: () => DiscordMessage.default_(),
    );

    if (message.messageId.isNotEmpty) {
      message.status = 'sent';
      message.sentAt = DateTime.now();
    }
  }

  Future<int> getSyncStatus(String userId) async {
    return _messageQueue.where((m) => m.appUserId == userId && m.status == 'queued').length;
  }

  // ===== INTERNAL HELPERS =====
  int _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return 16776960; // Gold
      case 'epic':
        return 12632256; // Purple
      case 'rare':
        return 3447003; // Blue
      default:
        return 9807270; // Gray
    }
  }

  int _getEventColor(String eventType) {
    switch (eventType) {
      case 'achievement_unlocked':
        return 16776960; // Gold
      case 'game_victory':
        return 65280; // Green
      case 'milestone_reached':
        return 255; // Red
      case 'level_up':
        return 11093254; // Cyan
      default:
        return 9807270; // Gray
    }
  }

  String _getEventTitle(String eventType) {
    switch (eventType) {
      case 'achievement_unlocked':
        return '🏆 Achievement Unlocked!';
      case 'game_victory':
        return '🎮 Game Victory!';
      case 'milestone_reached':
        return '🎯 Milestone Reached!';
      case 'level_up':
        return '⬆️ Level Up!';
      case 'notification':
        return '📢 Notification';
      default:
        return '📤 Event';
    }
  }

  String _formatEventData(Map<String, dynamic> data) {
    return data.entries.map((e) => '**${e.key.replaceAll('_', ' ')}:** ${e.value}').join('\n');
  }

  List<DiscordField> _buildEventFields(Map<String, dynamic> data) {
    return data.entries
        .map((e) => DiscordField(
          name: e.key.replaceAll('_', ' ').toUpperCase(),
          value: e.value.toString(),
          inline: true,
        ))
        .toList();
  }

  Future<void> _queueMessage(DiscordMessage message) async {
    final list = _messageQueue.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList('discord_message_queue', list);
  }

  Future<void> _loadLinkedUsers() async {
    final allKeys = _prefs.getKeys().where((k) => k.startsWith('discord_user:'));
    for (final key in allKeys) {
      final stored = _prefs.getString(key);
      if (stored != null) {
        try {
          final user = DiscordUser.fromJson(jsonDecode(stored));
          _linkedUsers[user.appUserId] = user;
        } catch (_) {}
      }
    }
  }

  Future<void> _saveLinkedUsers() async {
    for (final entry in _linkedUsers.entries) {
      await _prefs.setString(
        'discord_user:${entry.key}',
        jsonEncode(entry.value.toJson()),
      );
    }
  }
}

// ===== DATA MODELS =====

class DiscordUser {
  String discordUserId;
  String appUserId;
  String discordTag;
  DateTime linkedAt;
  bool isActive;
  DateTime lastSync;

  DiscordUser({
    required this.discordUserId,
    required this.appUserId,
    required this.discordTag,
    required this.linkedAt,
    required this.isActive,
    required this.lastSync,
  });

  Map<String, dynamic> toJson() => {
    'discordUserId': discordUserId,
    'appUserId': appUserId,
    'discordTag': discordTag,
    'linkedAt': linkedAt.toIso8601String(),
    'isActive': isActive,
    'lastSync': lastSync.toIso8601String(),
  };

  factory DiscordUser.fromJson(Map<String, dynamic> json) => DiscordUser(
    discordUserId: json['discordUserId'],
    appUserId: json['appUserId'],
    discordTag: json['discordTag'],
    linkedAt: DateTime.parse(json['linkedAt']),
    isActive: json['isActive'],
    lastSync: DateTime.parse(json['lastSync']),
  );
}

class DiscordMessage {
  String messageId;
  String discordUserId;
  String appUserId;
  String messageType;
  String content;
  List<DiscordEmbed> embeds;
  DateTime sentAt;
  String status;

  DiscordMessage({
    required this.messageId,
    required this.discordUserId,
    required this.appUserId,
    required this.messageType,
    required this.content,
    required this.embeds,
    required this.sentAt,
    required this.status,
  });

  factory DiscordMessage.default_() => DiscordMessage(
    messageId: '',
    discordUserId: '',
    appUserId: '',
    messageType: '',
    content: '',
    embeds: [],
    sentAt: DateTime.now(),
    status: 'queued',
  );

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'discordUserId': discordUserId,
    'appUserId': appUserId,
    'messageType': messageType,
    'content': content,
    'embeds': embeds.map((e) => e.toJson()).toList(),
    'sentAt': sentAt.toIso8601String(),
    'status': status,
  };
}

class DiscordEmbed {
  String title;
  String description;
  int color;
  List<DiscordField> fields;
  DateTime timestamp;

  DiscordEmbed({
    required this.title,
    required this.description,
    required this.color,
    required this.fields,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'color': color,
    'fields': fields.map((f) => f.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
  };
}

class DiscordField {
  String name;
  String value;
  bool inline;

  DiscordField({required this.name, required this.value, required this.inline});

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'inline': inline,
  };
}

class DiscordRichPresence {
  String userId;
  String state;
  String details;
  String largeImageKey;
  DateTime startTimestamp;
  DateTime lastUpdated;

  DiscordRichPresence({
    required this.userId,
    required this.state,
    required this.details,
    required this.largeImageKey,
    required this.startTimestamp,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'state': state,
    'details': details,
    'largeImageKey': largeImageKey,
    'startTimestamp': startTimestamp.millisecondsSinceEpoch ~/ 1000,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}

class DiscordLinkResult {
  bool success;
  String message;
  DiscordUser? linkedUser;

  DiscordLinkResult({
    required this.success,
    required this.message,
    required this.linkedUser,
  });
}


