enum MemoryEventType {
  firstMessage,
  confession,
  longGap,
  moodShift,
  worldUnlock,
  milestone,
  deepConversation,
  specialMoment,
}

class MemoryEvent {
  final String id;
  final MemoryEventType type;
  final String description;
  final DateTime timestamp;
  final double emotionalWeight;
  final Map<String, dynamic>? metadata;

  MemoryEvent({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.emotionalWeight = 1.0,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'emotionalWeight': emotionalWeight,
        'metadata': metadata,
      };

  factory MemoryEvent.fromJson(Map<String, dynamic> json) => MemoryEvent(
        id: json['id'] as String,
        type: MemoryEventType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MemoryEventType.specialMoment,
        ),
        description: json['description'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        emotionalWeight:
            (json['emotionalWeight'] as num?)?.toDouble() ?? 1.0,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  String toContextString() =>
      '[${type.name}] $description (weight: ${emotionalWeight.toStringAsFixed(1)})';
}
