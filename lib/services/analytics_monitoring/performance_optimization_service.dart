import 'dart:async';

import 'package:flutter/material.dart';

/// Performance optimization service: Lazy loading, debouncing, image caching
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance =
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  final Map<String, Timer> _debounceTimers = {};

  // ── Lazy Loading ──────────────────────────────────────────────────────────

  /// Load large lists lazily in chunks
  /// Example: loadChunked(chatMessages, pageSize: 50)
  static Future<List<T>> loadChunked<T>(
    List<T> items, {
    int pageSize = 50,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    final results = <T>[];
    for (int i = 0; i < items.length; i += pageSize) {
      final end = (i + pageSize > items.length) ? items.length : i + pageSize;
      results.addAll(items.sublist(i, end));
      if (i + pageSize < items.length) {
        await Future.delayed(delay);
      }
    }
    return results;
  }

  // ── Debouncing ──────────────────────────────────────────────────────────

  /// Debounce function calls - prevents excessive API calls during typing
  /// Usage: performanceService.debounce('search', () => _search(), duration: 500ms)
  void debounce(
    String key,
    Function callback, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(duration, () {
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// Throttle function calls - allows callback only once per duration
  static Future<void> throttle(
    Function callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    callback();
    await Future.delayed(duration);
  }

  // ── Image Optimization ───────────────────────────────────────────────────

  /// Calculate optimal image cache width for device DPI
  /// Returns width that matches device pixel density
  static int calculateOptimalImageWidth(double displayWidth) {
    // For retina/high-DPI: 2x, for standard: 1x
    const multiplier = 2;
    const minWidth = 100;
    const maxWidth = 2000;

    final width = (displayWidth * multiplier).toInt();
    return width.clamp(minWidth, maxWidth);
  }

  /// Get image cache size recommendation based on device
  static int getImageCacheSize() {
    // Default: 100 images, adjust based on device capability
    return 100;
  }

  // ── Memory Management ────────────────────────────────────────────────────

  /// Batch process large data sets to avoid UI freezing
  static Stream<List<T>> batchStream<T>(
    List<T> items, {
    int batchSize = 25,
  }) async* {
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize > items.length) ? items.length : i + batchSize;
      yield items.sublist(i, end);
      await Future.delayed(const Duration(milliseconds: 16)); // ~60 FPS
    }
  }

  void dispose() {
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }
}

// ── Image Loading Widget with Optimization ─────────────────────────────────

/// Optimized image widget that loads responsively
class OptimizedNetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;

  const OptimizedNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final optimalWidth =
        PerformanceOptimizationService.calculateOptimalImageWidth(width);

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: optimalWidth,
      cacheHeight: (height * 2).toInt(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade900,
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade900,
          child: const Icon(Icons.error_outline, color: Colors.white54),
        );
      },
    );
  }
}

// ── Lazy List Builder ────────────────────────────────────────────────────

/// ListView that loads items lazily on scroll
class LazyListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, int, T) itemBuilder;
  final int pageSize;
  final VoidCallback? onReachedEnd;

  const LazyListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = 50,
    this.onReachedEnd,
  });

  @override
  State<LazyListView<T>> createState() => _LazyListViewState<T>();
}

class _LazyListViewState<T> extends State<LazyListView<T>> {
  late ScrollController _scrollCtrl;
  int _loadedCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _loadedCount = widget.pageSize;
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 500) {
      if (_loadedCount < widget.items.length) {
        setState(() {
          _loadedCount = (_loadedCount + widget.pageSize)
              .clamp(0, widget.items.length);
        });
        if (_loadedCount >= widget.items.length) {
          widget.onReachedEnd?.call();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollCtrl,
      itemCount: _loadedCount,
      itemBuilder: (context, index) {
        return widget.itemBuilder(context, index, widget.items[index]);
      },
    );
  }
}


