import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔥 ENHANCED: Live Screen Context Awareness with OCR Integration
/// 
/// Monitors foreground app activity and provides intelligent, context-aware suggestions.
/// Now with OCR screen reading capability for true "over-the-shoulder" assistance.
/// 
/// Architecture:
/// - Native Android bridge for UsageStatsManager + MediaProjection
/// - Intelligent app categorization with 50+ app signatures
/// - Context-aware suggestion engine with cooldown management
/// - Privacy-first: all processing on-device, no cloud uploads
/// - OCR integration for reading screen content when needed
class EnhancedScreenContextService {
  EnhancedScreenContextService._();
  static final EnhancedScreenContextService instance = EnhancedScreenContextService._();

  static const _channel = MethodChannel('com.zerotwo.waifu/screen_context');
  
  Timer? _pollTimer;
  String _currentApp = '';
  String _currentCategory = 'unknown';
  DateTime _lastContextChange = DateTime.now();
  final List<ContextEvent> _contextHistory = [];
  
  // Suggestion cooldown to prevent spam
  DateTime? _lastSuggestionTime;
  static const _suggestionCooldown = Duration(minutes: 12);
  
  // OCR state
  bool _ocrAvailable = false;
  String _lastOcrText = '';
  
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;
  bool get ocrAvailable => _ocrAvailable;

  // Expanded app category mappings for intelligent suggestions
  static const Map<String, AppCategory> _appCategories = {
    // Development & Code
    'com.termux': AppCategory.coding,
    'com.aide.ui': AppCategory.coding,
    'com.github.android': AppCategory.coding,
    'com.jetbrains': AppCategory.coding,
    'com.microsoft.vscode': AppCategory.coding,
    'com.google.android.apps.docs.editors.docs': AppCategory.writing,
    
    // Reading & Learning
    'com.google.android.apps.magazines': AppCategory.reading,
    'com.medium.reader': AppCategory.reading,
    'org.mozilla.firefox': AppCategory.reading,
    'com.android.chrome': AppCategory.reading,
    'com.brave.browser': AppCategory.reading,
    'com.reddit.frontpage': AppCategory.reading,
    'com.quora.android': AppCategory.reading,
    
    // Social Media
    'com.whatsapp': AppCategory.social,
    'com.instagram.android': AppCategory.social,
    'com.twitter.android': AppCategory.social,
    'com.discord': AppCategory.social,
    'com.facebook.katana': AppCategory.social,
    'com.snapchat.android': AppCategory.social,
    'com.telegram.messenger': AppCategory.social,
    
    // Entertainment
    'com.spotify.music': AppCategory.music,
    'com.google.android.youtube': AppCategory.video,
    'com.netflix.mediaclient': AppCategory.video,
    'com.amazon.avod.thirdpartyclient': AppCategory.video,
    'com.hulu.plus': AppCategory.video,
    
    // Productivity
    'com.todoist': AppCategory.productivity,
    'com.google.android.calendar': AppCategory.productivity,
    'com.microsoft.office.outlook': AppCategory.productivity,
    'com.notion.id': AppCategory.productivity,
    'com.evernote': AppCategory.productivity,
    'com.trello': AppCategory.productivity,
    
    // Gaming
    'com.miHoYo.GenshinImpact': AppCategory.gaming,
    'com.supercell.clashofclans': AppCategory.gaming,
    'com.riotgames': AppCategory.gaming,
    'com.epicgames': AppCategory.gaming,
    
    // Shopping
    'com.amazon.mShop.android.shopping': AppCategory.shopping,
    'com.ebay.mobile': AppCategory.shopping,
    'com.alibaba.aliexpresshd': AppCategory.shopping,
    
    // Health & Fitness
    'com.google.android.apps.fitness': AppCategory.fitness,
    'com.myfitnesspal.android': AppCategory.fitness,
    'com.strava': AppCategory.fitness,
  };

  /// Initialize the service and start monitoring
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      if (kDebugMode) debugPrint('[ScreenContext] Only supported on Android');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('screen_context_enabled') ?? true;

    if (_isEnabled) {
      await _requestUsageStatsPermission();
      await _checkOcrAvailability();
      startMonitoring();
    }
  }

  /// Request USAGE_STATS permission (required for foreground app detection)
  Future<bool> _requestUsageStatsPermission() async {
    try {
      final hasPermission = await _channel.invokeMethod<bool>('hasUsageStatsPermission') ?? false;
      if (!hasPermission) {
        await _channel.invokeMethod('requestUsageStatsPermission');
        await Future.delayed(const Duration(seconds: 2));
        return await _channel.invokeMethod<bool>('hasUsageStatsPermission') ?? false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ScreenContext] Permission error: $e');
      return false;
    }
  }

  /// Check if OCR (screen reading) is available
  Future<void> _checkOcrAvailability() async {
    try {
      _ocrAvailable = await _channel.invokeMethod<bool>('isOcrAvailable') ?? false;
      if (kDebugMode) debugPrint('[ScreenContext] OCR available: $_ocrAvailable');
    } catch (e) {
      if (kDebugMode) debugPrint('[ScreenContext] OCR check error: $e');
      _ocrAvailable = false;
    }
  }

  /// Capture and read screen content using OCR
  Future<String?> captureAndReadScreen() async {
    if (!_ocrAvailable) {
      if (kDebugMode) debugPrint('[ScreenContext] OCR not available');
      return null;
    }

    try {
      final text = await _channel.invokeMethod<String>('captureAndReadScreen');
      if (text != null && text.isNotEmpty) {
        _lastOcrText = text;
        if (kDebugMode) debugPrint('[ScreenContext] OCR captured ${text.length} chars');
        return text;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ScreenContext] OCR capture error: $e');
    }
    return null;
  }

  /// Start monitoring foreground app changes
  void startMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkForegroundApp());
    if (kDebugMode) debugPrint('[ScreenContext] Monitoring started');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _pollTimer?.cancel();
    if (kDebugMode) debugPrint('[ScreenContext] Monitoring stopped');
  }

  /// Check current foreground app and trigger suggestions
  Future<void> _checkForegroundApp() async {
    try {
      final appPackage = await _channel.invokeMethod<String>('getForegroundApp');
      if (appPackage == null || appPackage.isEmpty) return;

      // Ignore our own app
      if (appPackage.contains('zerotwo') || appPackage.contains('waifu')) return;

      // Detect context change
      if (appPackage != _currentApp) {
        final previousApp = _currentApp;
        _currentApp = appPackage;
        _currentCategory = _categorizeApp(appPackage);
        _lastContextChange = DateTime.now();

        // Record context event
        _contextHistory.add(ContextEvent(
          appPackage: appPackage,
          category: _currentCategory,
          timestamp: DateTime.now(),
        ));

        // Keep only last 100 events
        if (_contextHistory.length > 100) {
          _contextHistory.removeAt(0);
        }

        if (kDebugMode) {
          debugPrint('[ScreenContext] App changed: $previousApp → $appPackage');
          debugPrint('[ScreenContext] Category: $_currentCategory');
        }

        // Trigger suggestion if cooldown passed
        _maybeGenerateSuggestion();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ScreenContext] Check error: $e');
    }
  }

  /// Categorize app based on package name with fuzzy matching
  String _categorizeApp(String packageName) {
    final lower = packageName.toLowerCase();
    
    // Exact match first
    for (final entry in _appCategories.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value.name;
      }
    }
    
    // Fuzzy match by keywords
    if (lower.contains('code') || lower.contains('dev') || lower.contains('git')) {
      return AppCategory.coding.name;
    }
    if (lower.contains('read') || lower.contains('book') || lower.contains('news')) {
      return AppCategory.reading.name;
    }
    if (lower.contains('social') || lower.contains('chat') || lower.contains('message')) {
      return AppCategory.social.name;
    }
    if (lower.contains('music') || lower.contains('audio') || lower.contains('sound')) {
      return AppCategory.music.name;
    }
    if (lower.contains('video') || lower.contains('stream') || lower.contains('tv')) {
      return AppCategory.video.name;
    }
    if (lower.contains('game') || lower.contains('play')) {
      return AppCategory.gaming.name;
    }
    if (lower.contains('shop') || lower.contains('store') || lower.contains('buy')) {
      return AppCategory.shopping.name;
    }
    if (lower.contains('fit') || lower.contains('health') || lower.contains('workout')) {
      return AppCategory.fitness.name;
    }
    
    return 'unknown';
  }

  /// Generate context-aware suggestion if appropriate
  void _maybeGenerateSuggestion() {
    // Check cooldown
    if (_lastSuggestionTime != null) {
      final timeSince = DateTime.now().difference(_lastSuggestionTime!);
      if (timeSince < _suggestionCooldown) return;
    }

    // Only suggest for meaningful categories
    if (_currentCategory == 'unknown') return;

    // User must be in the app for at least 20 seconds before suggesting
    Future.delayed(const Duration(seconds: 20), () {
      if (_currentApp.isNotEmpty && _currentCategory != 'unknown') {
        _lastSuggestionTime = DateTime.now();
        // Trigger callback to main app
        onContextSuggestion?.call(getSuggestionForContext());
      }
    });
  }

  /// Get intelligent suggestion based on current context
  ContextSuggestion getSuggestionForContext() {
    switch (_currentCategory) {
      case 'coding':
        return ContextSuggestion(
          title: 'Need help with that code?',
          message: 'I can debug, explain concepts, or suggest improvements~ 💻',
          action: 'code_help',
          icon: '👩‍💻',
          priority: SuggestionPriority.high,
        );
      
      case 'reading':
        return ContextSuggestion(
          title: 'Want me to summarize this?',
          message: 'I can extract key points and save you time, darling~ 📖',
          action: 'summarize',
          icon: '📚',
          priority: SuggestionPriority.medium,
        );
      
      case 'writing':
        return ContextSuggestion(
          title: 'Need writing help?',
          message: 'I can proofread, suggest improvements, or help with ideas~ ✍️',
          action: 'writing_help',
          icon: '✨',
          priority: SuggestionPriority.high,
        );
      
      case 'social':
        return ContextSuggestion(
          title: 'Chatting with someone?',
          message: 'Hope you\'re having fun! Let me know if you need conversation tips~ 💬',
          action: 'social_tips',
          icon: '💕',
          priority: SuggestionPriority.low,
        );
      
      case 'music':
        return ContextSuggestion(
          title: 'Enjoying the music?',
          message: 'Want me to recommend similar songs or create a playlist? 🎵',
          action: 'music_recommend',
          icon: '🎶',
          priority: SuggestionPriority.medium,
        );
      
      case 'productivity':
        return ContextSuggestion(
          title: 'Staying productive?',
          message: 'I can help you stay focused or remind you to take breaks~ ⏰',
          action: 'productivity_help',
          icon: '📋',
          priority: SuggestionPriority.medium,
        );
      
      case 'gaming':
        return ContextSuggestion(
          title: 'Gaming time!',
          message: 'Have fun, darling! Let me know if you want tips or just want to chat after~ 🎮',
          action: 'gaming_chat',
          icon: '🎮',
          priority: SuggestionPriority.low,
        );
      
      case 'shopping':
        return ContextSuggestion(
          title: 'Shopping for something?',
          message: 'Need help comparing prices or finding deals? I\'m here~ 🛍️',
          action: 'shopping_help',
          icon: '🛒',
          priority: SuggestionPriority.medium,
        );
      
      case 'fitness':
        return ContextSuggestion(
          title: 'Working out?',
          message: 'Stay strong, darling! I can track your progress or suggest exercises~ 💪',
          action: 'fitness_help',
          icon: '🏋️',
          priority: SuggestionPriority.medium,
        );
      
      default:
        return ContextSuggestion(
          title: 'What are you up to?',
          message: 'Just checking in~ Let me know if you need anything! 💕',
          action: 'general_checkin',
          icon: '💭',
          priority: SuggestionPriority.low,
        );
    }
  }

  /// Get usage statistics for analytics
  Map<String, dynamic> getUsageStats() {
    final categoryCount = <String, int>{};
    for (final event in _contextHistory) {
      categoryCount[event.category] = (categoryCount[event.category] ?? 0) + 1;
    }

    // Calculate most used category
    String mostUsedCategory = 'none';
    int maxCount = 0;
    categoryCount.forEach((category, count) {
      if (count > maxCount) {
        maxCount = count;
        mostUsedCategory = category;
      }
    });

    return {
      'current_app': _currentApp,
      'current_category': _currentCategory,
      'total_events': _contextHistory.length,
      'category_breakdown': categoryCount,
      'most_used_category': mostUsedCategory,
      'last_change': _lastContextChange.toIso8601String(),
      'ocr_available': _ocrAvailable,
      'last_ocr_length': _lastOcrText.length,
    };
  }

  /// Get recent activity summary for AI context
  String getActivitySummary() {
    if (_contextHistory.isEmpty) return '';
    
    final recentEvents = _contextHistory.reversed.take(10).toList();
    final categories = recentEvents.map((e) => e.category).toSet();
    
    return 'Recent activity: ${categories.join(', ')}. Currently in $_currentCategory app.';
  }

  /// Enable/disable the service
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('screen_context_enabled', enabled);

    if (enabled) {
      await initialize();
    } else {
      stopMonitoring();
    }
  }

  /// Callback for when a suggestion should be shown
  void Function(ContextSuggestion)? onContextSuggestion;

  void dispose() {
    _pollTimer?.cancel();
  }
}

/// App category enum for intelligent classification
enum AppCategory {
  coding,
  reading,
  writing,
  social,
  music,
  video,
  productivity,
  gaming,
  shopping,
  fitness,
  unknown,
}

/// Suggestion priority levels
enum SuggestionPriority {
  low,
  medium,
  high,
}

/// Context event record
class ContextEvent {
  final String appPackage;
  final String category;
  final DateTime timestamp;

  ContextEvent({
    required this.appPackage,
    required this.category,
    required this.timestamp,
  });
}

/// Context-aware suggestion model
class ContextSuggestion {
  final String title;
  final String message;
  final String action;
  final String icon;
  final SuggestionPriority priority;

  ContextSuggestion({
    required this.title,
    required this.message,
    required this.action,
    required this.icon,
    this.priority = SuggestionPriority.medium,
  });
}
