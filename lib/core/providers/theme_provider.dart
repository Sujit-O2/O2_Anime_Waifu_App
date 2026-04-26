import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/config/app_themes.dart';

enum ThemeVisualMode { system, light, dark }

/// ─────────────────────────────────────────────────────────────────────────────
/// ThemeProvider — 10 Premium Themes
///
/// Manages theme mode, accent color overrides, and custom background URLs.
/// Persists choices to SharedPreferences.
/// ─────────────────────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  static const AppThemeMode defaultThemeMode = AppThemeMode.zeroTwo;
  static const String _themeIndexPrefKey = 'app_theme_index';
  static const String _themeAccentPrefKey = 'flutter.theme_accent_color';
  static const String _customBgUrlPrefKey = 'flutter.custom_bg_url';
  static const String _themeVisualModePrefKey = 'app_theme_visual_mode';

  /// The 10 active premium themes shown in the picker.
  static const Set<AppThemeMode> activeThemeModes = {
    AppThemeMode.zeroTwo,
    AppThemeMode.cyberPhantom,
    AppThemeMode.velvetNoir,
    AppThemeMode.toxicVenom,
    AppThemeMode.astralDream,
    AppThemeMode.infernoCore,
    AppThemeMode.arcticBlade,
    AppThemeMode.goldenEmperor,
    AppThemeMode.phantomViolet,
    AppThemeMode.oceanAbyss,
  };

  AppThemeMode _mode = defaultThemeMode;
  ThemeVisualMode _visualMode = ThemeVisualMode.dark;
  Color? _accentColor;
  String? _customBackgroundUrl;
  Future<SharedPreferences>? _prefsFuture;

  Future<SharedPreferences> _prefs() {
    return _prefsFuture ??= SharedPreferences.getInstance();
  }

  AppThemeMode get mode => _mode;
  ThemeVisualMode get visualMode => _visualMode;
  Color? get accentColor => _accentColor;
  String? get customBackgroundUrl => _customBackgroundUrl;
  ThemeData get theme => AppThemes.getTheme(_mode);
  ThemeMode get materialThemeMode {
    switch (_visualMode) {
      case ThemeVisualMode.light:
        return ThemeMode.light;
      case ThemeVisualMode.dark:
        return ThemeMode.dark;
      case ThemeVisualMode.system:
        return ThemeMode.system;
    }
  }

  /// Restore theme from SharedPreferences. Called once at app start.
  Future<void> restore() async {
    try {
      final prefs = await _prefs();
      final index = prefs.getInt(_themeIndexPrefKey) ?? 0;

      final savedAccent = prefs.getInt(_themeAccentPrefKey);
      if (savedAccent != null) {
        final accent = Color(savedAccent);
        AppThemes.customAccentColor = accent;
        _accentColor = accent;
      }

      final savedBgUrl = prefs.getString(_customBgUrlPrefKey);
      if (savedBgUrl != null && savedBgUrl.isNotEmpty) {
        _customBackgroundUrl = savedBgUrl;
      }

      final savedVisualMode = prefs.getString(_themeVisualModePrefKey);
      _visualMode = ThemeVisualMode.values.firstWhere(
        (mode) => mode.name == savedVisualMode,
        orElse: () => ThemeVisualMode.dark,
      );

      final savedTheme =
          AppThemeMode.values[index % AppThemeMode.values.length];

      // If saved theme is an active theme, use it; otherwise use default.
      _mode =
          activeThemeModes.contains(savedTheme) ? savedTheme : defaultThemeMode;

      if (!activeThemeModes.contains(savedTheme)) {
        await prefs.setInt(
            _themeIndexPrefKey, AppThemeMode.values.indexOf(defaultThemeMode));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to restore theme preferences: $e');
    }
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
    final prefs = await _prefs();
    await prefs.setInt(
        _themeIndexPrefKey, AppThemeMode.values.indexOf(newMode));
  }

  Future<void> setVisualMode(ThemeVisualMode newMode) async {
    if (_visualMode == newMode) return;
    _visualMode = newMode;
    notifyListeners();
    final prefs = await _prefs();
    await prefs.setString(_themeVisualModePrefKey, newMode.name);
  }

  Future<void> setAccentColor(Color? color) async {
    if (_accentColor == color) return;
    _accentColor = color;
    AppThemes.customAccentColor = color;
    notifyListeners();
    final prefs = await _prefs();
    if (color != null) {
      // ignore: deprecated_member_use
      await prefs.setInt(_themeAccentPrefKey, color.value);
    } else {
      await prefs.remove(_themeAccentPrefKey);
    }
  }

  Future<void> setCustomBackgroundUrl(String? url) async {
    final normalizedUrl =
        (url == null || url.trim().isEmpty) ? null : url.trim();
    if (_customBackgroundUrl == normalizedUrl) return;
    _customBackgroundUrl = normalizedUrl;
    notifyListeners();
    final prefs = await _prefs();
    if (normalizedUrl != null) {
      await prefs.setString(_customBgUrlPrefKey, normalizedUrl);
    } else {
      await prefs.remove(_customBgUrlPrefKey);
    }
  }
}
