import 'package:flutter/foundation.dart';

/// Rate Limiter Service - Prevent abuse with rate limiting
class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();
  factory RateLimiterService() => _instance;
  RateLimiterService._internal();

  final _requestCounts = <String, List<DateTime>>{};
  final _blacklist = <String, DateTime>{};

  /// Check if request is allowed (returns true if allowed, false if rate limited)
  bool allowRequest(
    String identifier, {
    int maxRequests = 10,
    Duration windowSize = const Duration(minutes: 1),
  }) {
    try {
      // Check if identifier is blacklisted
      if (_blacklist.containsKey(identifier)) {
        final blacklistUntil = _blacklist[identifier]!;
        if (DateTime.now().isBefore(blacklistUntil)) {
          debugPrint('⚠️ Request blocked: $identifier (blacklisted until $blacklistUntil)');
          return false;
        } else {
          _blacklist.remove(identifier);
        }
      }

      final now = DateTime.now();
      final windowStart = now.subtract(windowSize);

      // Get or create request list
      if (!_requestCounts.containsKey(identifier)) {
        _requestCounts[identifier] = [];
      }

      // Remove old requests outside window
      _requestCounts[identifier]!
          .removeWhere((time) => time.isBefore(windowStart));

      // Check if within limit
      if (_requestCounts[identifier]!.length >= maxRequests) {
        debugPrint('⚠️ Rate limit exceeded: $identifier (${_requestCounts[identifier]!.length}/$maxRequests)');
        return false;
      }

      // Add current request
      _requestCounts[identifier]!.add(now);
      debugPrint('✅ Request allowed: $identifier (${_requestCounts[identifier]!.length}/$maxRequests)');
      return true;
    } catch (e) {
      debugPrint('❌ Error in rate limiter: $e');
      return true; // Allow on error
    }
  }

  /// Get remaining requests in current window
  int getRemainingRequests(
    String identifier, {
    int maxRequests = 10,
    Duration windowSize = const Duration(minutes: 1),
  }) {
    try {
      final now = DateTime.now();
      final windowStart = now.subtract(windowSize);

      if (!_requestCounts.containsKey(identifier)) {
        return maxRequests;
      }

      final validRequests = _requestCounts[identifier]!
          .where((time) => time.isAfter(windowStart))
          .length;
      return (maxRequests - validRequests).clamp(0, maxRequests);
    } catch (e) {
      debugPrint('❌ Error getting remaining requests: $e');
      return maxRequests;
    }
  }

  /// Blacklist an identifier temporarily
  void blacklistIdentifier(String identifier, Duration duration) {
    try {
      _blacklist[identifier] = DateTime.now().add(duration);
      debugPrint('🚫 Blacklisted: $identifier for ${duration.inMinutes} minutes');
    } catch (e) {
      debugPrint('❌ Error blacklisting identifier: $e');
    }
  }

  /// Check for suspicious activity (multiple failed attempts)
  void recordFailedAttempt(String identifier) {
    try {
      // After 3 failed attempts, blacklist for 5 minutes
      const maxFailedAttempts = 3;
      const blacklistDuration = Duration(minutes: 5);

      if (!_requestCounts.containsKey('failed_$identifier')) {
        _requestCounts['failed_$identifier'] = [];
      }

      final now = DateTime.now();
      _requestCounts['failed_$identifier']!.add(now);

      final failedCount = _requestCounts['failed_$identifier']!.length;

      if (failedCount >= maxFailedAttempts) {
        blacklistIdentifier(identifier, blacklistDuration);
      }

      debugPrint('⚠️ Failed attempt recorded: $identifier ($failedCount/$maxFailedAttempts)');
    } catch (e) {
      debugPrint('❌ Error recording failed attempt: $e');
    }
  }

  /// Reset rate limit for identifier
  void resetRateLimit(String identifier) {
    try {
      _requestCounts.remove(identifier);
      _requestCounts.remove('failed_$identifier');
      _blacklist.remove(identifier);
      debugPrint('✅ Rate limit reset: $identifier');
    } catch (e) {
      debugPrint('❌ Error resetting rate limit: $e');
    }
  }

  /// Get rate limit statistics
  Future<RateLimitStats> getStats() async {
    try {
      int totalIdentifiers = _requestCounts.keys.length;
      int blacklistedCount = _blacklist.length;

      return RateLimitStats(
        totalTrackedIdentifiers: totalIdentifiers,
        blacklistedIdentifiers: blacklistedCount,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error getting rate limit stats: $e');
      return RateLimitStats(
        totalTrackedIdentifiers: 0,
        blacklistedIdentifiers: 0,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Clear all rate limit data
  void clearAll() {
    try {
      _requestCounts.clear();
      _blacklist.clear();
      debugPrint('✅ All rate limit data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing rate limit data: $e');
    }
  }
}

/// Rate Limit Statistics
class RateLimitStats {
  final int totalTrackedIdentifiers;
  final int blacklistedIdentifiers;
  final DateTime timestamp;

  RateLimitStats({
    required this.totalTrackedIdentifiers,
    required this.blacklistedIdentifiers,
    required this.timestamp,
  });

  @override
  String toString() =>
      'RateLimitStats(tracked: $totalTrackedIdentifiers, blacklisted: $blacklistedIdentifiers)';
}

/// Global instance
final rateLimiterService = RateLimiterService();


