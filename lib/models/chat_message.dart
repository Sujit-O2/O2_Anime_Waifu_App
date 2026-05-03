import 'package:uuid/uuid.dart';

/// Model for chat messages in the conversation
class ChatMessage {
  /// Unique ID for deletion/selection tracking
  final String id;

  /// Role: 'user', 'assistant', or 'system'
  final String role;

  /// Content of the message
  final String content;

  /// Timestamp when the message was created
  final DateTime timestamp;

  /// Whether this message has been pinned/starred by the user
  bool isPinned;

  /// Emoji reaction on this message (e.g. '❤️', '😂', '🔥')
  String? reaction;

  /// Optional local image path (for image-in-chat feature — user gallery photos)
  final String? imagePath;

  /// Optional remote image URL (for AI-generated images via Pollinations etc.)
  final String? imageUrl;

  /// Optional audio URL (for AI-generated music/audio inline in chat)
  final String? audioUrl;

  /// Optional video URL (for AI-generated video inline in chat)
  final String? videoUrl;

  /// Ghost/thinking placeholder
  bool isGhost;

  /// Optional internal thought (hidden reasoning/internal monologue)
  final String? internalThought;

  /// Create a new chat message
  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    this.internalThought,
    this.isPinned = false,
    this.isGhost = false,
    this.reaction,
    this.imagePath,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Restore a chat message from stored JSON (preserves timestamp if present)
  factory ChatMessage.fromJson(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String? ?? const Uuid().v4(),
      role: (map['role'] ?? 'user').toString(),
      content: (map['content'] ?? '').toString(),
      isPinned: map['isPinned'] as bool? ?? false,
      isGhost: map['isGhost'] as bool? ?? false,
      internalThought: map['internalThought'] as String?,
      reaction: map['reaction'] as String?,
      imagePath: map['imagePath'] as String?,
      imageUrl: map['imageUrl'] as String?,
      audioUrl: map['audioUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  /// Create a copy with optional field overrides
  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    String? internalThought,
    bool? isPinned,
    bool? isGhost,
    String? reaction,
    String? imagePath,
    String? imageUrl,
    String? audioUrl,
    String? videoUrl,
    DateTime? timestamp,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        role: role ?? this.role,
        content: content ?? this.content,
        internalThought: internalThought ?? this.internalThought,
        isPinned: isPinned ?? this.isPinned,
        isGhost: isGhost ?? this.isGhost,
        reaction: reaction ?? this.reaction,
        imagePath: imagePath ?? this.imagePath,
        imageUrl: imageUrl ?? this.imageUrl,
        audioUrl: audioUrl ?? this.audioUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  String toString() =>
      'ChatMessage(role: $role, content: ${content.length > 30 ? "${content.substring(0, 30)}..." : content})';

  /// Convert to JSON for storage (includes timestamp)
  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isPinned': isPinned,
        'isGhost': isGhost,
        if (internalThought != null) 'internalThought': internalThought,
        if (reaction != null) 'reaction': reaction,
        if (imagePath != null) 'imagePath': imagePath,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (audioUrl != null) 'audioUrl': audioUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
      };

  /// Robustly parse timestamps from various sources (ISO string, Firestore Timestamp, epoch int)
  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    final str = raw.toString();
    if (str.isEmpty) return DateTime.now();
    return DateTime.tryParse(str) ?? DateTime.now();
  }

  /// Convert to JSON for API (role and content only — no metadata/thoughts)
  Map<String, dynamic> toApiJson() => {
        'role': role,
        'content': content,
      };

  /// Sanitize message content — strips control chars, limits length
  static String sanitize(String input, {int maxLength = 10000}) {
    if (input.isEmpty) return input;
    // Remove control characters except newlines and tabs
    var clean = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    // Limit length
    if (clean.length > maxLength) {
      clean = clean.substring(0, maxLength);
    }
    return clean.trim();
  }
}
