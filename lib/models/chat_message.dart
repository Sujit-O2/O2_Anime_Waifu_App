/// Model for chat messages in the conversation
class ChatMessage {
  /// Role: 'user', 'assistant', or 'system'
  final String role;

  /// Content of the message
  final String content;

  /// Timestamp when the message was created
  final DateTime timestamp;

  /// Whether this message has been pinned/starred by the user
  bool isPinned;

  /// Optional local image path (for image-in-chat feature — user gallery photos)
  final String? imagePath;

  /// Optional remote image URL (for AI-generated images via Pollinations etc.)
  final String? imageUrl;

  /// Create a new chat message
  ChatMessage({
    required this.role,
    required this.content,
    this.isPinned = false,
    this.imagePath,
    this.imageUrl,
  }) : timestamp = DateTime.now();

  /// Restore a chat message from stored JSON (preserves timestamp if present)
  factory ChatMessage.fromJson(Map<String, dynamic> map) {
    return ChatMessage(
      role: (map['role'] ?? 'user').toString(),
      content: (map['content'] ?? '').toString(),
      isPinned: map['isPinned'] as bool? ?? false,
      imagePath: map['imagePath'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  /// Convert to JSON for storage (includes timestamp)
  Map<String, dynamic> toJson() => {
        "role": role,
        "content": content,
        "timestamp": timestamp.toIso8601String(),
        "isPinned": isPinned,
        if (imagePath != null) "imagePath": imagePath,
        if (imageUrl != null) "imageUrl": imageUrl,
      };

  /// Convert to JSON for API (role and content only — no image metadata)
  Map<String, dynamic> toApiJson() => {
        "role": role,
        "content": content,
      };
}
