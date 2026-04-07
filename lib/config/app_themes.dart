import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    this.labelUser = "YOU",
    this.labelAI = "ZERO TWO",
  });
}

// ── 10 Premium Themes ───────────────────────────────────────────────────────
enum AppThemeMode {
  zeroTwo,        // 1. Crimson blood — the OG
  cyberPhantom,   // 2. Electric cyan + violet — cyberpunk
  velvetNoir,     // 3. Rose gold + champagne — luxury
  toxicVenom,     // 4. Acid green + lime — matrix hacker
  astralDream,    // 5. Lavender + aurora pink — ethereal
  infernoCore,    // 6. Molten orange + lava red — volcanic
  arcticBlade,    // 7. Ice blue + frost white — minimal arctic
  goldenEmperor,  // 8. 24K gold + bronze — royal opulent
  phantomViolet,  // 9. Deep purple + magenta — mysterious
  oceanAbyss,     // 10. Deep teal + bioluminescent — deep sea

  // Legacy aliases — kept so old SharedPreferences indices don't crash.
  bloodMoon, voidMatrix, angelFall, titanSoul, cosmicRift,
  neonSerpent, chromaStorm, goldenRuler, frozenDivine, infernoGod,
  shadowBlade, pinkChaos, abyssWatcher, solarFlare, demonSlayer,
  midnightSilk, obsidianRose, onyxEmerald, velvetCrown, platinumDawn,
  hypergate, xenoCore, dataStream, gravityBend, quartzPulse,
  midnightForest, volcanicSea, stormDesert, sakuraNight, arcticSoul,
  amethystDream, titaniumFrost, sunsetRider, midnightRaven, electricLime,
}

enum ParticleType { circles, squares, lines, sakura, embers, bubbles, leaves, snow, stars, rain }

class AppThemes {
  static Color? _customAccentColor;
  static Color? get customAccentColor => _customAccentColor;
  static set customAccentColor(Color? c) {
    if (_customAccentColor == c) return;
    _customAccentColor = c;
    _themeCache.clear();
    _styleCache.clear();
  }

  static final Map<AppThemeMode, ThemeData> _themeCache = {};
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
    }
  }

  static ThemeData getRawTheme(AppThemeMode mode) {
    final Color? old = _customAccentColor;
    _customAccentColor = null;
    _themeCache.clear();
    final ThemeData t = getTheme(mode);
    _customAccentColor = old;
    _themeCache.clear();
    return t;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  THEME DATA (Colors)
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData getTheme(AppThemeMode mode) {
    final resolved = _resolve(mode);
    return _themeCache[resolved] ??= _buildTheme(resolved);
  }

  static ThemeData _buildTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.zeroTwo:
        return _build(primary: const Color(0xFFFF1744), secondary: const Color(0xFF880E4F), bg: const Color(0xFF0A0003), accent: const Color(0xFFFF4081));
      case AppThemeMode.cyberPhantom:
        return _build(primary: const Color(0xFF00E5FF), secondary: const Color(0xFF7C4DFF), bg: const Color(0xFF020810), accent: const Color(0xFF18FFFF));
      case AppThemeMode.velvetNoir:
        return _build(primary: const Color(0xFFB76E79), secondary: const Color(0xFF3E2723), bg: const Color(0xFF0C0808), accent: const Color(0xFFF7E7CE));
      case AppThemeMode.toxicVenom:
        return _build(primary: const Color(0xFF39FF14), secondary: const Color(0xFF00C853), bg: const Color(0xFF010D02), accent: const Color(0xFFADFF2F));
      case AppThemeMode.astralDream:
        return _build(primary: const Color(0xFFB388FF), secondary: const Color(0xFFCE93D8), bg: const Color(0xFF080010), accent: const Color(0xFFFF80AB));
      case AppThemeMode.infernoCore:
        return _build(primary: const Color(0xFFFF6D00), secondary: const Color(0xFFD50000), bg: const Color(0xFF0C0200), accent: const Color(0xFFFFAB00));
      case AppThemeMode.arcticBlade:
        return _build(primary: const Color(0xFF80D8FF), secondary: const Color(0xFF4FC3F7), bg: const Color(0xFF020A10), accent: const Color(0xFFE0F7FA));
      case AppThemeMode.goldenEmperor:
        return _build(primary: const Color(0xFFFFD700), secondary: const Color(0xFFCD7F32), bg: const Color(0xFF0A0600), accent: const Color(0xFFFFF8E1));
      case AppThemeMode.phantomViolet:
        return _build(primary: const Color(0xFFD500F9), secondary: const Color(0xFF6200EA), bg: const Color(0xFF0A0010), accent: const Color(0xFFEA80FC));
      case AppThemeMode.oceanAbyss:
        return _build(primary: const Color(0xFF1DE9B6), secondary: const Color(0xFF006064), bg: const Color(0xFF00080A), accent: const Color(0xFF84FFFF));
      default:
        return _build(primary: const Color(0xFFFF1744), secondary: const Color(0xFF880E4F), bg: const Color(0xFF0A0003), accent: const Color(0xFFFF4081));
    }
  }

  static ThemeData _build({required Color primary, required Color secondary, required Color bg, required Color accent}) {
    final effectivePrimary = _customAccentColor ?? primary;
    final effectiveAccent = _customAccentColor ?? accent;
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: effectivePrimary,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      colorScheme: ColorScheme.dark(
        primary: effectivePrimary,
        secondary: secondary,
        surface: bg,
        tertiary: effectiveAccent,
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
        return const [Color(0xFF0A0010), Color(0xFF3D0014), Color(0xFF6B0020), Color(0xFF1A0030), Color(0xFF000006)];
      case AppThemeMode.cyberPhantom:
        // Deep space → electric blue → violet pulse → cyan haze → void
        return const [Color(0xFF000810), Color(0xFF001A3D), Color(0xFF1A004A), Color(0xFF003040), Color(0xFF000408)];
      case AppThemeMode.velvetNoir:
        // Ink velvet → rose shadow → champagne glow → mahogany → noir
        return const [Color(0xFF080404), Color(0xFF2A1018), Color(0xFF3D2420), Color(0xFF1A0C08), Color(0xFF040202)];
      case AppThemeMode.toxicVenom:
        // Void → toxic jade → serpent green → acid glow → shadow
        return const [Color(0xFF000A02), Color(0xFF003810), Color(0xFF005020), Color(0xFF0A4000), Color(0xFF000800)];
      case AppThemeMode.astralDream:
        // Cosmic void → lavender mist → aurora pink → violet haze → deep
        return const [Color(0xFF060010), Color(0xFF1A0040), Color(0xFF3A1060), Color(0xFF200030), Color(0xFF040008)];
      case AppThemeMode.infernoCore:
        // Obsidian → volcanic red → molten orange → lava glow → ash
        return const [Color(0xFF060000), Color(0xFF3D0000), Color(0xFF5E1400), Color(0xFF3D0A00), Color(0xFF0A0000)];
      case AppThemeMode.arcticBlade:
        // Polar dark → deep arctic → ice blue → aurora teal → frost
        return const [Color(0xFF000510), Color(0xFF001830), Color(0xFF003050), Color(0xFF001A38), Color(0xFF000308)];
      case AppThemeMode.goldenEmperor:
        // Ancient ink → 24k shimmer → burnished amber → cognac → shadow
        return const [Color(0xFF080400), Color(0xFF3D2600), Color(0xFF604000), Color(0xFF3D1800), Color(0xFF0A0500)];
      case AppThemeMode.phantomViolet:
        // Void → violet surge → magenta crystal → deep purple → black
        return const [Color(0xFF040006), Color(0xFF180028), Color(0xFF380058), Color(0xFF200038), Color(0xFF040006)];
      case AppThemeMode.oceanAbyss:
        // Abyss → deep teal → biolume green → midnight navy → void
        return const [Color(0xFF000604), Color(0xFF002818), Color(0xFF004028), Color(0xFF001828), Color(0xFF000402)];
      default:
        return const [Color(0xFF0A0010), Color(0xFF3D0014), Color(0xFF6B0020), Color(0xFF1A0030), Color(0xFF000006)];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PARTICLES
  // ═══════════════════════════════════════════════════════════════════════════

  static ParticleType getParticleType(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:       return ParticleType.sakura;
      case AppThemeMode.cyberPhantom:  return ParticleType.rain;
      case AppThemeMode.velvetNoir:    return ParticleType.circles;
      case AppThemeMode.toxicVenom:    return ParticleType.lines;
      case AppThemeMode.astralDream:   return ParticleType.stars;
      case AppThemeMode.infernoCore:   return ParticleType.embers;
      case AppThemeMode.arcticBlade:   return ParticleType.snow;
      case AppThemeMode.goldenEmperor: return ParticleType.squares;
      case AppThemeMode.phantomViolet: return ParticleType.bubbles;
      case AppThemeMode.oceanAbyss:    return ParticleType.bubbles;
      default:                         return ParticleType.sakura;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  THEME NAMES
  // ═══════════════════════════════════════════════════════════════════════════

  static String getThemeName(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:       return "Zero Two";
      case AppThemeMode.cyberPhantom:  return "Cyber Phantom";
      case AppThemeMode.velvetNoir:    return "Velvet Noir";
      case AppThemeMode.toxicVenom:    return "Toxic Venom";
      case AppThemeMode.astralDream:   return "Astral Dream";
      case AppThemeMode.infernoCore:   return "Inferno Core";
      case AppThemeMode.arcticBlade:   return "Arctic Blade";
      case AppThemeMode.goldenEmperor: return "Golden Emperor";
      case AppThemeMode.phantomViolet: return "Phantom Violet";
      case AppThemeMode.oceanAbyss:    return "Ocean Abyss";
      default:                         return "Zero Two";
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  VISUAL FX INTENSITIES
  // ═══════════════════════════════════════════════════════════════════════════

  static double getBlurIntensity(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.cyberPhantom:  return 8.0;   // crisp neon
      case AppThemeMode.astralDream:   return 30.0;  // dreamy blur
      case AppThemeMode.velvetNoir:    return 28.0;  // soft luxury
      case AppThemeMode.arcticBlade:   return 25.0;  // frosted glass
      default:                         return 20.0;
    }
  }

  static bool hasScanlines(AppThemeMode mode) {
    final r = _resolve(mode);
    return r == AppThemeMode.cyberPhantom || r == AppThemeMode.toxicVenom;
  }

  static double getGrainIntensity(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:       return 0.12;
      case AppThemeMode.infernoCore:   return 0.14;
      case AppThemeMode.velvetNoir:    return 0.06;
      case AppThemeMode.goldenEmperor: return 0.08;
      default:                         return 0.0;
    }
  }

  static double getEdgeGlowIntensity(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:       return 0.90;
      case AppThemeMode.cyberPhantom:  return 0.95;
      case AppThemeMode.infernoCore:   return 0.95;
      case AppThemeMode.toxicVenom:    return 0.85;
      case AppThemeMode.phantomViolet: return 0.80;
      case AppThemeMode.goldenEmperor: return 0.65;
      case AppThemeMode.velvetNoir:    return 0.40;
      case AppThemeMode.astralDream:   return 0.50;
      case AppThemeMode.arcticBlade:   return 0.60;
      case AppThemeMode.oceanAbyss:    return 0.70;
      default:                         return 0.50;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUBBLE ACCENT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static Color getBubbleAccent(AppThemeMode mode) {
    switch (_resolve(mode)) {
      case AppThemeMode.zeroTwo:       return const Color(0x33FF1744);
      case AppThemeMode.cyberPhantom:  return const Color(0x3300E5FF);
      case AppThemeMode.velvetNoir:    return const Color(0x33B76E79);
      case AppThemeMode.toxicVenom:    return const Color(0x3339FF14);
      case AppThemeMode.astralDream:   return const Color(0x33B388FF);
      case AppThemeMode.infernoCore:   return const Color(0x33FF6D00);
      case AppThemeMode.arcticBlade:   return const Color(0x3380D8FF);
      case AppThemeMode.goldenEmperor: return const Color(0x33FFD700);
      case AppThemeMode.phantomViolet: return const Color(0x33D500F9);
      case AppThemeMode.oceanAbyss:    return const Color(0x331DE9B6);
      default:                         return const Color(0x33FF1744);
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
          font: (s, c) => GoogleFonts.exo2(fontSize: s, color: c, fontWeight: FontWeight.w700, letterSpacing: 1.0),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.solid,
          cornerRadius: 6, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.6),
          hintText: "Speak to the darkness...", labelUser: "YOU", labelAI: "ZERO TWO",
        );

      // ── 2. CYBER PHANTOM — Neon Cyberpunk ──────────────────────────────
      case AppThemeMode.cyberPhantom:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.orbitron(fontSize: s * 0.88, color: c, letterSpacing: 2.0, fontWeight: FontWeight.w500),
          bubbleStyle: BubbleStyle.terminal, inputStyle: InputStyle.terminal, animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.terminal, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.9),
          hintText: "> TRANSMIT_SIGNAL_", labelUser: "PILOT", labelAI: "PHANTOM",
        );

      // ── 3. VELVET NOIR — Luxury Elegance ───────────────────────────────
      case AppThemeMode.velvetNoir:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.playfairDisplay(fontSize: s, color: c, fontStyle: FontStyle.italic, height: 1.6),
          bubbleStyle: BubbleStyle.luxury, inputStyle: InputStyle.luxury, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 28, sharpCorner: 28, leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.15),
          hintText: "Whisper something beautiful...", labelUser: "♡", labelAI: "Darling",
        );

      // ── 4. TOXIC VENOM — Matrix Hacker ─────────────────────────────────
      case AppThemeMode.toxicVenom:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sourceCodePro(fontSize: s * 0.92, color: c, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.6),
          bubbleStyle: BubbleStyle.terminal, inputStyle: InputStyle.terminal, animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.85),
          hintText: "inject payload >", labelUser: "\$USER", labelAI: "\$VENOM",
        );

      // ── 5. ASTRAL DREAM — Ethereal Aurora ──────────────────────────────
      case AppThemeMode.astralDream:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.quicksand(fontSize: s, color: c, fontWeight: FontWeight.w300, letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.pill, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 32, sharpCorner: 32, leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.12),
          hintText: "drift into the cosmos...", labelUser: "✦", labelAI: "Zero Two ✧",
        );

      // ── 6. INFERNO CORE — Volcanic Fury ────────────────────────────────
      case AppThemeMode.infernoCore:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.rajdhani(fontSize: s * 1.05, color: c, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.banner,
          cornerRadius: 4, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.7),
          hintText: "FORGE YOUR MESSAGE...", labelUser: "WARRIOR", labelAI: "INFERNO",
        );

      // ── 7. ARCTIC BLADE — Frozen Minimal ───────────────────────────────
      case AppThemeMode.arcticBlade:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.inter(fontSize: s, color: c, fontWeight: FontWeight.w400, letterSpacing: 0.3),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.pill, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.transparent,
          cornerRadius: 20, sharpCorner: 20, leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.10),
          hintText: "whisper to the ice...", labelUser: "❄", labelAI: "Zero Two ~",
        );

      // ── 8. GOLDEN EMPEROR — Royal Opulence ─────────────────────────────
      case AppThemeMode.goldenEmperor:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.cinzel(fontSize: s * 0.95, color: c, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.luxury, inputStyle: InputStyle.luxury, animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.solid,
          cornerRadius: 12, sharpCorner: 4, leftAccentBar: false,
          borderColor: (p) => const Color(0xFFFFD700).withValues(alpha: 0.4),
          hintText: "Address the throne...", labelUser: "LORD", labelAI: "EMPRESS",
        );

      // ── 9. PHANTOM VIOLET — Dark Mystery ───────────────────────────────
      case AppThemeMode.phantomViolet:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.josefinSans(fontSize: s, color: c, letterSpacing: 2.0, fontWeight: FontWeight.w600),
          bubbleStyle: BubbleStyle.outlined, inputStyle: InputStyle.underline, animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 6, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.75),
          hintText: "speak into the void...", labelUser: "·", labelAI: "ZT ~",
        );

      // ── 10. OCEAN ABYSS — Deep Sea Glow ────────────────────────────────
      case AppThemeMode.oceanAbyss:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.nunito(fontSize: s, color: c, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.pill, animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.transparent,
          cornerRadius: 24, sharpCorner: 24, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.3),
          hintText: "echo through the deep...", labelUser: "🫧", labelAI: "Zero Two 🌊",
        );

      default:
        return _buildStyle(AppThemeMode.zeroTwo);
    }
  }
}