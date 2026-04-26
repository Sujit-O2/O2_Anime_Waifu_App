import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌓 Auto Theme Switcher Service
/// 
/// Changes theme based on time of day.
/// "Switching to night mode for your eyes 🌙"
class AutoThemeSwitcherService {
  AutoThemeSwitcherService._();
  static final AutoThemeSwitcherService instance = AutoThemeSwitcherService._();

  bool _isEnabled = false;
  Timer? _checkTimer;
  
  String _dayTheme = 'zeroTwo';
  String _nightTheme = 'velvetNoir';
  int _dayStartHour = 6;
  int _nightStartHour = 20;
  
  String? _lastAppliedTheme;

  bool get isEnabled => _isEnabled;
  String get dayTheme => _dayTheme;
  String get nightTheme => _nightTheme;
  int get dayStartHour => _dayStartHour;
  int get nightStartHour => _nightStartHour;

  Function(String theme, String message)? onThemeChange;

  Future<void> initialize() async {
    await _loadSettings();
    
    if (_isEnabled) {
      startMonitoring();
    }
    
    if (kDebugMode) debugPrint('[AutoTheme] Initialized (enabled: $_isEnabled)');
  }

  /// Start monitoring time for theme changes
  void startMonitoring() {
    _checkTimer?.cancel();
    
    // Check immediately
    _checkAndApplyTheme();
    
    // Check every 5 minutes
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkAndApplyTheme();
    });
    
    if (kDebugMode) debugPrint('[AutoTheme] Monitoring started');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _checkTimer?.cancel();
    if (kDebugMode) debugPrint('[AutoTheme] Monitoring stopped');
  }

  /// Check current time and apply appropriate theme
  void _checkAndApplyTheme() {
    final now = DateTime.now();
    final hour = now.hour;
    
    final shouldUseDayTheme = hour >= _dayStartHour && hour < _nightStartHour;
    final targetTheme = shouldUseDayTheme ? _dayTheme : _nightTheme;
    
    // Only trigger if theme actually changed
    if (_lastAppliedTheme != targetTheme) {
      _lastAppliedTheme = targetTheme;
      
      final message = shouldUseDayTheme
          ? '☀️ Good morning! Switching to day theme for your eyes~'
          : '🌙 Switching to night mode for your eyes, darling~';
      
      onThemeChange?.call(targetTheme, message);
      
      if (kDebugMode) {
        debugPrint('[AutoTheme] Applied theme: $targetTheme (hour: $hour)');
      }
    }
  }

  /// Enable auto theme switching
  Future<void> enable() async {
    _isEnabled = true;
    await _saveSettings();
    startMonitoring();
    
    if (kDebugMode) debugPrint('[AutoTheme] Enabled');
  }

  /// Disable auto theme switching
  Future<void> disable() async {
    _isEnabled = false;
    await _saveSettings();
    stopMonitoring();
    
    if (kDebugMode) debugPrint('[AutoTheme] Disabled');
  }

  /// Toggle auto theme switching
  Future<void> toggle() async {
    if (_isEnabled) {
      await disable();
    } else {
      await enable();
    }
  }

  /// Set day theme
  Future<void> setDayTheme(String theme) async {
    _dayTheme = theme;
    await _saveSettings();
    
    if (_isEnabled) {
      _checkAndApplyTheme();
    }
  }

  /// Set night theme
  Future<void> setNightTheme(String theme) async {
    _nightTheme = theme;
    await _saveSettings();
    
    if (_isEnabled) {
      _checkAndApplyTheme();
    }
  }

  /// Set day start hour (0-23)
  Future<void> setDayStartHour(int hour) async {
    _dayStartHour = hour.clamp(0, 23);
    await _saveSettings();
    
    if (_isEnabled) {
      _checkAndApplyTheme();
    }
  }

  /// Set night start hour (0-23)
  Future<void> setNightStartHour(int hour) async {
    _nightStartHour = hour.clamp(0, 23);
    await _saveSettings();
    
    if (_isEnabled) {
      _checkAndApplyTheme();
    }
  }

  /// Get current recommended theme
  String getCurrentRecommendedTheme() {
    final hour = DateTime.now().hour;
    return (hour >= _dayStartHour && hour < _nightStartHour) 
        ? _dayTheme 
        : _nightTheme;
  }

  /// Check if it's currently day time
  bool isDayTime() {
    final hour = DateTime.now().hour;
    return hour >= _dayStartHour && hour < _nightStartHour;
  }

  /// Get time until next theme change
  Duration getTimeUntilNextChange() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    
    int targetHour;
    if (hour >= _dayStartHour && hour < _nightStartHour) {
      // Currently day, next change is night
      targetHour = _nightStartHour;
    } else {
      // Currently night, next change is day
      targetHour = _dayStartHour;
      if (hour >= _nightStartHour) {
        // After night start, day is tomorrow
        targetHour += 24;
      }
    }
    
    final minutesUntilChange = (targetHour - hour) * 60 - minute;
    return Duration(minutes: minutesUntilChange);
  }

  /// Get settings summary
  Map<String, dynamic> getSettings() {
    return {
      'enabled': _isEnabled,
      'day_theme': _dayTheme,
      'night_theme': _nightTheme,
      'day_start_hour': _dayStartHour,
      'night_start_hour': _nightStartHour,
      'current_is_day': isDayTime(),
      'recommended_theme': getCurrentRecommendedTheme(),
      'time_until_next_change': getTimeUntilNextChange().inMinutes,
    };
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_theme_enabled', _isEnabled);
      await prefs.setString('auto_theme_day', _dayTheme);
      await prefs.setString('auto_theme_night', _nightTheme);
      await prefs.setInt('auto_theme_day_hour', _dayStartHour);
      await prefs.setInt('auto_theme_night_hour', _nightStartHour);
    } catch (e) {
      if (kDebugMode) debugPrint('[AutoTheme] Save error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('auto_theme_enabled') ?? false;
      _dayTheme = prefs.getString('auto_theme_day') ?? 'zeroTwo';
      _nightTheme = prefs.getString('auto_theme_night') ?? 'velvetNoir';
      _dayStartHour = prefs.getInt('auto_theme_day_hour') ?? 6;
      _nightStartHour = prefs.getInt('auto_theme_night_hour') ?? 20;
    } catch (e) {
      if (kDebugMode) debugPrint('[AutoTheme] Load error: $e');
    }
  }

  void dispose() {
    _checkTimer?.cancel();
  }
}
