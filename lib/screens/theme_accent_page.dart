import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_themes.dart';
import '../main.dart';

class ThemeAccentPage extends StatefulWidget {
  const ThemeAccentPage({super.key});

  @override
  State<ThemeAccentPage> createState() => _ThemeAccentPageState();
}

class _ThemeAccentPageState extends State<ThemeAccentPage> {
  // Pre-defined set of gorgeous neon colors
  final List<Color> _accentColors = [
    const Color(0xFFFF1744), // Crimson
    const Color(0xFF00FF41), // Matrix Green
    const Color(0xFF00E5FF), // Cyan
    const Color(0xFFFFAB40), // Amber
    const Color(0xFFEA80FC), // Violet
    const Color(0xFFFF4081), // Pink
    const Color(0xFFFFD700), // Gold
    const Color(0xFF4FC3F7), // Light Blue
    const Color(0xFF39FF14), // Toxic Neon
    const Color(0xFFFFFFFF), // Pure White
  ];

  Color? _selectedAccent;

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

    // Fire the global listener to rebuild MaterialApp immediately
    accentColorNotifier.value = color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Theme Accent', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize the Glow',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Override the app's primary neon accent color globally. This creates a visually stunning glassmorphism effect that matches your mood.",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Default option (No Override)
              GestureDetector(
                onTap: () => _setAccentColor(null),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedAccent == null
                        ? Colors.white10
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedAccent == null
                          ? Colors.white30
                          : Colors.white10,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Auto (Matches Personality)',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: _selectedAccent == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedAccent == null
                            ? Colors.white
                            : Colors.white60,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Manual Overrides',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _accentColors.length,
                  itemBuilder: (context, index) {
                    final color = _accentColors[index];
                    final isSelected = _selectedAccent?.value == color.value;

                    return GestureDetector(
                      onTap: () => _setAccentColor(color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 4,
                              )
                          ],
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
