import 'package:anime_waifu/services/analytics_monitoring/email_success_analytics_service.dart';
import 'package:anime_waifu/services/analytics_monitoring/firebase_analytics_service.dart';
import 'package:anime_waifu/services/analytics_monitoring/theme_usage_analytics_service.dart';
import 'package:anime_waifu/services/analytics_monitoring/user_action_logging_service.dart';
import 'package:flutter/foundation.dart';

/// Analytics Dashboard Service - Unified analytics dashboard and reporting
class AnalyticsDashboardService {
  static final AnalyticsDashboardService _instance =
      AnalyticsDashboardService._internal();
  factory AnalyticsDashboardService() => _instance;
  AnalyticsDashboardService._internal();

  // Service instances
  late FirebaseAnalyticsService _firebaseAnalyticsService;
  late UserActionLoggingService _userActionLoggingService;

  Future<void> initialize() async {
    _firebaseAnalyticsService = FirebaseAnalyticsService();
    _userActionLoggingService = UserActionLoggingService();
    debugPrint('✅ Analytics Dashboard Service initialized');
  }

  /// Get comprehensive dashboard data
  Future<DashboardData> getDashboardData() async {
    try {
      // Gather data from all analytics services
      final firebaseData = await _firebaseAnalyticsService.getDashboardData();
      final userActionStats = await _userActionLoggingService.getUserActionStats();

      return DashboardData(
        timestamp: DateTime.now(),
        firebaseAnalytics: firebaseData,
        themeUsageStats: null,
        emailMetrics: null,
        userActionStats: userActionStats,
        cacheStats: null,
      );
    } catch (e) {
      debugPrint('❌ Error getting dashboard data: $e');
      return DashboardData(
        timestamp: DateTime.now(),
        firebaseAnalytics: null,
        themeUsageStats: null,
        emailMetrics: null,
        userActionStats: null,
        cacheStats: null,
      );
    }
  }

  /// Get KPI summary
  Future<KPISummary> getKPISummary() async {
    try {
      final mostCommonActions =
          await _userActionLoggingService.getMostCommonActions();

      return KPISummary(
        totalThemeSessions: 0,
        totalThemeMinutes: 0,
        emailSuccessRate: 0,
        emailsSent: 0,
        mostPopularTheme: 'None',
        mostCommonAction: mostCommonActions.isNotEmpty
            ? mostCommonActions.first.name
            : 'None',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting KPI summary: $e');
      return KPISummary(
        totalThemeSessions: 0,
        totalThemeMinutes: 0,
        emailSuccessRate: 0,
        emailsSent: 0,
        mostPopularTheme: 'N/A',
        mostCommonAction: 'N/A',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get performance insights
  Future<PerformanceInsights> getPerformanceInsights() async {
    try {
      return PerformanceInsights(
        cacheUtilization: 0,
        cacheSize: 'N/A',
        averageThemeSessionMinutes: 0,
        totalThemesUsed: 0,
        emailProvidersUsed: 0,
        bestEmailProvider: 'N/A',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting performance insights: $e');
      return PerformanceInsights(
        cacheUtilization: 0,
        cacheSize: 'N/A',
        averageThemeSessionMinutes: 0,
        totalThemesUsed: 0,
        emailProvidersUsed: 0,
        bestEmailProvider: 'N/A',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get user behavior insights
  Future<UserBehaviorInsights> getUserBehaviorInsights() async {
    try {
      final screenUsage =
          await _userActionLoggingService.getMostUsedScreens();
      final commonActions =
          await _userActionLoggingService.getMostCommonActions();
      final hourlyPattern = await _userActionLoggingService.getHourlyActionPattern();
      final sessionSummary =
          await _userActionLoggingService.getUserSessionSummary();

      // Find peak activity hour
      int peakHour = 0;
      int maxCount = 0;
      hourlyPattern.forEach((hour, count) {
        if (count > maxCount) {
          maxCount = count;
          peakHour = hour;
        }
      });

      return UserBehaviorInsights(
        totalActionsLogged: sessionSummary.totalActions,
        uniqueScreensVisited: sessionSummary.uniqueScreens,
        uniqueActionsPerformed: sessionSummary.uniqueActions,
        mostVisitedScreen: screenUsage.isNotEmpty ? screenUsage.first.name : 'N/A',
        mostCommonInteraction: commonActions.isNotEmpty
            ? commonActions.first.name
            : 'N/A',
        peakActivityHour: '$peakHour:00',
        averageActionsPerSession: sessionSummary.uniqueScreens > 0
            ? (sessionSummary.totalActions / sessionSummary.uniqueScreens)
                .toStringAsFixed(1)
            : '0',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting user behavior insights: $e');
      return UserBehaviorInsights(
        totalActionsLogged: 0,
        uniqueScreensVisited: 0,
        uniqueActionsPerformed: 0,
        mostVisitedScreen: 'N/A',
        mostCommonInteraction: 'N/A',
        peakActivityHour: 'N/A',
        averageActionsPerSession: '0',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Generate full analytics report
  Future<AnalyticsReport> generateFullReport() async {
    try {
      final dashboardData = await getDashboardData();
      final kpiSummary = await getKPISummary();
      final performanceInsights = await getPerformanceInsights();
      final behaviorInsights = await getUserBehaviorInsights();

      return AnalyticsReport(
        timestamp: DateTime.now(),
        reportTitle: 'Anime Waifu Analytics Report',
        dashboardData: dashboardData,
        kpiSummary: kpiSummary,
        performanceInsights: performanceInsights,
        userBehaviorInsights: behaviorInsights,
        recommendations: _generateRecommendations(
          kpiSummary,
          performanceInsights,
          behaviorInsights,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error generating full report: $e');
      return AnalyticsReport(
        timestamp: DateTime.now(),
        reportTitle: 'Anime Waifu Analytics Report',
        dashboardData: DashboardData(
          timestamp: DateTime.now(),
          firebaseAnalytics: null,
          themeUsageStats: null,
          emailMetrics: null,
          userActionStats: null,
          cacheStats: null,
        ),
        kpiSummary: KPISummary(
          totalThemeSessions: 0,
          totalThemeMinutes: 0,
          emailSuccessRate: 0,
          emailsSent: 0,
          mostPopularTheme: 'N/A',
          mostCommonAction: 'N/A',
          timestamp: DateTime.now(),
        ),
        performanceInsights: PerformanceInsights(
          cacheUtilization: 0,
          cacheSize: '0 MB',
          averageThemeSessionMinutes: 0,
          totalThemesUsed: 0,
          emailProvidersUsed: 0,
          bestEmailProvider: 'N/A',
          timestamp: DateTime.now(),
        ),
        userBehaviorInsights: UserBehaviorInsights(
          totalActionsLogged: 0,
          uniqueScreensVisited: 0,
          uniqueActionsPerformed: 0,
          mostVisitedScreen: 'N/A',
          mostCommonInteraction: 'N/A',
          peakActivityHour: 'N/A',
          averageActionsPerSession: '0',
          timestamp: DateTime.now(),
        ),
        recommendations: [],
      );
    }
  }

  /// Export report as string
  Future<String> exportReportAsString() async {
    try {
      final report = await generateFullReport();
      final buffer = StringBuffer();

      buffer.writeln('╔════════════════════════════════════════════════════════════╗');
      buffer.writeln('║          ANIME WAIFU - ANALYTICS DASHBOARD REPORT         ║');
      buffer.writeln('╚════════════════════════════════════════════════════════════╝\n');

      buffer.writeln('Generated: ${report.timestamp}\n');

      buffer.writeln('📊 KEY PERFORMANCE INDICATORS (KPI)');
      buffer.writeln('├─ Theme Sessions: ${report.kpiSummary.totalThemeSessions}');
      buffer.writeln('├─ Theme Minutes: ${report.kpiSummary.totalThemeMinutes}');
      buffer.writeln('├─ Emails Sent: ${report.kpiSummary.emailsSent}');
      buffer.writeln('├─ Email Success Rate: ${report.kpiSummary.emailSuccessRate.toStringAsFixed(1)}%');
      buffer.writeln('├─ Most Popular Theme: ${report.kpiSummary.mostPopularTheme}');
      buffer.writeln('└─ Most Common Action: ${report.kpiSummary.mostCommonAction}\n');

      buffer.writeln('⚡ PERFORMANCE INSIGHTS');
      buffer.writeln('├─ Cache Utilization: ${report.performanceInsights.cacheUtilization.toStringAsFixed(1)}%');
      buffer.writeln('├─ Cache Size: ${report.performanceInsights.cacheSize}');
      buffer.writeln('├─ Avg Theme Session: ${report.performanceInsights.averageThemeSessionMinutes} min');
      buffer.writeln('├─ Total Themes Used: ${report.performanceInsights.totalThemesUsed}');
      buffer.writeln('├─ Email Providers: ${report.performanceInsights.emailProvidersUsed}');
      buffer.writeln('└─ Best Email Provider: ${report.performanceInsights.bestEmailProvider}\n');

      buffer.writeln('👥 USER BEHAVIOR');
      buffer.writeln('├─ Total Actions: ${report.userBehaviorInsights.totalActionsLogged}');
      buffer.writeln('├─ Screens Visited: ${report.userBehaviorInsights.uniqueScreensVisited}');
      buffer.writeln('├─ Unique Actions: ${report.userBehaviorInsights.uniqueActionsPerformed}');
      buffer.writeln('├─ Most Visited: ${report.userBehaviorInsights.mostVisitedScreen}');
      buffer.writeln('├─ Common Interaction: ${report.userBehaviorInsights.mostCommonInteraction}');
      buffer.writeln('├─ Peak Hour: ${report.userBehaviorInsights.peakActivityHour}');
      buffer.writeln('└─ Avg Actions/Session: ${report.userBehaviorInsights.averageActionsPerSession}\n');

      buffer.writeln('💡 RECOMMENDATIONS');
      for (final rec in report.recommendations) {
        buffer.writeln('├─ $rec');
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('❌ Error exporting report: $e');
      return 'Error generating report';
    }
  }

  List<String> _generateRecommendations(
    KPISummary kpi,
    PerformanceInsights perf,
    UserBehaviorInsights behavior,
  ) {
    final recommendations = <String>[];

    // KPI-based recommendations
    if (kpi.emailSuccessRate < 90) {
      recommendations.add('⚠️ Email success rate is below 90%. Review email provider settings.');
    } else {
      recommendations.add('✅ Email delivery performing well (${kpi.emailSuccessRate.toStringAsFixed(1)}%)');
    }

    // Performance-based recommendations
    if (perf.cacheUtilization > 80) {
      recommendations.add('⚠️ Cache is ${perf.cacheUtilization.toStringAsFixed(0)}% full. Consider clearing old data.');
    } else {
      recommendations.add('✅ Cache usage is optimal (${perf.cacheUtilization.toStringAsFixed(0)}%)');
    }

    // User behavior recommendations
    if (behavior.totalActionsLogged > 0) {
      recommendations
          .add('✅ Strong user engagement with ${behavior.uniqueActionsPerformed} different interaction types');
    }

    recommendations.add('💡 Peak activity hour: ${behavior.peakActivityHour} - optimize resources during this time');

    return recommendations;
  }
}

/// Dashboard Data Model
class DashboardData {
  final DateTime timestamp;
  final AnalyticsDashboard? firebaseAnalytics;
  final ThemeUsageStats? themeUsageStats;
  final EmailSuccessMetrics? emailMetrics;
  final UserActionStats? userActionStats;
  final CacheStats? cacheStats;

  DashboardData({
    required this.timestamp,
    this.firebaseAnalytics,
    this.themeUsageStats,
    this.emailMetrics,
    this.userActionStats,
    this.cacheStats,
  });
}

/// KPI Summary Model
class KPISummary {
  final int totalThemeSessions;
  final int totalThemeMinutes;
  final double emailSuccessRate;
  final int emailsSent;
  final String mostPopularTheme;
  final String mostCommonAction;
  final DateTime timestamp;

  KPISummary({
    required this.totalThemeSessions,
    required this.totalThemeMinutes,
    required this.emailSuccessRate,
    required this.emailsSent,
    required this.mostPopularTheme,
    required this.mostCommonAction,
    required this.timestamp,
  });
}

/// Performance Insights Model
class PerformanceInsights {
  final double cacheUtilization;
  final String cacheSize;
  final int averageThemeSessionMinutes;
  final int totalThemesUsed;
  final int emailProvidersUsed;
  final String bestEmailProvider;
  final DateTime timestamp;

  PerformanceInsights({
    required this.cacheUtilization,
    required this.cacheSize,
    required this.averageThemeSessionMinutes,
    required this.totalThemesUsed,
    required this.emailProvidersUsed,
    required this.bestEmailProvider,
    required this.timestamp,
  });
}

/// User Behavior Insights Model
class UserBehaviorInsights {
  final int totalActionsLogged;
  final int uniqueScreensVisited;
  final int uniqueActionsPerformed;
  final String mostVisitedScreen;
  final String mostCommonInteraction;
  final String peakActivityHour;
  final String averageActionsPerSession;
  final DateTime timestamp;

  UserBehaviorInsights({
    required this.totalActionsLogged,
    required this.uniqueScreensVisited,
    required this.uniqueActionsPerformed,
    required this.mostVisitedScreen,
    required this.mostCommonInteraction,
    required this.peakActivityHour,
    required this.averageActionsPerSession,
    required this.timestamp,
  });
}

/// Analytics Report Model
class AnalyticsReport {
  final DateTime timestamp;
  final String reportTitle;
  final DashboardData dashboardData;
  final KPISummary kpiSummary;
  final PerformanceInsights performanceInsights;
  final UserBehaviorInsights userBehaviorInsights;
  final List<String> recommendations;

  AnalyticsReport({
    required this.timestamp,
    required this.reportTitle,
    required this.dashboardData,
    required this.kpiSummary,
    required this.performanceInsights,
    required this.userBehaviorInsights,
    required this.recommendations,
  });

  @override
  String toString() => '$reportTitle (${timestamp.toLocal()})';
}

/// Cache Statistics Model
class CacheStats {
  final double usagePercentage;
  final String humanReadableSize;

  CacheStats({
    required this.usagePercentage,
    required this.humanReadableSize,
  });
}

/// Global instance
final analyticsDashboardService = AnalyticsDashboardService();


