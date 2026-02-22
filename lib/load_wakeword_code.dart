import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

/// Typedef for wake word detection callback
typedef WakeWordCallback = void Function(int keywordIndex);

/// Service for managing wake word detection using Picovoice Porcupine
class WakeWordService {
  final List<PorcupineManager> _managers = [];
  final Set<String> _activeKeywordPaths = <String>{};
  bool _running = false;
  bool _initialized = false;
  bool _initializing = false;
  bool _reinitRequired = false;
  String _accessKeyOverride = "";
  WakeWordCallback? _onDetected;

  static const String _babyGirlKeyword = "Baby-girl_en_android_v4_0_0.ppn";
  static const String _zeroTwoKeyword = "Zero-two_en_android_v4_0_0.ppn";
  static const String _darlingKeyword = "Darling_en_android_v4_0_0.ppn";

  // Prefer grouped keyword initialization first, then fill any missing
  // keywords with individual managers.
  static const List<List<String>> _keywordSetCandidates = [
    // Prefer trying all three together first.
    [
      "assets/wakeword/${_babyGirlKeyword}",
      "assets/wakeword/${_zeroTwoKeyword}",
      "assets/wakeword/${_darlingKeyword}",
    ],
    // If loading all three at once fails (for example mixed model versions),
    // try pair combinations first.
    [
      "assets/wakeword/${_babyGirlKeyword}",
      "assets/wakeword/${_zeroTwoKeyword}",
    ],
    [
      "assets/wakeword/${_babyGirlKeyword}",
      "assets/wakeword/${_darlingKeyword}",
    ],
    [
      "assets/wakeword/${_zeroTwoKeyword}",
      "assets/wakeword/${_darlingKeyword}",
    ],
  ];

  // Canonical list of keyword asset paths in global callback index order.
  static const List<String> _singleKeywordCandidates = [
    "assets/wakeword/${_babyGirlKeyword}",
    "assets/wakeword/${_zeroTwoKeyword}",
    "assets/wakeword/${_darlingKeyword}",
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

  int _globalKeywordIndex(String keywordPath) {
    return _singleKeywordCandidates.indexOf(keywordPath);
  }

  WakeWordCallback _buildKeywordCallback(List<String> keywordPaths) {
    final mappedIndexes = keywordPaths.map(_globalKeywordIndex).toList();
    return (int localKeywordIndex) {
      if (localKeywordIndex >= 0 && localKeywordIndex < mappedIndexes.length) {
        final mapped = mappedIndexes[localKeywordIndex];
        if (mapped >= 0) {
          _handleWakeWordDetected(mapped);
          return;
        }
      }
      _handleWakeWordDetected(localKeywordIndex);
    };
  }

  Future<PorcupineManager> _createManager(
    String accessKey,
    List<String> keywordPaths,
    WakeWordCallback onDetected,
  ) {
    // Create sensitivity array matching keyword count.
    final sensitivities = List<double>.filled(keywordPaths.length, 0.6);
    debugPrint(
      "Creating Porcupine manager with ${keywordPaths.length} keywords and ${sensitivities.length} sensitivities",
    );
    return PorcupineManager.fromKeywordPaths(
      accessKey,
      keywordPaths,
      onDetected,
      sensitivities: sensitivities,
      errorCallback: _handleWakeWordError,
    );
  }

  /// Returns keyword paths in canonical callback-index order.
  List<String> get loadedKeywords =>
      List.unmodifiable(_singleKeywordCandidates);

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
      await _disposeManagers();
      _activeKeywordPaths.clear();

      final accessKey = _resolveAccessKey();
      if (accessKey.isEmpty) {
        throw Exception('WAKE_WORD_KEY/PICOVOICE_KEY is missing in .env');
      }

      Object? lastError;
      var fatalAccessKeyError = false;

      debugPrint("Wake word: trying grouped keyword models first");
      for (final keywordPaths in _keywordSetCandidates) {
        try {
          debugPrint("Wake word: trying paths $keywordPaths");
          final manager = await _createManager(
            accessKey,
            keywordPaths,
            _buildKeywordCallback(keywordPaths),
          );
          _managers.add(manager);
          _activeKeywordPaths.addAll(keywordPaths);
          debugPrint(
              "Wake word initialized with grouped keywords: $keywordPaths");
          break;
        } catch (e) {
          lastError = e;
          final errorStr = e.toString();
          debugPrint("Wake word init failed for $keywordPaths: $e");
          if (_isFatalAccessKeyError(errorStr)) {
            debugPrint(
                "Wake word: access key/activation error, aborting retries");
            fatalAccessKeyError = true;
            break;
          }
        }
      }

      if (!fatalAccessKeyError) {
        final missingKeywordPaths = _singleKeywordCandidates
            .where((path) => !_activeKeywordPaths.contains(path))
            .toList();

        if (missingKeywordPaths.isNotEmpty) {
          debugPrint(
            "Wake word: trying single model fallback for missing: $missingKeywordPaths",
          );
        }

        for (final keywordPath in missingKeywordPaths) {
          try {
            debugPrint("Wake word: trying single path $keywordPath");
            final manager = await _createManager(
              accessKey,
              [keywordPath],
              _buildKeywordCallback([keywordPath]),
            );
            _managers.add(manager);
            _activeKeywordPaths.add(keywordPath);
            debugPrint(
                "Wake word initialized with single keyword: $keywordPath");
          } catch (e) {
            lastError = e;
            final errorStr = e.toString();
            debugPrint(
                "Wake word single-path init failed for $keywordPath: $e");
            if (_isFatalAccessKeyError(errorStr)) {
              debugPrint(
                  "Wake word: access key/activation error, aborting retries");
              fatalAccessKeyError = true;
              break;
            }
          }
        }
      }

      if (_managers.isEmpty) {
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
1. Ensure $_babyGirlKeyword, $_zeroTwoKeyword, and $_darlingKeyword exist
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

      final missingAfterFallback = _singleKeywordCandidates
          .where((path) => !_activeKeywordPaths.contains(path))
          .toList();
      if (missingAfterFallback.isNotEmpty) {
        debugPrint(
          "Wake word warning: some keywords are unavailable: $missingAfterFallback",
        );
      } else {
        debugPrint("Wake word initialized with all keywords");
      }

      if (startImmediately) {
        for (final manager in _managers) {
          await manager.start();
        }
        _running = true;
      } else {
        _running = false;
      }

      _initialized = true;
      _reinitRequired = false;
      debugPrint("Wake word service initialized");
    } catch (e) {
      debugPrint("Wake word init error: $e");
      await _disposeManagers();
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

    final names = loadedKeywords
        .map((p) => p.split('/').last.replaceAll('.ppn', ''))
        .toList();
    final detectedName = (keywordIndex >= 0 && keywordIndex < names.length)
        ? names[keywordIndex]
        : 'unknown';
    debugPrint(
      "Wake word detected: keyword index $keywordIndex (detected=$detectedName)",
    );
    try {
      callback(keywordIndex);
    } catch (e, st) {
      debugPrint("Wake word callback error: $e\n$st");
    }
  }

  /// Developer helper: trigger the detection callback programmatically.
  void testTriggerByIndex(int keywordIndex) {
    final callback = _onDetected;
    if (callback == null) return;
    try {
      callback(keywordIndex);
    } catch (e, st) {
      debugPrint("Wake word test trigger error: $e\n$st");
    }
  }

  void _handleWakeWordError(dynamic error) {
    // Use print (not debugPrint) so this is visible in release builds too.
    // ignore: avoid_print
    print("[WakeWord] Runtime error: $error");
    _running = false;
    _reinitRequired = true;
  }

  /// Safely dispose all Porcupine managers
  Future<void> _disposeManagers() async {
    if (_managers.isEmpty) {
      _running = false;
      _initialized = false;
      _activeKeywordPaths.clear();
      return;
    }

    final managers = List<PorcupineManager>.from(_managers);
    _managers.clear();
    _activeKeywordPaths.clear();

    for (final manager in managers) {
      try {
        await manager.stop();
      } catch (e) {
        debugPrint("Error stopping wake word manager: $e");
      }

      try {
        await manager.delete();
      } catch (e) {
        debugPrint("Error deleting wake word manager: $e");
      }
    }

    _running = false;
    _initialized = false;
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    await _disposeManagers();
    _reinitRequired = false;
    _onDetected = null;
    debugPrint("Wake word service disposed");
  }

  /// Stop wake word detection
  Future<void> stop() async {
    if (_managers.isEmpty || !_running) {
      return;
    }

    _running = false;
    for (final manager in _managers) {
      try {
        await manager.stop();
      } catch (e) {
        debugPrint("Error stopping wake word: $e");
      }
    }
    debugPrint("Wake word detection stopped");
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

    if (!_initialized || _managers.isEmpty) {
      final callback = _onDetected;
      if (callback == null) {
        debugPrint("Cannot start: no callback registered");
        return;
      }
      await init(callback);
      return;
    }

    try {
      for (final manager in _managers) {
        await manager.start();
      }
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
