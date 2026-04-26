import 'dart:async';
import 'dart:typed_data';

import 'package:anime_waifu/core/error_handler.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Image Cache Manager
/// Implements 3-layer caching: Memory → Disk → Network
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();

  factory ImageCacheManager() {
    return _instance;
  }

  ImageCacheManager._internal();

  // Memory cache (in-memory storage)
  final Map<String, CachedImage> _memoryCache = {};

  // Cache manager (disk cache)
  late CacheManager _cacheManager;
  bool _isInitialized = false;

  // Configuration
  static const int maxMemoryCacheSize = 60;
  static const Duration memoryCacheDuration = Duration(hours: 12);
  static const Duration diskCacheDuration = Duration(days: 3);
  static const int maxDiskCacheObjects = 40;

  /// Initialize cache manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _cacheManager = CacheManager(
        Config(
          'anime_waifu_cache',
          stalePeriod: diskCacheDuration,
          maxNrOfCacheObjects: maxDiskCacheObjects,
          repo: JsonCacheInfoRepository(databaseName: 'anime_waifu_cache'),
        ),
      );
      _isInitialized = true;
      startAutoCleanup(interval: const Duration(hours: 2));

      if (kDebugMode) debugPrint('✅ Image Cache Manager initialized');
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ Error initializing Image Cache Manager: $e');
    }
  }

  /// Get image from cache or network
  Future<Result<Uint8List>> getImage(String imageUrl) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      // 1. Check memory cache first (fastest)
      final memoryCached = _getFromMemoryCache(imageUrl);
      if (memoryCached != null) {
        if (kDebugMode) debugPrint('✅ Image loaded from memory cache');
        return Result.success(memoryCached);
      }

      // 2. Check disk cache (fast), fallback to network fetch
      final diskCached = await _getFromDiskOrNetworkCache(imageUrl);
      if (diskCached != null) {
        if (kDebugMode) debugPrint('✅ Image loaded from disk cache');
        _addToMemoryCache(imageUrl, diskCached);
        return Result.success(diskCached);
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
    // Refresh insertion order so this behaves like a simple LRU.
    _memoryCache.remove(key);

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
  Future<Uint8List?> _getFromDiskOrNetworkCache(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      final data = await file.readAsBytes();
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error downloading image: $e');
      return null;
    }
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
    if (kDebugMode) debugPrint('✅ Memory cache cleared');
  }

  /// Clear disk cache
  Future<void> clearDiskCache() async {
    if (!_isInitialized) return;
    try {
      await _cacheManager.emptyCache();
      if (kDebugMode) debugPrint('✅ Disk cache cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearing disk cache: $e');
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    clearMemoryCache();
    await clearDiskCache();
    if (kDebugMode) debugPrint('✅ All caches cleared');
  }

  /// Get cache size statistics
  Future<CacheStatistics> getCacheStatistics() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      final memoryCacheSize = _memoryCache.length;
      int diskCacheSize = 0;

      // flutter_cache_manager does not expose a stable public API for listing
      // disk entries across versions, so keep this to the known memory count.

      return CacheStatistics(
        memoryCacheSize: memoryCacheSize,
        diskCacheSize: diskCacheSize,
        totalSize: memoryCacheSize + diskCacheSize,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting cache statistics: $e');
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
      if (kDebugMode) debugPrint('✅ Preloaded ${imageUrls.length} images');
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
      if (!_isInitialized) {
        await initialize();
      }
      _memoryCache.remove(imageUrl);
      await _cacheManager.removeFile(imageUrl);
      if (kDebugMode) debugPrint('✅ Image removed from cache: $imageUrl');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error removing image: $e');
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
      if (kDebugMode)
        debugPrint('✅ Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  /// Auto cleanup on a timer
  Timer? _cleanupTimer;

  void startAutoCleanup({Duration interval = const Duration(hours: 1)}) {
    _cleanupTimer = Timer.periodic(interval, (_) {
      cleanupExpiredCache();
    });
    if (kDebugMode)
      debugPrint(
          '✅ Auto cleanup started (interval: ${interval.inMinutes} minutes)');
  }

  void stopAutoCleanup() {
    _cleanupTimer?.cancel();
    if (kDebugMode) debugPrint('✅ Auto cleanup stopped');
  }

  /// Dispose resources
  Future<void> dispose() async {
    stopAutoCleanup();
    clearMemoryCache();
    if (kDebugMode) debugPrint('✅ Image Cache Manager disposed');
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
