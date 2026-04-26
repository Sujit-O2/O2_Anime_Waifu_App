import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔥 FEATURE 1: Live Screen Context Awareness
/// 
/// Monitors foreground app activity and provides intelligent context-aware suggestions.
/// Integrates with RealWorldPresenceEngine for seamless AI assistance.
/// 
/// Architecture:
/// - Native Android bridge for UsageStatsManager
/// - Intelligent app categorization (coding, reading, social, etc.)
/// - Context-aware suggestion engine
/// - Privacy-first: all processing on-device
class ScreenContextService {
  ScreenContextService._();
  static final ScreenContextService instance = ScreenContextService._();

  static const _channel = MethodChannel('com.zerotwo.waifu/screen_context');
  
  Timer? _pollTimer;
  String _currentApp = '';
  String _currentCategory = 'unknown';
  DateTime _lastContextChange = DateTime.now();
  final List<ContextEvent> _contextHistory = [];
  
  // Suggestion cooldown to prevent spam
  DateTime? _lastSuggestionTime;
  static const _suggestionCooldown = Duration(minutes: 15);
  
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  // App category mappings for intelligent suggestions
  static const Map<String, AppCategory> _appCategories = {
    // Development
    'com.termux': AppCategory.coding,
    'com.aide.ui': AppCategory.coding,
    'com.github.android': AppCategory.coding,
    'com.google.android.apps.docs.editors.docs': AppCategory.writing,
    
    // Reading
    'com.google.android.apps.magazines': AppCategory.reading,
    'com.medium.reader': AppCategory.reading,
    'org.mozilla.firefox': AppCategory.reading,
    'com.android.chrome': AppCategory.reading,
    
    // Social
    'com.whatsapp': AppCategory.social,
    'com.instagram.android': AppCategory.social,
    'com.twitter.android': AppCategory.social,
    'com.discord': AppCategory.social,
    
    // Entertainment
    'com.spotify.music': AppCategory.music,
    'com.google.android.youtube': AppCategory.video,
    'com.netflix.mediaclient': AppCategory.video,
    
    // Productivity
    'com.todoist': AppCategory.productivity,
    'com.google.android.calendar': AppCategory.productivity,
    'com.microsoft.office.outlook': AppCategory.productivity,
    
    // Gaming
    'com.miHoYo.GenshinImpact': AppCategory.gaming,
    'com.supercell.clashofclans': AppCategory.gaming,
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
      startMonitoring();
    }
  }

  /// Request USAGE_STATS permission (required for foreground app detection)
  Future<bool> _requestUsageStatsPermission() async {
    try {
      final hasPermission = await _channel.invokeMethod<bool>('hasUsageStatsPermission') ?? false;
      if (!hasPermission) {
        await _channel.invokeMethod('requestUsageStatsPermission');
        // Wait for user to grant permission
        await Future.delayed(const Duration(seconds: 2));
        return await _channel.invokeMethod<bool>('hasUsageStatsPermission') ?? false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ScreenContext] Permission error: $e');
      return false;
    }
  }

  /// Start monitoring foreground app changes
  void startMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkForegroundApp());
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

        // Keep only last 50 events
        if (_contextHistory.length > 50) {
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

  /// Categorize app based on package name
  String _categorizeApp(String packageName) {
    for (final entry in _appCategories.entries) {
      if (packageName.contains(entry.key)) {
        return entry.value.name;
      }
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

    // User must be in the app for at least 30 seconds before suggesting
    Future.delayed(const Duration(seconds: 30), () {
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
          message: 'I can help debug, explain concepts, or suggest improvements~ 💻',
          action: 'code_help',
          icon: '👩‍💻',
        );
      
      case 'reading':
        return ContextSuggestion(
          title: 'Want me to summarize this?',
          message: 'I can give you the key points so you save time, darling~ 📖',
          action: 'summarize',
          icon: '📚',
        );
      
      case 'writing':
        return ContextSuggestion(
          title: 'Need writing help?',
          message: 'I can proofread, suggest improvements, or help with ideas~ ✍️',
          action: 'writing_help',
          icon: '✨',
        );
      
      case 'social':
        return ContextSuggestion(
          title: 'Chatting with someone?',
          message: 'Hope you\'re having fun! Let me know if you need conversation tips~ 💬',
          action: 'social_tips',
          icon: '💕',
        );
      
      case 'music':
        return ContextSuggestion(
          title: 'Enjoying the music?',
          message: 'Want me to recommend similar songs or create a playlist for your mood? 🎵',
          action: 'music_recommend',
          icon: '🎶',
        );
      
      case 'productivity':
        return ContextSuggestion(
          title: 'Staying productive?',
          message: 'I can help you stay focused or take a break when needed~ ⏰',
          action: 'productivity_help',
          icon: '📋',
        );
      
      case 'gaming':
        return ContextSuggestion(
          title: 'Gaming time!',
          message: 'Have fun, darling! Let me know if you want tips or just want to chat after~ 🎮',
          action: 'gaming_chat',
          icon: '🎮',
        );
      
      default:
        return ContextSuggestion(
          title: 'What are you up to?',
          message: 'Just checking in~ Let me know if you need anything! 💕',
          action: 'general_checkin',
          icon: '💭',
        );
    }
  }

  /// Get usage statistics for analytics
  Map<String, dynamic> getUsageStats() {
    final categoryCount = <String, int>{};
    for (final event in _contextHistory) {
      categoryCount[event.category] = (categoryCount[event.category] ?? 0) + 1;
    }

    return {
      'current_app': _currentApp,
      'current_category': _currentCategory,
      'total_events': _contextHistory.length,
      'category_breakdown': categoryCount,
      'last_change': _lastContextChange.toIso8601String(),
    };
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
  unknown,
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

  ContextSuggestion({
    required this.title,
    required this.message,
    required this.action,
    required this.icon,
  });
}
