part of '../main.dart';

extension _MainThemesExtension on _ChatHomePageState {
// ── Page: Themes (inline version of theme selector) ───────────────────────
  Widget _buildThemesPage() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('ATMOSPHERE',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _buildThemesHero(),
          ),
          // ── Quick controls strip ─────────────────────────────────────────
          ValueListenableBuilder<AppThemeMode>(
            valueListenable: themeNotifier,
            builder: (ctx, currentMode, _) {
              final td = AppThemes.getTheme(currentMode);
              final name = AppThemes.getThemeName(currentMode);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    // Current theme badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: td.primaryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: td.primaryColor.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: td.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              color: td.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Lite Mode chip
                    GestureDetector(
                      onTap: _toggleLiteMode,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _liteModeEnabled
                              ? Colors.greenAccent.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _liteModeEnabled
                                  ? Colors.greenAccent.withValues(alpha: 0.45)
                                  : Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _liteModeEnabled
                                  ? Icons.speed_rounded
                                  : Icons.auto_awesome,
                              color: _liteModeEnabled
                                  ? Colors.greenAccent
                                  : Colors.white38,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _liteModeEnabled ? 'Lite' : 'Full FX',
                              style: GoogleFonts.outfit(
                                color: _liteModeEnabled
                                    ? Colors.greenAccent
                                    : Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Randomize button
                    GestureDetector(
                      onTap: () async {
                        final all = AppThemeMode.values;
                        final next =
                            all[DateTime.now().millisecond % all.length];
                        themeNotifier.value = next;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('app_theme_index',
                            AppThemeMode.values.indexOf(next));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purpleAccent.withValues(alpha: 0.25),
                              Colors.pinkAccent.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  Colors.purpleAccent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shuffle_rounded,
                                color: Colors.purpleAccent, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              'Randomize',
                              style: GoogleFonts.outfit(
                                color: Colors.purpleAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: ValueListenableBuilder<AppThemeMode>(
              valueListenable: themeNotifier,
              builder: (ctx, currentMode, _) {
                final tiers = _buildThemeTiers();

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: tiers.length,
                  itemBuilder: (ctx, i) {
                    final tier = tiers[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 16, bottom: 10, left: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                    color: tier.accentColor,
                                    borderRadius: BorderRadius.circular(2)),
                              ),
                              const SizedBox(width: 8),
                              Text(tier.label,
                                  style: GoogleFonts.outfit(
                                      color: tier.accentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8)),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: tier.modes.length,
                          itemBuilder: (ctx, idx) {
                            final mode = tier.modes[idx];
                            final isSelected = currentMode == mode;
                            final td = AppThemes.getRawTheme(mode);
                            final name = AppThemes.getThemeName(mode);
                            final grad = AppThemes.getGradient(mode);
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                themeNotifier.value = mode;
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setInt('app_theme_index',
                                    AppThemeMode.values.indexOf(mode));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                    topRight: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: td.primaryColor
                                                .withValues(alpha: 0.6),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                    topRight: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 8.0, sigmaY: 8.0),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: grad.take(3).toList(),
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(24),
                                          bottomRight: Radius.circular(24),
                                          topRight: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? td.primaryColor
                                              : Colors.white
                                                  .withValues(alpha: 0.15),
                                          width: isSelected ? 2.5 : 1,
                                        ),
                                        color: isSelected
                                            ? Colors.transparent
                                            : Colors.black
                                                .withValues(alpha: 0.3),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            width: isSelected ? 28 : 22,
                                            height: isSelected ? 28 : 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: td.primaryColor,
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: td.primaryColor
                                                            .withValues(
                                                                alpha: 0.8),
                                                        blurRadius: 8,
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.black87,
                                                    size: 14)
                                                : null,
                                          ),
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Text(
                                              name,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontSize: 8.5,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesHero() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/img/bg2.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black87,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Visual Presets',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Colors.purpleAccent.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick a mood for chat and effects',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  List<_ThemeTier> _buildThemeTiers() => [
        _ThemeTier(
            'ULTRA-PREMIUM',
            [
              AppThemeMode.neonSerpent,
              AppThemeMode.chromaStorm,
              AppThemeMode.goldenRuler,
              AppThemeMode.frozenDivine,
              AppThemeMode.infernoGod,
            ],
            const Color(0xFFFFD700)),
        _ThemeTier(
            'ANIME LEGENDS',
            [
              AppThemeMode.shadowBlade,
              AppThemeMode.pinkChaos,
              AppThemeMode.abyssWatcher,
              AppThemeMode.solarFlare,
              AppThemeMode.demonSlayer,
            ],
            const Color(0xFFFF4081)),
        _ThemeTier(
            'LUXURY & FASHION',
            [
              AppThemeMode.midnightSilk,
              AppThemeMode.obsidianRose,
              AppThemeMode.onyxEmerald,
              AppThemeMode.velvetCrown,
              AppThemeMode.platinumDawn,
            ],
            const Color(0xFFCE93D8)),
        _ThemeTier(
            'SCI-FI',
            [
              AppThemeMode.hypergate,
              AppThemeMode.xenoCore,
              AppThemeMode.dataStream,
              AppThemeMode.gravityBend,
              AppThemeMode.quartzPulse,
            ],
            const Color(0xFF40C4FF)),
        _ThemeTier(
            'NATURE',
            [
              AppThemeMode.midnightForest,
              AppThemeMode.volcanicSea,
              AppThemeMode.stormDesert,
              AppThemeMode.sakuraNight,
              AppThemeMode.arcticSoul,
            ],
            const Color(0xFF81C784)),
      ];
}

// ── Theme picker tier group model ──────────────────────────────────────────
class _ThemeTier {
  final String label;
  final List<AppThemeMode> modes;
  final Color accentColor;
  const _ThemeTier(this.label, this.modes, this.accentColor);
}
