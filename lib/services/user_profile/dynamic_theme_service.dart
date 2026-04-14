import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Dynamic color extraction — extracts dominant colors from anime cover URLs.
/// Uses pixel sampling from the image to build a color palette.
class DynamicThemeService {
  static final Map<String, ColorPalette> _cache = {};

  /// Extract dominant colors from an image URL.
  static Future<ColorPalette> extractColors(String imageUrl) async {
    if (_cache.containsKey(imageUrl)) return _cache[imageUrl]!;

    try {
      final resp = await http.get(Uri.parse(imageUrl), headers: {
        'User-Agent': 'Mozilla/5.0',
      }).timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) return ColorPalette.fallback();

      final codec = await ui.instantiateImageCodec(resp.bodyBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Sample pixels from the image
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return ColorPalette.fallback();

      final pixels = data.buffer.asUint8List();
      final width = image.width;
      final height = image.height;

      // Sample grid of pixels (every 10th pixel for performance)
      final colorCounts = <int, int>{};
      final step = max(1, (width * height) ~/ 200); // ~200 samples

      for (int i = 0; i < pixels.length - 3; i += step * 4) {
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];

        // Skip near-black and near-white pixels
        if (r + g + b < 30 || r + g + b > 720) continue;

        // Quantize to reduce similar colors
        final qr = (r ~/ 32) * 32;
        final qg = (g ~/ 32) * 32;
        final qb = (b ~/ 32) * 32;
        final key = (qr << 16) | (qg << 8) | qb;
        colorCounts[key] = (colorCounts[key] ?? 0) + 1;
      }

      image.dispose();

      // Sort by frequency
      final sorted = colorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sorted.isEmpty) return ColorPalette.fallback();

      Color colorFromKey(int key) => Color.fromARGB(
          255, (key >> 16) & 0xFF, (key >> 8) & 0xFF, key & 0xFF);

      final dominant = colorFromKey(sorted[0].key);
      final secondary = sorted.length > 1
          ? colorFromKey(sorted[1].key) : dominant.withValues(alpha: 0.7);
      final tertiary = sorted.length > 2
          ? colorFromKey(sorted[2].key) : dominant.withValues(alpha: 0.5);

      // Calculate if dominant color is light or dark
      final brightness = (dominant.r * 299 + dominant.g * 587 + dominant.b * 114) / 1000;
      final isDark = brightness < 128;

      final palette = ColorPalette(
        dominant: dominant,
        secondary: secondary,
        tertiary: tertiary,
        isDark: isDark,
        textColor: isDark ? Colors.white : Colors.black,
      );

      _cache[imageUrl] = palette;
      return palette;
    } catch (_) {
      return ColorPalette.fallback();
    }
  }

  /// Pre-warm cache for a list of URLs
  static Future<void> preWarm(List<String> urls) async {
    for (final url in urls.take(5)) {
      await extractColors(url);
    }
  }
}

class ColorPalette {
  final Color dominant;
  final Color secondary;
  final Color tertiary;
  final bool isDark;
  final Color textColor;

  const ColorPalette({
    required this.dominant,
    required this.secondary,
    required this.tertiary,
    required this.isDark,
    required this.textColor,
  });

  factory ColorPalette.fallback() => const ColorPalette(
    dominant: Color(0xFF6200EA),
    secondary: Color(0xFF9C27B0),
    tertiary: Color(0xFF7C4DFF),
    isDark: true,
    textColor: Colors.white,
  );

  /// Gradient from dominant to black
  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [dominant.withValues(alpha: 0.6), const Color(0xFF0D0D0D)],
  );

  /// Accent gradient between dominant and secondary
  LinearGradient get accentGradient => LinearGradient(
    colors: [dominant, secondary],
  );
}


