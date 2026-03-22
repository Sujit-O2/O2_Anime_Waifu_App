import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Topic-based semantic retrieval injected into LLM prompt.
class SemanticMemory {
  final String topic;
  final String content;
  final DateTime timestamp;
  final int accessCount;

  SemanticMemory({
    required this.topic,
    required this.content,
    required this.timestamp,
    this.accessCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'accessCount': accessCount,
      };

  factory SemanticMemory.fromJson(Map<String, dynamic> json) =>
      SemanticMemory(
        topic: json['topic'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        accessCount: json['accessCount'] as int? ?? 0,
      );
}

class SemanticMemoryService {
  static const int _maxMemories = 200;
  final List<SemanticMemory> _memories = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('semantic_memories');
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      _memories.clear();
      _memories.addAll(
        decoded
            .map((e) => SemanticMemory.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  void addMemory(String topic, String content) {
    final existing = _memories.indexWhere(
        (m) => m.topic.toLowerCase() == topic.toLowerCase());
    if (existing >= 0) {
      _memories[existing] = SemanticMemory(
        topic: topic,
        content: content,
        timestamp: DateTime.now(),
        accessCount: _memories[existing].accessCount + 1,
      );
    } else {
      _memories.add(SemanticMemory(
        topic: topic,
        content: content,
        timestamp: DateTime.now(),
      ));
    }
    if (_memories.length > _maxMemories) {
      _memories.sort((a, b) => a.accessCount.compareTo(b.accessCount));
      _memories.removeAt(0);
    }
    _persist();
  }

  List<SemanticMemory> search(String query) {
    final queryLower = query.toLowerCase();
    return _memories
        .where((m) =>
            m.topic.toLowerCase().contains(queryLower) ||
            m.content.toLowerCase().contains(queryLower))
        .toList();
  }

  String getRelevantContext(String userMessage) {
    final results = search(userMessage);
    if (results.isEmpty) return '';
    return '[Semantic Memory]\n${results.take(3).map((m) => '- ${m.topic}: ${m.content}').join('\n')}';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'semantic_memories',
      jsonEncode(_memories.map((m) => m.toJson()).toList()),
    );
  }
}
