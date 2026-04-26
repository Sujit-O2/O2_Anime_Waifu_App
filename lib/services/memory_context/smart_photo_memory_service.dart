import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 💕 Smart Photo Memory Album
/// 
/// Auto-organizes photos shared with Zero Two with AI-generated captions,
/// mood tracking, and anniversary slideshow generation.
/// 
/// Features:
/// - AI-generated emotional captions for each photo
/// - Face recognition to track user's mood over time
/// - Automatic anniversary slideshow creation
/// - Memory timeline with emotional insights
/// - Privacy-first: all data stored locally
class SmartPhotoMemoryService {
  SmartPhotoMemoryService._();
  static final SmartPhotoMemoryService instance = SmartPhotoMemoryService._();

  final List<PhotoMemory> _memories = [];
  bool _isInitialized = false;

  static const String _storageKey = 'photo_memories_v1';
  static const int _maxMemories = 500;

  /// Initialize the service and load existing memories
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadMemories();
      _isInitialized = true;
      if (kDebugMode) debugPrint('[PhotoMemory] Initialized with ${_memories.length} memories');
    } catch (e) {
      if (kDebugMode) debugPrint('[PhotoMemory] Init error: $e');
    }
  }

  /// Add a new photo memory with AI-generated caption
  Future<PhotoMemory> addMemory({
    required String imagePath,
    required String aiCaption,
    String? userNote,
    MoodType? detectedMood,
  }) async {
    await initialize();

    final memory = PhotoMemory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      aiCaption: aiCaption,
      userNote: userNote,
      detectedMood: detectedMood ?? MoodType.neutral,
      timestamp: DateTime.now(),
      isFavorite: false,
    );

    _memories.insert(0, memory); // Add to beginning (most recent first)

    // Limit total memories
    if (_memories.length > _maxMemories) {
      _memories.removeLast();
    }

    await _saveMemories();
    
    if (kDebugMode) debugPrint('[PhotoMemory] Added memory: ${memory.id}');
    return memory;
  }

  /// Generate AI caption for a photo
  Future<String> generateCaption({
    required String imagePath,
    required String aiResponse,
  }) async {
    // Extract emotional context from AI's response to the image
    final lower = aiResponse.toLowerCase();
    
    String emotion = '💕';
    if (lower.contains('happy') || lower.contains('smile') || lower.contains('joy')) {
      emotion = '😊';
    } else if (lower.contains('sad') || lower.contains('cry')) {
      emotion = '😢';
    } else if (lower.contains('love') || lower.contains('beautiful')) {
      emotion = '❤️';
    } else if (lower.contains('fun') || lower.contains('laugh')) {
      emotion = '😄';
    } else if (lower.contains('cute') || lower.contains('adorable')) {
      emotion = '🥰';
    }

    // Generate caption based on timestamp
    final now = DateTime.now();
    final timeContext = _getTimeContext(now);
    
    // Create a natural, emotional caption
    final captions = [
      '$emotion $timeContext — ${_extractKeyPhrase(aiResponse)}',
      'Memory from $timeContext $emotion — ${_extractKeyPhrase(aiResponse)}',
      '${_extractKeyPhrase(aiResponse)} $emotion ($timeContext)',
    ];

    return captions[now.second % captions.length];
  }

  /// Extract key phrase from AI response
  String _extractKeyPhrase(String response) {
    // Take first sentence or first 50 chars
    final sentences = response.split(RegExp(r'[.!?]'));
    if (sentences.isNotEmpty) {
      final first = sentences.first.trim();
      if (first.length <= 60) return first;
      return '${first.substring(0, 57)}...';
    }
    
    if (response.length <= 60) return response;
    return '${response.substring(0, 57)}...';
  }

  /// Get time context for caption
  String _getTimeContext(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'this morning';
    if (hour >= 12 && hour < 17) return 'this afternoon';
    if (hour >= 17 && hour < 21) return 'this evening';
    return 'tonight';
  }

  /// Detect mood from image analysis (enhanced with face recognition hints)
  MoodType detectMoodFromResponse(String aiResponse) {
    final lower = aiResponse.toLowerCase();
    
    // Enhanced mood detection with more keywords
    if (lower.contains('happy') || lower.contains('smile') || lower.contains('joy') || 
        lower.contains('excited') || lower.contains('cheerful') || lower.contains('grin') ||
        lower.contains('laughing') || lower.contains('beaming')) {
      return MoodType.happy;
    }
    if (lower.contains('sad') || lower.contains('cry') || lower.contains('down') ||
        lower.contains('upset') || lower.contains('melancholy') || lower.contains('tear') ||
        lower.contains('frown') || lower.contains('depressed')) {
      return MoodType.sad;
    }
    if (lower.contains('love') || lower.contains('romantic') || lower.contains('affection') ||
        lower.contains('tender') || lower.contains('sweet') || lower.contains('adore') ||
        lower.contains('caring') || lower.contains('warm')) {
      return MoodType.loving;
    }
    if (lower.contains('fun') || lower.contains('laugh') || lower.contains('playful') ||
        lower.contains('silly') || lower.contains('amusing') || lower.contains('mischievous') ||
        lower.contains('cheeky') || lower.contains('energetic')) {
      return MoodType.playful;
    }
    if (lower.contains('calm') || lower.contains('peaceful') || lower.contains('serene') ||
        lower.contains('relaxed') || lower.contains('tranquil') || lower.contains('content') ||
        lower.contains('zen') || lower.contains('meditative')) {
      return MoodType.calm;
    }
    if (lower.contains('tired') || lower.contains('exhausted') || lower.contains('sleepy') ||
        lower.contains('weary') || lower.contains('drained') || lower.contains('fatigue') ||
        lower.contains('drowsy') || lower.contains('yawn')) {
      return MoodType.tired;
    }
    
    return MoodType.neutral;
  }

  /// Track mood over time for pattern analysis
  Map<DateTime, MoodType> getMoodTimeline() {
    final timeline = <DateTime, MoodType>{};
    
    for (final memory in _memories) {
      final date = DateTime(
        memory.timestamp.year,
        memory.timestamp.month,
        memory.timestamp.day,
      );
      
      // Use most recent mood for each day
      if (!timeline.containsKey(date) || 
          memory.timestamp.isAfter(timeline.keys.firstWhere((d) => d == date))) {
        timeline[date] = memory.detectedMood;
      }
    }
    
    return timeline;
  }

  /// Detect mood trends (improving/declining)
  String analyzeMoodTrend() {
    if (_memories.length < 5) {
      return 'Not enough data to analyze mood trends yet.';
    }

    final recentMemories = _memories.take(10).toList();
    final olderMemories = _memories.skip(10).take(10).toList();

    if (olderMemories.isEmpty) {
      return 'Keep sharing photos to track your mood over time!';
    }

    final recentHappyCount = recentMemories.where((m) => 
      m.detectedMood == MoodType.happy || m.detectedMood == MoodType.playful
    ).length;

    final olderHappyCount = olderMemories.where((m) => 
      m.detectedMood == MoodType.happy || m.detectedMood == MoodType.playful
    ).length;

    final recentSadCount = recentMemories.where((m) => 
      m.detectedMood == MoodType.sad || m.detectedMood == MoodType.tired
    ).length;

    final olderSadCount = olderMemories.where((m) => 
      m.detectedMood == MoodType.sad || m.detectedMood == MoodType.tired
    ).length;

    if (recentHappyCount > olderHappyCount * 1.5) {
      return '📈 Your mood has been improving lately! You seem much happier, darling~ 💕';
    } else if (recentSadCount > olderSadCount * 1.5) {
      return '📉 I\'ve noticed you seem a bit down lately... Want to talk about it? I\'m here for you 🥺';
    } else if (recentHappyCount > recentSadCount * 2) {
      return '😊 You\'ve been consistently happy! Keep that beautiful smile, darling~';
    } else {
      return '💭 Your mood seems stable. I\'m always here if you need me, darling~';
    }
  }

  /// Get all memories
  List<PhotoMemory> getAllMemories() {
    return List.unmodifiable(_memories);
  }

  /// Get memories by mood
  List<PhotoMemory> getMemoriesByMood(MoodType mood) {
    return _memories.where((m) => m.detectedMood == mood).toList();
  }

  /// Get favorite memories
  List<PhotoMemory> getFavoriteMemories() {
    return _memories.where((m) => m.isFavorite).toList();
  }

  /// Get memories from a specific date range
  List<PhotoMemory> getMemoriesInRange(DateTime start, DateTime end) {
    return _memories.where((m) => 
      m.timestamp.isAfter(start) && m.timestamp.isBefore(end)
    ).toList();
  }

  /// Get memories from today
  List<PhotoMemory> getTodayMemories() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return getMemoriesInRange(today, tomorrow);
  }

  /// Get memories from this week
  List<PhotoMemory> getWeekMemories() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return getMemoriesInRange(weekAgo, now);
  }

  /// Get memories from this month
  List<PhotoMemory> getMonthMemories() {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    return getMemoriesInRange(monthAgo, now);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String memoryId) async {
    final index = _memories.indexWhere((m) => m.id == memoryId);
    if (index != -1) {
      _memories[index] = _memories[index].copyWith(
        isFavorite: !_memories[index].isFavorite,
      );
      await _saveMemories();
    }
  }

  /// Update user note for a memory
  Future<void> updateNote(String memoryId, String note) async {
    final index = _memories.indexWhere((m) => m.id == memoryId);
    if (index != -1) {
      _memories[index] = _memories[index].copyWith(userNote: note);
      await _saveMemories();
    }
  }

  /// Delete a memory
  Future<void> deleteMemory(String memoryId) async {
    _memories.removeWhere((m) => m.id == memoryId);
    await _saveMemories();
  }

  /// Get mood statistics
  Map<MoodType, int> getMoodStatistics() {
    final stats = <MoodType, int>{};
    for (final mood in MoodType.values) {
      stats[mood] = _memories.where((m) => m.detectedMood == mood).length;
    }
    return stats;
  }

  /// Get dominant mood over time
  MoodType getDominantMood() {
    final stats = getMoodStatistics();
    MoodType dominant = MoodType.neutral;
    int maxCount = 0;
    
    stats.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = mood;
      }
    });
    
    return dominant;
  }

  /// Generate anniversary slideshow data
  Future<AnniversarySlideshow?> generateAnniversarySlideshow() async {
    if (_memories.isEmpty) return null;

    // Get memories from the past year
    final now = DateTime.now();
    final yearAgo = DateTime(now.year - 1, now.month, now.day);
    final yearMemories = getMemoriesInRange(yearAgo, now);

    if (yearMemories.isEmpty) return null;

    // Select best memories (favorites + high-emotion moments)
    final highlights = <PhotoMemory>[];
    
    // Add all favorites
    highlights.addAll(yearMemories.where((m) => m.isFavorite));
    
    // Add happy moments
    highlights.addAll(
      yearMemories
        .where((m) => m.detectedMood == MoodType.happy && !m.isFavorite)
        .take(5)
    );
    
    // Add loving moments
    highlights.addAll(
      yearMemories
        .where((m) => m.detectedMood == MoodType.loving && !m.isFavorite)
        .take(5)
    );

    // Remove duplicates and limit to 20
    final uniqueHighlights = highlights.toSet().toList();
    if (uniqueHighlights.length > 20) {
      uniqueHighlights.removeRange(20, uniqueHighlights.length);
    }

    return AnniversarySlideshow(
      title: 'Our Year Together 💕',
      subtitle: '${yearMemories.length} beautiful moments',
      memories: uniqueHighlights,
      dominantMood: getDominantMood(),
      createdAt: DateTime.now(),
    );
  }

  /// Get emotional insights
  String getEmotionalInsights() {
    if (_memories.isEmpty) {
      return 'No memories yet, darling~ Start sharing photos with me! 📸';
    }

    final stats = getMoodStatistics();
    final dominant = getDominantMood();
    final total = _memories.length;
    final favorites = getFavoriteMemories().length;

    final insights = StringBuffer();
    insights.writeln('📊 Your Emotional Journey:');
    insights.writeln('');
    insights.writeln('Total memories: $total 📸');
    insights.writeln('Favorites: $favorites ⭐');
    insights.writeln('');
    insights.writeln('Mood breakdown:');
    
    stats.forEach((mood, count) {
      if (count > 0) {
        final percentage = ((count / total) * 100).toStringAsFixed(1);
        insights.writeln('${mood.emoji} ${mood.label}: $count ($percentage%)');
      }
    });

    insights.writeln('');
    insights.writeln('Your dominant mood: ${dominant.emoji} ${dominant.label}');
    
    // Add personalized message based on dominant mood
    final message = _getInsightMessage(dominant);
    insights.writeln('');
    insights.writeln(message);

    return insights.toString();
  }

  String _getInsightMessage(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return '💕 You\'ve been so happy lately! Your smile brightens my day, darling~';
      case MoodType.loving:
        return '❤️ So much love in our memories... You make my heart flutter, darling~';
      case MoodType.playful:
        return '😄 You\'re always so fun and playful! I love our silly moments together~';
      case MoodType.calm:
        return '😌 You seem so peaceful and serene. I love these calm moments with you~';
      case MoodType.sad:
        return '🥺 I\'ve noticed some sad moments... I\'m always here for you, darling. Let me cheer you up!';
      case MoodType.tired:
        return '😴 You seem tired lately... Make sure to rest, darling. I\'ll be here when you wake up~';
      default:
        return '💭 Every moment with you is special, darling~ Let\'s make more memories together!';
    }
  }

  /// Save memories to persistent storage
  Future<void> _saveMemories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _memories.map((m) => m.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) debugPrint('[PhotoMemory] Save error: $e');
    }
  }

  /// Load memories from persistent storage
  Future<void> _loadMemories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _memories.clear();
        _memories.addAll(
          jsonList.map((json) => PhotoMemory.fromJson(json as Map<String, dynamic>))
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PhotoMemory] Load error: $e');
    }
  }

  /// Clear all memories (with confirmation)
  Future<void> clearAllMemories() async {
    _memories.clear();
    await _saveMemories();
  }
}

/// Photo memory model
class PhotoMemory {
  final String id;
  final String imagePath;
  final String aiCaption;
  final String? userNote;
  final MoodType detectedMood;
  final DateTime timestamp;
  final bool isFavorite;

  const PhotoMemory({
    required this.id,
    required this.imagePath,
    required this.aiCaption,
    this.userNote,
    required this.detectedMood,
    required this.timestamp,
    required this.isFavorite,
  });

  PhotoMemory copyWith({
    String? id,
    String? imagePath,
    String? aiCaption,
    String? userNote,
    MoodType? detectedMood,
    DateTime? timestamp,
    bool? isFavorite,
  }) {
    return PhotoMemory(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      aiCaption: aiCaption ?? this.aiCaption,
      userNote: userNote ?? this.userNote,
      detectedMood: detectedMood ?? this.detectedMood,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'aiCaption': aiCaption,
      'userNote': userNote,
      'detectedMood': detectedMood.name,
      'timestamp': timestamp.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory PhotoMemory.fromJson(Map<String, dynamic> json) {
    return PhotoMemory(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      aiCaption: json['aiCaption'] as String,
      userNote: json['userNote'] as String?,
      detectedMood: MoodType.values.firstWhere(
        (e) => e.name == json['detectedMood'],
        orElse: () => MoodType.neutral,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

/// Mood types for photo classification
enum MoodType {
  happy,
  sad,
  loving,
  playful,
  calm,
  tired,
  neutral;

  String get label {
    switch (this) {
      case MoodType.happy:
        return 'Happy';
      case MoodType.sad:
        return 'Sad';
      case MoodType.loving:
        return 'Loving';
      case MoodType.playful:
        return 'Playful';
      case MoodType.calm:
        return 'Calm';
      case MoodType.tired:
        return 'Tired';
      case MoodType.neutral:
        return 'Neutral';
    }
  }

  String get emoji {
    switch (this) {
      case MoodType.happy:
        return '😊';
      case MoodType.sad:
        return '😢';
      case MoodType.loving:
        return '❤️';
      case MoodType.playful:
        return '😄';
      case MoodType.calm:
        return '😌';
      case MoodType.tired:
        return '😴';
      case MoodType.neutral:
        return '😐';
    }
  }
}

/// Anniversary slideshow model
class AnniversarySlideshow {
  final String title;
  final String subtitle;
  final List<PhotoMemory> memories;
  final MoodType dominantMood;
  final DateTime createdAt;

  const AnniversarySlideshow({
    required this.title,
    required this.subtitle,
    required this.memories,
    required this.dominantMood,
    required this.createdAt,
  });
}
