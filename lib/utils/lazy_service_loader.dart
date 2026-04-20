import 'package:flutter/foundation.dart';

/// Lazy-loads services in background to not block UI thread
class LazyServiceLoader {
  static final Map<String, Future<void> Function()> _services = {};
  static final Set<String> _initialized = {};

  /// Register a service that should be lazy-loaded
  static void register(String name, Future<void> Function() loader) {
    _services[name] = loader;
  }

  /// Initialize a specific service
  static Future<void> init(String name) async {
    if (_initialized.contains(name)) return;
    final loader = _services[name];
    if (loader != null) {
      try {
        await loader();
        _initialized.add(name);
      } catch (e) {
        debugPrint('❌ Failed to load service $name: $e');
      }
    }
  }

  /// Initialize all critical services first, then load the rest in background
  static Future<void> initCritical(List<String> criticalServices) async {
    // Load critical services immediately
    for (final service in criticalServices) {
      await init(service);
    }

    // Load remaining services in background
    Future.wait(
      _services.keys
          .where((s) => !_initialized.contains(s))
          .map((s) => init(s)),
      eagerError: false,
    ).then((_) {
      debugPrint('✅ All services loaded');
    });
  }
}
