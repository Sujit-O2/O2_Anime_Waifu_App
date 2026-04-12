import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class AppThemeNotifier extends ChangeNotifier {
  static final AppThemeNotifier instance = AppThemeNotifier._();

  AppThemeNotifier._();

  static const String _key = 'selected_app_theme';
  AppThemeVariant _current = AppThemeVariant.zerTwo;

  AppThemeVariant get current => _current;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_key);
    if (saved != null) {
      _current = AppThemeVariant.values.firstWhere(
        (AppThemeVariant variant) => variant.name == saved,
        orElse: () => AppThemeVariant.zerTwo,
      );
      notifyListeners();
    }
  }

  Future<void> set(AppThemeVariant variant) async {
    _current = variant;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, variant.name);
  }
}

enum AppThemeVariant { zerTwo, night, sakura, darling, cyber }

extension AppThemeExt on AppThemeVariant {
  String get displayName {
    switch (this) {
      case AppThemeVariant.zerTwo:
        return 'Zero Two';
      case AppThemeVariant.night:
        return 'Night Mode';
      case AppThemeVariant.sakura:
        return 'Sakura';
      case AppThemeVariant.darling:
        return 'Darling';
      case AppThemeVariant.cyber:
        return 'Cyber';
    }
  }

  String get subtitle {
    switch (this) {
      case AppThemeVariant.zerTwo:
        return 'Her signature red and pink. Classic.';
      case AppThemeVariant.night:
        return 'Deep cyan on dark navy. Sleek.';
      case AppThemeVariant.sakura:
        return 'Soft blossom pink with dreamy warmth.';
      case AppThemeVariant.darling:
        return 'Warm rose gold for a softer glow.';
      case AppThemeVariant.cyber:
        return 'Neon green on black for full arcade energy.';
    }
  }

  String get emoji {
    switch (this) {
      case AppThemeVariant.zerTwo:
        return '♥';
      case AppThemeVariant.night:
        return '☾';
      case AppThemeVariant.sakura:
        return '✿';
      case AppThemeVariant.darling:
        return '♡';
      case AppThemeVariant.cyber:
        return '⚡';
    }
  }

  Color get primary {
    switch (this) {
      case AppThemeVariant.zerTwo:
        return const Color(0xFFFF4081);
      case AppThemeVariant.night:
        return const Color(0xFF00E5FF);
      case AppThemeVariant.sakura:
        return const Color(0xFFFF80AB);
      case AppThemeVariant.darling:
        return const Color(0xFFFFAB76);
      case AppThemeVariant.cyber:
        return const Color(0xFF69FF47);
    }
  }

  Color get secondary {
    switch (this) {
      case AppThemeVariant.zerTwo:
        return const Color(0xFFD50000);
      case AppThemeVariant.night:
        return const Color(0xFF0D47A1);
      case AppThemeVariant.sakura:
        return const Color(0xFFFF4081);
      case AppThemeVariant.darling:
        return const Color(0xFFE91E63);
      case AppThemeVariant.cyber:
        return const Color(0xFF1B5E20);
    }
  }

  Color get bgDark {
    switch (this) {
      case AppThemeVariant.zerTwo:
        return const Color(0xFF0D0613);
      case AppThemeVariant.night:
        return const Color(0xFF050D1A);
      case AppThemeVariant.sakura:
        return const Color(0xFF1A0A14);
      case AppThemeVariant.darling:
        return const Color(0xFF1A0A08);
      case AppThemeVariant.cyber:
        return const Color(0xFF000000);
    }
  }

  LinearGradient get bubbleGradient {
    return LinearGradient(
      colors: <Color>[
        secondary.withValues(alpha: 0.7),
        primary.withValues(alpha: 0.5),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class ThemeSwitcherPage extends StatefulWidget {
  const ThemeSwitcherPage({super.key});

  @override
  State<ThemeSwitcherPage> createState() => _ThemeSwitcherPageState();
}

class _ThemeSwitcherPageState extends State<ThemeSwitcherPage> {
  AppThemeVariant _selected = AppThemeNotifier.instance.current;

  String get _commentaryMood =>
      _selected == AppThemeVariant.zerTwo ? 'relaxed' : 'motivated';

  Future<void> _applyTheme(AppThemeVariant variant) async {
    setState(() => _selected = variant);
    await AppThemeNotifier.instance.set(variant);
    if (!mounted) {
      return;
    }
    showSuccessSnackbar(context, '${variant.displayName} theme applied.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'APP THEME',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Choose the overall aesthetic',
                        style: GoogleFonts.outfit(
                          color: V2Theme.secondaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedEntry(
              index: 0,
              child: GlassCard(
                margin: EdgeInsets.zero,
                glow: true,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme snapshot',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selected.displayName,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selected.subtitle,
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ProgressRing(
                      progress: (AppThemeVariant.values.indexOf(_selected) + 1) /
                          AppThemeVariant.values.length,
                      foreground: _selected.primary,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: _selected.bubbleGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            _selected.emoji,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedEntry(
              index: 1,
              child: WaifuCommentary(mood: _commentaryMood),
            ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Themes',
                    value: '${AppThemeVariant.values.length}',
                    icon: Icons.layers_rounded,
                    color: V2Theme.primaryColor,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Active',
                    value: _selected.displayName,
                    icon: Icons.check_circle_rounded,
                    color: _selected.primary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Primary',
                    value:
                        '#${_selected.primary.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                    icon: Icons.palette_rounded,
                    color: _selected.secondary,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Mood',
                    value: _selected == AppThemeVariant.cyber ? 'Bold' : 'Soft',
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.amberAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...AppThemeVariant.values.asMap().entries.map((entry) {
              final int index = entry.key;
              final AppThemeVariant variant = entry.value;
              return AnimatedEntry(
                index: index + 2,
                child: _ThemeCard(
                  variant: variant,
                  selected: _selected == variant,
                  onTap: () => _applyTheme(variant),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final AppThemeVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      glow: selected,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: variant.bubbleGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: variant.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Center(
              child: Text(
                variant.emoji,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.displayName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  variant.subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(
              Icons.check_circle_rounded,
              color: variant.primary,
              size: 26,
            ),
        ],
      ),
    );
  }
}



