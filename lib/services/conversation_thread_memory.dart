import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 2: 14 topic threads, stores 30 threads x 12 messages.
/// Follow-up detection: "you never told me how the exam went..."
class ConversationThread {
  final String topic;
  final List<String> messages;
  final DateTime lastUpdated;
  bool isResolved;

  ConversationThread({
    required this.topic,
    List<String>? messages,
    DateTime? lastUpdated,
    this.isResolved = false,
  })  : messages = messages ?? [],
        lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'messages': messages,
        'lastUpdated': lastUpdated.toIso8601String(),
        'isResolved': isResolved,
      };

  factory ConversationThread.fromJson(Map<String, dynamic> json) =>
      ConversationThread(
        topic: json['topic'] as String,
        messages: (json['messages'] as List<dynamic>).cast<String>(),
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
        isResolved: json['isResolved'] as bool? ?? false,
      );
}

class ConversationThreadMemory {
  static const int _maxThreads = 30;
  static const int _maxMessagesPerThread = 12;
  final List<ConversationThread> _threads = [];

  List<ConversationThread> get threads => List.unmodifiable(_threads);

  int get unresolvedCount =>
      _threads.where((t) => !t.isResolved).length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('conversation_threads');
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      _threads.clear();
      _threads.addAll(
        decoded.map(
            (e) => ConversationThread.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  void addToThread(String topic, String message) {
    var thread = _threads.firstWhere(
      (t) => t.topic.toLowerCase() == topic.toLowerCase(),
      orElse: () {
        final newThread = ConversationThread(topic: topic);
        _threads.add(newThread);
        return newThread;
      },
    );

    thread.messages.add(message);
    if (thread.messages.length > _maxMessagesPerThread) {
      thread.messages.removeAt(0);
    }

    // Trim total threads
    if (_threads.length > _maxThreads) {
      _threads.sort(
          (a, b) => a.lastUpdated.compareTo(b.lastUpdated));
      _threads.removeAt(0);
    }

    _persist();
  }

  void resolveThread(String topic) {
    final thread = _threads.firstWhere(
      (t) => t.topic.toLowerCase() == topic.toLowerCase(),
      orElse: () => ConversationThread(topic: ''),
    );
    if (thread.topic.isNotEmpty) {
      thread.isResolved = true;
      _persist();
    }
  }

  List<ConversationThread> getUnresolvedThreads() {
    return _threads.where((t) => !t.isResolved).toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  }

  String? getFollowUpSuggestion() {
    final unresolved = getUnresolvedThreads();
    if (unresolved.isEmpty) return null;

    final oldest = unresolved.last;
    final hoursSince =
        DateTime.now().difference(oldest.lastUpdated).inHours;
    if (hoursSince > 2) {
      return 'You never told me how "${oldest.topic}" went...';
    }
    return null;
  }

  String toContextString() {
    final unresolved = getUnresolvedThreads();
    if (unresolved.isEmpty) return '';
    return '[Active Threads] ${unresolved.map((t) => t.topic).join(', ')} (${unresolved.length} unresolved)';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'conversation_threads',
      jsonEncode(_threads.map((t) => t.toJson()).toList()),
    );
  }
}
