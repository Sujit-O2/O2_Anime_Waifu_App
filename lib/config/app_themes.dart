import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cyber-Vibrant Glassmorphism theme engine.
/// Primary: High-Saturation Neon (#FF0057 Pink, #00D1FF Cyan).
/// Typography: Inter-weight Google Fonts (Outfit & Roboto).

enum AppThemeMode {
  cyberPink,
  neonCyan,
  midnightPurple,
  sakuraBloom,
  darkMatter,
  emeraldDream,
}

enum ParticleType { circles, squares, stars, hearts, none }

class AppThemeConfig {
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color chatBubbleUser;
  final Color chatBubbleAI;
  final Color textColor;
  final Color glowColor;
  final ParticleType particleType;

  const AppThemeConfig({
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.chatBubbleUser,
    required this.chatBubbleAI,
    required this.textColor,
    required this.glowColor,
    this.particleType = ParticleType.circles,
  });
}

class AppThemes {
  static const Map<AppThemeMode, AppThemeConfig> _configs = {
    AppThemeMode.cyberPink: AppThemeConfig(
      primaryColor: Color(0xFFFF0057),
      accentColor: Color(0xFF00D1FF),
      backgroundColor: Color(0xFF0A0A1A),
      surfaceColor: Color(0xFF1A1A2E),
      chatBubbleUser: Color(0xFF1A1A2E),
      chatBubbleAI: Color(0xFF0D0D1A),
      textColor: Color(0xFFEAEAEA),
      glowColor: Color(0xFFFF0057),
      particleType: ParticleType.circles,
    ),
    AppThemeMode.neonCyan: AppThemeConfig(
      primaryColor: Color(0xFF00D1FF),
      accentColor: Color(0xFFFF0057),
      backgroundColor: Color(0xFF0A1A1A),
      surfaceColor: Color(0xFF1A2E2E),
      chatBubbleUser: Color(0xFF1A2E2E),
      chatBubbleAI: Color(0xFF0D1A1A),
      textColor: Color(0xFFEAEAEA),
      glowColor: Color(0xFF00D1FF),
      particleType: ParticleType.stars,
    ),
    AppThemeMode.midnightPurple: AppThemeConfig(
      primaryColor: Color(0xFF9B59B6),
      accentColor: Color(0xFFE74C3C),
      backgroundColor: Color(0xFF0A0A14),
      surfaceColor: Color(0xFF2D1B69),
      chatBubbleUser: Color(0xFF2D1B69),
      chatBubbleAI: Color(0xFF1A0A2E),
      textColor: Color(0xFFEAEAEA),
      glowColor: Color(0xFF9B59B6),
      particleType: ParticleType.circles,
    ),
    AppThemeMode.sakuraBloom: AppThemeConfig(
      primaryColor: Color(0xFFFF69B4),
      accentColor: Color(0xFFFFB7C5),
      backgroundColor: Color(0xFF1A0A14),
      surfaceColor: Color(0xFF2E1A24),
      chatBubbleUser: Color(0xFF2E1A24),
      chatBubbleAI: Color(0xFF1A0D14),
      textColor: Color(0xFFEAEAEA),
      glowColor: Color(0xFFFF69B4),
      particleType: ParticleType.hearts,
    ),
    AppThemeMode.darkMatter: AppThemeConfig(
      primaryColor: Color(0xFF4ECDC4),
      accentColor: Color(0xFFFF6B6B),
      backgroundColor: Color(0xFF0D0D0D),
      surfaceColor: Color(0xFF1A1A1A),
      chatBubbleUser: Color(0xFF1A1A1A),
      chatBubbleAI: Color(0xFF0D0D0D),
      textColor: Color(0xFFEAEAEA),
      glowColor: Color(0xFF4ECDC4),
      particleType: ParticleType.squares,
    ),
    AppThemeMode.emeraldDream: AppThemeConfig(
      primaryColor: Color(0xFF00E676),
      accentColor: Color(0xFF69F0AE),
      backgroundColor: Color(0xFF0A1A0A),
      surfaceColor: Color(0xFF1A2E1A),
      chatBubbleUser: Color(0xFF1A2E1A),
      chatBubbleAI: Color(0xFF0D1A0D),
      textColor: Color(0xFFEAEAEA),
      glowColor: Color(0xFF00E676),
      particleType: ParticleType.stars,
    ),
  };

  static AppThemeConfig getConfig(AppThemeMode mode) =>
      _configs[mode] ?? _configs[AppThemeMode.cyberPink]!;

  static ThemeData buildTheme(AppThemeMode mode) {
    final config = getConfig(mode);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: config.primaryColor,
      scaffoldBackgroundColor: config.backgroundColor,
      colorScheme: ColorScheme.dark(
        primary: config.primaryColor,
        secondary: config.accentColor,
        surface: config.surfaceColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Color(0xFFEAEAEA)),
          displayMedium: TextStyle(color: Color(0xFFEAEAEA)),
          displaySmall: TextStyle(color: Color(0xFFEAEAEA)),
          headlineLarge: TextStyle(color: Color(0xFFEAEAEA)),
          headlineMedium: TextStyle(color: Color(0xFFEAEAEA)),
          headlineSmall: TextStyle(color: Color(0xFFEAEAEA)),
          titleLarge: TextStyle(color: Color(0xFFEAEAEA)),
          titleMedium: TextStyle(color: Color(0xFFEAEAEA)),
          titleSmall: TextStyle(color: Color(0xFFEAEAEA)),
          bodyLarge: TextStyle(color: Color(0xFFEAEAEA)),
          bodyMedium: TextStyle(color: Color(0xFFEAEAEA)),
          bodySmall: TextStyle(color: Color(0xCCEAEAEA)),
          labelLarge: TextStyle(color: Color(0xFFEAEAEA)),
          labelMedium: TextStyle(color: Color(0xFFEAEAEA)),
          labelSmall: TextStyle(color: Color(0xCCEAEAEA)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: config.surfaceColor.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: config.primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: config.backgroundColor.withValues(alpha: 0.95),
      ),
      cardTheme: CardThemeData(
        color: config.surfaceColor.withValues(alpha: 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: config.primaryColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.surfaceColor.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: config.primaryColor, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: config.textColor.withValues(alpha: 0.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      iconTheme: IconThemeData(color: config.primaryColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
