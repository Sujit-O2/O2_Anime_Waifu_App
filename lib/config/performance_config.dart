/// Performance optimization settings
class PerformanceConfig {
  /// Enable/disable performance monitoring
  static const bool enableMonitoring = false; // Set to false in release

  /// Cache network responses for this duration
  static const Duration networkCacheDuration = Duration(hours: 1);

  /// Maximum concurrent downloads
  static const int maxConcurrentDownloads = 3;

  /// Image quality optimization
  static const bool compressImages = true;
  static const int imageCompressionQuality = 80;

  /// Lazy load non-critical services
  static const bool lazyLoadServices = true;

  /// Disable animations on low-end devices
  static const bool respectAnimationSettings = true;

  /// Pre-cache frequently used fonts
  static const bool preCacheFonts = true;

  /// Enable frame throttling for expensive operations
  static const int frameThrottleMs = 16; // 60 FPS

  /// Limit rebuild frequency for expensive widgets
  static const Duration rebuildThrottle = Duration(milliseconds: 250);

  /// Memory limits
  static const int maxCacheItems = 100;
  static const int maxCacheMemoryMB = 100;

  /// Database optimization
  static const bool useQueryOptimization = true;
  static const bool enableIndexing = true;

  /// Firebase optimization
  static const int firestoreBatchSize = 100;
  static const Duration firestoreCacheDuration = Duration(minutes: 5);
}
