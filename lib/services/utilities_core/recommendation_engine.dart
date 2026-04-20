import 'package:anime_waifu/services/analytics_monitoring/advanced_analytics_service.dart';
import 'package:anime_waifu/services/user_profile/custom_theme_service.dart';
import 'package:flutter/foundation.dart';

/// Smart Recommendation Engine - Suggest themes based on usage patterns
class RecommendationEngine {
  static final RecommendationEngine _instance =
      RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  
  late AdvancedAnalyticsService _analyticsService;
  late CustomThemeService _customThemeService;

  RecommendationEngine._internal() {
    _analyticsService = AdvancedAnalyticsService();
    _customThemeService = CustomThemeService();
  }

  /// Get recommended themes based on user behavior
  Future<List<ThemeRecommendation>> getRecommendedThemes({
    int limit = 5,
  }) async {
    try {
      // Get usage stats
      final popularThemes = await _analyticsService.getMostPopularThemes();
      final allThemes = await _customThemeService.getAllCustomThemes();
      
      final recommendations = <ThemeRecommendation>[];

      // Score each theme
      for (final theme in allThemes) {
        int score = 0;

        // Check if it's in popular themes
        final isPopular = popularThemes.any((t) => t.themeId == theme.id);
        if (isPopular) score += 30;

        // Check engagement
        final engagementScore =
            await _analyticsService.getThemeEngagementScore(theme.id);
        score += engagementScore ~/ 3; // 0-33 points

        // Recent animation types boost
        if (theme.animationType == 'pulse' ||
            theme.animationType == 'shimmer') {
          score += 20;
        }

        // Dark mode preference boost
        if (theme.isDarkMode) score += 15;

        recommendations.add(
          ThemeRecommendation(
            theme: theme,
            score: score,
            reason: _generateReason(theme, isPopular, engagementScore),
          ),
        );
      }

      // Sort by score and return top N
      recommendations.sort((a, b) => b.score.compareTo(a.score));
      debugPrint('✅ Generated ${recommendations.length} recommendations');
      return recommendations.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error generating recommendations: $e');
      return [];
    }
  }

  /// Get personalized theme based on time of day
  Future<ThemeRecommendation?> getTimeBasedThemeRecommendation() async {
    try {
      final now = DateTime.now();
      final hour = now.hour;
      final allThemes = await _customThemeService.getAllCustomThemes();

      CustomTheme? selected;

      if (hour >= 6 && hour < 12) {
        // Morning - recommend bright themes
        selected = allThemes
            .where((t) => !t.isDarkMode)
            .fold<CustomTheme?>(null, (prev, t) => prev ?? t);
      } else if (hour >= 12 && hour < 18) {
        // Afternoon - recommend energetic themes
        selected = allThemes
            .where((t) =>
                t.animationType == 'pulse' || t.animationType == 'bounce')
            .fold<CustomTheme?>(null, (prev, t) => prev ?? t);
      } else {
        // Evening/Night - recommend dark, calm themes
        selected = allThemes
            .where((t) => t.isDarkMode && t.animationType != 'pulse')
            .fold<CustomTheme?>(null, (prev, t) => prev ?? t);
      }

      if (selected == null) return null;

      return ThemeRecommendation(
        theme: selected,
        score: 85,
        reason: 'Perfect for ${_getTimeOfDay(hour)}',
      );
    } catch (e) {
      debugPrint('❌ Error getting time-based recommendation: $e');
      return null;
    }
  }

  /// Get trending themes (most used in last 7 days)
  Future<List<ThemeRecommendation>> getTrendingThemes({int limit = 5}) async {
    try {
      final trending = await _analyticsService.getMostUsedThemesInDays(7);
      final allThemes = await _customThemeService.getAllCustomThemes();

      final recommendations = trending.map((analytic) {
        final theme = allThemes.firstWhere(
          (t) => t.id == analytic.themeId,
          orElse: () =>
              CustomTheme(id: '', name: '', primaryColor: '#000000', accentColor: '#ffffff', backgroundColor: '#000000', secondaryColor: '#333333'),
        );

        return ThemeRecommendation(
          theme: theme,
          score: analytic.usageCount * 10,
          reason: 'Trending with ${analytic.usageCount} uses this week',
        );
      }).toList();

      return recommendations.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting trending themes: $e');
      return [];
    }
  }

  /// Get similar themes based on theme properties
  Future<List<ThemeRecommendation>> getSimilarThemes(
    String themeId, {
    int limit = 5,
  }) async {
    try {
      final baseTheme = await _customThemeService.getCustomTheme(themeId);
      if (baseTheme == null) return [];

      final allThemes = await _customThemeService.getAllCustomThemes();
      final similar = <ThemeRecommendation>[];

      for (final theme in allThemes) {
        if (theme.id == themeId) continue;

        int score = 0;

        // Same dark mode
        if (theme.isDarkMode == baseTheme.isDarkMode) score += 30;

        // Same animation type
        if (theme.animationType == baseTheme.animationType) score += 40;

        // Similar animation speed
        if ((theme.animationSpeed - baseTheme.animationSpeed).abs() < 0.3) {
          score += 20;
        }

        // Similar color tone
        if (theme.primaryColor.length == baseTheme.primaryColor.length) {
          score += 10;
        }

        similar.add(
          ThemeRecommendation(
            theme: theme,
            score: score,
            reason: 'Similar to ${baseTheme.name}',
          ),
        );
      }

      similar.sort((a, b) => b.score.compareTo(a.score));
      return similar.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting similar themes: $e');
      return [];
    }
  }

  String _generateReason(
    CustomTheme theme,
    bool isPopular,
    int engagementScore,
  ) {
    if (isPopular && engagementScore > 70) {
      return '⭐ Popular & Highly Engaged';
    } else if (isPopular) {
      return '⭐ Popular with users';
    } else if (engagementScore > 70) {
      return '🔥 Highly engaging';
    } else if (theme.animationType == 'shimmer') {
      return '✨ Beautiful animations';
    } else {
      return '💎 Great choice';
    }
  }

  String _getTimeOfDay(int hour) {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    return 'evening';
  }
}

/// Theme Recommendation Model
class ThemeRecommendation {
  final CustomTheme theme;
  final int score; // 0-100
  final String reason;

  ThemeRecommendation({
    required this.theme,
    required this.score,
    required this.reason,
  });

  @override
  String toString() =>
      'ThemeRecommendation(${theme.name}, score: $score, reason: $reason)';
}

/// Global instance
final recommendationEngine = RecommendationEngine();


