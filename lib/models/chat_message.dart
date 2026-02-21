class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content})
      : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        "role": role,
        "content": content,
        "timestamp": timestamp.toIso8601String(),
      };
}
