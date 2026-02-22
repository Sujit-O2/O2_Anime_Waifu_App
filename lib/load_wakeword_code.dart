import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

/// Typedef for wake word detection callback
typedef WakeWordCallback = void Function(int keywordIndex);

/// Service for managing wake word detection using Picovoice Porcupine
class WakeWordService {
  PorcupineManager? _manager;
  bool _running = false;
  bool _initialized = false;
  bool _initializing = false;
  bool _reinitRequired = false;
  String _accessKeyOverride = "";
  WakeWordCallback? _onDetected;

  static const String _babyGirlKeyword = "Baby-girl_en_android_v4_0_0.ppn";
  static const String _zeroTwoKeyword = "Hay-Zero-two_en_android_v3_0_0.ppn";
  static const String _darlingKeyword = "Darling_en_android_v4_0_0.ppn";

  // Try paired keywords first so both wake phrases are supported.
  static const List<List<String>> _keywordSetCandidates = [
    [
      "assets/wakeword/Baby-girl_en_android_v4_0_0.ppn",
      "assets/wakeword/Hay-Zero-two_en_android_v3_0_0.ppn",
      "assets/wakeword/Darling_en_android_v4_0_0.ppn",
    ],
  ];

  // Fallback to a single keyword when only one model is packaged.
  static const List<String> _singleKeywordCandidates = [
    "assets/wakeword/Baby-girl_en_android_v4_0_0.ppn",
    "assets/wakeword/Hay-Zero-two_en_android_v3_0_0.ppn",
    "assets/wakeword/Darling_en_android_v4_0_0.ppn",
  ];

  /// Configure access key for Picovoice
  void configure({String? accessKeyOverride}) {
    if (accessKeyOverride == null) return;
    final normalized = _normalizeAccessKey(accessKeyOverride);
    if (normalized == _accessKeyOverride) return;
    _accessKeyOverride = normalized;
    _reinitRequired = true;
  }

  String _normalizeAccessKey(String value) {
    final trimmed = value.trim();
    if (trimmed.length >= 2 &&
        ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
            (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
      return trimmed.substring(1, trimmed.length - 1).trim();
    }
    return trimmed;
  }

  bool _containsToken(String input, List<String> tokens) {
    final lower = input.toLowerCase();
    return tokens.any(lower.contains);
  }

  bool _isActivationLimitError(String error) {
    return _containsToken(error, ['activationlimit', 'activation limit']);
  }

  bool _isAccessKeyError(String error) {
    return _containsToken(
      error,
      ['accesskey', 'access key', 'invalid access key', 'expired access key'],
    );
  }

  bool _isFatalAccessKeyError(String error) {
    return _isActivationLimitError(error) || _isAccessKeyError(error);
  }

  Future<PorcupineManager> _createManager(
    String accessKey,
    List<String> keywordPaths,
  ) {
    final sensitivitiesList = List<double>.filled(keywordPaths.length, 0.6);
    return PorcupineManager.fromKeywordPaths(
      accessKey,
      keywordPaths,
      _handleWakeWordDetected,
      sensitivities: sensitivitiesList,
      errorCallback: _handleWakeWordError,
    );
  }

  /// Initialize wake word engine
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

      debugPrint("Wake word: trying paired keyword models first");
      for (final keywordPaths in _keywordSetCandidates) {
        try {
          debugPrint("Wake word: trying paths $keywordPaths");
          manager = await _createManager(accessKey, keywordPaths);
          debugPrint("Wake word initialized with keywords: $keywordPaths");
          break;
        } catch (e) {
          lastError = e;
          final errorStr = e.toString();
          debugPrint("Wake word init failed for $keywordPaths: $e");
          if (_isFatalAccessKeyError(errorStr)) {
            debugPrint(
                "Wake word: access key/activation error, aborting retries");
            break;
          }
        }
      }

      if (manager == null &&
          !_isFatalAccessKeyError(lastError?.toString() ?? "")) {
        debugPrint(
          "Wake word: paired models unavailable, trying single model fallback",
        );
        for (final keywordPath in _singleKeywordCandidates) {
          try {
            debugPrint("Wake word: trying single path $keywordPath");
            manager = await _createManager(accessKey, [keywordPath]);
            debugPrint(
                "Wake word initialized with single keyword: $keywordPath");
            break;
          } catch (e) {
            lastError = e;
            final errorStr = e.toString();
            debugPrint(
                "Wake word single-path init failed for $keywordPath: $e");
            if (_isFatalAccessKeyError(errorStr)) {
              debugPrint(
                  "Wake word: access key/activation error, aborting retries");
              break;
            }
          }
        }
      }

      if (manager == null) {
        final errorStr = lastError.toString();
        final isActivationError = _isActivationLimitError(errorStr);
        final isAccessKeyError = _isAccessKeyError(errorStr);

        String solution;
        if (isActivationError) {
          solution = """
======= PICOVOICE ACTIVATION LIMIT REACHED =======
Your Picovoice access key has exceeded activation limits.

SOLUTION:
1. Go to https://console.picovoice.ai/
2. Generate a new/updated access key
3. Update WAKE_WORD_KEY in .env file
4. Rebuild the app

Wake word disabled for now - using text input mode
===================================================
""";
        } else if (isAccessKeyError) {
          solution = """
======= INVALID PICOVOICE ACCESS KEY =======
The access key is invalid or expired.

SOLUTION:
1. Check WAKE_WORD_KEY in .env file
2. Verify the key is correct from Picovoice console
3. Try regenerating the access key
4. Rebuild the app

Wake word disabled for now - using text input mode
===================================================
""";
        } else {
          solution = """
======= WAKE WORD INITIALIZATION FAILED =======
Failed to load wake word model.

SOLUTION:
1. Ensure $_babyGirlKeyword and $_zeroTwoKeyword exist
2. For PRODUCTION: put .ppn files in assets/wakeword/
3. Confirm pubspec.yaml includes assets/wakeword/ via assets/
4. Run 'flutter clean && flutter pub get'
5. Rebuild the app

Last error: $lastError
===================================================
""";
        }
        debugPrint(solution);
        throw Exception(solution);
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
      debugPrint("Wake word service initialized");
    } catch (e) {
      debugPrint("Wake word init error: $e");
      _manager = null;
      _initialized = false;
      rethrow;
    } finally {
      _initializing = false;
    }
  }

  String _resolveAccessKey() {
    if (_accessKeyOverride.isNotEmpty) {
      debugPrint("Wake word: Using access key from override");
      return _accessKeyOverride;
    }
    final wakeKey = _normalizeAccessKey(dotenv.env['WAKE_WORD_KEY'] ?? '');
    if (wakeKey.isNotEmpty) {
      debugPrint("Wake word: Using WAKE_WORD_KEY from .env");
      return wakeKey;
    }
    final picoKey = _normalizeAccessKey(dotenv.env['PICOVOICE_KEY'] ?? '');
    if (picoKey.isNotEmpty) {
      debugPrint("Wake word: Using PICOVOICE_KEY from .env");
      return picoKey;
    }
    debugPrint("Wake word: ERROR - No access key found in .env or override!");
    return '';
  }

  void _handleWakeWordDetected(int keywordIndex) {
    if (!_running) {
      return;
    }

    final callback = _onDetected;
    if (callback == null) {
      debugPrint("Wake word detected but no callback registered");
      return;
    }

    debugPrint("Wake word detected: keyword $keywordIndex");
    try {
      callback(keywordIndex);
    } catch (e, st) {
      debugPrint("Wake word callback error: $e\n$st");
    }
  }

  void _handleWakeWordError(dynamic error) {
    // Use print (not debugPrint) so this is visible in release builds too.
    // ignore: avoid_print
    print("[WakeWord] Runtime error: $error");
    _running = false;
    _reinitRequired = true;
  }

  /// Safely dispose of the Porcupine manager
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
    } catch (e) {
      debugPrint("Error stopping wake word manager: $e");
    }

    try {
      await manager.delete();
    } catch (e) {
      debugPrint("Error deleting wake word manager: $e");
    }

    _manager = null;
    _running = false;
    _initialized = false;
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    await _disposeManager();
    _reinitRequired = false;
    _onDetected = null;
    debugPrint("Wake word service disposed");
  }

  /// Stop wake word detection
  Future<void> stop() async {
    final manager = _manager;
    if (manager == null || !_running) {
      return;
    }

    _running = false;
    try {
      await manager.stop();
      debugPrint("Wake word detection stopped");
    } catch (e) {
      debugPrint("Error stopping wake word: $e");
    }
  }

  /// Start wake word detection
  Future<void> start() async {
    if (_initializing || _running) return;

    if (_reinitRequired) {
      final callback = _onDetected;
      if (callback == null) {
        debugPrint("Cannot start: no callback registered");
        return;
      }
      await init(callback);
      return;
    }

    if (!_initialized || _manager == null) {
      final callback = _onDetected;
      if (callback == null) {
        debugPrint("Cannot start: no callback registered");
        return;
      }
      await init(callback);
      return;
    }

    try {
      await _manager!.start();
      _running = true;
      debugPrint("Wake word detection started");
    } catch (e) {
      debugPrint("Error starting wake word: $e");
      rethrow;
    }
  }

  /// Check if wake word detection is running
  bool get isRunning => _running;
}
