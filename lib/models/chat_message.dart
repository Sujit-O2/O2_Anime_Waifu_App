import 'package:flutter/material.dart';

enum MessageType { user, ai, system, innerThought, storyEvent }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? imageBase64;
  final String? mood;
  final double? emotionalWeight;
  final bool isInnerThought;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    DateTime? timestamp,
    this.imageBase64,
    this.mood,
    this.emotionalWeight,
    this.isInnerThought = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'mood': mood,
        'emotionalWeight': emotionalWeight,
        'isInnerThought': isInnerThought,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        content: json['content'] as String,
        type: MessageType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MessageType.ai,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        mood: json['mood'] as String?,
        emotionalWeight: (json['emotionalWeight'] as num?)?.toDouble(),
        isInnerThought: json['isInnerThought'] as bool? ?? false,
      );

  Color get bubbleColor {
    switch (type) {
      case MessageType.user:
        return const Color(0xFF1A1A2E);
      case MessageType.ai:
        return const Color(0xFF0D0D1A);
      case MessageType.system:
        return const Color(0xFF2D1B69);
      case MessageType.innerThought:
        return const Color(0xFF1A0A2E).withValues(alpha: 0.6);
      case MessageType.storyEvent:
        return const Color(0xFF0A1A2E);
    }
  }
}
