import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
//   THEME STYLE ENUMS — Drive per-theme visual identity
// ============================================================

enum BubbleStyle {
  glassmorphic,
  terminal,
  outlined,
  solid,
  luxury,
}

enum InputStyle {
  pill,
  squareNeon,
  underline,
  terminal,
  luxury,
}

enum AnimStyle {
  elastic,
  slideSide,
  glitch,
  fadeZoom,
  press,
}

enum LayoutMode {
  classic,
  terminal,
  centered,
  wideCard,
}

enum AppBarStyle {
  transparent,
  neonBorder,
  solid,
  minimal,
  banner,
}

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

enum AppThemeMode {
  // ── TIER 1: ICONIC ────────────────────────────────────────
  bloodMoon,
  voidMatrix,
  angelFall,
  titanSoul,
  cosmicRift,

  // ── TIER 2: ULTRA-PREMIUM ─────────────────────────────────
  neonSerpent,
  chromaStorm,
  goldenRuler,
  frozenDivine,
  infernoGod,

  // ── TIER 3: ANIME LEGENDS ─────────────────────────────────
  shadowBlade,
  pinkChaos,
  abyssWatcher,
  solarFlare,
  demonSlayer,

  // ── TIER 4: LUXURY & FASHION ──────────────────────────────
  midnightSilk,
  obsidianRose,
  onyxEmerald,
  velvetCrown,
  platinumDawn,

  // ── TIER 5: SCI-FI ────────────────────────────────────────
  hypergate,
  xenoCore,
  dataStream,
  gravityBend,
  quartzPulse,

  // ── TIER 6: NATURE ────────────────────────────────────────
  midnightForest,
  volcanicSea,
  stormDesert,
  sakuraNight,
  arcticSoul,

  // ── TIER 7: ETHEREAL (NEW) ────────────────────────────────
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
  rain,
}

class AppThemes {
  static Color? _customAccentColor;
  static Color? get customAccentColor => _customAccentColor;
  static set customAccentColor(Color? c) {
    if (_customAccentColor == c) return;
    _customAccentColor = c;
    _styleCache.clear(); // force style rebuild with new accent colour
  }


  static ThemeData getRawTheme(AppThemeMode mode) {
    final Color? old = _customAccentColor;
    _customAccentColor = null; // bypass setter to skip cache clear
    final ThemeData t = getTheme(mode);
    _customAccentColor = old;  // restore without triggering cache clear
    return t;
  }


  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon:
        return _build(primary: const Color(0xFFFF1744), secondary: const Color(0xFF880E4F), bg: const Color(0xFF0A0003), accent: const Color(0xFFFF4081));
      case AppThemeMode.voidMatrix:
        return _build(primary: const Color(0xFF00FF41), secondary: const Color(0xFF00E676), bg: const Color(0xFF000A00), accent: const Color(0xFF69FF47));
      case AppThemeMode.angelFall:
        return _build(primary: const Color(0xFFFFCDD2), secondary: const Color(0xFFF8BBD0), bg: const Color(0xFF100810), accent: const Color(0xFFFF80AB));
      case AppThemeMode.titanSoul:
        return _build(primary: const Color(0xFFFFAB40), secondary: const Color(0xFFBF360C), bg: const Color(0xFF0C0600), accent: const Color(0xFFFFCC02));
      case AppThemeMode.cosmicRift:
        return _build(primary: const Color(0xFFEA80FC), secondary: const Color(0xFF7C4DFF), bg: const Color(0xFF040008), accent: const Color(0xFF00E5FF));
      case AppThemeMode.neonSerpent:
        return _build(primary: const Color(0xFF39FF14), secondary: const Color(0xFF00C853), bg: const Color(0xFF010D06), accent: const Color(0xFFB2FF59));
      case AppThemeMode.chromaStorm:
        return _build(primary: const Color(0xFFFF00FF), secondary: const Color(0xFF00E5FF), bg: const Color(0xFF05000F), accent: const Color(0xFFFF4081));
      case AppThemeMode.goldenRuler:
        return _build(primary: const Color(0xFFFFD700), secondary: const Color(0xFFFF8F00), bg: const Color(0xFF050300), accent: const Color(0xFFFFF9C4));
      case AppThemeMode.frozenDivine:
        return _build(primary: const Color(0xFFB3E5FC), secondary: const Color(0xFF4FC3F7), bg: const Color(0xFF00050F), accent: const Color(0xFFE1F5FE));
      case AppThemeMode.infernoGod:
        return _build(primary: const Color(0xFFFF3D00), secondary: const Color(0xFFBF360C), bg: const Color(0xFF060000), accent: const Color(0xFFFF6D00));
      case AppThemeMode.shadowBlade:
        return _build(primary: const Color(0xFFBDBDBD), secondary: const Color(0xFF616161), bg: const Color(0xFF030303), accent: const Color(0xFFEEEEEE));
      case AppThemeMode.pinkChaos:
        return _build(primary: const Color(0xFFFF4081), secondary: const Color(0xFFAD1457), bg: const Color(0xFF0D0009), accent: const Color(0xFFFF80AB));
      case AppThemeMode.abyssWatcher:
        return _build(primary: const Color(0xFF26C6DA), secondary: const Color(0xFF006064), bg: const Color(0xFF00050F), accent: const Color(0xFF80DEEA));
      case AppThemeMode.solarFlare:
        return _build(primary: const Color(0xFFFF6D00), secondary: const Color(0xFFBF360C), bg: const Color(0xFF0F0500), accent: const Color(0xFFFFAB40));
      case AppThemeMode.demonSlayer:
        return _build(primary: const Color(0xFF43A047), secondary: const Color(0xFF1B5E20), bg: const Color(0xFF020D02), accent: const Color(0xFFA5D6A7));
      case AppThemeMode.midnightSilk:
        return _build(primary: const Color(0xFFD4A5A5), secondary: const Color(0xFF1A237E), bg: const Color(0xFF01010D), accent: const Color(0xFFE8C8C8));
      case AppThemeMode.obsidianRose:
        return _build(primary: const Color(0xFFEC407A), secondary: const Color(0xFF880E4F), bg: const Color(0xFF060208), accent: const Color(0xFFF48FB1));
      case AppThemeMode.onyxEmerald:
        return _build(primary: const Color(0xFF26A69A), secondary: const Color(0xFF00695C), bg: const Color(0xFF01080A), accent: const Color(0xFF80CBC4));
      case AppThemeMode.velvetCrown:
        return _build(primary: const Color(0xFFCE93D8), secondary: const Color(0xFF6A1B9A), bg: const Color(0xFF080010), accent: const Color(0xFFFFD54F));
      case AppThemeMode.platinumDawn:
        return _build(primary: const Color(0xFFE0E0E0), secondary: const Color(0xFF9E9E9E), bg: const Color(0xFF040404), accent: const Color(0xFFFFCCBC));
      case AppThemeMode.hypergate:
        return _build(primary: const Color(0xFF40C4FF), secondary: const Color(0xFF0091EA), bg: const Color(0xFF000A14), accent: const Color(0xFFFFFFFF));
      case AppThemeMode.xenoCore:
        return _build(primary: const Color(0xFF1DE9B6), secondary: const Color(0xFF00BFA5), bg: const Color(0xFF00050A), accent: const Color(0xFFA7FFEB));
      case AppThemeMode.dataStream:
        return _build(primary: const Color(0xFF00E5FF), secondary: const Color(0xFF006064), bg: const Color(0xFF000B0F), accent: const Color(0xFF84FFFF));
      case AppThemeMode.gravityBend:
        return _build(primary: const Color(0xFFFF6F00), secondary: const Color(0xFF311B92), bg: const Color(0xFF040010), accent: const Color(0xFFFFD180));
      case AppThemeMode.quartzPulse:
        return _build(primary: const Color(0xFFD500F9), secondary: const Color(0xFF6200EA), bg: const Color(0xFF060008), accent: const Color(0xFFEA80FC));
      case AppThemeMode.midnightForest:
        return _build(primary: const Color(0xFF81C784), secondary: const Color(0xFF2E7D32), bg: const Color(0xFF010A01), accent: const Color(0xFFC8E6C9));
      case AppThemeMode.volcanicSea:
        return _build(primary: const Color(0xFFFF7043), secondary: const Color(0xFF01579B), bg: const Color(0xFF030712), accent: const Color(0xFFFF8A65));
      case AppThemeMode.stormDesert:
        return _build(primary: const Color(0xFFBCAAA4), secondary: const Color(0xFF4E342E), bg: const Color(0xFF0C0804), accent: const Color(0xFFF5F5DC));
      case AppThemeMode.sakuraNight:
        return _build(primary: const Color(0xFFFFB7C5), secondary: const Color(0xFF880E4F), bg: const Color(0xFF040008), accent: const Color(0xFFFFE0E6));
      case AppThemeMode.arcticSoul:
        return _build(primary: const Color(0xFFB3E5FC), secondary: const Color(0xFF80D8FF), bg: const Color(0xFF000508), accent: const Color(0xFFE0F7FA));
      // ── TIER 7: ETHEREAL ──────────────────────────────────
      case AppThemeMode.amethystDream:
        return _build(primary: const Color(0xFF9966CC), secondary: const Color(0xFFDB7093), bg: const Color(0xFF08040C), accent: const Color(0xFFCDA4DE));
      case AppThemeMode.titaniumFrost:
        return _build(primary: const Color(0xFF878787), secondary: const Color(0xFF4FC3F7), bg: const Color(0xFF060608), accent: const Color(0xFFB0C4DE));
      case AppThemeMode.sunsetRider:
        return _build(primary: const Color(0xFFFF6347), secondary: const Color(0xFF7B2D8E), bg: const Color(0xFF0C0404), accent: const Color(0xFFFF8C00));
      case AppThemeMode.midnightRaven:
        return _build(primary: const Color(0xFF1A1A2E), secondary: const Color(0xFF16213E), bg: const Color(0xFF020204), accent: const Color(0xFF0F3460));
      case AppThemeMode.electricLime:
        return _build(primary: const Color(0xFFBFFF00), secondary: const Color(0xFF00FF41), bg: const Color(0xFF040800), accent: const Color(0xFFADFF2F));
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

  static List<Color> getGradient(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon:
        // Deep obsidian → blood crimson → dark rose → purple shadow → void
        return [const Color(0xFF0A0010), const Color(0xFF3D0014), const Color(0xFF6B0020), const Color(0xFF1A0030), const Color(0xFF000006)];
      case AppThemeMode.voidMatrix:
        // Terminal black → matrix green glow → dark cyan → void
        return [const Color(0xFF000800), const Color(0xFF003300), const Color(0xFF00220F), const Color(0xFF001A1A), const Color(0xFF000303)];
      case AppThemeMode.angelFall:
        // Ink → deep rose → lavender mist → twilight indigo → black
        return [const Color(0xFF0A0010), const Color(0xFF3D1020), const Color(0xFF6B204A), const Color(0xFF2A0A3A), const Color(0xFF050003)];
      case AppThemeMode.titanSoul:
        // Charcoal → burnt amber → deep orange → war crimson → shadow
        return [const Color(0xFF0C0800), const Color(0xFF3D1A00), const Color(0xFF5E2800), const Color(0xFF3D0A00), const Color(0xFF0A0200)];
      case AppThemeMode.cosmicRift:
        // Singularity → deep violet → aurora teal → indigo plasma → void
        return [const Color(0xFF04000A), const Color(0xFF1A0060), const Color(0xFF003060), const Color(0xFF200040), const Color(0xFF02000F)];
      case AppThemeMode.neonSerpent:
        // Void → toxic jade → serpent teal → electric green → shadow
        return [const Color(0xFF000A02), const Color(0xFF00400F), const Color(0xFF003020), const Color(0xFF0A4000), const Color(0xFF000A00)];
      case AppThemeMode.chromaStorm:
        // Black → magenta surge → electric cyan → violet core → void
        return [const Color(0xFF050005), const Color(0xFF400020), const Color(0xFF002040), const Color(0xFF280050), const Color(0xFF020005)];
      case AppThemeMode.goldenRuler:
        // Ink → 24k gold → burnished amber → cognac → shadow
        return [const Color(0xFF080400), const Color(0xFF3D2600), const Color(0xFF604000), const Color(0xFF3D1800), const Color(0xFF0A0500)];
      case AppThemeMode.frozenDivine:
        // Abyss → glacial blue → arctic teal → ice violet → deep
        return [const Color(0xFF00020A), const Color(0xFF003060), const Color(0xFF005050), const Color(0xFF100040), const Color(0xFF000308)];
      case AppThemeMode.infernoGod:
        // Obsidian → volcanic red → lava orange → deep crimson → ash
        return [const Color(0xFF050000), const Color(0xFF3D0000), const Color(0xFF5E1400), const Color(0xFF3D0600), const Color(0xFF0A0000)];
      case AppThemeMode.shadowBlade:
        // Pure void → slate → steel → deep gunmetal → black
        return [const Color(0xFF060606), const Color(0xFF1A1A1A), const Color(0xFF282828), const Color(0xFF141414), const Color(0xFF020202)];
      case AppThemeMode.pinkChaos:
        // Deep void → magenta burst → hot pink → lavender → shadow
        return [const Color(0xFF080006), const Color(0xFF3D001C), const Color(0xFF5E0030), const Color(0xFF280030), const Color(0xFF080006)];
      case AppThemeMode.abyssWatcher:
        // Abyss → navy deep → teal cold → midnight blue → void
        return [const Color(0xFF000208), const Color(0xFF001830), const Color(0xFF003040), const Color(0xFF001828), const Color(0xFF000108)];
      case AppThemeMode.solarFlare:
        // Coal → deep orange → flame red → amber glow → shadow
        return [const Color(0xFF0A0400), const Color(0xFF3D1400), const Color(0xFF5E2000), const Color(0xFF3D0A00), const Color(0xFF080200)];
      case AppThemeMode.demonSlayer:
        // Forest shadow → hunting green → jade → dark moss → void
        return [const Color(0xFF010600), const Color(0xFF0A2808), const Color(0xFF143A10), const Color(0xFF0A2000), const Color(0xFF020802)];
      case AppThemeMode.midnightSilk:
        // Ink navy → deep indigo → rose shimmer → midnight → shadow
        return [const Color(0xFF02020C), const Color(0xFF0A0A30), const Color(0xFF3A102A), const Color(0xFF0A0820), const Color(0xFF020208)];
      case AppThemeMode.obsidianRose:
        // Matte black → deep rose → magenta bloom → dark plum → void
        return [const Color(0xFF050005), const Color(0xFF2A0010), const Color(0xFF50001E), const Color(0xFF280028), const Color(0xFF050005)];
      case AppThemeMode.onyxEmerald:
        // Void → gunmetal → emerald jewel → teal crystal → dark
        return [const Color(0xFF010506), const Color(0xFF001A14), const Color(0xFF003828), const Color(0xFF001A20), const Color(0xFF010406)];
      case AppThemeMode.velvetCrown:
        // Deep black → royal purple → velvet indigo → gold shimmer → void
        return [const Color(0xFF050008), const Color(0xFF18003A), const Color(0xFF300058), const Color(0xFF200030), const Color(0xFF060008)];
      case AppThemeMode.platinumDawn:
        // Pure black → charcoal → steel grey → twilight peach → dark
        return [const Color(0xFF040404), const Color(0xFF141414), const Color(0xFF242424), const Color(0xFF1C1010), const Color(0xFF060404)];
      case AppThemeMode.hypergate:
        // Dark space → electric blue → portal cyan → deep navy → void
        return [const Color(0xFF000508), const Color(0xFF001A3D), const Color(0xFF003A5E), const Color(0xFF001828), const Color(0xFF000308)];
      case AppThemeMode.xenoCore:
        // Black → alien teal → biolume turquoise → dark verde → void
        return [const Color(0xFF000402), const Color(0xFF002818), const Color(0xFF004028), const Color(0xFF002018), const Color(0xFF000402)];
      case AppThemeMode.dataStream:
        // Terminal black → data cyan → aqua stream → dark teal → void
        return [const Color(0xFF000408), const Color(0xFF001A20), const Color(0xFF003040), const Color(0xFF001820), const Color(0xFF000408)];
      case AppThemeMode.gravityBend:
        // Dark space → deep indigo → gravity orange halo → warp purple → void
        return [const Color(0xFF030010), const Color(0xFF100030), const Color(0xFF2A000A), const Color(0xFF180040), const Color(0xFF040010)];
      case AppThemeMode.quartzPulse:
        // Void → violet surge → magenta crystal → deep purple → black
        return [const Color(0xFF040006), const Color(0xFF180028), const Color(0xFF300050), const Color(0xFF200038), const Color(0xFF040006)];
      case AppThemeMode.midnightForest:
        // Forest floor → deep pine → mossy teal → moonlit navy → shadow
        return [const Color(0xFF010800), const Color(0xFF033010), const Color(0xFF054020), const Color(0xFF022014), const Color(0xFF010600)];
      case AppThemeMode.volcanicSea:
        // Deep ocean → navy abyss → lava seam → fiery orange → dark
        return [const Color(0xFF02040C), const Color(0xFF041828), const Color(0xFF101A18), const Color(0xFF2A0800), const Color(0xFF040208)];
      case AppThemeMode.stormDesert:
        // Dark sand → storm amber → dust rose → lightning grey → shadow
        return [const Color(0xFF0C0A06), const Color(0xFF281A08), const Color(0xFF341E0A), const Color(0xFF201418), const Color(0xFF0A0806)];
      case AppThemeMode.sakuraNight:
        // Ink night → deep sakura → blush pink → twilight indigo → void
        return [const Color(0xFF040006), const Color(0xFF200010), const Color(0xFF400020), const Color(0xFF200030), const Color(0xFF040006)];
      case AppThemeMode.arcticSoul:
        // Polar dark → deep arctic → ice blue → aurora teal → shadow
        return [const Color(0xFF000308), const Color(0xFF001828), const Color(0xFF003040), const Color(0xFF001A30), const Color(0xFF000208)];
      // ── TIER 7: ETHEREAL ──────────────────────────────────
      case AppThemeMode.amethystDream:
        // Velvet night → amethyst → deep rose → violet mist → shadow
        return [const Color(0xFF050008), const Color(0xFF1A0040), const Color(0xFF3A1060), const Color(0xFF280828), const Color(0xFF050006)];
      case AppThemeMode.titaniumFrost:
        // Dark steel → titanium blue → frost cyan → silver shimmer → void
        return [const Color(0xFF030308), const Color(0xFF101020), const Color(0xFF102030), const Color(0xFF181828), const Color(0xFF040408)];
      case AppThemeMode.sunsetRider:
        // Night sky → deep crimson → sunset orange → violet horizon → shadow
        return [const Color(0xFF050002), const Color(0xFF300800), const Color(0xFF501800), const Color(0xFF300040), const Color(0xFF040002)];
      case AppThemeMode.midnightRaven:
        // Deep void → ink navy → raven blue → charcoal → pitch black
        return [const Color(0xFF010106), const Color(0xFF060614), const Color(0xFF0A0A20), const Color(0xFF080818), const Color(0xFF020208)];
      case AppThemeMode.electricLime:
        // Void → toxic green → electric lime → neon yellow → dark
        return [const Color(0xFF020600), const Color(0xFF082000), const Color(0xFF103800), const Color(0xFF0A2800), const Color(0xFF020600)];
    }
  }


  static ParticleType getParticleType(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon: return ParticleType.sakura;
      case AppThemeMode.voidMatrix: return ParticleType.rain;
      case AppThemeMode.angelFall: return ParticleType.sakura;
      case AppThemeMode.titanSoul: return ParticleType.embers;
      case AppThemeMode.cosmicRift: return ParticleType.stars;
      case AppThemeMode.neonSerpent: return ParticleType.bubbles;
      case AppThemeMode.chromaStorm: return ParticleType.lines;
      case AppThemeMode.goldenRuler: return ParticleType.circles;
      case AppThemeMode.frozenDivine: return ParticleType.snow;
      case AppThemeMode.infernoGod: return ParticleType.embers;
      case AppThemeMode.shadowBlade: return ParticleType.lines;
      case AppThemeMode.pinkChaos: return ParticleType.sakura;
      case AppThemeMode.abyssWatcher: return ParticleType.bubbles;
      case AppThemeMode.solarFlare: return ParticleType.embers;
      case AppThemeMode.demonSlayer: return ParticleType.leaves;
      case AppThemeMode.midnightSilk: return ParticleType.circles;
      case AppThemeMode.obsidianRose: return ParticleType.sakura;
      case AppThemeMode.onyxEmerald: return ParticleType.bubbles;
      case AppThemeMode.velvetCrown: return ParticleType.stars;
      case AppThemeMode.platinumDawn: return ParticleType.circles;
      case AppThemeMode.hypergate: return ParticleType.lines;
      case AppThemeMode.xenoCore: return ParticleType.bubbles;
      case AppThemeMode.dataStream: return ParticleType.rain;
      case AppThemeMode.gravityBend: return ParticleType.squares;
      case AppThemeMode.quartzPulse: return ParticleType.stars;
      case AppThemeMode.midnightForest: return ParticleType.leaves;
      case AppThemeMode.volcanicSea: return ParticleType.embers;
      case AppThemeMode.stormDesert: return ParticleType.lines;
      case AppThemeMode.sakuraNight: return ParticleType.sakura;
      case AppThemeMode.arcticSoul: return ParticleType.snow;
      case AppThemeMode.amethystDream: return ParticleType.stars;
      case AppThemeMode.titaniumFrost: return ParticleType.snow;
      case AppThemeMode.sunsetRider: return ParticleType.embers;
      case AppThemeMode.midnightRaven: return ParticleType.lines;
      case AppThemeMode.electricLime: return ParticleType.rain;
    }
  }

  static String getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon: return "Blood Moon";
      case AppThemeMode.voidMatrix: return "Void Matrix";
      case AppThemeMode.angelFall: return "Angel Fall";
      case AppThemeMode.titanSoul: return "Titan Soul";
      case AppThemeMode.cosmicRift: return "Cosmic Rift";
      case AppThemeMode.neonSerpent: return "Neon Serpent";
      case AppThemeMode.chromaStorm: return "Chroma Storm";
      case AppThemeMode.goldenRuler: return "Golden Ruler";
      case AppThemeMode.frozenDivine: return "Frozen Divine";
      case AppThemeMode.infernoGod: return "Inferno God";
      case AppThemeMode.shadowBlade: return "Shadow Blade";
      case AppThemeMode.pinkChaos: return "Pink Chaos";
      case AppThemeMode.abyssWatcher: return "Abyss Watcher";
      case AppThemeMode.solarFlare: return "Solar Flare";
      case AppThemeMode.demonSlayer: return "Demon Slayer";
      case AppThemeMode.midnightSilk: return "Midnight Silk";
      case AppThemeMode.obsidianRose: return "Obsidian Rose";
      case AppThemeMode.onyxEmerald: return "Onyx Emerald";
      case AppThemeMode.velvetCrown: return "Velvet Crown";
      case AppThemeMode.platinumDawn: return "Platinum Dawn";
      case AppThemeMode.hypergate: return "Hypergate";
      case AppThemeMode.xenoCore: return "Xeno Core";
      case AppThemeMode.dataStream: return "Data Stream";
      case AppThemeMode.gravityBend: return "Gravity Bend";
      case AppThemeMode.quartzPulse: return "Quartz Pulse";
      case AppThemeMode.midnightForest: return "Midnight Forest";
      case AppThemeMode.volcanicSea: return "Volcanic Sea";
      case AppThemeMode.stormDesert: return "Storm Desert";
      case AppThemeMode.sakuraNight: return "Sakura Night";
      case AppThemeMode.arcticSoul: return "Arctic Soul";
      case AppThemeMode.amethystDream: return "Amethyst Dream";
      case AppThemeMode.titaniumFrost: return "Titanium Frost";
      case AppThemeMode.sunsetRider: return "Sunset Rider";
      case AppThemeMode.midnightRaven: return "Midnight Raven";
      case AppThemeMode.electricLime: return "Electric Lime";
    }
  }

  static double getBlurIntensity(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.voidMatrix:
      case AppThemeMode.chromaStorm:
        return 8.0;
      case AppThemeMode.angelFall:
      case AppThemeMode.frozenDivine:
      case AppThemeMode.amethystDream:
        return 30.0;
      default:
        return 20.0;
    }
  }

  static bool hasScanlines(AppThemeMode mode) {
    return mode == AppThemeMode.voidMatrix || mode == AppThemeMode.chromaStorm || mode == AppThemeMode.electricLime;
  }

  static double getGrainIntensity(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon: return 0.12;
      case AppThemeMode.titanSoul: return 0.10;
      case AppThemeMode.infernoGod: return 0.14;
      case AppThemeMode.cosmicRift: return 0.07;
      case AppThemeMode.angelFall: return 0.04;
      default: return 0.0;
    }
  }

  static double getEdgeGlowIntensity(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon: return 0.9;
      case AppThemeMode.infernoGod: return 0.95;
      case AppThemeMode.chromaStorm: return 0.85;
      case AppThemeMode.cosmicRift: return 0.80;
      case AppThemeMode.voidMatrix: return 0.70;
      case AppThemeMode.neonSerpent: return 0.75;
      case AppThemeMode.goldenRuler: return 0.65;
      case AppThemeMode.frozenDivine: return 0.60;
      case AppThemeMode.titanSoul: return 0.55;
      case AppThemeMode.angelFall: return 0.40;
      default: return 0.50;
    }
  }

  static Color getBubbleAccent(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.bloodMoon: return const Color(0x33FF1744);
      case AppThemeMode.voidMatrix: return const Color(0x3300FF41);
      case AppThemeMode.angelFall: return const Color(0x33FF80AB);
      case AppThemeMode.titanSoul: return const Color(0x33FFAB40);
      case AppThemeMode.cosmicRift: return const Color(0x33EA80FC);
      case AppThemeMode.neonSerpent: return const Color(0x3339FF14);
      case AppThemeMode.chromaStorm: return const Color(0x33FF00FF);
      case AppThemeMode.goldenRuler: return const Color(0x33FFD700);
      case AppThemeMode.frozenDivine: return const Color(0x334FC3F7);
      case AppThemeMode.infernoGod: return const Color(0x33FF3D00);
      case AppThemeMode.shadowBlade: return const Color(0x33BDBDBD);
      case AppThemeMode.pinkChaos: return const Color(0x33FF4081);
      case AppThemeMode.abyssWatcher: return const Color(0x3326C6DA);
      case AppThemeMode.solarFlare: return const Color(0x33FF6D00);
      case AppThemeMode.demonSlayer: return const Color(0x3343A047);
      case AppThemeMode.midnightSilk: return const Color(0x33D4A5A5);
      case AppThemeMode.obsidianRose: return const Color(0x33EC407A);
      case AppThemeMode.onyxEmerald: return const Color(0x3326A69A);
      case AppThemeMode.velvetCrown: return const Color(0x33CE93D8);
      case AppThemeMode.platinumDawn: return const Color(0x33E0E0E0);
      case AppThemeMode.hypergate: return const Color(0x3340C4FF);
      case AppThemeMode.xenoCore: return const Color(0x331DE9B6);
      case AppThemeMode.dataStream: return const Color(0x3300E5FF);
      case AppThemeMode.gravityBend: return const Color(0x33FF6F00);
      case AppThemeMode.quartzPulse: return const Color(0x33D500F9);
      case AppThemeMode.midnightForest: return const Color(0x3381C784);
      case AppThemeMode.volcanicSea: return const Color(0x33FF7043);
      case AppThemeMode.stormDesert: return const Color(0x33BCAAA4);
      case AppThemeMode.sakuraNight: return const Color(0x33FFB7C5);
      case AppThemeMode.arcticSoul: return const Color(0x33B3E5FC);
      case AppThemeMode.amethystDream: return const Color(0x339966CC);
      case AppThemeMode.titaniumFrost: return const Color(0x33878787);
      case AppThemeMode.sunsetRider: return const Color(0x33FF6347);
      case AppThemeMode.midnightRaven: return const Color(0x331A1A2E);
      case AppThemeMode.electricLime: return const Color(0x33BFFF00);
    }
  }

  static ThemeStyle getStyle(AppThemeMode mode) {
    return _styleCache[mode] ??= _buildStyle(mode);
  }

  static final Map<AppThemeMode, ThemeStyle> _styleCache = {};

  // Called at most once per theme mode thanks to the cache above.
  static ThemeStyle _buildStyle(AppThemeMode mode) {
    switch (mode) {

      case AppThemeMode.bloodMoon:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.exo2(fontSize: s, color: c, fontWeight: FontWeight.w700, letterSpacing: 1.0),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.solid,
          cornerRadius: 6, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.6),
          hintText: "Speak to the darkness...", labelUser: "YOU", labelAI: "ZERO TWO",
        );
      case AppThemeMode.voidMatrix:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sourceCodePro(fontSize: s * 0.95, color: c, letterSpacing: 0.5, height: 1.6),
          bubbleStyle: BubbleStyle.terminal, inputStyle: InputStyle.terminal, animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.8),
          hintText: "> type command_", labelUser: "USER", labelAI: "ZERO_TWO",
        );
      case AppThemeMode.angelFall:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.playfairDisplay(fontSize: s, color: c, fontStyle: FontStyle.italic, height: 1.6),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.pill, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 32, sharpCorner: 32, leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.25),
          hintText: "Whisper something beautiful...", labelUser: "♡", labelAI: "Zero Two",
        );
      case AppThemeMode.titanSoul:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.blackOpsOne(fontSize: s, color: c, letterSpacing: 0.8),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.banner,
          cornerRadius: 4, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.7),
          hintText: "FORGE YOUR MESSAGE...", labelUser: "WARRIOR", labelAI: "ZERO TWO",
        );
      case AppThemeMode.cosmicRift:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.orbitron(fontSize: s * 0.9, color: c, letterSpacing: 1.5, fontWeight: FontWeight.w500),
          bubbleStyle: BubbleStyle.outlined, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 16, sharpCorner: 2, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.9),
          hintText: "TRANSMIT SIGNAL...", labelUser: "PILOT", labelAI: "ZERO TWO",
        );
      case AppThemeMode.neonSerpent:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sourceCodePro(fontSize: s * 0.95, color: c, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          bubbleStyle: BubbleStyle.terminal, inputStyle: InputStyle.terminal, animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.85),
          hintText: "inject payload >", labelUser: "\$USER", labelAI: "\$SERPENT",
        );
      case AppThemeMode.chromaStorm:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.rajdhani(fontSize: s * 1.05, color: c, fontWeight: FontWeight.w600, letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.outlined, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.solid,
          cornerRadius: 8, sharpCorner: 0, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.9),
          hintText: "CHROMA SYNC...", labelUser: "HOST", labelAI: "ZERO TWO",
        );
      case AppThemeMode.goldenRuler:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.playfairDisplay(fontSize: s, color: c, fontWeight: FontWeight.w500, height: 1.55),
          bubbleStyle: BubbleStyle.luxury, inputStyle: InputStyle.luxury, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.banner,
          cornerRadius: 12, sharpCorner: 4, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.5),
          hintText: "Speak, Your Highness...", labelUser: "MY LIEGE", labelAI: "ZERO TWO",
        );
      case AppThemeMode.frozenDivine:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.quicksand(fontSize: s, color: c, fontWeight: FontWeight.w500, height: 1.6),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.underline, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 24, sharpCorner: 4, leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.15),
          hintText: "Breathe into the silence...", labelUser: "·", labelAI: "Zero Two ~",
        );
      case AppThemeMode.infernoGod:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.notoSans(fontSize: s, color: c, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.3),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.solid,
          cornerRadius: 2, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.75),
          hintText: "COMMAND THE FLAMES...", labelUser: "MORTAL", labelAI: "ZERO TWO",
        );
      case AppThemeMode.shadowBlade:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.rajdhani(fontSize: s * 1.05, color: c, fontWeight: FontWeight.w800, letterSpacing: 1.0),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.solid,
          cornerRadius: 2, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.5),
          hintText: "EXECUTE...", labelUser: "RONIN", labelAI: "ZERO TWO",
        );
      case AppThemeMode.pinkChaos:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.pacifico(fontSize: s * 0.9, color: c),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.pill, animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 28, sharpCorner: 4, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.4),
          hintText: "I love you~ ♡", labelUser: "♡", labelAI: "Yuno",
        );
      case AppThemeMode.abyssWatcher:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.orbitron(fontSize: s * 0.88, color: c, letterSpacing: 1.2),
          bubbleStyle: BubbleStyle.outlined, inputStyle: InputStyle.underline, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 18, sharpCorner: 2, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.7),
          hintText: "From the depths...", labelUser: "DIVER", labelAI: "ZERO TWO",
        );
      case AppThemeMode.solarFlare:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.exo2(fontSize: s, color: c, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.banner,
          cornerRadius: 8, sharpCorner: 2, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.65),
          hintText: "BELIEVE IT!", labelUser: "SHINOBI", labelAI: "ZERO TWO",
        );
      case AppThemeMode.demonSlayer:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.rajdhani(fontSize: s * 1.05, color: c, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.solid,
          cornerRadius: 4, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.8),
          hintText: "TOTAL CONCENTRATION...", labelUser: "SLAYER", labelAI: "ZERO TWO",
        );
      case AppThemeMode.midnightSilk:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.cormorantGaramond(fontSize: s * 1.1, color: c, fontStyle: FontStyle.italic, height: 1.6),
          bubbleStyle: BubbleStyle.luxury, inputStyle: InputStyle.luxury, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.banner,
          cornerRadius: 14, sharpCorner: 4, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.4),
          hintText: "Darling...", labelUser: "MY LOVE", labelAI: "Zero Two",
        );
      case AppThemeMode.obsidianRose:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.playfairDisplay(fontSize: s, color: c, fontWeight: FontWeight.w600, height: 1.55),
          bubbleStyle: BubbleStyle.luxury, inputStyle: InputStyle.pill, animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.solid,
          cornerRadius: 20, sharpCorner: 4, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.5),
          hintText: "My rose...", labelUser: "BELOVED", labelAI: "ZERO TWO",
        );
      case AppThemeMode.onyxEmerald:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.josefinSans(fontSize: s, color: c, letterSpacing: 2.0, fontWeight: FontWeight.w600),
          bubbleStyle: BubbleStyle.outlined, inputStyle: InputStyle.underline, animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 6, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.75),
          hintText: "speak...", labelUser: "·", labelAI: "ZT ~",
        );
      case AppThemeMode.velvetCrown:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.cormorantGaramond(fontSize: s * 1.0, color: c, fontWeight: FontWeight.w600, letterSpacing: 1.4),
          bubbleStyle: BubbleStyle.luxury, inputStyle: InputStyle.luxury, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.banner,
          cornerRadius: 10, sharpCorner: 2, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.5),
          hintText: "By royal decree...", labelUser: "YOUR GRACE", labelAI: "ZERO TWO",
        );
      case AppThemeMode.platinumDawn:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.raleway(fontSize: s, color: c, fontWeight: FontWeight.w300, letterSpacing: 2.5),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.underline, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 20, sharpCorner: 20, leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.15),
          hintText: "      say something", labelUser: "", labelAI: "",
        );
      case AppThemeMode.hypergate:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.exo2(fontSize: s, color: c, fontWeight: FontWeight.w600, letterSpacing: 1.0),
          bubbleStyle: BubbleStyle.outlined, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 12, sharpCorner: 2, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.9),
          hintText: "OPEN GATE...", labelUser: "ENTITY", labelAI: "ZERO TWO",
        );
      case AppThemeMode.xenoCore:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.audiowide(fontSize: s * 0.9, color: c, letterSpacing: 0.8),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.terminal, animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.85),
          hintText: ">XENO_INPUT:", labelUser: "\$HOST", labelAI: "\$XENO",
        );
      case AppThemeMode.dataStream:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sourceCodePro(fontSize: s * 0.95, color: c, letterSpacing: 0.8, height: 1.5),
          bubbleStyle: BubbleStyle.terminal, inputStyle: InputStyle.terminal, animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.9),
          hintText: ">> INPUT DATA", labelUser: "IN", labelAI: "OUT",
        );
      case AppThemeMode.gravityBend:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.orbitron(fontSize: s * 0.88, color: c, letterSpacing: 1.2, fontWeight: FontWeight.w700),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.solid,
          cornerRadius: 6, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.7),
          hintText: "WARP SIGNAL...", labelUser: "TRAVELER", labelAI: "ZERO TWO",
        );
      case AppThemeMode.quartzPulse:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.exo2(fontSize: s * 0.95, color: c, fontWeight: FontWeight.w700, letterSpacing: 1.8),
          bubbleStyle: BubbleStyle.outlined, inputStyle: InputStyle.pill, animStyle: AnimStyle.elastic,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 30, sharpCorner: 30, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.8),
          hintText: "resonate...", labelUser: "◌", labelAI: "ZERO TWO",
        );
      case AppThemeMode.midnightForest:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.lora(fontSize: s, color: c, fontStyle: FontStyle.italic, height: 1.6),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.underline, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 16, sharpCorner: 4, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.3),
          hintText: "through the trees...", labelUser: "WANDERER", labelAI: "Zero Two",
        );
      case AppThemeMode.volcanicSea:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.exo2(fontSize: s, color: c, fontWeight: FontWeight.w700, letterSpacing: 0.8),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.banner,
          cornerRadius: 4, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.7),
          hintText: "FROM THE DEEP...", labelUser: "SAILOR", labelAI: "ZERO TWO",
        );
      case AppThemeMode.stormDesert:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.exo2(fontSize: s, color: c, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          bubbleStyle: BubbleStyle.outlined, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.glitch,
          layoutMode: LayoutMode.classic, appBarStyle: AppBarStyle.solid,
          cornerRadius: 2, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.6),
          hintText: "Dust on the wind...", labelUser: "NOMAD", labelAI: "ZERO TWO",
        );
      case AppThemeMode.sakuraNight:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sawarabiGothic(fontSize: s, color: c, height: 1.7),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.pill, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 28, sharpCorner: 28, leftAccentBar: false,
          borderColor: (p) => p.withValues(alpha: 0.25),
          hintText: "何かを話して...", labelUser: "君", labelAI: "ゼロツー",
        );
      case AppThemeMode.arcticSoul:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.quicksand(fontSize: s, color: c, fontWeight: FontWeight.w300, letterSpacing: 1.5),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.underline, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 22, sharpCorner: 22, leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.12),
          hintText: "whisper to the ice...", labelUser: "❄", labelAI: "Zero Two ~",
        );
      // ── TIER 7: ETHEREAL ────────────────────────────────────
      case AppThemeMode.amethystDream:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.playfairDisplay(fontSize: s, color: c, fontStyle: FontStyle.italic, height: 1.6),
          bubbleStyle: BubbleStyle.glassmorphic, inputStyle: InputStyle.pill, animStyle: AnimStyle.fadeZoom,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.minimal,
          cornerRadius: 32, sharpCorner: 32, leftAccentBar: false,
          borderColor: (p) => Colors.white.withValues(alpha: 0.25),
          hintText: "Whisper something beautiful...", labelUser: "♡", labelAI: "Zero Two",
        );
      case AppThemeMode.titaniumFrost:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.sourceCodePro(fontSize: s * 0.95, color: c, letterSpacing: 0.5, height: 1.6),
          bubbleStyle: BubbleStyle.terminal, inputStyle: InputStyle.terminal, animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.terminal, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.8),
          hintText: "> type command_", labelUser: "USER", labelAI: "ZERO_TWO",
        );
      case AppThemeMode.sunsetRider:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.rajdhani(fontSize: s * 1.05, color: c, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          bubbleStyle: BubbleStyle.solid, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.wideCard, appBarStyle: AppBarStyle.banner,
          cornerRadius: 4, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.7),
          hintText: "FORGE YOUR MESSAGE...", labelUser: "WARRIOR", labelAI: "ZERO TWO",
        );
      case AppThemeMode.midnightRaven:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.josefinSans(fontSize: s, color: c, letterSpacing: 2.0, fontWeight: FontWeight.w600),
          bubbleStyle: BubbleStyle.outlined, inputStyle: InputStyle.underline, animStyle: AnimStyle.slideSide,
          layoutMode: LayoutMode.centered, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 6, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.75),
          hintText: "speak...", labelUser: "·", labelAI: "ZT ~",
        );
      case AppThemeMode.electricLime:
        return ThemeStyle(
          font: (s, c) => GoogleFonts.rajdhani(fontSize: s * 1.05, color: c, fontWeight: FontWeight.w700, letterSpacing: 1.2),
          bubbleStyle: BubbleStyle.terminal, inputStyle: InputStyle.squareNeon, animStyle: AnimStyle.press,
          layoutMode: LayoutMode.terminal, appBarStyle: AppBarStyle.neonBorder,
          cornerRadius: 0, sharpCorner: 0, leftAccentBar: true,
          borderColor: (p) => p.withValues(alpha: 0.9),
          hintText: "RISE FROM THE ASHES >", labelUser: "\$FLAME", labelAI: "\$PHOENIX",
        );
    }
  }
}