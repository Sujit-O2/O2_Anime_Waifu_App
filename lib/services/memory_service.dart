import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/models/chat_message.dart';

/// Sliding Window Context Buffer - manages bounded conversation window
/// to ensure LLM never receives context larger than token limit.
class MemoryService {
  static const int maxMessages = 20;
  static const String _storageKey = 'chat_history';

  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatMessage> get recentMessages =>
      _messages.length > maxMessages
          ? _messages.sublist(_messages.length - maxMessages)
          : List.from(_messages);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      _messages.clear();
      _messages.addAll(
        decoded.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    _persist();
  }

  void clearHistory() {
    _messages.clear();
    _persist();
  }

  List<Map<String, dynamic>> getContextWindow() {
    return recentMessages.map((m) {
      return {
        'role': m.type == MessageType.user ? 'user' : 'assistant',
        'content': m.content,
      };
    }).toList();
  }

  int get totalMessageCount => _messages.length;

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  String exportAsText() {
    final buffer = StringBuffer();
    for (final msg in _messages) {
      final prefix = msg.type == MessageType.user ? 'User' : 'Zero Two';
      buffer.writeln('[$prefix] ${msg.content}');
    }
    return buffer.toString();
  }
}
