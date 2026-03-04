/// Model for chat messages in the conversation
class ChatMessage {
  /// Role: 'user', 'assistant', or 'system'
  final String role;

  /// Content of the message
  final String content;

  /// Timestamp when the message was created
  final DateTime timestamp;

  /// Create a new chat message
  ChatMessage({required this.role, required this.content})
      : timestamp = DateTime.now();

  /// Restore a chat message from stored JSON (preserves timestamp if present)
  factory ChatMessage.fromJson(Map<String, dynamic> map) {
    return ChatMessage(
      role: (map['role'] ?? 'user').toString(),
      content: (map['content'] ?? '').toString(),
    );
  }

  /// Convert to JSON for storage (includes timestamp)
  Map<String, dynamic> toJson() => {
        "role": role,
        "content": content,
        "timestamp": timestamp.toIso8601String(),
      };

  /// Convert to JSON for API (role and content only)
  Map<String, dynamic> toApiJson() => {
        "role": role,
        "content": content,
      };
}
