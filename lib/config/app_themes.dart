import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
//   THEME STYLE ENUMS â€” Drive per-theme visual identity
// ============================================================

enum BubbleStyle {
  glassmorphic, // Frosted glass, soft blur
  terminal, // Monospace text, no bubble fill
  outlined, // Hollow border glow, no fill
  solid, // Opaque single-color fill
  luxury, // Rich card with border shimmer
}

enum InputStyle {
  pill, // Rounded pill, frosted glass (classic)
  squareNeon, // Sharp rectangle, neon border glow
  underline, // Just a bottom line, minimal
  terminal, // Monospace, cursor blink style
  luxury, // Gold/silver bordered card style
}

enum AnimStyle {
  elastic, // Bounce spring (current)
  slideSide, // Slides in from the bubble's side
  glitch, // Fast scale-overshoot then settle
  fadeZoom, // Fade + gentle zoom in
  press, // Scale up from nothing, quick
}

/// How the chat body lays out messages
enum LayoutMode {
  classic, // User right, AI left (standard)
  terminal, // All left-aligned, full-width, no bubble border
  centered, // All centered on screen
  wideCard, // Full-width card each message, left-aligned label
}

/// AppBar visual style
enum AppBarStyle {
  transparent, // Classic glass with no background
  neonBorder, // Dark bar with glowing bottom border
  solid, // Opaque colored bar
  minimal, // Just the title, no border or color, floating
  banner, // Full gradient banner with larger title
}

/// Encapsulates the full visual identity for one theme
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
  final String
      labelUser; // How the user is labeled in terminal/wideCard layouts
  final String labelAI; // How Zero Two is labeled

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

enum AppThemeMode {
  // â”€â”€ TIER 1: ICONIC â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bloodMoon, // Zero Two: deep crimson cinematic
  voidMatrix, // Pure black cyberpunk, green data rain
  angelFall, // Sakura + celestial white haze
  titanSoul, // Amber brutal war-torn
  cosmicRift, // Deep space purple + aurora shimmer

  // â”€â”€ TIER 2: ULTRA-PREMIUM â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  neonSerpent, // Poison jade viper energy
  chromaStorm, // Magenta + cyan glitch aberration
  goldenRuler, // 24k luxury gold + ink black
  frozenDivine, // Glacier arctic crystalline
  infernoGod, // Volcanic lava obsidian

  // â”€â”€ TIER 3: ANIME LEGENDS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  shadowBlade, // Samurai ink, matte black + silver slash
  pinkChaos, // Yuno Gasai: hot pink + white corruption
  abyssWatcher, // Abyss: midnight navy + faint teal glow
  solarFlare, // Naruto warm orange + deep red energy
  demonSlayer, // Inosuke: jade beast + dark forest

  // â”€â”€ TIER 4: LUXURY & FASHION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  midnightSilk, // Deep navy + rose gold shimmer
  obsidianRose, // Matte black + blooming pink
  onyxEmerald, // Gunmetal + rich emerald jewel
  velvetCrown, // Deep purple + pale gold crown
  platinumDawn, // Cool silver + dawn peach luxury

  // â”€â”€ TIER 5: SCI-FI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  hypergate, // Electric blue + white dimension portal
  xenoCore, // Alien bioluminescent teal + void black
  dataStream, // Cyan cascading data on black
  gravityBend, // Dark indigo + warped light orange
  quartzPulse, // Crystal white + pulsing violet

  // â”€â”€ TIER 6: NATURE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  midnightForest, // Dark wood green + moonlit silver
  volcanicSea, // Deep ocean blue + molten orange seam
  stormDesert, // Warm sand beige + electric storm grey
  sakuraNight, // Ink black + falling pink sakura petals
  arcticSoul, // Pure ice blue + barely-there aurora violet
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
  rain,
}

class AppThemes {
  // ==========================================================
  //  PRIMARY GETTER
  // ==========================================================
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon:
        return _build(
          primary: const Color(0xFFFF1744),
          secondary: const Color(0xFF880E4F),
          bg: const Color(0xFF0A0003),
          accent: const Color(0xFFFF4081),
        );
      case AppThemeMode.voidMatrix:
        return _build(
          primary: const Color(0xFF00FF41),
          secondary: const Color(0xFF00E676),
          bg: const Color(0xFF000A00),
          accent: const Color(0xFF69FF47),
        );
      case AppThemeMode.angelFall:
        return _build(
          primary: const Color(0xFFFFCDD2),
          secondary: const Color(0xFFF8BBD0),
          bg: const Color(0xFF100810),
          accent: const Color(0xFFFF80AB),
        );
      case AppThemeMode.titanSoul:
        return _build(
          primary: const Color(0xFFFFAB40),
          secondary: const Color(0xFFBF360C),
          bg: const Color(0xFF0C0600),
          accent: const Color(0xFFFFCC02),
        );
      case AppThemeMode.cosmicRift:
        return _build(
          primary: const Color(0xFFEA80FC),
          secondary: const Color(0xFF7C4DFF),
          bg: const Color(0xFF040008),
          accent: const Color(0xFF00E5FF),
        );
      case AppThemeMode.neonSerpent:
        return _build(
          primary: const Color(0xFF39FF14),
          secondary: const Color(0xFF00C853),
          bg: const Color(0xFF010D06),
          accent: const Color(0xFFB2FF59),
        );
      case AppThemeMode.chromaStorm:
        return _build(
          primary: const Color(0xFFFF00FF),
          secondary: const Color(0xFF00E5FF),
          bg: const Color(0xFF05000F),
          accent: const Color(0xFFFF4081),
        );
      case AppThemeMode.goldenRuler:
        return _build(
          primary: const Color(0xFFFFD700),
          secondary: const Color(0xFFFF8F00),
          bg: const Color(0xFF050300),
          accent: const Color(0xFFFFF9C4),
        );
      case AppThemeMode.frozenDivine:
        return _build(
          primary: const Color(0xFFB3E5FC),
          secondary: const Color(0xFF4FC3F7),
          bg: const Color(0xFF00050F),
          accent: const Color(0xFFE1F5FE),
        );
      case AppThemeMode.infernoGod:
        return _build(
            primary: const Color(0xFFFF3D00),
            secondary: const Color(0xFFBF360C),
            bg: const Color(0xFF060000),
            accent: const Color(0xFFFF6D00));
      // â”€â”€ TIER 3: ANIME LEGENDS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case AppThemeMode.shadowBlade:
        return _build(
            primary: const Color(0xFFBDBDBD),
            secondary: const Color(0xFF616161),
            bg: const Color(0xFF030303),
            accent: const Color(0xFFEEEEEE));
      case AppThemeMode.pinkChaos:
        return _build(
            primary: const Color(0xFFFF4081),
            secondary: const Color(0xFFAD1457),
            bg: const Color(0xFF0D0009),
            accent: const Color(0xFFFF80AB));
      case AppThemeMode.abyssWatcher:
        return _build(
            primary: const Color(0xFF26C6DA),
            secondary: const Color(0xFF006064),
            bg: const Color(0xFF00050F),
            accent: const Color(0xFF80DEEA));
      case AppThemeMode.solarFlare:
        return _build(
            primary: const Color(0xFFFF6D00),
            secondary: const Color(0xFFBF360C),
            bg: const Color(0xFF0F0500),
            accent: const Color(0xFFFFAB40));
      case AppThemeMode.demonSlayer:
        return _build(
            primary: const Color(0xFF43A047),
            secondary: const Color(0xFF1B5E20),
            bg: const Color(0xFF020D02),
            accent: const Color(0xFFA5D6A7));
      // â”€â”€ TIER 4: LUXURY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case AppThemeMode.midnightSilk:
        return _build(
            primary: const Color(0xFFD4A5A5),
            secondary: const Color(0xFF1A237E),
            bg: const Color(0xFF01010D),
            accent: const Color(0xFFE8C8C8));
      case AppThemeMode.obsidianRose:
        return _build(
            primary: const Color(0xFFEC407A),
            secondary: const Color(0xFF880E4F),
            bg: const Color(0xFF060208),
            accent: const Color(0xFFF48FB1));
      case AppThemeMode.onyxEmerald:
        return _build(
            primary: const Color(0xFF26A69A),
            secondary: const Color(0xFF00695C),
            bg: const Color(0xFF01080A),
            accent: const Color(0xFF80CBC4));
      case AppThemeMode.velvetCrown:
        return _build(
            primary: const Color(0xFFCE93D8),
            secondary: const Color(0xFF6A1B9A),
            bg: const Color(0xFF080010),
            accent: const Color(0xFFFFD54F));
      case AppThemeMode.platinumDawn:
        return _build(
            primary: const Color(0xFFE0E0E0),
            secondary: const Color(0xFF9E9E9E),
            bg: const Color(0xFF040404),
            accent: const Color(0xFFFFCCBC));
      // â”€â”€ TIER 5: SCI-FI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case AppThemeMode.hypergate:
        return _build(
            primary: const Color(0xFF40C4FF),
            secondary: const Color(0xFF0091EA),
            bg: const Color(0xFF000A14),
            accent: const Color(0xFFFFFFFF));
      case AppThemeMode.xenoCore:
        return _build(
            primary: const Color(0xFF1DE9B6),
            secondary: const Color(0xFF00BFA5),
            bg: const Color(0xFF00050A),
            accent: const Color(0xFFA7FFEB));
      case AppThemeMode.dataStream:
        return _build(
            primary: const Color(0xFF00E5FF),
            secondary: const Color(0xFF006064),
            bg: const Color(0xFF000B0F),
            accent: const Color(0xFF84FFFF));
      case AppThemeMode.gravityBend:
        return _build(
            primary: const Color(0xFFFF6F00),
            secondary: const Color(0xFF311B92),
            bg: const Color(0xFF040010),
            accent: const Color(0xFFFFD180));
      case AppThemeMode.quartzPulse:
        return _build(
            primary: const Color(0xFFD500F9),
            secondary: const Color(0xFF6200EA),
            bg: const Color(0xFF060008),
            accent: const Color(0xFFEA80FC));
      // â”€â”€ TIER 6: NATURE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case AppThemeMode.midnightForest:
        return _build(
            primary: const Color(0xFF81C784),
            secondary: const Color(0xFF2E7D32),
            bg: const Color(0xFF010A01),
            accent: const Color(0xFFC8E6C9));
      case AppThemeMode.volcanicSea:
        return _build(
            primary: const Color(0xFFFF7043),
            secondary: const Color(0xFF01579B),
            bg: const Color(0xFF030712),
            accent: const Color(0xFFFF8A65));
      case AppThemeMode.stormDesert:
        return _build(
            primary: const Color(0xFFBCAAA4),
            secondary: const Color(0xFF4E342E),
            bg: const Color(0xFF0C0804),
            accent: const Color(0xFFF5F5DC));
      case AppThemeMode.sakuraNight:
        return _build(
            primary: const Color(0xFFFFB7C5),
            secondary: const Color(0xFF880E4F),
            bg: const Color(0xFF040008),
            accent: const Color(0xFFFFE0E6));
      case AppThemeMode.arcticSoul:
        return _build(
            primary: const Color(0xFFB3E5FC),
            secondary: const Color(0xFF80D8FF),
            bg: const Color(0xFF000508),
            accent: const Color(0xFFE0F7FA));
    }
  }

  static ThemeData _build({
    required Color primary,
    required Color secondary,
    required Color bg,
    required Color accent,
  }) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: bg,
        tertiary: accent,
      ),
    );
  }

  // ==========================================================
  //  ULTRA-RICH MULTI-STOP GRADIENTS (3-5 stops each)
  // ==========================================================
  static List<Color> getGradient(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon:
        // Deep obsidian â†’ blood crimson haze â†’ night void
        return [
          const Color(0xFF1C000A),
          const Color(0xFF3D0014),
          const Color(0xFF1A000A),
          const Color(0xFF0A0003),
          const Color(0xFF000000),
        ];
      case AppThemeMode.voidMatrix:
        // Void black â†’ matrix green trace â†’ terminal dark
        return [
          const Color(0xFF001500),
          const Color(0xFF002A00),
          const Color(0xFF001000),
          const Color(0xFF000000),
        ];
      case AppThemeMode.angelFall:
        // Twilight black â†’ rose petal mist â†’ faint white aether
        return [
          const Color(0xFF1E0C1A),
          const Color(0xFF3D1F2F),
          const Color(0xFF2B1120),
          const Color(0xFF100810),
          const Color(0xFF000000),
        ];
      case AppThemeMode.titanSoul:
        // War-ash black â†’ burnt amber â†’ volcanic ember â†’ shadow
        return [
          const Color(0xFF1F0F00),
          const Color(0xFF3D1A00),
          const Color(0xFF2B1000),
          const Color(0xFF0C0600),
          const Color(0xFF000000),
        ];
      case AppThemeMode.cosmicRift:
        // Singularity black â†’ deep space violet â†’ aurora plasma edge
        return [
          const Color(0xFF0D0018),
          const Color(0xFF1E0040),
          const Color(0xFF0A0030),
          const Color(0xFF040008),
          const Color(0xFF000000),
        ];
      case AppThemeMode.neonSerpent:
        // Jungle shadow â†’ toxic jade â†’ serpent neon â†’ void
        return [
          const Color(0xFF001A06),
          const Color(0xFF002E0F),
          const Color(0xFF001A08),
          const Color(0xFF010D06),
          const Color(0xFF000000),
        ];
      case AppThemeMode.chromaStorm:
        // Absolute black â†’ plasma magenta core â†’ electric cyan halo
        return [
          const Color(0xFF0F000A),
          const Color(0xFF1E0030),
          const Color(0xFF0A001A),
          const Color(0xFF05000F),
          const Color(0xFF000000),
        ];
      case AppThemeMode.goldenRuler:
        // Ink black â†’ 24k gold trace â†’ burnished amber â†’ shadow
        return [
          const Color(0xFF150D00),
          const Color(0xFF2A1800),
          const Color(0xFF1C1000),
          const Color(0xFF050300),
          const Color(0xFF000000),
        ];
      case AppThemeMode.frozenDivine:
        // Glacial abyss â†’ ice blue depth â†’ crystal mist â†’ dark
        return [
          const Color(0xFF001020),
          const Color(0xFF00203D),
          const Color(0xFF001530),
          const Color(0xFF00050F),
          const Color(0xFF000000),
        ];
      case AppThemeMode.infernoGod:
        return [
          const Color(0xFF1A0000),
          const Color(0xFF3D0000),
          const Color(0xFF060000),
          const Color(0xFF000000)
        ];
      case AppThemeMode.shadowBlade:
        return [
          const Color(0xFF0A0A0A),
          const Color(0xFF1C1C1C),
          const Color(0xFF0A0A0A),
          const Color(0xFF000000)
        ];
      case AppThemeMode.pinkChaos:
        return [
          const Color(0xFF1A0010),
          const Color(0xFF3D0025),
          const Color(0xFF150010),
          const Color(0xFF0D0009)
        ];
      case AppThemeMode.abyssWatcher:
        return [
          const Color(0xFF001820),
          const Color(0xFF003040),
          const Color(0xFF001020),
          const Color(0xFF00050F)
        ];
      case AppThemeMode.solarFlare:
        return [
          const Color(0xFF1A0A00),
          const Color(0xFF3D1800),
          const Color(0xFF200A00),
          const Color(0xFF0F0500)
        ];
      case AppThemeMode.demonSlayer:
        return [
          const Color(0xFF021402),
          const Color(0xFF042804),
          const Color(0xFF021002),
          const Color(0xFF020D02)
        ];
      case AppThemeMode.midnightSilk:
        return [
          const Color(0xFF08082A),
          const Color(0xFF14144A),
          const Color(0xFF0A0A20),
          const Color(0xFF01010D)
        ];
      case AppThemeMode.obsidianRose:
        return [
          const Color(0xFF18000E),
          const Color(0xFF32001C),
          const Color(0xFF180010),
          const Color(0xFF060208)
        ];
      case AppThemeMode.onyxEmerald:
        return [
          const Color(0xFF001A18),
          const Color(0xFF003030),
          const Color(0xFF001818),
          const Color(0xFF01080A)
        ];
      case AppThemeMode.velvetCrown:
        return [
          const Color(0xFF100020),
          const Color(0xFF200040),
          const Color(0xFF0C0020),
          const Color(0xFF080010)
        ];
      case AppThemeMode.platinumDawn:
        return [
          const Color(0xFF0C0C0C),
          const Color(0xFF181818),
          const Color(0xFF080808),
          const Color(0xFF040404)
        ];
      case AppThemeMode.hypergate:
        return [
          const Color(0xFF001A28),
          const Color(0xFF00304A),
          const Color(0xFF001520),
          const Color(0xFF000A14)
        ];
      case AppThemeMode.xenoCore:
        return [
          const Color(0xFF001A14),
          const Color(0xFF003025),
          const Color(0xFF001510),
          const Color(0xFF00050A)
        ];
      case AppThemeMode.dataStream:
        return [
          const Color(0xFF001820),
          const Color(0xFF003040),
          const Color(0xFF001020),
          const Color(0xFF000B0F)
        ];
      case AppThemeMode.gravityBend:
        return [
          const Color(0xFF100020),
          const Color(0xFF1C001A),
          const Color(0xFF0A0010),
          const Color(0xFF040010)
        ];
      case AppThemeMode.quartzPulse:
        return [
          const Color(0xFF100012),
          const Color(0xFF200030),
          const Color(0xFF0C000E),
          const Color(0xFF060008)
        ];
      case AppThemeMode.midnightForest:
        return [
          const Color(0xFF011401),
          const Color(0xFF022502),
          const Color(0xFF01100A),
          const Color(0xFF010A01)
        ];
      case AppThemeMode.volcanicSea:
        return [
          const Color(0xFF040C14),
          const Color(0xFF0A1828),
          const Color(0xFF040A18),
          const Color(0xFF030712)
        ];
      case AppThemeMode.stormDesert:
        return [
          const Color(0xFF1A1410),
          const Color(0xFF2C221C),
          const Color(0xFF140E0A),
          const Color(0xFF0C0804)
        ];
      case AppThemeMode.sakuraNight:
        return [
          const Color(0xFF14000E),
          const Color(0xFF28001C),
          const Color(0xFF10000C),
          const Color(0xFF040008)
        ];
      case AppThemeMode.arcticSoul:
        return [
          const Color(0xFF000E18),
          const Color(0xFF001A2C),
          const Color(0xFF000A14),
          const Color(0xFF000508)
        ];
    }
  }

  // ==========================================================
  //  PARTICLE PHYSICS MAPPING
  // ==========================================================
  static ParticleType getParticleType(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon:
        return ParticleType.sakura; // Crimson petals falling
      case AppThemeMode.voidMatrix:
        return ParticleType.rain; // Data rain
      case AppThemeMode.angelFall:
        return ParticleType.sakura; // White/pink petals
      case AppThemeMode.titanSoul:
        return ParticleType.embers; // Battle embers
      case AppThemeMode.cosmicRift:
        return ParticleType.stars; // Drifting stars & aurora
      case AppThemeMode.neonSerpent:
        return ParticleType.bubbles; // Toxic bubbles rising
      case AppThemeMode.chromaStorm:
        return ParticleType.lines; // Lightning traces
      case AppThemeMode.goldenRuler:
        return ParticleType.circles; // Gold dust motes
      case AppThemeMode.frozenDivine:
        return ParticleType.snow; // Divine snowfall
      case AppThemeMode.infernoGod:
        return ParticleType.embers;
      case AppThemeMode.shadowBlade:
        return ParticleType.lines;
      case AppThemeMode.pinkChaos:
        return ParticleType.sakura;
      case AppThemeMode.abyssWatcher:
        return ParticleType.bubbles;
      case AppThemeMode.solarFlare:
        return ParticleType.embers;
      case AppThemeMode.demonSlayer:
        return ParticleType.leaves;
      case AppThemeMode.midnightSilk:
        return ParticleType.circles;
      case AppThemeMode.obsidianRose:
        return ParticleType.sakura;
      case AppThemeMode.onyxEmerald:
        return ParticleType.bubbles;
      case AppThemeMode.velvetCrown:
        return ParticleType.stars;
      case AppThemeMode.platinumDawn:
        return ParticleType.circles;
      case AppThemeMode.hypergate:
        return ParticleType.lines;
      case AppThemeMode.xenoCore:
        return ParticleType.bubbles;
      case AppThemeMode.dataStream:
        return ParticleType.rain;
      case AppThemeMode.gravityBend:
        return ParticleType.squares;
      case AppThemeMode.quartzPulse:
        return ParticleType.stars;
      case AppThemeMode.midnightForest:
        return ParticleType.leaves;
      case AppThemeMode.volcanicSea:
        return ParticleType.embers;
      case AppThemeMode.stormDesert:
        return ParticleType.lines;
      case AppThemeMode.sakuraNight:
        return ParticleType.sakura;
      case AppThemeMode.arcticSoul:
        return ParticleType.snow;
    }
  }

  // ==========================================================
  //  DISPLAY NAME
  // ==========================================================
  static String getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon:
        return "Blood Moon";
      case AppThemeMode.voidMatrix:
        return "Void Matrix";
      case AppThemeMode.angelFall:
        return "Angel Fall";
      case AppThemeMode.titanSoul:
        return "Titan Soul";
      case AppThemeMode.cosmicRift:
        return "Cosmic Rift";
      case AppThemeMode.neonSerpent:
        return "Neon Serpent";
      case AppThemeMode.chromaStorm:
        return "Chroma Storm";
      case AppThemeMode.goldenRuler:
        return "Golden Ruler";
      case AppThemeMode.frozenDivine:
        return "Frozen Divine";
      case AppThemeMode.infernoGod:
        return "Inferno God";
      case AppThemeMode.shadowBlade:
        return "Shadow Blade";
      case AppThemeMode.pinkChaos:
        return "Pink Chaos";
      case AppThemeMode.abyssWatcher:
        return "Abyss Watcher";
      case AppThemeMode.solarFlare:
        return "Solar Flare";
      case AppThemeMode.demonSlayer:
        return "Demon Slayer";
      case AppThemeMode.midnightSilk:
        return "Midnight Silk";
      case AppThemeMode.obsidianRose:
        return "Obsidian Rose";
      case AppThemeMode.onyxEmerald:
        return "Onyx Emerald";
      case AppThemeMode.velvetCrown:
        return "Velvet Crown";
      case AppThemeMode.platinumDawn:
        return "Platinum Dawn";
      case AppThemeMode.hypergate:
        return "Hypergate";
      case AppThemeMode.xenoCore:
        return "Xeno Core";
      case AppThemeMode.dataStream:
        return "Data Stream";
      case AppThemeMode.gravityBend:
        return "Gravity Bend";
      case AppThemeMode.quartzPulse:
        return "Quartz Pulse";
      case AppThemeMode.midnightForest:
        return "Midnight Forest";
      case AppThemeMode.volcanicSea:
        return "Volcanic Sea";
      case AppThemeMode.stormDesert:
        return "Storm Desert";
      case AppThemeMode.sakuraNight:
        return "Sakura Night";
      case AppThemeMode.arcticSoul:
        return "Arctic Soul";
    }
  }

  // ==========================================================
  //  CINEMATIC EFFECTS METADATA
  // ==========================================================
  static double getBlurIntensity(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.voidMatrix:
      case AppThemeMode.chromaStorm:
        return 8.0; // Sharp, electric feel
      case AppThemeMode.angelFall:
      case AppThemeMode.frozenDivine:
        return 30.0; // Dreamy soft blur
      default:
        return 20.0;
    }
  }

  static bool hasScanlines(AppThemeMode mode) {
    // CRT scanlines: Matrix, Chroma Storm (high-tech distortion)
    return mode == AppThemeMode.voidMatrix || mode == AppThemeMode.chromaStorm;
  }

  static double getGrainIntensity(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon:
        return 0.12; // Heavy noir grain
      case AppThemeMode.titanSoul:
        return 0.10; // War-worn grit
      case AppThemeMode.infernoGod:
        return 0.14; // Volcanic ash grain
      case AppThemeMode.cosmicRift:
        return 0.07; // Nebula dust
      case AppThemeMode.angelFall:
        return 0.04; // Soft celestial grain
      default:
        return 0.0;
    }
  }

  static double getEdgeGlowIntensity(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon:
        return 0.9; // intense crimson pulse
      case AppThemeMode.infernoGod:
        return 0.95; // lava-edge burn
      case AppThemeMode.chromaStorm:
        return 0.85; // electric edges
      case AppThemeMode.cosmicRift:
        return 0.80; // aurora ripple
      case AppThemeMode.voidMatrix:
        return 0.70; // matrix data edge
      case AppThemeMode.neonSerpent:
        return 0.75; // toxic neon edge
      case AppThemeMode.goldenRuler:
        return 0.65; // gold emboss
      case AppThemeMode.frozenDivine:
        return 0.60; // icy cold edge
      case AppThemeMode.titanSoul:
        return 0.55; // ember edge
      case AppThemeMode.angelFall:
        return 0.40;
      default:
        return 0.50;
    }
  }

  // ==========================================================
  //  SECONDARY GRADIENT ACCENT (used for chat bubble highlights)
  // ==========================================================
  static Color getBubbleAccent(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon:
        return const Color(0x33FF1744);
      case AppThemeMode.voidMatrix:
        return const Color(0x3300FF41);
      case AppThemeMode.angelFall:
        return const Color(0x33FF80AB);
      case AppThemeMode.titanSoul:
        return const Color(0x33FFAB40);
      case AppThemeMode.cosmicRift:
        return const Color(0x33EA80FC);
      case AppThemeMode.neonSerpent:
        return const Color(0x3339FF14);
      case AppThemeMode.chromaStorm:
        return const Color(0x33FF00FF);
      case AppThemeMode.goldenRuler:
        return const Color(0x33FFD700);
      case AppThemeMode.frozenDivine:
        return const Color(0x334FC3F7);
      case AppThemeMode.infernoGod:
        return const Color(0x33FF3D00);
      case AppThemeMode.shadowBlade:
        return const Color(0x33BDBDBD);
      case AppThemeMode.pinkChaos:
        return const Color(0x33FF4081);
      case AppThemeMode.abyssWatcher:
        return const Color(0x3326C6DA);
      case AppThemeMode.solarFlare:
        return const Color(0x33FF6D00);
      case AppThemeMode.demonSlayer:
        return const Color(0x3343A047);
      case AppThemeMode.midnightSilk:
        return const Color(0x33D4A5A5);
      case AppThemeMode.obsidianRose:
        return const Color(0x33EC407A);
      case AppThemeMode.onyxEmerald:
        return const Color(0x3326A69A);
      case AppThemeMode.velvetCrown:
        return const Color(0x33CE93D8);
      case AppThemeMode.platinumDawn:
        return const Color(0x33E0E0E0);
      case AppThemeMode.hypergate:
        return const Color(0x3340C4FF);
      case AppThemeMode.xenoCore:
        return const Color(0x331DE9B6);
      case AppThemeMode.dataStream:
        return const Color(0x3300E5FF);
      case AppThemeMode.gravityBend:
        return const Color(0x33FF6F00);
      case AppThemeMode.quartzPulse:
        return const Color(0x33D500F9);
      case AppThemeMode.midnightForest:
        return const Color(0x3381C784);
      case AppThemeMode.volcanicSea:
        return const Color(0x33FF7043);
      case AppThemeMode.stormDesert:
        return const Color(0x33BCAAA4);
      case AppThemeMode.sakuraNight:
        return const Color(0x33FFB7C5);
      case AppThemeMode.arcticSoul:
        return const Color(0x33B3E5FC);
    }
  }

  // ==========================================================
  //  PER-THEME COMPLETE VISUAL STYLE IDENTITY
  // ==========================================================
  static ThemeStyle getStyle(AppThemeMode mode) {
    switch (mode) {
      /// â”€â”€ BLOOD MOON â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Classic (user right, AI left)
      /// AppBar: Solid deep crimson bar with glow
      /// Bubbles: Sharp solid with left accent bar
      case AppThemeMode.bloodMoon:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.bebasNeue(
              fontSize: s * 1.1, color: c, letterSpacing: 1.2),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.press,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 6,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.6),
          hintText: "Speak to the darkness...",
          labelUser: "YOU",
          labelAI: "ZERO TWO",
        );

      /// â”€â”€ VOID MATRIX â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Terminal (full-width log, no bubbles)
      /// AppBar: Neon border, monospace status
      case AppThemeMode.voidMatrix:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sourceCodePro(
              fontSize: s * 0.95, color: c, letterSpacing: 0.5, height: 1.6),
          bubbleStyle: BubbleStyle.terminal,
          inputStyle: InputStyle.terminal,
          animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.8),
          hintText: "> type command_",
          labelUser: "USER",
          labelAI: "ZERO_TWO",
        );

      /// â”€â”€ ANGEL FALL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Centered (all bubbles centered on screen)
      /// AppBar: Minimal floating (no bar visible)
      case AppThemeMode.angelFall:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.playfairDisplay(
              fontSize: s, color: c, fontStyle: FontStyle.italic, height: 1.6),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.pill,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 32,
          sharpCorner: 32,
          leftAccentBar: false,
          borderColor: (p) => Colors.white.withOpacity(0.25),
          hintText: "Whisper something beautiful...",
          labelUser: "â™¡",
          labelAI: "Zero Two",
        );

      /// â”€â”€ TITAN SOUL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Wide card (full-width cards with role label)
      /// AppBar: Banner with large bold title
      case AppThemeMode.titanSoul:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.blackOpsOne(
              fontSize: s, color: c, letterSpacing: 0.8),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.banner,
          cornerRadius: 4,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.7),
          hintText: "FORGE YOUR MESSAGE...",
          labelUser: "WARRIOR",
          labelAI: "ZERO TWO",
        );

      /// â”€â”€ COSMIC RIFT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Classic with glowing outlined bubbles
      /// AppBar: Neon border with space font
      case AppThemeMode.cosmicRift:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.orbitron(
              fontSize: s * 0.9,
              color: c,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500),
          bubbleStyle: BubbleStyle.outlined,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 16,
          sharpCorner: 2,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.9),
          hintText: "TRANSMIT SIGNAL...",
          labelUser: "PILOT",
          labelAI: "ZERO TWO",
        );

      /// â”€â”€ NEON SERPENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Terminal (full-width chat log)
      /// AppBar: Neon border with toxic prompt style
      case AppThemeMode.neonSerpent:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sourceCodePro(
              fontSize: s * 0.95,
              color: c,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3),
          bubbleStyle: BubbleStyle.terminal,
          inputStyle: InputStyle.terminal,
          animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.85),
          hintText: "inject payload >",
          labelUser: "\$USER",
          labelAI: "\$SERPENT",
        );

      /// â”€â”€ CHROMA STORM â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Classic with glowing outlined bubbles
      /// AppBar: Solid glitch-colored bar
      case AppThemeMode.chromaStorm:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.rajdhani(
              fontSize: s * 1.05,
              color: c,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.outlined,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 8,
          sharpCorner: 0,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.9),
          hintText: "CHROMA SYNC...",
          labelUser: "HOST",
          labelAI: "ZERO TWO",
        );

      /// â”€â”€ GOLDEN RULER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Wide card (luxury scrolls, full-width)
      /// AppBar: Banner large serif title
      case AppThemeMode.goldenRuler:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.playfairDisplay(
              fontSize: s, color: c, fontWeight: FontWeight.w500, height: 1.55),
          bubbleStyle: BubbleStyle.luxury,
          inputStyle: InputStyle.luxury,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.banner,
          cornerRadius: 12,
          sharpCorner: 4,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.5),
          hintText: "Speak, Your Highness...",
          labelUser: "MY LIEGE",
          labelAI: "ZERO TWO",
        );

      /// â”€â”€ FROZEN DIVINE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Centered (soft ethereal floating center)
      /// AppBar: Minimal floating
      case AppThemeMode.frozenDivine:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.quicksand(
              fontSize: s, color: c, fontWeight: FontWeight.w500, height: 1.6),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.underline,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 24,
          sharpCorner: 4,
          leftAccentBar: false,
          borderColor: (p) => Colors.white.withOpacity(0.15),
          hintText: "Breathe into the silence...",
          labelUser: "Â·",
          labelAI: "Zero Two ~",
        );

      /// â”€â”€ INFERNO GOD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      /// Layout: Wide card (scorched proclamation cards)
      /// AppBar: Solid volcanic bar
      case AppThemeMode.infernoGod:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.bebasNeue(
              fontSize: s * 1.1, color: c, letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 2,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.75),
          hintText: "COMMAND THE FLAMES...",
          labelUser: "MORTAL",
          labelAI: "ZERO TWO",
        );
      // â”€â”€ TIER 3: ANIME LEGENDS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case AppThemeMode.shadowBlade:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.blackOpsOne(
              fontSize: s, color: c, letterSpacing: 1.0),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 2,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.5),
          hintText: "EXECUTE...",
          labelUser: "RONIN",
          labelAI: "ZERO TWO",
        );
      case AppThemeMode.pinkChaos:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.pacifico(fontSize: s * 0.9, color: c),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.pill,
          animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 28,
          sharpCorner: 4,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.4),
          hintText: "I love you~ â™¡",
          labelUser: "â™¡",
          labelAI: "Yuno",
        );
      case AppThemeMode.abyssWatcher:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.orbitron(
              fontSize: s * 0.88, color: c, letterSpacing: 1.2),
          bubbleStyle: BubbleStyle.outlined,
          inputStyle: InputStyle.underline,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 18,
          sharpCorner: 2,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.7),
          hintText: "From the depths...",
          labelUser: "DIVER",
          labelAI: "ZERO TWO",
        );
      case AppThemeMode.solarFlare:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.bebasNeue(
              fontSize: s * 1.1, color: c, letterSpacing: 1.8),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.press,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.banner,
          cornerRadius: 8,
          sharpCorner: 2,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.65),
          hintText: "BELIEVE IT!",
          labelUser: "SHINOBI",
          labelAI: "ZERO TWO",
        );
      case AppThemeMode.demonSlayer:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.rajdhani(
              fontSize: s * 1.05,
              color: c,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 4,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.8),
          hintText: "TOTAL CONCENTRATION...",
          labelUser: "SLAYER",
          labelAI: "ZERO TWO",
        );
      // â”€â”€ TIER 4: LUXURY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case AppThemeMode.midnightSilk:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.cormorantGaramond(
              fontSize: s * 1.1,
              color: c,
              fontStyle: FontStyle.italic,
              height: 1.6),
          bubbleStyle: BubbleStyle.luxury,
          inputStyle: InputStyle.luxury,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.banner,
          cornerRadius: 14,
          sharpCorner: 4,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.4),
          hintText: "Darling...",
          labelUser: "MY LOVE",
          labelAI: "Zero Two",
        );
      case AppThemeMode.obsidianRose:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.playfairDisplay(
              fontSize: s, color: c, fontWeight: FontWeight.w600, height: 1.55),
          bubbleStyle: BubbleStyle.luxury,
          inputStyle: InputStyle.pill,
          animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 20,
          sharpCorner: 4,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.5),
          hintText: "My rose...",
          labelUser: "BELOVED",
          labelAI: "ZERO TWO",
        );
      case AppThemeMode.onyxEmerald:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.josefinSans(
              fontSize: s,
              color: c,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600),
          bubbleStyle: BubbleStyle.outlined,
          inputStyle: InputStyle.underline,
          animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 6,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.75),
          hintText: "speak...",
          labelUser: "Â·",
          labelAI: "ZT ~",
        );
      case AppThemeMode.velvetCrown:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.cinzel(
              fontSize: s * 0.95, color: c, letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.luxury,
          inputStyle: InputStyle.luxury,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.banner,
          cornerRadius: 10,
          sharpCorner: 2,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.5),
          hintText: "By royal decree...",
          labelUser: "YOUR GRACE",
          labelAI: "ZERO TWO",
        );
      case AppThemeMode.platinumDawn:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.raleway(
              fontSize: s,
              color: c,
              fontWeight: FontWeight.w300,
              letterSpacing: 2.5),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.underline,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 20,
          sharpCorner: 20,
          leftAccentBar: false,
          borderColor: (p) => Colors.white.withOpacity(0.15),
          hintText: "      say something",
          labelUser: "",
          labelAI: "",
        );
      // â”€â”€ TIER 5: SCI-FI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case AppThemeMode.hypergate:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.exo2(
              fontSize: s,
              color: c,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0),
          bubbleStyle: BubbleStyle.outlined,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 12,
          sharpCorner: 2,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.9),
          hintText: "OPEN GATE...",
          labelUser: "ENTITY",
          labelAI: "ZERO TWO",
        );
      case AppThemeMode.xenoCore:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.audiowide(
              fontSize: s * 0.9, color: c, letterSpacing: 0.8),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.terminal,
          animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.85),
          hintText: ">XENO_INPUT:",
          labelUser: "\$HOST",
          labelAI: "\$XENO",
        );
      case AppThemeMode.dataStream:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sourceCodePro(
              fontSize: s * 0.95, color: c, letterSpacing: 0.8, height: 1.5),
          bubbleStyle: BubbleStyle.terminal,
          inputStyle: InputStyle.terminal,
          animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal,
          appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.9),
          hintText: ">> INPUT DATA",
          labelUser: "IN",
          labelAI: "OUT",
        );
      case AppThemeMode.gravityBend:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.orbitron(
              fontSize: s * 0.88,
              color: c,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.press,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 6,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.7),
          hintText: "WARP SIGNAL...",
          labelUser: "TRAVELER",
          labelAI: "ZERO TWO",
        );
      case AppThemeMode.quartzPulse:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.syncopate(
              fontSize: s * 0.85,
              color: c,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0),
          bubbleStyle: BubbleStyle.outlined,
          inputStyle: InputStyle.pill,
          animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 30,
          sharpCorner: 30,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.8),
          hintText: "resonate...",
          labelUser: "â—‡",
          labelAI: "ZERO TWO",
        );
      // â”€â”€ TIER 6: NATURE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case AppThemeMode.midnightForest:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.lora(
              fontSize: s, color: c, fontStyle: FontStyle.italic, height: 1.6),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.underline,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 16,
          sharpCorner: 4,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.3),
          hintText: "through the trees...",
          labelUser: "WANDERER",
          labelAI: "Zero Two",
        );
      case AppThemeMode.volcanicSea:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.bebasNeue(
              fontSize: s * 1.05, color: c, letterSpacing: 1.0),
          bubbleStyle: BubbleStyle.solid,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard,
          appBarStyle: AppBarStyle.banner,
          cornerRadius: 4,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.7),
          hintText: "FROM THE DEEP...",
          labelUser: "SAILOR",
          labelAI: "ZERO TWO",
        );
      case AppThemeMode.stormDesert:
        return ThemeStyle(
          font: (s, c) =>
              GoogleFonts.teko(fontSize: s * 1.1, color: c, letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.outlined,
          inputStyle: InputStyle.squareNeon,
          animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic,
          appBarStyle: AppBarStyle.solid,
          cornerRadius: 2,
          sharpCorner: 0,
          leftAccentBar: true,
          borderColor: (p) => p.withOpacity(0.6),
          hintText: "Dust on the wind...",
          labelUser: "NOMAD",
          labelAI: "ZERO TWO",
        );
      case AppThemeMode.sakuraNight:
        return ThemeStyle(
          font: (s, c) =>
              GoogleFonts.sawarabiGothic(fontSize: s, color: c, height: 1.7),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.pill,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 28,
          sharpCorner: 28,
          leftAccentBar: false,
          borderColor: (p) => p.withOpacity(0.25),
          hintText: "å¤œã«å’²ã...",
          labelUser: "èŠ±",
          labelAI: "ã‚¼ãƒ­ãƒ„ãƒ¼",
        );
      case AppThemeMode.arcticSoul:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.quicksand(
              fontSize: s,
              color: c,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.glassmorphic,
          inputStyle: InputStyle.underline,
          animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered,
          appBarStyle: AppBarStyle.minimal,
          cornerRadius: 22,
          sharpCorner: 22,
          leftAccentBar: false,
          borderColor: (p) => Colors.white.withOpacity(0.12),
          hintText: "whisper to the ice...",
          labelUser: "â„",
          labelAI: "Zero Two ~",
        );
    }
  }
}
