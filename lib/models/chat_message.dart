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

  /// Convert to JSON for API/storage
  Map<String, dynamic> toJson() => {
        "role": role,
        "content": content,
        "timestamp": timestamp.toIso8601String(),
      };
}
