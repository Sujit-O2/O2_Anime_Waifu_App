import 'dart:ui';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/core/providers/theme_provider.dart';
import 'package:anime_waifu/main.dart' show themeNotifier;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ThemesPage — Premium theme gallery with live preview cards
/// ─────────────────────────────────────────────────────────────────────────────
class ThemesPage extends StatefulWidget {
  const ThemesPage({super.key});
  @override
  State<ThemesPage> createState() => _ThemesPageState();
}

class _ThemesPageState extends State<ThemesPage> with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  static const _themeDescriptions = <AppThemeMode, String>{
    AppThemeMode.zeroTwo:       'Blood crimson & sakura pink — her signature aesthetic',
    AppThemeMode.cyberPhantom:  'Electric cyan & violet — neon-drenched cyberpunk',
    AppThemeMode.velvetNoir:    'Rose gold & champagne — luxury dark elegance',
    AppThemeMode.toxicVenom:    'Acid green & lime — terminal hacker aesthetic',
    AppThemeMode.astralDream:   'Lavender & aurora pink — ethereal cosmic dream',
    AppThemeMode.infernoCore:   'Molten orange & lava red — volcanic intensity',
    AppThemeMode.arcticBlade:   'Ice blue & frost white — minimal arctic blade',
    AppThemeMode.goldenEmperor: '24K gold & bronze — royal opulence',
    AppThemeMode.phantomViolet: 'Deep purple & magenta — dark mystery',
    AppThemeMode.oceanAbyss:    'Bioluminescent teal — deep sea glow',
  };

  static const _themeEmojis = <AppThemeMode, String>{
    AppThemeMode.zeroTwo:       '🩸',
    AppThemeMode.cyberPhantom:  '⚡',
    AppThemeMode.velvetNoir:    '🥀',
    AppThemeMode.toxicVenom:    '☠️',
    AppThemeMode.astralDream:   '✨',
    AppThemeMode.infernoCore:   '🌋',
    AppThemeMode.arcticBlade:   '❄️',
    AppThemeMode.goldenEmperor: '👑',
    AppThemeMode.phantomViolet: '🔮',
    AppThemeMode.oceanAbyss:    '🌊',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final currentMode = tp.mode;
    final themes = ThemeProvider.activeThemeModes.toList();

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        cacheExtent: 250,
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                children: [
                  Text('ATMOSPHERE',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                    )),
                  const SizedBox(height: 6),
                  Text('10 premium themes with unique fonts, effects & vibes',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 11,
                    )),
                ],
              ),
            ),
          ),

          // ── Current Theme Hero ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildCurrentThemeHero(currentMode),
            ),
          ),

          // ── Theme Grid ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildThemeCard(themes[i], currentMode, tp),
                childCount: themes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentThemeHero(AppThemeMode mode) {
    final td = AppThemes.getTheme(mode);
    final primary = td.colorScheme.primary;
    final gradient = AppThemes.getGradient(mode);
    final name = AppThemes.getThemeName(mode);
    final emoji = _themeEmojis[mode] ?? '🎨';

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final glowAlpha = 0.2 + (_pulseCtrl.value * 0.15);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: gradient.take(3).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: primary.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: glowAlpha),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE THEME',
                      style: GoogleFonts.outfit(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      )),
                    const SizedBox(height: 2),
                    Text(name,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      )),
                    const SizedBox(height: 4),
                    Text(_themeDescriptions[mode] ?? '',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.3,
                      )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(AppThemeMode mode, AppThemeMode current, ThemeProvider tp) {
    final isActive = mode == current;
    final td = AppThemes.getRawTheme(mode);
    final primary = td.colorScheme.primary;
    final secondary = td.colorScheme.secondary;
    final accent = td.colorScheme.tertiary;
    final gradient = AppThemes.getGradient(mode);
    final name = AppThemes.getThemeName(mode);
    final emoji = _themeEmojis[mode] ?? '🎨';
    final particle = AppThemes.getParticleType(mode);
    final style = AppThemes.getStyle(mode);

    return GestureDetector(
      onTap: () async {
        await tp.setMode(mode);
        themeNotifier.value = mode;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              gradient[0],
              gradient[1],
              gradient[2],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isActive ? primary : Colors.white.withValues(alpha: 0.08),
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 2)]
              : [],
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji + active badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 28)),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primary.withValues(alpha: 0.6)),
                          ),
                          child: Text('ACTIVE',
                            style: GoogleFonts.outfit(
                              color: primary,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            )),
                        ),
                    ],
                  ),
                  const Spacer(),

                  // Theme name
                  Text(name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    )),
                  const SizedBox(height: 4),

                  // Description
                  Text(_themeDescriptions[mode] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 9.5,
                      height: 1.3,
                    )),
                  const SizedBox(height: 10),

                  // Color swatches
                  Row(
                    children: [
                      _swatch(primary, 18),
                      const SizedBox(width: 4),
                      _swatch(secondary, 14),
                      const SizedBox(width: 4),
                      _swatch(accent, 14),
                      const Spacer(),
                      // Style badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _particleName(particle),
                          style: GoogleFonts.outfit(
                            color: Colors.white30,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Font preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.white.withValues(alpha: 0.04),
                      child: Text(
                        style.hintText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.font(9, Colors.white30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6)],
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
    );
  }

  String _particleName(ParticleType t) {
    switch (t) {
      case ParticleType.sakura:  return '🌸 sakura';
      case ParticleType.rain:    return '🌧 rain';
      case ParticleType.circles: return '○ circles';
      case ParticleType.lines:   return '║ lines';
      case ParticleType.stars:   return '★ stars';
      case ParticleType.embers:  return '🔥 embers';
      case ParticleType.snow:    return '❄ snow';
      case ParticleType.squares: return '◆ squares';
      case ParticleType.bubbles: return '○ bubbles';
      case ParticleType.leaves:  return '🍃 leaves';
    }
  }
}



