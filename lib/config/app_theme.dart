import 'package:flutter/material.dart';

/// Build the custom theme for the Zero Two application
/// Uses dark theme with red/pink accent colors matching the anime character
ThemeData buildAppTheme() {
  return ThemeData.dark().copyWith(
    primaryColor: const Color(0xFFFF5252),
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF5252),
      secondary: Color(0xFFFF80AB),
      surface: Color(0xFF1E1E1E),
    ),
  );
}
