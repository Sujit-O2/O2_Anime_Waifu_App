import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Singleton Service Locator (without external dependencies)
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  // Service storage
  final Map<Type, dynamic> _services = {};

  /// Register a singleton service
  void registerSingleton<T>(T instance) {
    _services[T] = instance;
  }

  /// Get a service by type
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not found in locator');
    }
    return service as T;
  }

  /// Check if service is registered
  bool has<T>() {
    return _services.containsKey(T);
  }

  /// Reset all services
  void reset() {
    _services.clear();
  }
}

/// Global service locator instance
final locator = ServiceLocator();

/// Initialize all services
/// Example usage - customize based on your actual services
Future<void> setupServiceLocator() async {
  try {
    if (kDebugMode) debugPrint('🔧 Initializing Service Locator...');

    // Example: Register Performance Optimization Service
    // Uncomment when service is available
    // locator.registerSingleton<PerformanceOptimizationService>(
    //   PerformanceOptimizationService(),
    // );

    // Example: Register Mobile First UI Service
    // locator.registerSingleton<MobileFirstUIService>(
    //   MobileFirstUIService(),
    // );

    // Add more service registrations here as needed...

    if (kDebugMode) debugPrint('✅ Service Locator initialized');
    if (kDebugMode) debugPrint('✅ Services ready to use');
  } catch (e) {
    if (kDebugMode) debugPrint('❌ Error initializing Service Locator: $e');
    rethrow;
  }
}


