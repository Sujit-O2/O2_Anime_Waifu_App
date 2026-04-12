import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 5 NEW PREMIUM THEMES WITH ENHANCED ANIMATIONS & SEXY VISUALS
/// ════════════════════════════════════════════════════════════════════════════
/// 
/// These 5 new themes represent cutting-edge design trends:
/// 1. NeonPulse - High-energy neon with pulsing animation effects
/// 2. MoonlitMagic - Ethereal nighttime magic with smooth transitions
/// 3. SolsticeBlaze - Summer solstice fire with dynamic animations
/// 4. AuroraBorealis - Northern lights with gradient flowing effects
/// 5. MidnightEclipse - Dark luxury with sophisticated animation layers
/// ════════════════════════════════════════════════════════════════════════════

enum NewAnimStyle { 
  pulse,          /// Rhythmic pulsing effect
  shimmer,        /// Delicate shimmer animation
  glow,           /// Smooth glowing effect
  flow,           /// Liquid flowing animation
  bounce,         /// Playful bounce animation
  spiral,         /// Mesmerizing spiral motion
  ripple,         /// Water ripple effect
  glitch,         /// Cyberpunk glitch effect
}

enum NewParticleType {
  neon,          /// Bright neon particles
  moonlight,     /// Soft moonlit particles
  flames,        /// Animated fire particles
  aurora,        /// Northern lights particles
  cosmic,        /// Deep space cosmic particles
}

/// NEW THEME ENUM ADDITIONS (Add to AppThemeMode in app_themes.dart)
enum NewTheme {
  neonPulse,     /// Theme 11: Electric neon with pulsing effects
  moonlitMagic,  /// Theme 12: Ethereal moonlight magic
  solsticeBlaze, /// Theme 13: Fiery summer solstice
  auroraBorealis,/// Theme 14: Northern lights style
  midnightEclipse,/// Theme 15: Dark luxury eclipse
}

/// New Theme Specifications
class NewThemeSpec {
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final List<Color> gradient;
  final NewAnimStyle animStyle;
  final NewParticleType particleType;
  final double animationSpeed;
  final bool enableGlow;
  final bool enableScanlines;
  final double blurIntensity;
  final double glowIntensity;

  const NewThemeSpec({
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.gradient,
    required this.animStyle,
    required this.particleType,
    this.animationSpeed = 1.0,
    this.enableGlow = true,
    this.enableScanlines = false,
    this.blurIntensity = 20.0,
    this.glowIntensity = 0.8,
  });
}

/// New Themes Configuration
class NewThemes {
  /// Theme 11: Neon Pulse
  /// Electric neon colors with rhythmic pulsing animations
  /// Perfect for: High-energy, modern, tech-forward users
  static const NewThemeSpec neonPulse = NewThemeSpec(
    name: 'Neon Pulse',
    description: 'Electric neon with rhythmic pulsing animations',
    primary: Color(0xFF00FF88),      /// Neon green
    secondary: Color(0xFFFF00FF),    /// Magenta
    accent: Color(0xFF00FFFF),       /// Cyan
    background: Color(0xFF0A0E27),   /// Very dark blue
    gradient: [
      Color(0xFF0A0E27),
      Color(0xFF0F1A3A),
      Color(0xFF1A0F2E),
      Color(0xFF0F1A2E),
      Color(0xFF050709),
    ],
    animStyle: NewAnimStyle.pulse,
    particleType: NewParticleType.neon,
    animationSpeed: 1.2,
    enableGlow: true,
    enableScanlines: true,
    blurIntensity: 15.0,
    glowIntensity: 0.95,
  );

  /// Theme 12: Moonlit Magic
  /// Ethereal silver and purple tones with smooth flowing animations
  /// Perfect for: Creative, peaceful, mystical users
  static const NewThemeSpec moonlitMagic = NewThemeSpec(
    name: 'Moonlit Magic',
    description: 'Ethereal moonlight with smooth flowing animations',
    primary: Color(0xFFE0E3FF),      /// Soft lavender
    secondary: Color(0xFF9D8FD1),    /// Purple
    accent: Color(0xFFC8B6FF),       /// Light lavender
    background: Color(0xFF0F0B1E),   /// Deep purple-black
    gradient: [
      Color(0xFF0F0B1E),
      Color(0xFF1A0F3A),
      Color(0xFF2D1B4E),
      Color(0xFF14082F),
      Color(0xFF060409),
    ],
    animStyle: NewAnimStyle.flow,
    particleType: NewParticleType.moonlight,
    animationSpeed: 0.6,
    enableGlow: true,
    enableScanlines: false,
    blurIntensity: 30.0,
    glowIntensity: 0.6,
  );

  /// Theme 13: Solstice Blaze
  /// Fiery orange and red with dynamic bouncing animations
  /// Perfect for: Bold, energetic, passionate users
  static const NewThemeSpec solsticeBlaze = NewThemeSpec(
    name: 'Solstice Blaze',
    description: 'Fiery summer solstice with dynamic animations',
    primary: Color(0xFFFF4500),      /// Orange red
    secondary: Color(0xFFFF1744),    /// Deep red
    accent: Color(0xFFFFB74D),       /// Light orange
    background: Color(0xFF1A0A00),   /// Burnt dark
    gradient: [
      Color(0xFF1A0A00),
      Color(0xFF3D1000),
      Color(0xFF5E1400),
      Color(0xFF3D0A00),
      Color(0xFF0A0000),
    ],
    animStyle: NewAnimStyle.bounce,
    particleType: NewParticleType.flames,
    animationSpeed: 1.3,
    enableGlow: true,
    enableScanlines: false,
    blurIntensity: 18.0,
    glowIntensity: 0.9,
  );

  /// Theme 14: Aurora Borealis
  /// Northern lights inspired with gradient flowing effects
  /// Perfect for: Dreamy, artistic, serene users
  static const NewThemeSpec auroraBorealis = NewThemeSpec(
    name: 'Aurora Borealis',
    description: 'Northern lights with gradient flowing effects',
    primary: Color(0xFF00D9A3),      /// Teal green
    secondary: Color(0xFF00E5B3),    /// Mint
    accent: Color(0xFF7FFF00),       /// Chartreuse
    background: Color(0xFF0A1F1F),   /// Deep teal
    gradient: [
      Color(0xFF0A1F1F),
      Color(0xFF001A2E),
      Color(0xFF0F2E3A),
      Color(0xFF0A1F28),
      Color(0xFF040808),
    ],
    animStyle: NewAnimStyle.shimmer,
    particleType: NewParticleType.aurora,
    animationSpeed: 0.8,
    enableGlow: true,
    enableScanlines: false,
    blurIntensity: 25.0,
    glowIntensity: 0.75,
  );

  /// Theme 15: Midnight Eclipse
  /// Dark luxury with sophisticated animation layers
  /// Perfect for: Premium, sophisticated, luxury users
  static const NewThemeSpec midnightEclipse = NewThemeSpec(
    name: 'Midnight Eclipse',
    description: 'Dark luxury with sophisticated animations',
    primary: Color(0xFFC9A961),      /// Gold
    secondary: Color(0xFF2D2D44),    /// Deep gray-purple
    accent: Color(0xFFE5D4B1),       /// Light gold
    background: Color(0xFF0D0D0D),   /// Pure black
    gradient: [
      Color(0xFF0D0D0D),
      Color(0xFF1A1A2E),
      Color(0xFF2D2D44),
      Color(0xFF161625),
      Color(0xFF000000),
    ],
    animStyle: NewAnimStyle.glow,
    particleType: NewParticleType.cosmic,
    animationSpeed: 0.7,
    enableGlow: true,
    enableScanlines: false,
    blurIntensity: 28.0,
    glowIntensity: 0.5,
  );

  /// Get theme by enum
  static NewThemeSpec getTheme(NewTheme theme) {
    switch (theme) {
      case NewTheme.neonPulse:
        return neonPulse;
      case NewTheme.moonlitMagic:
        return moonlitMagic;
      case NewTheme.solsticeBlaze:
        return solsticeBlaze;
      case NewTheme.auroraBorealis:
        return auroraBorealis;
      case NewTheme.midnightEclipse:
        return midnightEclipse;
    }
  }

  /// Get all new themes
  static List<NewThemeSpec> getAllThemes() => [
    neonPulse,
    moonlitMagic,
    solsticeBlaze,
    auroraBorealis,
    midnightEclipse,
  ];
}

/// INTEGRATION GUIDE FOR NEW THEMES
/// ════════════════════════════════════════════════════════════════════════════
/// 
/// 1. In AppThemeMode enum, add:
///    neonPulse,
///    moonlitMagic,
///    solsticeBlaze,
///    auroraBorealis,
///    midnightEclipse,
///
/// 2. In getTheme() switch statement, add:
///    case AppThemeMode.neonPulse:
///      return _build(
///        primary: const Color(0xFF00FF88),
///        secondary: const Color(0xFFFF00FF),
///        bg: const Color(0xFF0A0E27),
///        accent: const Color(0xFF00FFFF));
///    case AppThemeMode.moonlitMagic:
///      return _build(
///        primary: const Color(0xFFE0E3FF),
///        secondary: const Color(0xFF9D8FD1),
///        bg: const Color(0xFF0F0B1E),
///        accent: const Color(0xFFC8B6FF));
///    case AppThemeMode.solsticeBlaze:
///      return _build(
///        primary: const Color(0xFFFF4500),
///        secondary: const Color(0xFFFF1744),
///        bg: const Color(0xFF1A0A00),
///        accent: const Color(0xFFFFB74D));
///    case AppThemeMode.auroraBorealis:
///      return _build(
///        primary: const Color(0xFF00D9A3),
///        secondary: const Color(0xFF00E5B3),
///        bg: const Color(0xFF0A1F1F),
///        accent: const Color(0xFF7FFF00));
///    case AppThemeMode.midnightEclipse:
///      return _build(
///        primary: const Color(0xFFC9A961),
///        secondary: const Color(0xFF2D2D44),
///        bg: const Color(0xFF0D0D0D),
///        accent: const Color(0xFFE5D4B1));
///
/// 3. In getParticleType() switch, add particle types for each new theme
/// 
/// 4. In getThemeName() switch, add display names:
///    case AppThemeMode.neonPulse: return "Neon Pulse";
///    case AppThemeMode.moonlitMagic: return "Moonlit Magic";
///    case AppThemeMode.solsticeBlaze: return "Solstice Blaze";
///    case AppThemeMode.auroraBorealis: return "Aurora Borealis";
///    case AppThemeMode.midnightEclipse: return "Midnight Eclipse";
///
/// 5. In getGradient() switch, add gradients (see above)
/// 
/// 6. Update animation speeds in getBlurIntensity() and getEdgeGlowIntensity()
/// ════════════════════════════════════════════════════════════════════════════


