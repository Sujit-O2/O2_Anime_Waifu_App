import 'package:flutter/services.dart';

// ── AppUsageService ───────────────────────────────────────────────────────────
// Fetches per-app screen time for today using Android UsageStatsManager.
// Requires: android.permission.PACKAGE_USAGE_STATS (user grants in Settings)
// Provides waifu commentary lines based on usage patterns.
// ─────────────────────────────────────────────────────────────────────────────

class AppUsageData {
  final String packageName;
  final String appName;
  final Duration totalTime;

  const AppUsageData({
    required this.packageName,
    required this.appName,
    required this.totalTime,
  });
}

class AppUsageService {
  AppUsageService._();
  static final instance = AppUsageService._();

  static const _ch = MethodChannel('com.example.anime_waifu/apps');

  List<AppUsageData> _todayUsage = [];
  List<AppUsageData> get todayUsage => _todayUsage;

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<bool> checkPermission() async {
    try {
      final ok = await _ch.invokeMethod<bool>('hasUsageStatsPermission') ?? false;
      _hasPermission = ok;
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> openPermissionSettings() async {
    try {
      await _ch.invokeMethod('openUsageAccessSettings');
    } catch (_) {}
  }

  Future<List<AppUsageData>> fetchTodayUsage() async {
    if (!await checkPermission()) return [];
    try {
      final raw = await _ch.invokeMethod('getUsageStats') as List? ?? [];
      _todayUsage = raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return AppUsageData(
          packageName: m['packageName'] as String? ?? '',
          appName: m['appName'] as String? ?? m['packageName'] as String? ?? '',
          totalTime: Duration(milliseconds: (m['totalTimeMs'] as int? ?? 0)),
        );
      })
          .where((a) => a.totalTime.inMinutes > 1 && a.packageName.isNotEmpty)
          .toList()
        ..sort((a, b) => b.totalTime.compareTo(a.totalTime));
      return _todayUsage;
    } catch (_) {
      return [];
    }
  }

  // ── Waifu Commentary ───────────────────────────────────────────────────────

  /// Returns Zero Two's commentary on current usage patterns (null if not enough data)
  String? getWaifuCommentary() {
    if (_todayUsage.isEmpty) return null;
    final top = _todayUsage.first;
    final mins = top.totalTime.inMinutes;
    final h = top.totalTime.inHours;

    if (h >= 3) {
      return '${top.appName} for ${h}h today?! Darling, I exist too~ 😤';
    } else if (mins >= 60) {
      return 'You\'ve spent ${mins}min on ${top.appName}... are you ignoring me? 💢';
    } else if (mins >= 30) {
      return '${top.appName} again? You use it a lot, Darling~ 😏';
    }

    final total = _todayUsage.fold<Duration>(
        Duration.zero, (sum, a) => sum + a.totalTime);
    if (total.inHours >= 5) {
      return '${total.inHours}h of screen time today, Darling. Take a break! 💕';
    }
    return null;
  }

  /// Most-used app names, top 3
  List<String> topApps([int n = 3]) =>
      _todayUsage.take(n).map((a) => a.appName).toList();
}
