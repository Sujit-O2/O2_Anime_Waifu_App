import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ⭐ Conversation Bookmarks Service
/// 
/// Star important messages for quick access.
/// "Remember when you said..." feature.
/// Export specific conversations as PDFs.
class ConversationBookmarksService {
  ConversationBookmarksService._();
  static final ConversationBookmarksService instance = ConversationBookmarksService._();

  final List<BookmarkedMessage> _bookmarks = [];
  final Map<String, List<String>> _collections = {};

  static const String _storageKey = 'conversation_bookmarks_v1';
  static const int _maxBookmarks = 500;

  Future<void> initialize() async {
    await _loadBookmarks();
    if (kDebugMode) debugPrint('[Bookmarks] Initialized with ${_bookmarks.length} bookmarks');
  }

  /// Bookmark a message
  Future<BookmarkedMessage> addBookmark({
    required String messageId,
    required String messageText,
    required String sender,
    required DateTime timestamp,
    String? note,
    List<String>? tags,
    String? collectionId,
  }) async {
    // Check if already bookmarked
    if (_bookmarks.any((b) => b.messageId == messageId)) {
      throw Exception('Message already bookmarked');
    }

    final bookmark = BookmarkedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: messageId,
      messageText: messageText,
      sender: sender,
      timestamp: timestamp,
      bookmarkedAt: DateTime.now(),
      note: note,
      tags: tags ?? [],
      collectionId: collectionId,
    );

    _bookmarks.insert(0, bookmark);
    if (_bookmarks.length > _maxBookmarks) {
      _bookmarks.removeLast();
    }

    await _saveBookmarks();
    
    if (kDebugMode) debugPrint('[Bookmarks] Added: ${bookmark.messageText.substring(0, 30)}...');
    return bookmark;
  }

  /// Remove bookmark
  Future<void> removeBookmark(String bookmarkId) async {
    _bookmarks.removeWhere((b) => b.id == bookmarkId);
    await _saveBookmarks();
  }

  /// Update bookmark note
  Future<void> updateNote(String bookmarkId, String note) async {
    final index = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index != -1) {
      _bookmarks[index] = _bookmarks[index].copyWith(note: note);
      await _saveBookmarks();
    }
  }

  /// Add tags to bookmark
  Future<void> addTags(String bookmarkId, List<String> tags) async {
    final index = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index != -1) {
      final existingTags = _bookmarks[index].tags;
      final newTags = {...existingTags, ...tags}.toList();
      _bookmarks[index] = _bookmarks[index].copyWith(tags: newTags);
      await _saveBookmarks();
    }
  }

  /// Create a collection
  Future<void> createCollection(String name, List<String> bookmarkIds) async {
    final collectionId = DateTime.now().millisecondsSinceEpoch.toString();
    _collections[collectionId] = bookmarkIds;

    // Update bookmarks with collection ID
    for (final bookmarkId in bookmarkIds) {
      final index = _bookmarks.indexWhere((b) => b.id == bookmarkId);
      if (index != -1) {
        _bookmarks[index] = _bookmarks[index].copyWith(collectionId: collectionId);
      }
    }

    await _saveBookmarks();
  }

  /// Get all bookmarks
  List<BookmarkedMessage> getAllBookmarks() => List.unmodifiable(_bookmarks);

  /// Get bookmarks by tag
  List<BookmarkedMessage> getBookmarksByTag(String tag) {
    return _bookmarks.where((b) => b.tags.contains(tag)).toList();
  }

  /// Get bookmarks by sender
  List<BookmarkedMessage> getBookmarksBySender(String sender) {
    return _bookmarks.where((b) => b.sender == sender).toList();
  }

  /// Get bookmarks in date range
  List<BookmarkedMessage> getBookmarksInRange(DateTime start, DateTime end) {
    return _bookmarks.where((b) => 
      b.timestamp.isAfter(start) && b.timestamp.isBefore(end)
    ).toList();
  }

  /// Search bookmarks
  List<BookmarkedMessage> searchBookmarks(String query) {
    final lowerQuery = query.toLowerCase();
    return _bookmarks.where((b) => 
      b.messageText.toLowerCase().contains(lowerQuery) ||
      (b.note?.toLowerCase().contains(lowerQuery) ?? false) ||
      b.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  /// Get all unique tags
  List<String> getAllTags() {
    final tags = <String>{};
    for (final bookmark in _bookmarks) {
      tags.addAll(bookmark.tags);
    }
    return tags.toList()..sort();
  }

  /// Get bookmark statistics
  Map<String, dynamic> getStatistics() {
    if (_bookmarks.isEmpty) {
      return {
        'total_bookmarks': 0,
        'by_sender': {},
        'by_tag': {},
        'oldest': null,
        'newest': null,
      };
    }

    final bySender = <String, int>{};
    final byTag = <String, int>{};

    for (final bookmark in _bookmarks) {
      bySender[bookmark.sender] = (bySender[bookmark.sender] ?? 0) + 1;
      for (final tag in bookmark.tags) {
        byTag[tag] = (byTag[tag] ?? 0) + 1;
      }
    }

    return {
      'total_bookmarks': _bookmarks.length,
      'by_sender': bySender,
      'by_tag': byTag,
      'oldest': _bookmarks.last.timestamp.toIso8601String(),
      'newest': _bookmarks.first.timestamp.toIso8601String(),
    };
  }

  /// Generate AI summary for bookmarks
  String generateAISummary({List<String>? bookmarkIds}) {
    final toSummarize = bookmarkIds != null
        ? _bookmarks.where((b) => bookmarkIds.contains(b.id)).toList()
        : _bookmarks;

    if (toSummarize.isEmpty) {
      return 'No bookmarks to summarize.';
    }

    final buffer = StringBuffer();
    buffer.writeln('🤖 AI-Generated Summary\n');

    // Analyze emotional tone
    final emotionalWords = _analyzeEmotionalTone(toSummarize);
    buffer.writeln('Emotional Tone: ${emotionalWords.join(', ')}\n');

    // Find key topics
    final topics = _extractKeyTopics(toSummarize);
    if (topics.isNotEmpty) {
      buffer.writeln('Key Topics:');
      for (final topic in topics) {
        buffer.writeln('  • $topic');
      }
      buffer.writeln();
    }

    // Timeline summary
    if (toSummarize.length > 1) {
      final firstDate = toSummarize.last.timestamp;
      final lastDate = toSummarize.first.timestamp;
      final daysDiff = lastDate.difference(firstDate).inDays;
      buffer.writeln('Timeline: ${toSummarize.length} messages over $daysDiff days\n');
    }

    // Most memorable moments
    buffer.writeln('Most Memorable Moments:');
    for (final bookmark in toSummarize.take(5)) {
      final preview = bookmark.messageText.length > 80
          ? '${bookmark.messageText.substring(0, 80)}...'
          : bookmark.messageText;
      buffer.writeln('  "$preview"');
    }

    return buffer.toString();
  }

  List<String> _analyzeEmotionalTone(List<BookmarkedMessage> bookmarks) {
    final emotions = <String>[];
    final allText = bookmarks.map((b) => b.messageText.toLowerCase()).join(' ');

    if (allText.contains(RegExp(r'love|adore|cherish|treasure'))) emotions.add('💕 Loving');
    if (allText.contains(RegExp(r'happy|joy|excited|great'))) emotions.add('😊 Happy');
    if (allText.contains(RegExp(r'sad|miss|lonely|hurt'))) emotions.add('😢 Sad');
    if (allText.contains(RegExp(r'thank|grateful|appreciate'))) emotions.add('🙏 Grateful');
    if (allText.contains(RegExp(r'fun|laugh|hilarious|funny'))) emotions.add('😄 Playful');
    if (allText.contains(RegExp(r'important|serious|matter'))) emotions.add('🎯 Serious');

    return emotions.isEmpty ? ['😐 Neutral'] : emotions;
  }

  List<String> _extractKeyTopics(List<BookmarkedMessage> bookmarks) {
    final topics = <String>{};
    final allText = bookmarks.map((b) => b.messageText.toLowerCase()).join(' ');

    // Common topic keywords
    const topicMap = {
      'work': ['work', 'job', 'career', 'office', 'meeting'],
      'relationship': ['love', 'relationship', 'together', 'us', 'couple'],
      'family': ['family', 'mom', 'dad', 'parent', 'sibling'],
      'health': ['health', 'doctor', 'sick', 'medicine', 'exercise'],
      'travel': ['travel', 'trip', 'vacation', 'visit', 'journey'],
      'food': ['food', 'eat', 'dinner', 'lunch', 'cook'],
      'hobbies': ['hobby', 'game', 'music', 'movie', 'book'],
      'future': ['future', 'plan', 'dream', 'goal', 'hope'],
    };

    topicMap.forEach((topic, keywords) {
      for (final keyword in keywords) {
        if (allText.contains(keyword)) {
          topics.add(topic);
          break;
        }
      }
    });

    return topics.toList();
  }

  /// Export bookmarks as text
  String exportAsText({List<String>? bookmarkIds}) {
    final toExport = bookmarkIds != null
        ? _bookmarks.where((b) => bookmarkIds.contains(b.id)).toList()
        : _bookmarks;

    final buffer = StringBuffer();
    buffer.writeln('📚 Bookmarked Conversations\n');
    buffer.writeln('Exported: ${DateTime.now()}\n');
    buffer.writeln('Total: ${toExport.length} messages\n');
    buffer.writeln('${'=' * 50}\n');

    for (final bookmark in toExport) {
      buffer.writeln('Date: ${_formatDate(bookmark.timestamp)}');
      buffer.writeln('From: ${bookmark.sender}');
      if (bookmark.tags.isNotEmpty) {
        buffer.writeln('Tags: ${bookmark.tags.join(', ')}');
      }
      buffer.writeln('\nMessage:');
      buffer.writeln(bookmark.messageText);
      if (bookmark.note != null) {
        buffer.writeln('\nNote: ${bookmark.note}');
      }
      buffer.writeln('\n${'=' * 50}\n');
    }

    return buffer.toString();
  }

  /// Get "Remember when..." suggestions
  List<String> getRememberWhenSuggestions({int limit = 5}) {
    if (_bookmarks.isEmpty) return [];

    final suggestions = <String>[];
    
    // Get random bookmarks
    final shuffled = List<BookmarkedMessage>.from(_bookmarks)..shuffle();
    
    for (final bookmark in shuffled.take(limit)) {
      final preview = bookmark.messageText.length > 50
          ? '${bookmark.messageText.substring(0, 50)}...'
          : bookmark.messageText;
      
      suggestions.add('Remember when you said: "$preview"');
    }

    return suggestions;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'bookmarks': _bookmarks.map((b) => b.toJson()).toList(),
        'collections': _collections,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[Bookmarks] Save error: $e');
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _bookmarks.clear();
        _bookmarks.addAll(
          (data['bookmarks'] as List<dynamic>)
              .map((b) => BookmarkedMessage.fromJson(b as Map<String, dynamic>))
        );

        _collections.clear();
        (data['collections'] as Map<String, dynamic>).forEach((k, v) {
          _collections[k] = List<String>.from(v as List);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Bookmarks] Load error: $e');
    }
  }
}

class BookmarkedMessage {
  final String id;
  final String messageId;
  final String messageText;
  final String sender;
  final DateTime timestamp;
  final DateTime bookmarkedAt;
  final String? note;
  final List<String> tags;
  final String? collectionId;

  const BookmarkedMessage({
    required this.id,
    required this.messageId,
    required this.messageText,
    required this.sender,
    required this.timestamp,
    required this.bookmarkedAt,
    this.note,
    required this.tags,
    this.collectionId,
  });

  BookmarkedMessage copyWith({
    String? id,
    String? messageId,
    String? messageText,
    String? sender,
    DateTime? timestamp,
    DateTime? bookmarkedAt,
    String? note,
    List<String>? tags,
    String? collectionId,
  }) {
    return BookmarkedMessage(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      messageText: messageText ?? this.messageText,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      collectionId: collectionId ?? this.collectionId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'messageId': messageId,
    'messageText': messageText,
    'sender': sender,
    'timestamp': timestamp.toIso8601String(),
    'bookmarkedAt': bookmarkedAt.toIso8601String(),
    'note': note,
    'tags': tags,
    'collectionId': collectionId,
  };

  factory BookmarkedMessage.fromJson(Map<String, dynamic> json) => BookmarkedMessage(
    id: json['id'] as String,
    messageId: json['messageId'] as String,
    messageText: json['messageText'] as String,
    sender: json['sender'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    bookmarkedAt: DateTime.parse(json['bookmarkedAt'] as String),
    note: json['note'] as String?,
    tags: List<String>.from(json['tags'] as List),
    collectionId: json['collectionId'] as String?,
  );
}
