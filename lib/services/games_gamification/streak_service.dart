import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily watching/reading streaks for gamification.
class StreakService {
  static const String _lastDateKey = 'streak_last_date';
  static const String _currentKey = 'streak_current';
  static const String _bestKey = 'streak_best';
  static const String _totalDaysKey = 'streak_total_days';

  /// Call this when user watches an episode or reads a chapter.
  static Future<StreakInfo> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateString(DateTime.now());
    final lastDate = prefs.getString(_lastDateKey) ?? '';

    int current = prefs.getInt(_currentKey) ?? 0;
    int best = prefs.getInt(_bestKey) ?? 0;
    int totalDays = prefs.getInt(_totalDaysKey) ?? 0;

    if (lastDate == today) {
      // Already recorded today
      return StreakInfo(current: current, best: best, totalDays: totalDays);
    }

    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
    if (lastDate == yesterday) {
      current++;
    } else {
      current = 1; // Streak broken, restart
    }

    totalDays++;
    if (current > best) best = current;

    await prefs.setString(_lastDateKey, today);
    await prefs.setInt(_currentKey, current);
    await prefs.setInt(_bestKey, best);
    await prefs.setInt(_totalDaysKey, totalDays);

    return StreakInfo(current: current, best: best, totalDays: totalDays);
  }

  static Future<StreakInfo> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastDateKey) ?? '';
    int current = prefs.getInt(_currentKey) ?? 0;
    final best = prefs.getInt(_bestKey) ?? 0;
    final totalDays = prefs.getInt(_totalDaysKey) ?? 0;

    // Check if streak is still active
    final today = _dateString(DateTime.now());
    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
    if (lastDate != today && lastDate != yesterday) {
      current = 0; // Streak broken
    }

    return StreakInfo(current: current, best: best, totalDays: totalDays);
  }

  static String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Get the badge emoji for a streak level
  static String streakBadge(int streak) {
    if (streak >= 365) return '👑';
    if (streak >= 100) return '💎';
    if (streak >= 30) return '🏆';
    if (streak >= 14) return '⚡';
    if (streak >= 7) return '🔥';
    if (streak >= 3) return '✨';
    return '🌱';
  }
}

class StreakInfo {
  final int current;
  final int best;
  final int totalDays;
  const StreakInfo({required this.current, required this.best, required this.totalDays});
}


