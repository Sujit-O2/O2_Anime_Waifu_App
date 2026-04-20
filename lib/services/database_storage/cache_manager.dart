import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache Manager - Smart caching for images, data, and API responses
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  static const String _cacheKey = 'cache_data';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100 MB
  static const Duration _defaultTTL = Duration(hours: 24);

  late SharedPreferences _prefs;
  final _cache = <String, CacheEntry>{};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ Cache Manager initialized');
  }

  /// Cache data with TTL
  Future<void> cache(
    String key,
    dynamic value, {
    Duration ttl = _defaultTTL,
  }) async {
    try {
      final entry = CacheEntry(
        key: key,
        value: jsonEncode(value),
        expiresAt: DateTime.now().add(ttl),
        createdAt: DateTime.now(),
      );

      _cache[key] = entry;
      await _prefs.setString(_cacheKey, jsonEncode(_serializeCache()));
      debugPrint('✅ Cached: $key (TTL: ${ttl.inHours}h)');
    } catch (e) {
      debugPrint('❌ Error caching data: $e');
    }
  }

  /// Get cached data
  Future<T?> get<T>(String key) async {
    try {
      if (_cache.containsKey(key)) {
        final entry = _cache[key]!;
        
        // Check if expired
        if (entry.expiresAt.isBefore(DateTime.now())) {
          await remove(key);
          return null;
        }

        final value = jsonDecode(entry.value) as T;
        debugPrint('✅ Cache hit: $key');
        return value;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error retrieving cached data: $e');
      return null;
    }
  }

  /// Cache image URL
  Future<void> cacheImageUrl(String url, String base64Data) async {
    await cache('img_$url', base64Data, ttl: const Duration(days: 7));
  }

  /// Get cached image
  Future<String?> getCachedImage(String url) async {
    return get<String>('img_$url');
  }

  /// Lazy load data - only load if not cached
  Future<T?> lazyLoad<T>(
    String key,
    Future<T> Function() loader, {
    Duration ttl = _defaultTTL,
  }) async {
    try {
      // Check cache first
      final cached = await get<T>(key);
      if (cached != null) return cached;

      // Load fresh data
      final data = await loader();
      await cache(key, data, ttl: ttl);
      return data;
    } catch (e) {
      debugPrint('❌ Error in lazy load: $e');
      return null;
    }
  }

  /// Remove cached data
  Future<void> remove(String key) async {
    try {
      _cache.remove(key);
      await _prefs.setString(_cacheKey, jsonEncode(_serializeCache()));
      debugPrint('✅ Removed from cache: $key');
    } catch (e) {
      debugPrint('❌ Error removing cached data: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    try {
      _cache.clear();
      await _prefs.remove(_cacheKey);
      debugPrint('✅ Cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Clean expired entries
  Future<void> cleanExpired() async {
    try {
      final now = DateTime.now();
      final expiredKeys = _cache.entries
          .where((e) => e.value.expiresAt.isBefore(now))
          .map((e) => e.key)
          .toList();

      for (final key in expiredKeys) {
        _cache.remove(key);
      }

      if (expiredKeys.isNotEmpty) {
        await _prefs.setString(_cacheKey, jsonEncode(_serializeCache()));
        debugPrint('✅ Cleaned ${expiredKeys.length} expired cache entries');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning cache: $e');
    }
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    await cleanExpired();
    
    int totalSize = 0;
    for (final entry in _cache.values) {
      totalSize += entry.value.length;
    }

    return CacheStats(
      entriesCount: _cache.length,
      totalSizeBytes: totalSize,
      maxSizeBytes: _maxCacheSize,
      usagePercentage: totalSize > 0 ? (totalSize / _maxCacheSize) * 100 : 0,
    );
  }

  Map<String, dynamic> _serializeCache() {
    final result = <String, dynamic>{};
    for (final entry in _cache.entries) {
      result[entry.key] = entry.value.toJson();
    }
    return result;
  }
}

/// Cache Entry Model
class CacheEntry {
  final String key;
  final String value;
  final DateTime expiresAt;
  final DateTime createdAt;

  CacheEntry({
    required this.key,
    required this.value,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'expiresAt': expiresAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Cache Statistics
class CacheStats {
  final int entriesCount;
  final int totalSizeBytes;
  final int maxSizeBytes;
  final double usagePercentage;

  CacheStats({
    required this.entriesCount,
    required this.totalSizeBytes,
    required this.maxSizeBytes,
    required this.usagePercentage,
  });

  String get humanReadableSize =>
      '${(totalSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB';

  @override
  String toString() =>
      'CacheStats(entries: $entriesCount, size: $humanReadableSize, usage: ${usagePercentage.toStringAsFixed(1)}%)';
}

/// Global instance
final cacheManager = CacheManager();


