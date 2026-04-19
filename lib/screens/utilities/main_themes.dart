import 'dart:ui';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/core/providers/theme_provider.dart';
import 'package:anime_waifu/main.dart' show themeNotifier;
import 'package:anime_waifu/services/user_profile/custom_theme_service.dart';
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
  final CustomThemeService _customThemeService = CustomThemeService();

  static const _themeDescriptions = <AppThemeMode, String>{
    AppThemeMode.zeroTwo:
        'Blood crimson & sakura pink — her signature aesthetic',
    AppThemeMode.cyberPhantom:
        'Electric cyan & violet — neon-drenched cyberpunk',
    AppThemeMode.velvetNoir: 'Rose gold & champagne — luxury dark elegance',
    AppThemeMode.toxicVenom: 'Acid green & lime — terminal hacker aesthetic',
    AppThemeMode.astralDream: 'Lavender & aurora pink — ethereal cosmic dream',
    AppThemeMode.infernoCore: 'Molten orange & lava red — volcanic intensity',
    AppThemeMode.arcticBlade: 'Ice blue & frost white — minimal arctic blade',
    AppThemeMode.goldenEmperor: '24K gold & bronze — royal opulence',
    AppThemeMode.phantomViolet: 'Deep purple & magenta — dark mystery',
    AppThemeMode.oceanAbyss: 'Bioluminescent teal — deep sea glow',
  };

  static const _themeEmojis = <AppThemeMode, String>{
    AppThemeMode.zeroTwo: '🩸',
    AppThemeMode.cyberPhantom: '⚡',
    AppThemeMode.velvetNoir: '🥀',
    AppThemeMode.toxicVenom: '☠️',
    AppThemeMode.astralDream: '✨',
    AppThemeMode.infernoCore: '🌋',
    AppThemeMode.arcticBlade: '❄️',
    AppThemeMode.goldenEmperor: '👑',
    AppThemeMode.phantomViolet: '🔮',
    AppThemeMode.oceanAbyss: '🌊',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _customThemeService.initialize();
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

          // ── Custom Theme Creation Section ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CREATE CUSTOM',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      )),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showCreateThemeDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            color: Colors.white54,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text('Create New Theme',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Your Custom Themes ─────────────────────────────────────────
          FutureBuilder<List<CustomTheme>>(
            future: _customThemeService.getAllCustomThemes(),
            builder: (ctx, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              final customThemes = snap.data!;
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR CUSTOM THEMES (${customThemes.length})',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          )),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: customThemes.length,
                          itemBuilder: (ctx, i) =>
                              _buildCustomThemePreview(customThemes[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  void _showCreateThemeDialog() {
    final nameCtrl = TextEditingController();
    final primaryColorNotifier = ValueNotifier<Color>(Colors.red);
    final accentColorNotifier = ValueNotifier<Color>(Colors.pink);
    final backgroundColorNotifier = ValueNotifier<Color>(Colors.black);
    final secondaryColorNotifier = ValueNotifier<Color>(Colors.grey);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Create New Theme',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: StatefulBuilder(
          builder: (dialogCtx, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Theme name',
                    hintStyle: GoogleFonts.outfit(color: Colors.white30),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<Color>(
                  valueListenable: primaryColorNotifier,
                  builder: (_, pc, __) => _colorPickerRow(
                    'Primary',
                    pc,
                    (c) {
                      primaryColorNotifier.value = c;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<Color>(
                  valueListenable: accentColorNotifier,
                  builder: (_, ac, __) => _colorPickerRow(
                    'Accent',
                    ac,
                    (c) {
                      accentColorNotifier.value = c;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<Color>(
                  valueListenable: backgroundColorNotifier,
                  builder: (_, bc, __) => _colorPickerRow(
                    'Background',
                    bc,
                    (c) {
                      backgroundColorNotifier.value = c;
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<Color>(
                  valueListenable: secondaryColorNotifier,
                  builder: (_, sc, __) => _colorPickerRow(
                    'Secondary',
                    sc,
                    (c) {
                      secondaryColorNotifier.value = c;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                String hexColor(Color c) =>
                    '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

                final theme = CustomTheme(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  primaryColor: hexColor(primaryColorNotifier.value),
                  accentColor: hexColor(accentColorNotifier.value),
                  backgroundColor: hexColor(backgroundColorNotifier.value),
                  secondaryColor: hexColor(secondaryColorNotifier.value),
                );
                await _customThemeService.createCustomTheme(theme);
                if (mounted) {
                  setState(() {});
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: const Text('Create',
                style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  Widget _colorPickerRow(String label, Color color, Function(Color) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
        GestureDetector(
          onTap: () {
            final colors = [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.purple,
              Colors.orange,
              Colors.pink
            ];
            int currentIndex = 0;
            for (int i = 0; i < colors.length; i++) {
              if (colors[i].value == color.value) {
                currentIndex = i;
                break;
              }
            }
            final nextColor = colors[(currentIndex + 1) % colors.length];
            onChanged(nextColor);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomThemePreview(CustomTheme theme) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(theme.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _swatch(
                  Color(
                      int.parse(theme.primaryColor.replaceFirst('#', '0xff'))),
                  12),
              const SizedBox(width: 4),
              _swatch(
                  Color(int.parse(theme.accentColor.replaceFirst('#', '0xff'))),
                  10),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  // Apply custom theme
                  debugPrint('Applying custom theme: ${theme.name}');
                },
                child: const Icon(Icons.check_circle_outline,
                    color: Colors.greenAccent, size: 16),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await _customThemeService.deleteCustomTheme(theme.id);
                  setState(() {});
                },
                child: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 16),
              ),
            ],
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

  Widget _buildThemeCard(
      AppThemeMode mode, AppThemeMode current, ThemeProvider tp) {
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
              gradient.length > 3 ? gradient[3] : gradient[2],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isActive
                ? primary.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.08),
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 2),
                  BoxShadow(
                      color: primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -2),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.4),
                                primary.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: primary.withValues(alpha: 0.7)),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
    );
  }

  String _particleName(ParticleType t) {
    switch (t) {
      case ParticleType.sakura:
        return '🌸 sakura';
      case ParticleType.rain:
        return '🌧 rain';
      case ParticleType.circles:
        return '○ circles';
      case ParticleType.lines:
        return '║ lines';
      case ParticleType.stars:
        return '★ stars';
      case ParticleType.embers:
        return '🔥 embers';
      case ParticleType.snow:
        return '❄ snow';
      case ParticleType.squares:
        return '◆ squares';
      case ParticleType.bubbles:
        return '○ bubbles';
      case ParticleType.leaves:
        return '🍃 leaves';
    }
  }
}
