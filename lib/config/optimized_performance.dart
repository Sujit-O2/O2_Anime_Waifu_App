import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PERFORMANCE OPTIMIZATION CONFIG
/// ═══════════════════════════════════════════════════════════════════════════

class PerformanceConfig {
  // ── Animation Durations ────────────────────────────────────────────────
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 400);

  // ── Frame Budget ───────────────────────────────────────────────────────
  static const int targetFPS = 60;
  static const Duration frameBudget = Duration(milliseconds: 16); // 60fps

  // ── Particle System ────────────────────────────────────────────────────
  static const int maxParticles = 30; // Reduced from 50+
  static const int particlePoolSize = 50;
  static const bool enableParticles = true;
  static const bool enableParticlePhysics = true;

  // ── Image Caching ──────────────────────────────────────────────────────
  static const int imageCacheSize = 100; // MB
  static const int imageCacheCount = 1000;
  static const Duration imageCacheExpiry = Duration(days: 7);

  // ── List Performance ───────────────────────────────────────────────────
  static const double listCacheExtent = 500.0;
  static const int maxChatMessagesInMemory = 200;
  static const int chatMessagesPerPage = 50;

  // ── Blur Performance ───────────────────────────────────────────────────
  static const double maxBlurSigma = 12.0;
  static const bool enableBackdropFilter = true;
  static const bool enableGlassmorphism = true;

  // ── Animation Performance ──────────────────────────────────────────────
  static const bool enableHeroAnimations = true;
  static const bool enablePageTransitions = true;
  static const bool enableMicroAnimations = true;

  // ── Debug Settings ─────────────────────────────────────────────────────
  static const bool showPerformanceOverlay = false;
  static const bool debugPaintSizeEnabled = false;
  static const bool debugPaintLayerBordersEnabled = false;

  /// Initialize performance optimizations
  static void initialize() {
    // Set image cache size
    PaintingBinding.instance.imageCache.maximumSize = imageCacheCount;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        imageCacheSize * 1024 * 1024;

    // Enable performance optimizations
    debugProfilePaintsEnabled = false;
  }

  /// Get optimized scroll physics
  static ScrollPhysics getScrollPhysics() {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  /// Get optimized page transition
  static PageTransitionsBuilder getPageTransition() {
    return const CupertinoPageTransitionsBuilder();
  }

  /// Check if device can handle heavy animations
  static bool canHandleHeavyAnimations(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final totalPixels = size.width * size.height * pixelRatio;

    // Devices with > 2M pixels can handle heavy animations
    return totalPixels > 2000000;
  }

  /// Get adaptive blur sigma based on device capability
  static double getAdaptiveBlurSigma(BuildContext context) {
    return canHandleHeavyAnimations(context) ? maxBlurSigma : maxBlurSigma * 0.6;
  }

  /// Get adaptive particle count based on device capability
  static int getAdaptiveParticleCount(BuildContext context) {
    return canHandleHeavyAnimations(context) ? maxParticles : maxParticles ~/ 2;
  }
}

/// Optimized RepaintBoundary wrapper
class OptimizedRepaintBoundary extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const OptimizedRepaintBoundary({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return RepaintBoundary(child: child);
  }
}

/// Optimized AnimatedBuilder with frame budget
class OptimizedAnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, double) builder;

  const OptimizedAnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => builder(context, animation.value),
    );
  }
}

/// Lazy loading wrapper for expensive widgets
class LazyLoadWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const LazyLoadWidget({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    return widget.child;
  }
}

/// Optimized list view builder
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool reverse;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      reverse: reverse,
      physics: PerformanceConfig.getScrollPhysics(),
      cacheExtent: PerformanceConfig.listCacheExtent,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return OptimizedRepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// Debouncer for expensive operations
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler for rate-limiting operations
class Throttler {
  final Duration interval;
  DateTime? _lastCall;

  Throttler({this.interval = const Duration(milliseconds: 300)});

  bool canCall() {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= interval) {
      _lastCall = now;
      return true;
    }
    return false;
  }

  void call(VoidCallback action) {
    if (canCall()) action();
  }
}
