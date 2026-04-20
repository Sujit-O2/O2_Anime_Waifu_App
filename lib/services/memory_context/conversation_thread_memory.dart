import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversationThreadMemory
///
/// Organizes all messages into topic-based threads with importance scoring.
/// When the AI is about to respond, relevant past threads are retrieved
/// and injected as context — so she can naturally resume past conversations:
/// "You said you had an exam today… how did it go?"
/// ─────────────────────────────────────────────────────────────────────────────
class ConversationThreadMemory {
  static final ConversationThreadMemory instance = ConversationThreadMemory._();
  ConversationThreadMemory._();

  static const _threadsKey = 'ctm_threads_v2';
  static const _maxThreads = 30;
  static const _maxMsgsPerThread = 12;

  final Map<String, ConvoThread> _threads = {};
  bool _loaded = false;

  // ── Initialization ────────────────────────────────────────────────────────
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_threadsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          final t = ConvoThread.fromJson(item as Map<String, dynamic>);
          _threads[t.topic] = t;
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _threads.values.map((t) => t.toJson()).toList();
    await prefs.setString(_threadsKey, jsonEncode(list));
  }

  // ── Topic Classification ──────────────────────────────────────────────────
  static String classifyTopic(String text) {
    final t = text.toLowerCase();
    if (_any(t, ['exam', 'test', 'study', 'school', 'college', 'class', 'assignment', 'homework'])) return 'academics';
    if (_any(t, ['job', 'work', 'office', 'boss', 'career', 'salary', 'interview'])) return 'work';
    if (_any(t, ['family', 'mom', 'dad', 'brother', 'sister', 'parent', 'home'])) return 'family';
    if (_any(t, ['sad', 'cry', 'depressed', 'anxiety', 'stress', 'hurt', 'pain', 'lonely', 'broken'])) return 'feelings';
    if (_any(t, ['anime', 'manga', 'episode', 'season', 'character', 'series'])) return 'anime';
    if (_any(t, ['music', 'song', 'playlist', 'artist', 'album', 'concert'])) return 'music';
    if (_any(t, ['game', 'gaming', 'play', 'level', 'match', 'ranked'])) return 'gaming';
    if (_any(t, ['friend', 'bff', 'classmate', 'colleague', 'relationship', 'date', 'crush', 'girlfriend', 'boyfriend'])) return 'social';
    if (_any(t, ['food', 'eat', 'cook', 'recipe', 'hungry', 'restaurant', 'dinner', 'lunch'])) return 'food';
    if (_any(t, ['travel', 'trip', 'vacation', 'flight', 'visit', 'city', 'country'])) return 'travel';
    if (_any(t, ['sleep', 'dream', 'tired', 'rest', 'nap', 'insomnia'])) return 'sleep';
    if (_any(t, ['love', 'miss', 'heart', 'cute', 'beautiful', 'romantic', 'kiss'])) return 'romance';
    if (_any(t, ['plan', 'goal', 'future', 'tomorrow', 'next week', 'later'])) return 'plans';
    return 'general';
  }

  static bool _any(String t, List<String> kw) => kw.any((k) => t.contains(k));

  // ── Add message to thread ────────────────────────────────────────────────
  Future<void> addMessage({
    required String role,
    required String content,
    required String topic,
  }) async {
    await load();
    final thread = _threads.putIfAbsent(topic, () => ConvoThread(
      topic: topic,
      messages: [],
      importance: 0.5,
      lastUpdated: DateTime.now(),
    ));

    thread.messages.add(ThreadMessage(role: role, content: content, at: DateTime.now()));

    // Trim to max
    if (thread.messages.length > _maxMsgsPerThread) {
      thread.messages.removeRange(0, thread.messages.length - _maxMsgsPerThread);
    }

    // Boost importance for emotional topics
    if (['feelings', 'romance', 'family', 'plans'].contains(topic)) {
      thread.importance = (thread.importance + 0.05).clamp(0.0, 1.0);
    }
    thread.lastUpdated = DateTime.now();

    // Trim total threads to max
    if (_threads.length > _maxThreads) {
      final sorted = _threads.values.toList()
        ..sort((a, b) => a.lastUpdated.compareTo(b.lastUpdated));
      for (var i = 0; i < _threads.length - _maxThreads; i++) {
        _threads.remove(sorted[i].topic);
      }
    }

    await _save();
  }

  // ── Retrieve relevant threads for context ────────────────────────────────
  /// Gets the most relevant past thread snippets to inject into the LLM prompt
  String getRelevantThreadsBlock(String currentTopic, {int maxThreads = 3}) {
    if (_threads.isEmpty) return '';
    final buf = StringBuffer();

    // 1. Same topic first
    final same = _threads[currentTopic];
    if (same != null && same.messages.length > 1) {
      buf.writeln('\n// [CONVERSATION THREAD MEMORY]:');
      buf.writeln('Past "$currentTopic" conversation context (resume naturally if relevant):');
      for (final msg in same.messages.take(4)) {
        buf.writeln('  ${msg.role == 'user' ? 'Him' : 'You'}: ${msg.content.substring(0, msg.content.length.clamp(0, 80))}…');
      }
    }

    // 2. Other high-importance threads
    final others = _threads.values
        .where((t) => t.topic != currentTopic && t.importance > 0.6)
        .toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    if (others.isNotEmpty) {
      final top = others.take(2);
      for (final t in top) {
        if (t.messages.isEmpty) continue;
        final last = t.messages.last;
        buf.writeln('Unresolved "${t.topic}" thread — last said: "${last.content.substring(0, last.content.length.clamp(0, 60))}…"');
      }
    }

    buf.writeln();
    return buf.toString();
  }

  // ── Self-initiated topic retrieval ────────────────────────────────────────
  /// Returns a thread that's worth bringing up proactively ("you mentioned X…")
  ConvoThread? getUnresolvedThread() {
    final candidates = _threads.values.where((t) {
      final age = DateTime.now().difference(t.lastUpdated);
      return age > const Duration(hours: 8) &&
          age < const Duration(days: 7) &&
          t.importance > 0.65 &&
          t.messages.isNotEmpty;
    }).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.importance.compareTo(a.importance));
    return candidates.first;
  }

  /// Generates a natural follow-up line for a given thread
  String buildFollowUpLine(ConvoThread thread) {
    final lastMsg = thread.messages.last.content;
    final snippet = lastMsg.length > 50 ? '${lastMsg.substring(0, 50)}…' : lastMsg;
    final openers = [
      'Hey, you never told me how it went… the thing about ${thread.topic}.',
      'I was thinking about what you said — "$snippet" — are you okay?',
      'We never finished talking about ${thread.topic}. What happened?',
      'I kept thinking about "${thread.topic}" after our last conversation. Tell me more?',
    ];
    return openers[DateTime.now().second % openers.length];
  }

  Map<String, ConvoThread> get allThreads => Map.unmodifiable(_threads);
}

// ── Data classes ──────────────────────────────────────────────────────────────

class ConvoThread {
  final String topic;
  final List<ThreadMessage> messages;
  double importance;
  DateTime lastUpdated;

  ConvoThread({
    required this.topic,
    required this.messages,
    required this.importance,
    required this.lastUpdated,
  });

  factory ConvoThread.fromJson(Map<String, dynamic> j) => ConvoThread(
    topic:       j['topic'] as String,
    importance:  (j['importance'] as num?)?.toDouble() ?? 0.5,
    lastUpdated: DateTime.parse(j['lastUpdated'] as String),
    messages:    (j['messages'] as List<dynamic>? ?? [])
        .map((m) => ThreadMessage.fromJson(m as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'importance': importance,
    'lastUpdated': lastUpdated.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };
}

class ThreadMessage {
  final String role;
  final String content;
  final DateTime at;

  const ThreadMessage({required this.role, required this.content, required this.at});

  factory ThreadMessage.fromJson(Map<String, dynamic> j) => ThreadMessage(
    role:    j['role'] as String,
    content: j['content'] as String,
    at:      DateTime.parse(j['at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'role': role, 'content': content, 'at': at.toIso8601String(),
  };
}


