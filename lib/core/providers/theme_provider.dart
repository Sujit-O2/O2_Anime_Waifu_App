import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/config/app_themes.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ThemeProvider
///
/// Replaces the global ValueNotifier-based theme management with a proper
/// ChangeNotifier. Manages theme mode, accent color overrides, and custom
/// background URLs. Persists choices to SharedPreferences.
/// ─────────────────────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  static const AppThemeMode defaultThemeMode = AppThemeMode.neonSerpent;

  static const Set<AppThemeMode> activeThemeModes = {
    AppThemeMode.neonSerpent,
    AppThemeMode.chromaStorm,
    AppThemeMode.goldenRuler,
    AppThemeMode.frozenDivine,
    AppThemeMode.infernoGod,
    AppThemeMode.shadowBlade,
    AppThemeMode.pinkChaos,
    AppThemeMode.abyssWatcher,
    AppThemeMode.solarFlare,
    AppThemeMode.demonSlayer,
    AppThemeMode.midnightSilk,
    AppThemeMode.obsidianRose,
    AppThemeMode.onyxEmerald,
    AppThemeMode.velvetCrown,
    AppThemeMode.platinumDawn,
    AppThemeMode.hypergate,
    AppThemeMode.xenoCore,
    AppThemeMode.dataStream,
    AppThemeMode.gravityBend,
    AppThemeMode.quartzPulse,
    AppThemeMode.midnightForest,
    AppThemeMode.volcanicSea,
    AppThemeMode.stormDesert,
    AppThemeMode.sakuraNight,
    AppThemeMode.arcticSoul,
  };

  AppThemeMode _mode = defaultThemeMode;
  Color? _accentColor;
  String? _customBackgroundUrl;

  AppThemeMode get mode => _mode;
  Color? get accentColor => _accentColor;
  String? get customBackgroundUrl => _customBackgroundUrl;
  ThemeData get theme => AppThemes.getTheme(_mode);

  /// Restore theme from SharedPreferences. Called once at app start.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt('app_theme_index') ?? 0;

      final savedAccent = prefs.getInt('flutter.theme_accent_color');
      if (savedAccent != null) {
        final accent = Color(savedAccent);
        AppThemes.customAccentColor = accent;
        _accentColor = accent;
      }

      final savedBgUrl = prefs.getString('flutter.custom_bg_url');
      if (savedBgUrl != null && savedBgUrl.isNotEmpty) {
        _customBackgroundUrl = savedBgUrl;
      }

      final savedTheme =
          AppThemeMode.values[index % AppThemeMode.values.length];
      final migratedTheme =
          savedTheme == AppThemeMode.infernoGod ? defaultThemeMode : savedTheme;
      _mode = activeThemeModes.contains(migratedTheme)
          ? migratedTheme
          : defaultThemeMode;

      if (savedTheme == AppThemeMode.infernoGod) {
        await prefs.setInt(
          'app_theme_index',
          AppThemeMode.values.indexOf(defaultThemeMode),
        );
      }
    } catch (e) {
      debugPrint("Failed to restore theme preferences: $e");
    }
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme_index', AppThemeMode.values.indexOf(newMode));
  }

  Future<void> setAccentColor(Color? color) async {
    _accentColor = color;
    AppThemes.customAccentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (color != null) {
      // ignore: deprecated_member_use
      await prefs.setInt('flutter.theme_accent_color', color.value);
    } else {
      await prefs.remove('flutter.theme_accent_color');
    }
  }

  Future<void> setCustomBackgroundUrl(String? url) async {
    _customBackgroundUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (url != null && url.isNotEmpty) {
      await prefs.setString('flutter.custom_bg_url', url);
    } else {
      await prefs.remove('flutter.custom_bg_url');
    }
  }
}
