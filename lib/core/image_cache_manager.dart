import 'dart:async';

import 'package:anime_waifu/core/error_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Image Cache Manager
/// Implements 3-layer caching: Memory → Disk → Network
class ImageCacheManager {
  static final ImageCacheManager _instance =
      ImageCacheManager._internal();

  factory ImageCacheManager() {
    return _instance;
  }

  ImageCacheManager._internal();

  // Memory cache (in-memory storage)
  final Map<String, CachedImage> _memoryCache = {};

  // Cache manager (disk cache)
  late CacheManager _cacheManager;

  // Configuration
  static const int maxMemoryCacheSize = 100;
  static const Duration memoryCacheDuration = Duration(hours: 24);
  static const Duration diskCacheDuration = Duration(days: 7);

  /// Initialize cache manager
  Future<void> initialize() async {
    try {
      _cacheManager = CacheManager(
        Config(
          'anime_waifu_cache',
          stalePeriod: diskCacheDuration,
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: 'anime_waifu_cache'),
        ),
      );

      debugPrint('✅ Image Cache Manager initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Image Cache Manager: $e');
    }
  }

  /// Get image from cache or network
  Future<Result<Uint8List>> getImage(String imageUrl) async {
    try {
      // 1. Check memory cache first (fastest)
      final memoryCached = _getFromMemoryCache(imageUrl);
      if (memoryCached != null) {
        debugPrint('✅ Image loaded from memory cache');
        return Result.success(memoryCached);
      }

      // 2. Check disk cache (fast)
      final diskCached = await _getFromDiskCache(imageUrl);
      if (diskCached != null) {
        debugPrint('✅ Image loaded from disk cache');
        _addToMemoryCache(imageUrl, diskCached);
        return Result.success(diskCached);
      }

      // 3. Download from network (slow)
      final networkImage = await _downloadImage(imageUrl);
      if (networkImage != null) {
        debugPrint('✅ Image downloaded from network');
        _addToMemoryCache(imageUrl, networkImage);
        return Result.success(networkImage);
      }

      return Result.failure(
        AppException(message: 'Failed to load image: $imageUrl'),
      );
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Get from memory cache
  Uint8List? _getFromMemoryCache(String key) {
    final cached = _memoryCache[key];

    if (cached != null) {
      // Check if expired
      if (DateTime.now().isBefore(cached.expireAt)) {
        return cached.data;
      } else {
        _memoryCache.remove(key);
      }
    }

    return null;
  }

  /// Add to memory cache
  void _addToMemoryCache(String key, Uint8List data) {
    // Check cache size limit
    if (_memoryCache.length >= maxMemoryCacheSize) {
      // Remove oldest entry
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[key] = CachedImage(
      data: data,
      expireAt: DateTime.now().add(memoryCacheDuration),
    );
  }

  /// Get from disk cache
  Future<Uint8List?> _getFromDiskCache(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      final data = await file.readAsBytes();
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Download image from network
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      final data = await file.readAsBytes();
      return data;
    } catch (e) {
      debugPrint('❌ Error downloading image: $e');
      return null;
    }
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
    debugPrint('✅ Memory cache cleared');
  }

  /// Clear disk cache
  Future<void> clearDiskCache() async {
    try {
      await _cacheManager.emptyCache();
      debugPrint('✅ Disk cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing disk cache: $e');
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    clearMemoryCache();
    await clearDiskCache();
    debugPrint('✅ All caches cleared');
  }

  /// Get cache size statistics
  Future<CacheStatistics> getCacheStatistics() async {
    try {
      final memoryCacheSize = _memoryCache.length;
      int diskCacheSize = 0;
      
      try {
        // Try to get disk cache file count
        diskCacheSize = _memoryCache.length; // Placeholder
      } catch (e) {
        // Silently fail if cache manager doesn't support listing
      }

      return CacheStatistics(
        memoryCacheSize: memoryCacheSize,
        diskCacheSize: diskCacheSize,
        totalSize: memoryCacheSize + diskCacheSize,
      );
    } catch (e) {
      debugPrint('❌ Error getting cache statistics: $e');
      return CacheStatistics(
        memoryCacheSize: 0,
        diskCacheSize: 0,
        totalSize: 0,
      );
    }
  }

  /// Preload image into cache
  Future<Result<void>> preloadImage(String imageUrl) async {
    try {
      await getImage(imageUrl);
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Preload multiple images
  Future<Result<void>> preloadImages(List<String> imageUrls) async {
    try {
      final futures = imageUrls.map((url) => getImage(url));
      await Future.wait(futures);
      debugPrint('✅ Preloaded ${imageUrls.length} images');
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        ErrorHandler.handleException(e, stackTrace),
      );
    }
  }

  /// Remove specific image from cache
  Future<void> removeImage(String imageUrl) async {
    try {
      _memoryCache.remove(imageUrl);
      await _cacheManager.removeFile(imageUrl);
      debugPrint('✅ Image removed from cache: $imageUrl');
    } catch (e) {
      debugPrint('❌ Error removing image: $e');
    }
  }

  /// Get memory cache size
  int getMemoryCacheSize() {
    return _memoryCache.length;
  }

  /// Get memory cache usage percentage
  double getMemoryCacheUsagePercentage() {
    return (_memoryCache.length / maxMemoryCacheSize) * 100;
  }

  /// Get all cached image keys
  List<String> getCachedImageKeys() {
    return _memoryCache.keys.toList();
  }

  /// Cleanup expired memory cache entries
  void cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _memoryCache.entries
        .where((entry) => now.isAfter(entry.value.expireAt))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('✅ Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  /// Auto cleanup on a timer
  Timer? _cleanupTimer;

  void startAutoCleanup({Duration interval = const Duration(hours: 1)}) {
    _cleanupTimer = Timer.periodic(interval, (_) {
      cleanupExpiredCache();
    });
    debugPrint('✅ Auto cleanup started (interval: ${interval.inMinutes} minutes)');
  }

  void stopAutoCleanup() {
    _cleanupTimer?.cancel();
    debugPrint('✅ Auto cleanup stopped');
  }

  /// Dispose resources
  Future<void> dispose() async {
    stopAutoCleanup();
    clearMemoryCache();
    debugPrint('✅ Image Cache Manager disposed');
  }
}

/// Cached image model
class CachedImage {
  final Uint8List data;
  final DateTime expireAt;

  CachedImage({
    required this.data,
    required this.expireAt,
  });
}

/// Cache statistics
class CacheStatistics {
  final int memoryCacheSize;
  final int diskCacheSize;
  final int totalSize;

  CacheStatistics({
    required this.memoryCacheSize,
    required this.diskCacheSize,
    required this.totalSize,
  });

  @override
  String toString() {
    return 'CacheStatistics(memory: $memoryCacheSize, disk: $diskCacheSize, total: $totalSize)';
  }
}



