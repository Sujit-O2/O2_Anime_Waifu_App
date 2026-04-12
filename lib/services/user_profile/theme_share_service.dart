import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/user_profile/custom_theme_service.dart';

/// Theme Share Service - Share themes with other users
class ThemeShareService {
  static final ThemeShareService _instance = ThemeShareService._internal();
  factory ThemeShareService() => _instance;
  ThemeShareService._internal();

  static const String _sharedThemesKey = 'shared_themes';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Export theme as JSON string
  String exportTheme(CustomTheme theme) {
    return jsonEncode(theme.toJson());
  }

  /// Import theme from JSON string
  Future<bool> importTheme(String jsonString) async {
    try {
      final json = jsonDecode(jsonString);
      final theme = CustomTheme.fromJson(json);
      return await customThemeService.createCustomTheme(theme);
    } catch (e) {
      debugPrint('❌ Error importing theme: $e');
      return false;
    }
  }

  /// Generate unique share code for theme
  String generateShareCode(String themeId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final code = '${themeId.substring(0, 4).toUpperCase()}-${timestamp % 10000}';
    return code;
  }

  /// Share theme publicly with code
  Future<String?> shareTheme(String themeId) async {
    try {
      final theme = await customThemeService.getCustomTheme(themeId);
      if (theme == null) return null;

      final code = generateShareCode(themeId);
      final sharedTheme = theme.copyWith(isPublic: true);

      // Store shared theme
      final shared = _prefs.getString(_sharedThemesKey) ?? '{}';
      final sharedMap = jsonDecode(shared) as Map<String, dynamic>;
      sharedMap[code] = sharedTheme.toJson();
      await _prefs.setString(_sharedThemesKey, jsonEncode(sharedMap));

      debugPrint('✅ Theme shared with code: $code');
      return code;
    } catch (e) {
      debugPrint('❌ Error sharing theme: $e');
      return null;
    }
  }

  /// Retrieve shared theme by code
  Future<CustomTheme?> getSharedTheme(String code) async {
    try {
      final shared = _prefs.getString(_sharedThemesKey) ?? '{}';
      final sharedMap = jsonDecode(shared) as Map<String, dynamic>;
      if (sharedMap.containsKey(code)) {
        return CustomTheme.fromJson(sharedMap[code]);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error retrieving shared theme: $e');
      return null;
    }
  }

  /// Get all shared themes
  Future<List<CustomTheme>> getAllSharedThemes() async {
    try {
      final shared = _prefs.getString(_sharedThemesKey) ?? '{}';
      final sharedMap = jsonDecode(shared) as Map<String, dynamic>;
      return sharedMap.values
          .cast<Map<String, dynamic>>()
          .map((json) => CustomTheme.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading shared themes: $e');
      return [];
    }
  }

  /// Unshare theme
  Future<bool> unshareTheme(String code) async {
    try {
      final shared = _prefs.getString(_sharedThemesKey) ?? '{}';
      final sharedMap = jsonDecode(shared) as Map<String, dynamic>;
      sharedMap.remove(code);
      await _prefs.setString(_sharedThemesKey, jsonEncode(sharedMap));
      return true;
    } catch (e) {
      debugPrint('❌ Error unsharing theme: $e');
      return false;
    }
  }
}

/// Global instance
final themeShareService = ThemeShareService();


