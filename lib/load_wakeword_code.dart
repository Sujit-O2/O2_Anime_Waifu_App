import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

class WakeWordService {
  PorcupineManager? _manager;
  bool _running = false;
  bool _initialized = false;
  bool _initializing = false;
  bool _reinitRequired = false;
  String _accessKeyOverride = "";
  WakeWordCallback? _onDetected;

  // Paths tried in order. Must match exactly what is declared in pubspec.yaml
  // assets section. porcupine_flutter v4 extracts Flutter assets by this path.
  static const List<String> _keywordPathCandidates = [
    "Baby-girl_en_android_v4_0_0.ppn",
  ];

  void configure({String? accessKeyOverride}) {
    if (accessKeyOverride == null) return;
    final normalized = accessKeyOverride.trim();
    if (normalized == _accessKeyOverride) return;
    _accessKeyOverride = normalized;
    _reinitRequired = true;
  }

  Future<void> init(
    WakeWordCallback onDetected, {
    bool startImmediately = true,
  }) async {
    _onDetected = onDetected;
    if (_initializing) return;
    if (_initialized && !_reinitRequired) return;
    _initializing = true;

    try {
      await _disposeManager();
      final accessKey = _resolveAccessKey();
      if (accessKey.isEmpty) {
        throw Exception('WAKE_WORD_KEY/PICOVOICE_KEY is missing in .env');
      }

      PorcupineManager? manager;
      Object? lastError;
      for (final keywordPath in _keywordPathCandidates) {
        try {
          manager = await PorcupineManager.fromKeywordPaths(
            accessKey,
            [keywordPath],
            _handleWakeWordDetected,
            sensitivities: [0.6],
            errorCallback: _handleWakeWordError,
          );
          break;
        } catch (e) {
          lastError = e;
        }
      }

      if (manager == null) {
        throw Exception(
          "Failed to initialize wake word model. Last error: $lastError",
        );
      }

      _manager = manager;
      if (startImmediately) {
        await _manager!.start();
        _running = true;
      } else {
        _running = false;
      }
      _initialized = true;
      _reinitRequired = false;
    } finally {
      _initializing = false;
    }
  }

  String _resolveAccessKey() {
    if (_accessKeyOverride.trim().isNotEmpty) return _accessKeyOverride.trim();
    final wakeKey = dotenv.env['WAKE_WORD_KEY']?.trim() ?? '';
    if (wakeKey.isNotEmpty) return wakeKey;
    return dotenv.env['PICOVOICE_KEY']?.trim() ?? '';
  }

  void _handleWakeWordDetected(int keywordIndex) {
    final callback = _onDetected;
    if (callback == null) return;
    callback(keywordIndex);
  }

  void _handleWakeWordError(dynamic error) {
    // Use print (not debugPrint) so this is visible in release builds too.
    // ignore: avoid_print
    print("[WakeWord] Runtime error: $error");
  }

  Future<void> _disposeManager() async {
    final manager = _manager;
    if (manager == null) {
      _running = false;
      _initialized = false;
      return;
    }

    try {
      if (_running) {
        await manager.stop();
      }
    } catch (_) {}

    try {
      await manager.delete();
    } catch (_) {}

    _manager = null;
    _running = false;
    _initialized = false;
  }

  Future<void> dispose() async {
    await _disposeManager();
    _reinitRequired = false;
    _onDetected = null;
  }

  Future<void> stop() async {
    final manager = _manager;
    if (manager != null && _running) {
      await manager.stop();
      _running = false;
    }
  }

  Future<void> start() async {
    if (_initializing) return;
    if (_reinitRequired) {
      final callback = _onDetected;
      if (callback == null) return;
      await init(callback);
      return;
    }

    if (!_initialized || _manager == null) {
      final callback = _onDetected;
      if (callback == null) return;
      await init(callback);
      return;
    }

    if (!_running) {
      await _manager!.start();
      _running = true;
    }
  }

  bool get isRunning => _running;
}
