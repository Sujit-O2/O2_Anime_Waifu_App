class SecretNote {
  final String id;
  final String encryptedContent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;

  SecretNote({
    required this.id,
    required this.encryptedContent,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'encryptedContent': encryptedContent,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'title': title,
      };

  factory SecretNote.fromJson(Map<String, dynamic> json) => SecretNote(
        id: json['id'] as String,
        encryptedContent: json['encryptedContent'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        title: json['title'] as String?,
      );
}
