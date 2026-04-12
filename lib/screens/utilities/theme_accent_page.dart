import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/main.dart';

class ThemeAccentPage extends StatefulWidget {
  const ThemeAccentPage({super.key});

  @override
  State<ThemeAccentPage> createState() => _ThemeAccentPageState();
}

class _ThemeAccentPageState extends State<ThemeAccentPage> {
  final List<Color> _accentColors = <Color>[
    const Color(0xFFFF1744),
    const Color(0xFF00FF41),
    const Color(0xFF00E5FF),
    const Color(0xFFFFAB40),
    const Color(0xFFEA80FC),
    const Color(0xFFFF4081),
    const Color(0xFFFFD700),
    const Color(0xFF4FC3F7),
    const Color(0xFF39FF14),
    const Color(0xFFFFFFFF),
  ];

  Color? _selectedAccent;

  String get _commentaryMood =>
      _selectedAccent == null ? 'relaxed' : 'motivated';

  String get _activeLabel =>
      _selectedAccent == null ? 'Auto personality accent' : _hex(_selectedAccent!);

  @override
  void initState() {
    super.initState();
    _selectedAccent = AppThemes.customAccentColor;
  }

  Future<void> _setAccentColor(Color? color) async {
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove('flutter.theme_accent_color');
    } else {
      await prefs.setInt('flutter.theme_accent_color', color.value);
    }

    setState(() {
      _selectedAccent = color;
      AppThemes.customAccentColor = color;
    });

    accentColorNotifier.value = color;
    if (!mounted) {
      return;
    }
    showSuccessSnackbar(
      context,
      color == null
          ? 'Accent reset to automatic personality mode.'
          : 'Accent updated to ${_hex(color)}.',
    );
  }

  String _hex(Color color) =>
      '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

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
                        'THEME ACCENT',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Tune the app glow',
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
                            'Accent preview',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _activeLabel,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedAccent == null
                                ? 'Automatic mode follows the personality theme so the whole app can shift with the mood.'
                                : 'Manual mode locks a custom glow across cards, highlights, and primary actions.',
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
                      progress: _selectedAccent == null ? 0.45 : 1,
                      foreground: _selectedAccent ?? V2Theme.secondaryColor,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: (_selectedAccent ?? V2Theme.secondaryColor)
                              .withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.palette_rounded,
                          color: _selectedAccent ?? V2Theme.secondaryColor,
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
                    title: 'Mode',
                    value: _selectedAccent == null ? 'Auto' : 'Manual',
                    icon: Icons.auto_awesome_rounded,
                    color: V2Theme.primaryColor,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Palette',
                    value: '${_accentColors.length}',
                    icon: Icons.color_lens_rounded,
                    color: V2Theme.secondaryColor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Current',
                    value: _selectedAccent == null ? 'Dynamic' : 'Locked',
                    icon: Icons.tune_rounded,
                    color: Colors.amberAccent,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Preview',
                    value: _selectedAccent == null ? 'Mood' : 'Glow',
                    icon: Icons.visibility_rounded,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              margin: EdgeInsets.zero,
              onTap: () => _setAccentColor(null),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: V2Theme.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto personality accent',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Let the app choose the accent based on the active personality and theme mood.',
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedAccent == null)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'MANUAL OVERRIDES',
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _accentColors.length,
              itemBuilder: (BuildContext context, int index) {
                final Color color = _accentColors[index];
                final bool isSelected = _selectedAccent?.value == color.value;

                return GestureDetector(
                  onTap: () => _setAccentColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 22,
                            spreadRadius: 3,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            GlassCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live preview',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          (_selectedAccent ?? V2Theme.primaryColor)
                              .withValues(alpha: 0.24),
                          (_selectedAccent ?? V2Theme.secondaryColor)
                              .withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: (_selectedAccent ?? V2Theme.primaryColor)
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: (_selectedAccent ?? V2Theme.primaryColor)
                                .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: _selectedAccent ?? V2Theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accent powered surfaces',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Buttons, highlights, rings, and focused states will follow this glow.',
                                style: GoogleFonts.outfit(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}



