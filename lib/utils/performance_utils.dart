import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cached text styles to avoid expensive GoogleFonts rebuilds
class AppTextStyles {
  // Cache TextStyle instances to avoid rebuilding on every frame
  static final TextStyle outfit12w500 = GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500);
  static final TextStyle outfit12w600 = GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600);
  static final TextStyle outfit12w700 = GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700);
  static final TextStyle outfit13w600 = GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600);
  static final TextStyle outfit14w400 = GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400);
  static final TextStyle outfit14w600 = GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600);
  static final TextStyle outfit14w800 = GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800);
  static final TextStyle outfit16w600 = GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600);
  static final TextStyle outfit16w800 = GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800);
  static final TextStyle outfit18w700 = GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700);
  static final TextStyle outfit20w900 = GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900);
  static final TextStyle outfit22w900 = GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900);
  static final TextStyle outfit52w800 = GoogleFonts.outfit(fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: -2);

  // Color variants
  static final TextStyle outfit14White = GoogleFonts.outfit(color: Colors.white, fontSize: 14);
  static final TextStyle outfit12White70 = GoogleFonts.outfit(color: Colors.white70, fontSize: 12);
  static final TextStyle outfit12White54 = GoogleFonts.outfit(color: Colors.white54, fontSize: 12);
  static final TextStyle outfit16White600 = GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600);
  static final TextStyle outfit18White700 = GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700);

  static void init() {
    // Force initialization at app startup
  }
}

/// Image caching configuration
class ImageCacheConfig {
  static void configure() {
    final imageCache = ImageCache();
    imageCache.maximumSize = 100; // Max 100 images
    imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100 MB max
  }
}

/// Performance monitoring helper
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void start(String label) {
    _timers[label] = Stopwatch()..start();
  }

  static void stop(String label) {
    final timer = _timers[label];
    if (timer != null) {
      timer.stop();
      if (timer.elapsedMilliseconds > 16) {
        // Jank threshold (16ms for 60fps)
        debugPrint('⚠️ JANK: $label took ${timer.elapsedMilliseconds}ms');
      }
      _timers.remove(label);
    }
  }
}
