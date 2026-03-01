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
                            final td = AppThemes.getTheme(mode);
                            final name = AppThemes.getThemeName(mode);
                            final grad = AppThemes.getGradient(mode);
                            return GestureDetector(
                              onTap: () async {
                                themeNotifier.value = mode;
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setInt('app_theme_index',
                                    AppThemeMode.values.indexOf(mode));
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: grad.take(3).toList(),
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? td.primaryColor
                                        : Colors.white.withOpacity(0.08),
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: td.primaryColor
                                                .withOpacity(0.5),
                                            blurRadius: 12,
                                          )
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: isSelected ? 28 : 22,
                                      height: isSelected ? 28 : 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: td.primaryColor,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded,
                                              color: Colors.black87, size: 14)
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
                                              : Colors.white60,
                                          fontSize: 8.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
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

  List<_ThemeTier> _buildThemeTiers() => [
        _ThemeTier(
            '⚡  ICONIC',
            [
              AppThemeMode.bloodMoon,
              AppThemeMode.voidMatrix,
              AppThemeMode.angelFall,
              AppThemeMode.titanSoul,
              AppThemeMode.cosmicRift
            ],
            const Color(0xFFFF1744)),
        _ThemeTier(
            '💎  ULTRA-PREMIUM',
            [
              AppThemeMode.neonSerpent,
              AppThemeMode.chromaStorm,
              AppThemeMode.goldenRuler,
              AppThemeMode.frozenDivine,
              AppThemeMode.infernoGod
            ],
            const Color(0xFFFFD700)),
        _ThemeTier(
            '🗡️  ANIME LEGENDS',
            [
              AppThemeMode.shadowBlade,
              AppThemeMode.pinkChaos,
              AppThemeMode.abyssWatcher,
              AppThemeMode.solarFlare,
              AppThemeMode.demonSlayer
            ],
            const Color(0xFFFF4081)),
        _ThemeTier(
            '🥀  LUXURY & FASHION',
            [
              AppThemeMode.midnightSilk,
              AppThemeMode.obsidianRose,
              AppThemeMode.onyxEmerald,
              AppThemeMode.velvetCrown,
              AppThemeMode.platinumDawn
            ],
            const Color(0xFFCE93D8)),
        _ThemeTier(
            '🛸  SCI-FI',
            [
              AppThemeMode.hypergate,
              AppThemeMode.xenoCore,
              AppThemeMode.dataStream,
              AppThemeMode.gravityBend,
              AppThemeMode.quartzPulse
            ],
            const Color(0xFF40C4FF)),
        _ThemeTier(
            '🌿  NATURE',
            [
              AppThemeMode.midnightForest,
              AppThemeMode.volcanicSea,
              AppThemeMode.stormDesert,
              AppThemeMode.sakuraNight,
              AppThemeMode.arcticSoul
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
