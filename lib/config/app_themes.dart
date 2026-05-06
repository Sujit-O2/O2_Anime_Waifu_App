import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  const AppDesignTokens({
    required this.panel,
    required this.panelElevated,
    required this.panelMuted,
    required this.outline,
    required this.outlineStrong,
    required this.textMuted,
    required this.textSoft,
    required this.onSurface,
    required this.tertiary,
    required this.heroGradient,
    required this.glassGradient,
    required this.shadowColor,
    required this.glowColor,
  });

  // Default fallback for when theme isn't loaded
  factory AppDesignTokens.fallback() {
    return const AppDesignTokens(
      panel: Color(0xFF1A0025),
      panelElevated: Color(0xFF2A0035),
      panelMuted: Color(0xFF0D0018),
      outline: Color(0x33FF0057),
      outlineStrong: Color(0x66FF0057),
      textMuted: Color(0x99FFFFFF),
      textSoft: Color(0xCCFFFFFF),
      onSurface: Color(0xFFFFFFFF),
      tertiary: Color(0xFFAA00FF),
      heroGradient: LinearGradient(colors: [Color(0xFFFF0057), Color(0xFFAA00FF)]),
      glassGradient: LinearGradient(colors: [Color(0x22FF0057), Color(0x11AA00FF)]),
      shadowColor: Color(0x66000000),
      glowColor: Color(0xFFFF0057),
    );
  }

  final Color panel;
  final Color panelElevated;
  final Color panelMuted;
  final Color outline;
  final Color outlineStrong;
  final Color textMuted;
  final Color textSoft;
  final Color onSurface;
  final Color tertiary;
  final LinearGradient heroGradient;
  final LinearGradient glassGradient;
  final Color shadowColor;
  final Color glowColor;

  @override
  AppDesignTokens copyWith({
    Color? panel,
    Color? panelElevated,
    Color? panelMuted,
    Color? outline,
    Color? outlineStrong,
    Color? textMuted,
    Color? textSoft,
    Color? onSurface,
    Color? tertiary,
    LinearGradient? heroGradient,
    LinearGradient? glassGradient,
    Color? shadowColor,
    Color? glowColor,
  }) {
    return AppDesignTokens(
      panel: panel ?? this.panel,
      panelElevated: panelElevated ?? this.panelElevated,
      panelMuted: panelMuted ?? this.panelMuted,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textMuted: textMuted ?? this.textMuted,
      textSoft: textSoft ?? this.textSoft,
      onSurface: onSurface ?? this.onSurface,
      tertiary: tertiary ?? this.tertiary,
      heroGradient: heroGradient ?? this.heroGradient,
      glassGradient: glassGradient ?? this.glassGradient,
      shadowColor: shadowColor ?? this.shadowColor,
      glowColor: glowColor ?? this.glowColor,
    );
  }

  @override
  AppDesignTokens lerp(
      covariant ThemeExtension<AppDesignTokens>? other, double t) {
    if (other is! AppDesignTokens) {
      return this;
    }
    return AppDesignTokens(
      panel: Color.lerp(panel, other.panel, t)!,
      panelElevated: Color.lerp(panelElevated, other.panelElevated, t)!,
      panelMuted: Color.lerp(panelMuted, other.panelMuted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSoft: Color.lerp(textSoft, other.textSoft, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      heroGradient: LinearGradient(
        begin: heroGradient.begin,
        end: heroGradient.end,
        colors: List<Color>.generate(
          heroGradient.colors.length,
          (index) => Color.lerp(
            heroGradient.colors[index],
            other.heroGradient.colors[index < other.heroGradient.colors.length
                ? index
                : other.heroGradient.colors.length - 1],
            t,
          )!,
        ),
      ),
      glassGradient: LinearGradient(
        begin: glassGradient.begin,
        end: glassGradient.end,
        colors: List<Color>.generate(
          glassGradient.colors.length,
          (index) => Color.lerp(
            glassGradient.colors[index],
            other.glassGradient.colors[index < other.glassGradient.colors.length
                ? index
                : other.glassGradient.colors.length - 1],
            t,
          )!,
        ),
      ),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppDesignTokens get appTokens {
    try {
      final theme = Theme.of(this);
      final tokens = theme.extension<AppDesignTokens>();
      if (tokens != null) return tokens;
    } catch (e) {
      debugPrint('appTokens error: $e');
    }
    return AppDesignTokens.fallback();
  }
}

class _ThemeSeed {
  const _ThemeSeed({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.accent,
  });

  final Color primary;
  final Color secondary;
  final Color background;
  final Color accent;
}

// ============================================================
//   THEME STYLE ENUMS — Drive per-theme visual identity
// ============================================================

enum BubbleStyle { glassmorphic, terminal, outlined, solid, luxury }

enum InputStyle { pill, squareNeon, underline, terminal, luxury }

enum AnimStyle { elastic, slideSide, glitch, fadeZoom, press }

enum LayoutMode { classic, terminal, centered, wideCard }

enum AppBarStyle { transparent, neonBorder, solid, minimal, banner }

class ThemeStyle {
  final TextStyle Function(double size, Color color) font;
  final BubbleStyle bubbleStyle;
  final InputStyle inputStyle;
  final AnimStyle animStyle;
  final LayoutMode layoutMode;
  final AppBarStyle appBarStyle;
  final double cornerRadius;
  final double sharpCorner;
  final bool leftAccentBar;
  final Color Function(Color primary) borderColor;
  final String hintText;
  final String labelUser;
  final String labelAI;

  const ThemeStyle({
    required this.font,
    required this.bubbleStyle,
    required this.inputStyle,
    required this.animStyle,
    required this.layoutMode,
    required this.appBarStyle,
    required this.cornerRadius,
    required this.sharpCorner,
    required this.borderColor,
    required this.hintText,
    this.leftAccentBar = false,
    this.labelUser = 'YOU',
    this.labelAI = 'ZERO TWO',
  });
}

// ── 15 Premium Themes (10 Original + 5 New) ─────────────────────────────────
enum AppThemeMode {
  zeroTwo, // 1. Crimson blood — the OG
  cyberPhantom, // 2. Electric cyan + violet — cyberpunk
  velvetNoir, // 3. Rose gold + champagne — luxury
  toxicVenom, // 4. Acid green + lime — matrix hacker
  astralDream, // 5. Lavender + aurora pink — ethereal
  infernoCore, // 6. Molten orange + lava red — volcanic
  arcticBlade, // 7. Ice blue + frost white — minimal arctic
  goldenEmperor, // 8. 24K gold + bronze — royal opulent
  phantomViolet, // 9. Deep purple + magenta — mysterious
  oceanAbyss, // 10. Deep teal + bioluminescent — deep sea

  // ─────── NEW THEMES (11-15) ──────────────────────────────────────────────
  neonPulse, // 11. Electric neon with pulsing animations
  moonlitMagic, // 12. Ethereal moonlight with smooth flows
  solsticeBlaze, // 13. Fiery summer solstice with dynamics
  auroraBorealis, // 14. Northern lights with gradient flows
  midnightEclipse, // 15. Dark luxury with sophisticated layers

  // Legacy aliases — kept so old SharedPreferences indices don't crash.
  bloodMoon,
  voidMatrix,
  angelFall,
  titanSoul,
  cosmicRift,
  neonSerpent,
  chromaStorm,
  goldenRuler,
  frozenDivine,
  infernoGod,
  shadowBlade,
  pinkChaos,
  abyssWatcher,
  solarFlare,
  demonSlayer,
  midnightSilk,
  obsidianRose,
  onyxEmerald,
  velvetCrown,
  platinumDawn,
  hypergate,
  xenoCore,
  dataStream,
  gravityBend,
  quartzPulse,
  midnightForest,
  volcanicSea,
  stormDesert,
  sakuraNight,
  arcticSoul,
  amethystDream,
  titaniumFrost,
  sunsetRider,
  midnightRaven,
  electricLime,
}

enum ParticleType {
  circles,
  squares,
  lines,
  sakura,
  embers,
  bubbles,
  leaves,
  snow,
  stars,
  rain
}

class AppThemes {
  static Color? _customAccentColor;
  static Color? get customAccentColor => _customAccentColor;
  static set customAccentColor(Color? c) {
    if (_customAccentColor == c) return;
    _customAccentColor = c;
    _themeCache.clear();
    _lightThemeCache.clear();
    _styleCache.clear();
  }

  static final Map<AppThemeMode, ThemeData> _themeCache = {};
  static final Map<AppThemeMode, ThemeData> _lightThemeCache = {};
  static final Map<AppThemeMode, ThemeStyle> _styleCache = {};

  // ── Resolve legacy aliases to new modes ──────────────────────────────────
  static AppThemeMode _resolve(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.zeroTwo:
      case AppThemeMode.bloodMoon:
      case AppThemeMode.pinkChaos:
      case AppThemeMode.obsidianRose:
        return AppThemeMode.zeroTwo;

      case AppThemeMode.cyberPhantom:
      case AppThemeMode.voidMatrix:
      case AppThemeMode.dataStream:
      case AppThemeMode.hypergate:
        return AppThemeMode.cyberPhantom;

      case AppThemeMode.velvetNoir:
      case AppThemeMode.midnightSilk:
      case AppThemeMode.platinumDawn:
      case AppThemeMode.velvetCrown:
        return AppThemeMode.velvetNoir;

      case AppThemeMode.toxicVenom:
      case AppThemeMode.neonSerpent:
      case AppThemeMode.electricLime:
      case AppThemeMode.demonSlayer:
        return AppThemeMode.toxicVenom;

      case AppThemeMode.astralDream:
      case AppThemeMode.angelFall:
      case AppThemeMode.cosmicRift:
      case AppThemeMode.amethystDream:
        return AppThemeMode.astralDream;

      case AppThemeMode.infernoCore:
      case AppThemeMode.infernoGod:
      case AppThemeMode.solarFlare:
      case AppThemeMode.sunsetRider:
        return AppThemeMode.infernoCore;

      case AppThemeMode.arcticBlade:
      case AppThemeMode.frozenDivine:
      case AppThemeMode.arcticSoul:
      case AppThemeMode.titaniumFrost:
        return AppThemeMode.arcticBlade;

      case AppThemeMode.goldenEmperor:
      case AppThemeMode.goldenRuler:
      case AppThemeMode.titanSoul:
      case AppThemeMode.stormDesert:
        return AppThemeMode.goldenEmperor;

      case AppThemeMode.phantomViolet:
      case AppThemeMode.chromaStorm:
      case AppThemeMode.quartzPulse:
      case AppThemeMode.gravityBend:
      case AppThemeMode.midnightRaven:
        return AppThemeMode.phantomViolet;

      case AppThemeMode.oceanAbyss:
      case AppThemeMode.abyssWatcher:
      case AppThemeMode.xenoCore:
      case AppThemeMode.onyxEmerald:
      case AppThemeMode.midnightForest:
      case AppThemeMode.volcanicSea:
      case AppThemeMode.sakuraNight:
      case AppThemeMode.shadowBlade:
        return AppThemeMode.oceanAbyss;

      // ─ New Themes (pass through) ──
      case AppThemeMode.neonPulse:
        return AppThemeMode.neonPulse;
      case AppThemeMode.moonlitMagic:
        return AppThemeMode.moonlitMagic;
      case AppThemeMode.solsticeBlaze:
        return AppThemeMode.solsticeBlaze;
      case AppThemeMode.auroraBorealis:
        return AppThemeMode.auroraBorealis;
      case AppThemeMode.midnightEclipse:
        return AppThemeMode.midnightEclipse;
    }
  }

  static ThemeData getRawTheme(AppThemeMode mode) {
    final Color? old = _customAccentColor;
    _customAccentColor = null;
    _themeCache.clear();
    _lightThemeCache.clear();
    final ThemeData t = getTheme(mode);
    _customAccentColor = old;
    _themeCache.clear();
    _lightThemeCache.clear();
    return t;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  THEME DATA (Colors)
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData getTheme(AppThemeMode mode) {
    final resolved = _resolve(mode);
    return _themeCache[resolved] ??= _buildTheme(resolved, Brightness.dark);
  }

  static ThemeData getLightTheme(AppThemeMode mode) {
    final resolved = _resolve(mode);
    return _lightThemeCache[resolved] ??=
        _buildTheme(resolved, Brightness.light);
  }

  static ThemeData getDarkTheme(AppThemeMode mode) {
    final resolved = _resolve(mode);
    return _themeCache[resolved] ??= _buildTheme(resolved, Brightness.dark);
  }

  static ThemeData _buildTheme(AppThemeMode mode, Brightness brightness) {
    final seed = _seedFor(mode);
    return _build(
      primary: seed.primary,
      secondary: seed.secondary,
      bg: seed.background,
      accent: seed.accent,
      brightness: brightness,
    );
  }

  static _ThemeSeed _seedFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.zeroTwo:
        return const _ThemeSeed(
            primary: Color(0xFFFF1744),
            secondary: Color(0xFF880E4F),
            background: Color(0xFF0A0003),
            accent: Color(0xFFFF4081));
      case AppThemeMode.cyberPhantom:
        return const _ThemeSeed(
            primary: Color(0xFF00E5FF),
            secondary: Color(0xFF7C4DFF),
            background: Color(0xFF020810),
            accent: Color(0xFF18FFFF));
      case AppThemeMode.velvetNoir:
        return const _ThemeSeed(
            primary: Color(0xFFB76E79),
            secondary: Color(0xFF3E2723),
            background: Color(0xFF0C0808),
            accent: Color(0xFFF7E7CE));
      case AppThemeMode.toxicVenom:
        return const _ThemeSeed(
            primary: Color(0xFF39FF14),
            secondary: Color(0xFF00C853),
            background: Color(0xFF010D02),
            accent: Color(0xFFADFF2F));
      case AppThemeMode.astralDream:
        return const _ThemeSeed(
            primary: Color(0xFFB388FF),
            secondary: Color(0xFFCE93D8),
            background: Color(0xFF080010),
            accent: Color(0xFFFF80AB));
      case AppThemeMode.infernoCore:
        return const _ThemeSeed(
            primary: Color(0xFFFF6D00),
            secondary: Color(0xFFD50000),
            background: Color(0xFF0C0200),
            accent: Color(0xFFFFAB00));
      case AppThemeMode.arcticBlade:
        return const _ThemeSeed(
            primary: Color(0xFF80D8FF),
            secondary: Color(0xFF4FC3F7),
            background: Color(0xFF020A10),
            accent: Color(0xFFE0F7FA));
      case AppThemeMode.goldenEmperor:
        return const _ThemeSeed(
            primary: Color(0xFFFFD700),
            secondary: Color(0xFFCD7F32),
            background: Color(0xFF0A0600),
            accent: Color(0xFFFFF8E1));
      case AppThemeMode.phantomViolet:
        return const _ThemeSeed(
            primary: Color(0xFFD500F9),
            secondary: Color(0xFF6200EA),
            background: Color(0xFF0A0010),
            accent: Color(0xFFEA80FC));
      case AppThemeMode.oceanAbyss:
        return const _ThemeSeed(
            primary: Color(0xFF1DE9B6),
            secondary: Color(0xFF006064),
            background: Color(0xFF00080A),
            accent: Color(0xFF84FFFF));

      // ─ NEW THEMES (11-15) ─────────────────────────────────────────────
      case AppThemeMode.neonPulse:
        return const _ThemeSeed(
            primary: Color(0xFF00FF88),
            secondary: Color(0xFFFF00FF),
            background: Color(0xFF0A0E27),
            accent: Color(0xFF00FFFF));
      case AppThemeMode.moonlitMagic:
        return const _ThemeSeed(
            primary: Color(0xFFE0E3FF),
            secondary: Color(0xFF9D8FD1),
            background: Color(0xFF0F0B1E),
            accent: Color(0xFFC8B6FF));
      case AppThemeMode.solsticeBlaze:
        return const _ThemeSeed(
            primary: Color(0xFFFF4500),
            secondary: Color(0xFFFF1744),
            background: Color(0xFF1A0A00),
            accent: Color(0xFFFFB74D));
      case AppThemeMode.auroraBorealis:
        return const _ThemeSeed(
            primary: Color(0xFF00D9A3),
            secondary: Color(0xFF00E5B3),
            background: Color(0xFF0A1F1F),
            accent: Color(0xFF7FFF00));
      case AppThemeMode.midnightEclipse:
        return const _ThemeSeed(
            primary: Color(0xFFC9A961),
            secondary: Color(0xFF2D2D44),
            background: Color(0xFF0D0D0D),
            accent: Color(0xFFE5D4B1));

      default:
        return const _ThemeSeed(
            primary: Color(0xFFFF1744),
            secondary: Color(0xFF880E4F),
            background: Color(0xFF0A0003),
            accent: Color(0xFFFF4081));
    }
  }

  static ThemeData _build(
      {required Color primary,
      required Color secondary,
      required Color bg,
      required Color accent,
      required Brightness brightness}) {
    final effectivePrimary = _customAccentColor ?? primary;
    final effectiveAccent = _customAccentColor ?? accent;
    final isDark = brightness == Brightness.dark;
    final baseBackground = isDark
        ? bg
        : Color.alphaBlend(
            effectivePrimary.withValues(alpha: 0.08),
            Colors.white,
          );
    final surface = isDark
        ? Color.alphaBlend(
            effectivePrimary.withValues(alpha: 0.08),
            bg.withValues(alpha: 0.96),
          )
        : Color.alphaBlend(
            effectivePrimary.withValues(alpha: 0.05),
            Colors.white,
          );
    final panel = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.02),
            surface,
          )
        : Color.alphaBlend(
            effectivePrimary.withValues(alpha: 0.06),
            Colors.white,
          );
    final panelElevated = isDark
        ? Color.alphaBlend(
            effectiveAccent.withValues(alpha: 0.10),
            surface,
          )
        : Color.alphaBlend(
            effectiveAccent.withValues(alpha: 0.12),
            const Color(0xFFFFFFFF),
          );
    final panelMuted = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.03),
            bg,
          )
        : const Color(0xFFF5F7FB);
    final outline =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0x140F172A);
    final outlineStrong = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : effectivePrimary.withValues(alpha: 0.18);
    final onSurface = isDark ? Colors.white : const Color(0xFF101828);
    final onSurfaceMuted =
        isDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF475467);
    final onSurfaceSoft =
        isDark ? Colors.white.withValues(alpha: 0.54) : const Color(0xFF667085);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.34)
        : const Color(0xFF0F172A).withValues(alpha: 0.10);
    final glowColor = effectivePrimary.withValues(alpha: isDark ? 0.16 : 0.10);
    final textTheme = GoogleFonts.outfitTextTheme(
      (isDark ? ThemeData.dark() : ThemeData.light()).textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.outfit(
        color: onSurface,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.outfit(
        color: onSurfaceMuted,
        height: 1.45,
      ),
      labelLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: onSurface,
      ),
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: effectivePrimary,
      brightness: brightness,
    ).copyWith(
      primary: effectivePrimary,
      secondary: secondary,
      tertiary: effectiveAccent,
      surface: surface,
      surfaceContainerHighest: panelElevated,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: isDark ? Colors.black : Colors.white,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceMuted,
      outline: outlineStrong,
      shadow: shadowColor,
      scrim: Colors.black.withValues(alpha: isDark ? 0.55 : 0.38),
    );
    final tokens = AppDesignTokens(
      panel: panel,
      panelElevated: panelElevated,
      panelMuted: panelMuted,
      outline: outline,
      outlineStrong: outlineStrong,
      textMuted: onSurfaceMuted,
      textSoft: onSurfaceSoft,
      onSurface: onSurface,
      tertiary: effectiveAccent,
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.alphaBlend(
            effectivePrimary.withValues(alpha: isDark ? 0.34 : 0.18),
            baseBackground,
          ),
          Color.alphaBlend(
            secondary.withValues(alpha: isDark ? 0.24 : 0.12),
            baseBackground,
          ),
          Color.alphaBlend(
            effectiveAccent.withValues(alpha: isDark ? 0.28 : 0.14),
            baseBackground,
          ),
        ],
      ),
      glassGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          (isDark ? Colors.white : Colors.white)
              .withValues(alpha: isDark ? 0.14 : 0.84),
          (isDark ? Colors.white : Colors.white)
              .withValues(alpha: isDark ? 0.06 : 0.58),
          (isDark ? Colors.white : Colors.white)
              .withValues(alpha: isDark ? 0.03 : 0.42),
        ],
      ),
      shadowColor: shadowColor,
      glowColor: glowColor,
    );

    return ThemeData(
      brightness: brightness,
      primaryColor: effectivePrimary,
      scaffoldBackgroundColor: baseBackground,
      canvasColor: surface,
      splashColor: effectivePrimary.withValues(alpha: 0.08),
      highlightColor: onSurface.withValues(alpha: 0.03),
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      useMaterial3: true,
      // Modern page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
      ),
      cardColor: surface,
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outline),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerColor: outline,
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xE6200010),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.pinkAccent.withValues(alpha: 0.35),
          ),
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: Colors.pinkAccent,
        elevation: 8,
      ),
      // Modern dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: Color.alphaBlend(
          effectivePrimary.withValues(alpha: isDark ? 0.09 : 0.04),
          surface.withValues(alpha: 0.98),
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: outlineStrong),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceMuted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.alphaBlend(
          effectivePrimary.withValues(alpha: isDark ? 0.08 : 0.03),
          panelElevated,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceMuted,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: effectivePrimary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceSoft,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: onSurfaceSoft,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: onSurfaceSoft,
        suffixIconColor: onSurfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: effectivePrimary.withValues(alpha: 0.7),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.7),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.6,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: effectivePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelMuted,
        selectedColor: effectivePrimary.withValues(alpha: 0.22),
        disabledColor: onSurface.withValues(alpha: 0.04),
        side: BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: onSurfaceMuted,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: effectivePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: outlineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: effectivePrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle:
              textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return effectivePrimary;
          return onSurface.withValues(alpha: 0.58);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return effectivePrimary.withValues(alpha: 0.35);
          }
          return onSurface.withValues(alpha: 0.1);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: effectivePrimary,
        inactiveTrackColor: onSurface.withValues(alpha: 0.1),
        thumbColor: effectivePrimary,
        overlayColor: effectivePrimary.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: effectivePrimary,
        linearTrackColor: onSurface.withValues(alpha: 0.08),
        circularTrackColor: onSurface.withValues(alpha: 0.08),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Color.alphaBlend(
          effectivePrimary.withValues(alpha: 0.03),
          baseBackground.withValues(alpha: 0.98),
        ),
        modalBackgroundColor: Color.alphaBlend(
          effectivePrimary.withValues(alpha: 0.03),
          baseBackground.withValues(alpha: 0.98),
        ),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        dragHandleColor: onSurface.withValues(alpha: 0.2),
        showDragHandle: true,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: onSurface,
        unselectedLabelColor: onSurfaceSoft,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              effectivePrimary.withValues(alpha: 0.22),
              effectiveAccent.withValues(alpha: 0.14),
            ],
          ),
          border: Border.all(color: outlineStrong),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: effectivePrimary,
        selectionColor: effectivePrimary.withValues(alpha: 0.22),
        selectionHandleColor: effectivePrimary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: panelElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outline),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: onSurfaceMuted),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Color.alphaBlend(
          effectivePrimary.withValues(alpha: 0.05),
          baseBackground.withValues(alpha: 0.97),
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outline),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurface,
          backgroundColor: panelMuted.withValues(alpha: 0.55),
          hoverColor: effectivePrimary.withValues(alpha: 0.08),
          highlightColor: effectivePrimary.withValues(alpha: 0.10),
          padding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: outline),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconColor: onSurfaceSoft,
        titleTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: onSurfaceSoft,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: effectivePrimary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  GRADIENTS (5-color deep background gradients)
  // ═══════════════════════════════════════════════════════════════════════════

  static List<Color> getGradient(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:
        // Obsidian → blood crimson → dark rose → purple shadow → void
        return const [
          Color(0xFF0A0010),
          Color(0xFF3D0014),
          Color(0xFF6B0020),
          Color(0xFF1A0030),
          Color(0xFF000006)
        ];
      case AppThemeMode.cyberPhantom:
        // Deep space → electric blue → violet pulse → cyan haze → void
        return const [
          Color(0xFF000810),
          Color(0xFF001A3D),
          Color(0xFF1A004A),
          Color(0xFF003040),
          Color(0xFF000408)
        ];
      case AppThemeMode.velvetNoir:
        // Ink velvet → rose shadow → champagne glow → mahogany → noir
        return const [
          Color(0xFF080404),
          Color(0xFF2A1018),
          Color(0xFF3D2420),
          Color(0xFF1A0C08),
          Color(0xFF040202)
        ];
      case AppThemeMode.toxicVenom:
        // Void → toxic jade → serpent green → acid glow → shadow
        return const [
          Color(0xFF000A02),
          Color(0xFF003810),
          Color(0xFF005020),
          Color(0xFF0A4000),
          Color(0xFF000800)
        ];
      case AppThemeMode.astralDream:
        // Cosmic void → lavender mist → aurora pink → violet haze → deep
        return const [
          Color(0xFF060010),
          Color(0xFF1A0040),
          Color(0xFF3A1060),
          Color(0xFF200030),
          Color(0xFF040008)
        ];
      case AppThemeMode.infernoCore:
        // Obsidian → volcanic red → molten orange → lava glow → ash
        return const [
          Color(0xFF060000),
          Color(0xFF3D0000),
          Color(0xFF5E1400),
          Color(0xFF3D0A00),
          Color(0xFF0A0000)
        ];
      case AppThemeMode.arcticBlade:
        // Polar dark → deep arctic → ice blue → aurora teal → frost
        return const [
          Color(0xFF000510),
          Color(0xFF001830),
          Color(0xFF003050),
          Color(0xFF001A38),
          Color(0xFF000308)
        ];
      case AppThemeMode.goldenEmperor:
        // Ancient ink → 24k shimmer → burnished amber → cognac → shadow
        return const [
          Color(0xFF080400),
          Color(0xFF3D2600),
          Color(0xFF604000),
          Color(0xFF3D1800),
          Color(0xFF0A0500)
        ];
      case AppThemeMode.phantomViolet:
        // Void → violet surge → magenta crystal → deep purple → black
        return const [
          Color(0xFF040006),
          Color(0xFF180028),
          Color(0xFF380058),
          Color(0xFF200038),
          Color(0xFF040006)
        ];
      case AppThemeMode.oceanAbyss:
        // Abyss → deep teal → biolume green → midnight navy → void
        return const [
          Color(0xFF000604),
          Color(0xFF002818),
          Color(0xFF004028),
          Color(0xFF001828),
          Color(0xFF000402)
        ];

      // ─ NEW THEME GRADIENTS ────────────────────────────────────────────
      case AppThemeMode.neonPulse:
        // Neon electric gradient with high energy
        return const [
          Color(0xFF0A0E27),
          Color(0xFF0F1A3A),
          Color(0xFF1A0F2E),
          Color(0xFF0F1A2E),
          Color(0xFF050709)
        ];
      case AppThemeMode.moonlitMagic:
        // Ethereal moonlit purple gradient
        return const [
          Color(0xFF0F0B1E),
          Color(0xFF1A0F3A),
          Color(0xFF2D1B4E),
          Color(0xFF14082F),
          Color(0xFF060409)
        ];
      case AppThemeMode.solsticeBlaze:
        // Fiery orange-red gradient
        return const [
          Color(0xFF1A0A00),
          Color(0xFF3D1000),
          Color(0xFF5E1400),
          Color(0xFF3D0A00),
          Color(0xFF0A0000)
        ];
      case AppThemeMode.auroraBorealis:
        // Northern lights teal-green gradient
        return const [
          Color(0xFF0A1F1F),
          Color(0xFF001A2E),
          Color(0xFF0F2E3A),
          Color(0xFF0A1F28),
          Color(0xFF040808)
        ];
      case AppThemeMode.midnightEclipse:
        // Sophisticated dark gold gradient
        return const [
          Color(0xFF0D0D0D),
          Color(0xFF1A1A2E),
          Color(0xFF2D2D44),
          Color(0xFF161625),
          Color(0xFF000000)
        ];

      default:
        return const [
          Color(0xFF0A0010),
          Color(0xFF3D0014),
          Color(0xFF6B0020),
          Color(0xFF1A0030),
          Color(0xFF000006)
        ];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PARTICLES
  // ═══════════════════════════════════════════════════════════════════════════

  static ParticleType getParticleType(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:
        return ParticleType.sakura;
      case AppThemeMode.cyberPhantom:
        return ParticleType.rain;
      case AppThemeMode.velvetNoir:
        return ParticleType.circles;
      case AppThemeMode.toxicVenom:
        return ParticleType.lines;
      case AppThemeMode.astralDream:
        return ParticleType.stars;
      case AppThemeMode.infernoCore:
        return ParticleType.embers;
      case AppThemeMode.arcticBlade:
        return ParticleType.snow;
      case AppThemeMode.goldenEmperor:
        return ParticleType.squares;
      case AppThemeMode.phantomViolet:
        return ParticleType.bubbles;
      case AppThemeMode.oceanAbyss:
        return ParticleType.bubbles;

      // ─ NEW PARTICLE TYPES ─────────────────────────────────────────────
      case AppThemeMode.neonPulse:
        return ParticleType.circles; // Pulsing circles
      case AppThemeMode.moonlitMagic:
        return ParticleType.bubbles; // Floating ethereal bubbles
      case AppThemeMode.solsticeBlaze:
        return ParticleType.embers; // Animated fire particles
      case AppThemeMode.auroraBorealis:
        return ParticleType.bubbles; // Aurora flowing bubbles
      case AppThemeMode.midnightEclipse:
        return ParticleType.circles; // Elegant circles

      default:
        return ParticleType.sakura;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  THEME NAMES
  // ═══════════════════════════════════════════════════════════════════════════

  static String getThemeName(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:
        return 'Zero Two';
      case AppThemeMode.cyberPhantom:
        return 'Cyber Phantom';
      case AppThemeMode.velvetNoir:
        return 'Velvet Noir';
      case AppThemeMode.toxicVenom:
        return 'Toxic Venom';
      case AppThemeMode.astralDream:
        return 'Astral Dream';
      case AppThemeMode.infernoCore:
        return 'Inferno Core';
      case AppThemeMode.arcticBlade:
        return 'Arctic Blade';
      case AppThemeMode.goldenEmperor:
        return 'Golden Emperor';
      case AppThemeMode.phantomViolet:
        return 'Phantom Violet';
      case AppThemeMode.oceanAbyss:
        return 'Ocean Abyss';

      // ─ NEW THEME NAMES ────────────────────────────────────────────────
      case AppThemeMode.neonPulse:
        return 'Neon Pulse';
      case AppThemeMode.moonlitMagic:
        return 'Moonlit Magic';
      case AppThemeMode.solsticeBlaze:
        return 'Solstice Blaze';
      case AppThemeMode.auroraBorealis:
        return 'Aurora Borealis';
      case AppThemeMode.midnightEclipse:
        return 'Midnight Eclipse';

      default:
        return 'Zero Two';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  VISUAL FX INTENSITIES
  // ═══════════════════════════════════════════════════════════════════════════

  static double getBlurIntensity(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.cyberPhantom:
        return 8.0; // crisp neon
      case AppThemeMode.astralDream:
        return 30.0; // dreamy blur
      case AppThemeMode.velvetNoir:
        return 28.0; // soft luxury
      case AppThemeMode.arcticBlade:
        return 25.0; // frosted glass

      // ─ NEW THEME BLUR ─────────────────────────────────────────────────
      case AppThemeMode.neonPulse:
        return 15.0; // Crisp neon effect
      case AppThemeMode.moonlitMagic:
        return 30.0; // Ethereal soft blur
      case AppThemeMode.solsticeBlaze:
        return 18.0; // Dynamic fire effect
      case AppThemeMode.auroraBorealis:
        return 25.0; // Shimmering aurora
      case AppThemeMode.midnightEclipse:
        return 28.0; // Sophisticated blur

      default:
        return 20.0;
    }
  }

  static bool hasScanlines(AppThemeMode mode) {
    final r = _resolve(mode);
    return r == AppThemeMode.cyberPhantom ||
        r == AppThemeMode.toxicVenom ||
        r == AppThemeMode.neonPulse;
  }

  static double getGrainIntensity(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:
        return 0.12;
      case AppThemeMode.infernoCore:
        return 0.14;
      case AppThemeMode.velvetNoir:
        return 0.06;
      case AppThemeMode.goldenEmperor:
        return 0.08;
      default:
        return 0.0;
    }
  }

  static double getEdgeGlowIntensity(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:
        return 0.90;
      case AppThemeMode.cyberPhantom:
        return 0.95;
      case AppThemeMode.infernoCore:
        return 0.95;
      case AppThemeMode.toxicVenom:
        return 0.85;
      case AppThemeMode.phantomViolet:
        return 0.80;
      case AppThemeMode.goldenEmperor:
        return 0.65;
      case AppThemeMode.velvetNoir:
        return 0.40;
      case AppThemeMode.astralDream:
        return 0.50;
      case AppThemeMode.arcticBlade:
        return 0.60;
      case AppThemeMode.oceanAbyss:
        return 0.70;

      // ─ NEW THEME GLOW ─────────────────────────────────────────────────
      case AppThemeMode.neonPulse:
        return 0.95; // High neon glow
      case AppThemeMode.moonlitMagic:
        return 0.55; // Soft moonlit glow
      case AppThemeMode.solsticeBlaze:
        return 0.92; // Intense fire glow
      case AppThemeMode.auroraBorealis:
        return 0.75; // Light aurora glow
      case AppThemeMode.midnightEclipse:
        return 0.50; // Subtle luxury glow

      default:
        return 0.50;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUBBLE ACCENT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static Color getBubbleAccent(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:
        return const Color(0x33FF1744);
      case AppThemeMode.cyberPhantom:
        return const Color(0x3300E5FF);
      case AppThemeMode.velvetNoir:
        return const Color(0x33B76E79);
      case AppThemeMode.toxicVenom:
        return const Color(0x3339FF14);
      case AppThemeMode.astralDream:
        return const Color(0x33B388FF);
      case AppThemeMode.infernoCore:
        return const Color(0x33FF6D00);
      case AppThemeMode.arcticBlade:
        return const Color(0x3380D8FF);
      case AppThemeMode.goldenEmperor:
        return const Color(0x33FFD700);
      case AppThemeMode.phantomViolet:
        return const Color(0x33D500F9);
      case AppThemeMode.oceanAbyss:
        return const Color(0x331DE9B6);

      // ─ NEW BUBBLE ACCENTS ─────────────────────────────────────────────
      case AppThemeMode.neonPulse:
        return const Color(0x3300FF88);
      case AppThemeMode.moonlitMagic:
        return const Color(0x33E0E3FF);
      case AppThemeMode.solsticeBlaze:
        return const Color(0x33FF4500);
      case AppThemeMode.auroraBorealis:
        return const Color(0x3300D9A3);
      case AppThemeMode.midnightEclipse:
        return const Color(0x33C9A961);

      default:
        return const Color(0x33FF1744);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  THEME STYLES (Font, Bubble, Input, Anim, Layout, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeStyle getStyle(AppThemeMode mode) {
    final resolved = _resolve(mode);
    return _styleCache[resolved] ??= _buildStyle(resolved);
  }

  static ThemeStyle _buildStyle(AppThemeMode mode) {
    switch (mode) {
      // ── 1. ZERO TWO — Blood & Passion ──────────────────────────────────
      case AppThemeMode.zeroTwo:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.exo2(
              fontSize: s,
              color: c,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.press,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 6,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.6),
          hintText: 'Speak to the darkness...',
          labelUser: 'YOU',
          labelAI: 'ZERO TWO',
        );

      // ── 2. CYBER PHANTOM — Neon Cyberpunk ──────────────────────────────
      case AppThemeMode.cyberPhantom:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.orbitron(
              fontSize: s * 0.88,
              color: c,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500),
          bubbleStyle: BubbleStyle.terminal,
          inputStyle: InputStyle.terminal,
          animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.terminal,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.9),
          hintText: '> TRANSMIT_SIGNAL_',
          labelUser: 'PILOT',
          labelAI: 'PHANTOM',
        );

      // ── 3. VELVET NOIR — Luxury Elegance ───────────────────────────────
      case AppThemeMode.velvetNoir:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.playfairDisplay(
              fontSize: s, color: c, fontStyle: FontStyle.italic, height: 1.6),
          bubbleStyle: BubbleStyle.luxury,
          inputStyle: InputStyle.luxury,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 28,
          sharpCorner: 28,
          leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.15),
          hintText: 'Whisper something beautiful...',
          labelUser: '♡',
          labelAI: 'Darling',
        );

      // ── 4. TOXIC VENOM — Matrix Hacker ─────────────────────────────────
      case AppThemeMode.toxicVenom:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sourceCodePro(
              fontSize: s * 0.92,
              color: c,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              height: 1.6),
          bubbleStyle: BubbleStyle.terminal,
          inputStyle: InputStyle.terminal,
          animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.85),
          hintText: 'inject payload >',
          labelUser: '\$USER',
          labelAI: '\$VENOM',
        );

      // ── 5. ASTRAL DREAM — Ethereal Aurora ──────────────────────────────
      case AppThemeMode.astralDream:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.quicksand(
              fontSize: s,
              color: c,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.pill,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 32,
          sharpCorner: 32,
          leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.12),
          hintText: 'drift into the cosmos...',
          labelUser: '✦',
          labelAI: 'Zero Two ✧',
        );

      // ── 6. INFERNO CORE — Volcanic Fury ────────────────────────────────
      case AppThemeMode.infernoCore:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.rajdhani(
              fontSize: s * 1.05,
              color: c,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.banner,
          cornerRadius: 4,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.7),
          hintText: 'FORGE YOUR MESSAGE...',
          labelUser: 'WARRIOR',
          labelAI: 'INFERNO',
        );

      // ── 7. ARCTIC BLADE — Frozen Minimal ───────────────────────────────
      case AppThemeMode.arcticBlade:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.inter(
              fontSize: s,
              color: c,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.pill,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.transparent,
          cornerRadius: 20,
          sharpCorner: 20,
          leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.10),
          hintText: 'whisper to the ice...',
          labelUser: '❄',
          labelAI: 'Zero Two ~',
        );

      // ── 8. GOLDEN EMPEROR — Royal Opulence ─────────────────────────────
      case AppThemeMode.goldenEmperor:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.cinzel(
              fontSize: s * 0.95,
              color: c,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.luxury,
          inputStyle: InputStyle.luxury,
          animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 12,
          sharpCorner: 4,
          leftAccentBar: false,
          borderColor: (p) => const Color(0xFFFFD700).withValues(alpha: 0.4),
          hintText: 'Address the throne...',
          labelUser: 'LORD',
          labelAI: 'EMPRESS',
        );

      // ── 9. PHANTOM VIOLET — Dark Mystery ───────────────────────────────
      case AppThemeMode.phantomViolet:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.josefinSans(
              fontSize: s,
              color: c,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600),
          bubbleStyle: BubbleStyle.outlined,
          inputStyle: InputStyle.underline,
          animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 6,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.75),
          hintText: 'speak into the void...',
          labelUser: '·',
          labelAI: 'ZT ~',
        );

      // ── 10. OCEAN ABYSS — Deep Sea Glow ────────────────────────────────
      case AppThemeMode.oceanAbyss:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.nunito(
              fontSize: s,
              color: c,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.pill,
          animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.transparent,
          cornerRadius: 24,
          sharpCorner: 24,
          leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.3),
          hintText: 'echo through the deep...',
          labelUser: '🫧',
          labelAI: 'Zero Two 🌊',
        );

      default:
        return _buildStyle(AppThemeMode.zeroTwo);
    }
  }
}
