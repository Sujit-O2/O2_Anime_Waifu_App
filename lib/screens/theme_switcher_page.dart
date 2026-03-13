import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme notifier — changing it rebuilds the whole app.
class AppThemeNotifier extends ChangeNotifier {
  static final AppThemeNotifier instance = AppThemeNotifier._();
  AppThemeNotifier._();

  static const _key = 'selected_app_theme';
  AppThemeVariant _current = AppThemeVariant.zerTwo;

  AppThemeVariant get current => _current;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _current = AppThemeVariant.values.firstWhere(
          (v) => v.name == saved,
          orElse: () => AppThemeVariant.zerTwo);
      notifyListeners();
    }
  }

  Future<void> set(AppThemeVariant v) async {
    _current = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, v.name);
  }
}

enum AppThemeVariant { zerTwo, night, sakura, darling, cyber }

extension AppThemeExt on AppThemeVariant {
  String get displayName {
    switch (this) {
      case AppThemeVariant.zerTwo:   return 'Zero Two';
      case AppThemeVariant.night:    return 'Night Mode';
      case AppThemeVariant.sakura:   return 'Sakura';
      case AppThemeVariant.darling:  return 'Darling';
      case AppThemeVariant.cyber:    return 'Cyber';
    }
  }

  String get subtitle {
    switch (this) {
      case AppThemeVariant.zerTwo:   return 'Her signature red & pink. Classic.';
      case AppThemeVariant.night:    return 'Deep cyan on dark navy. Sleek.';
      case AppThemeVariant.sakura:   return 'Soft cherry blossom pink. Dreamy~';
      case AppThemeVariant.darling:  return 'Warm rose gold. For the devoted.';
      case AppThemeVariant.cyber:    return 'Neon green on pure black. Techy.';
    }
  }

  String get emoji {
    switch (this) {
      case AppThemeVariant.zerTwo:   return '❤️';
      case AppThemeVariant.night:    return '🌙';
      case AppThemeVariant.sakura:   return '🌸';
      case AppThemeVariant.darling:  return '💝';
      case AppThemeVariant.cyber:    return '⚡';
    }
  }

  Color get primary {
    switch (this) {
      case AppThemeVariant.zerTwo:   return const Color(0xFFFF4081);
      case AppThemeVariant.night:    return const Color(0xFF00E5FF);
      case AppThemeVariant.sakura:   return const Color(0xFFFF80AB);
      case AppThemeVariant.darling:  return const Color(0xFFFFAB76);
      case AppThemeVariant.cyber:    return const Color(0xFF69FF47);
    }
  }

  Color get secondary {
    switch (this) {
      case AppThemeVariant.zerTwo:   return const Color(0xFFD50000);
      case AppThemeVariant.night:    return const Color(0xFF0D47A1);
      case AppThemeVariant.sakura:   return const Color(0xFFFF4081);
      case AppThemeVariant.darling:  return const Color(0xFFE91E63);
      case AppThemeVariant.cyber:    return const Color(0xFF1B5E20);
    }
  }

  Color get bgDark {
    switch (this) {
      case AppThemeVariant.zerTwo:   return const Color(0xFF0D0613);
      case AppThemeVariant.night:    return const Color(0xFF050D1A);
      case AppThemeVariant.sakura:   return const Color(0xFF1A0A14);
      case AppThemeVariant.darling:  return const Color(0xFF1A0A08);
      case AppThemeVariant.cyber:    return const Color(0xFF000000);
    }
  }

  LinearGradient get bubbleGradient {
    return LinearGradient(
      colors: [secondary.withValues(alpha: 0.7), primary.withValues(alpha: 0.5)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0514),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('App Theme',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Your Aesthetic~',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Changes colors across the whole app, Darling 💕',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: AppThemeVariant.values.map((v) => _ThemeCard(
                  variant: v,
                  selected: _selected == v,
                  onTap: () async {
                    setState(() => _selected = v);
                    final messenger = ScaffoldMessenger.of(context);
                    await AppThemeNotifier.instance.set(v);
                    if (mounted) {
                      messenger.showSnackBar(SnackBar(
                        backgroundColor: v.primary,
                        content: Text('${v.emoji} ${v.displayName} theme applied!',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                        duration: const Duration(seconds: 2),
                      ));
                    }
                  },
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeVariant variant;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({required this.variant, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              variant.secondary.withValues(alpha: selected ? 0.35 : 0.12),
              variant.primary.withValues(alpha: selected ? 0.25 : 0.08),
            ],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: selected ? variant.primary : Colors.white.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: variant.primary.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2)]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            // Color swatch strip
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [variant.secondary, variant.primary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Center(child: Text(variant.emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(variant.displayName,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(variant.subtitle,
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            ])),
            if (selected)
              Icon(Icons.check_circle_rounded, color: variant.primary, size: 26),
          ]),
        ),
      ),
    );
  }
}
