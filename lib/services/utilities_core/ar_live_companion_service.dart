import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎮 AR Live Companion Service
///
/// Zero Two appears in your room via camera (like Pokémon GO).
/// Walks around, reacts to your environment, can "sit" on your desk.
class ARLiveCompanionService {
  ARLiveCompanionService._();
  static final ARLiveCompanionService instance = ARLiveCompanionService._();

  CompanionState _state = CompanionState.idle;
  CompanionPosition _position = const CompanionPosition(x: 0, y: 0, z: 1.5);
  CompanionAnimation _currentAnimation = CompanionAnimation.idle;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  Timer? _behaviorTimer;
  Timer? _animationTimer;

  double _deviceTilt = 0.0;
  DateTime? _lastInteraction;

  bool _isInitialized = false;
  bool _isARActive = false;

  CompanionState get state => _state;
  CompanionPosition get position => _position;
  CompanionAnimation get currentAnimation => _currentAnimation;
  bool get isARActive => _isARActive;

  final List<CompanionBehavior> _behaviorQueue = [];
  final math.Random _random = math.Random();

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadState();
    _isInitialized = true;

    if (kDebugMode) debugPrint('[ARCompanion] Initialized');
  }

  /// Start AR session
  Future<void> startARSession() async {
    if (_isARActive) return;

    _isARActive = true;
    _state = CompanionState.appearing;
    _currentAnimation = CompanionAnimation.spawn;

    // Start sensor monitoring
    _startSensorMonitoring();

    // Start behavior loop
    _startBehaviorLoop();

    // Spawn animation
    await Future.delayed(const Duration(milliseconds: 1500));
    _state = CompanionState.idle;
    _currentAnimation = CompanionAnimation.idle;

    if (kDebugMode) debugPrint('[ARCompanion] AR session started');
  }

  /// Stop AR session
  Future<void> stopARSession() async {
    if (!_isARActive) return;

    _isARActive = false;
    _state = CompanionState.disappearing;
    _currentAnimation = CompanionAnimation.despawn;

    await Future.delayed(const Duration(milliseconds: 1000));

    _stopSensorMonitoring();
    _stopBehaviorLoop();

    _state = CompanionState.idle;
    await _saveState();

    if (kDebugMode) debugPrint('[ARCompanion] AR session stopped');
  }

  /// Start monitoring device sensors
  void _startSensorMonitoring() {
    // Monitor device tilt
    _accelSub = accelerometerEventStream().listen((event) {
      _deviceTilt = event.y / 9.8; // Normalize to -1 to 1
      _reactToDeviceMovement();
    });

    // Monitor device rotation
    _gyroSub = gyroscopeEventStream().listen((event) {
      if (event.z.abs() > 2.0) {
        _reactToQuickRotation();
      }
    });
  }

  void _stopSensorMonitoring() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
  }

  /// Start autonomous behavior loop
  void _startBehaviorLoop() {
    _behaviorTimer?.cancel();
    _behaviorTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_isARActive) return;
      _performRandomBehavior();
    });
  }

  void _stopBehaviorLoop() {
    _behaviorTimer?.cancel();
    _animationTimer?.cancel();
  }

  /// React to device movement
  void _reactToDeviceMovement() {
    if (_deviceTilt.abs() > 0.7) {
      // Device tilted significantly
      if (_state == CompanionState.sitting) {
        // Stand up if device is tilted while sitting
        _queueBehavior(CompanionBehavior.standUp);
      }
    }
  }

  /// React to quick device rotation
  void _reactToQuickRotation() {
    if (_state == CompanionState.idle) {
      _queueBehavior(CompanionBehavior.lookAround);
    }
  }

  /// Perform random autonomous behavior
  void _performRandomBehavior() {
    if (_behaviorQueue.isNotEmpty) return;

    final behaviors = [
      CompanionBehavior.walk,
      CompanionBehavior.wave,
      CompanionBehavior.lookAround,
      CompanionBehavior.stretch,
      CompanionBehavior.sit,
    ];

    // Weight behaviors based on current state
    if (_state == CompanionState.sitting) {
      // More likely to stand up or wave while sitting
      _queueBehavior(_random.nextBool()
          ? CompanionBehavior.wave
          : CompanionBehavior.standUp);
    } else {
      _queueBehavior(behaviors[_random.nextInt(behaviors.length)]);
    }
  }

  /// Queue a behavior for execution
  void _queueBehavior(CompanionBehavior behavior) {
    _behaviorQueue.add(behavior);
    if (_behaviorQueue.length == 1) {
      _executeBehavior(behavior);
    }
  }

  /// Execute a behavior
  Future<void> _executeBehavior(CompanionBehavior behavior) async {
    switch (behavior) {
      case CompanionBehavior.walk:
        await _performWalk();
        break;
      case CompanionBehavior.wave:
        await _performWave();
        break;
      case CompanionBehavior.lookAround:
        await _performLookAround();
        break;
      case CompanionBehavior.stretch:
        await _performStretch();
        break;
      case CompanionBehavior.sit:
        await _performSit();
        break;
      case CompanionBehavior.standUp:
        await _performStandUp();
        break;
      case CompanionBehavior.jump:
        await _performJump();
        break;
      case CompanionBehavior.dance:
        await _performDance();
        break;
    }

    _behaviorQueue.removeAt(0);
    if (_behaviorQueue.isNotEmpty) {
      await _executeBehavior(_behaviorQueue.first);
    }
  }

  Future<void> _performWalk() async {
    _state = CompanionState.walking;
    _currentAnimation = CompanionAnimation.walk;

    // Random walk direction
    final angle = _random.nextDouble() * 2 * math.pi;
    final distance = 0.3 + _random.nextDouble() * 0.5;

    final targetX = _position.x + math.cos(angle) * distance;
    final targetZ = _position.z + math.sin(angle) * distance;

    // Clamp to reasonable bounds
    _position = CompanionPosition(
      x: targetX.clamp(-2.0, 2.0),
      y: _position.y,
      z: targetZ.clamp(0.5, 3.0),
    );

    await Future.delayed(const Duration(milliseconds: 2000));
    _state = CompanionState.idle;
    _currentAnimation = CompanionAnimation.idle;
  }

  Future<void> _performWave() async {
    _state = CompanionState.waving;
    _currentAnimation = CompanionAnimation.wave;
    await Future.delayed(const Duration(milliseconds: 1500));
    _state = CompanionState.idle;
    _currentAnimation = CompanionAnimation.idle;
  }

  Future<void> _performLookAround() async {
    _state = CompanionState.lookingAround;
    _currentAnimation = CompanionAnimation.lookAround;
    await Future.delayed(const Duration(milliseconds: 2000));
    _state = CompanionState.idle;
    _currentAnimation = CompanionAnimation.idle;
  }

  Future<void> _performStretch() async {
    _state = CompanionState.stretching;
    _currentAnimation = CompanionAnimation.stretch;
    await Future.delayed(const Duration(milliseconds: 2500));
    _state = CompanionState.idle;
    _currentAnimation = CompanionAnimation.idle;
  }

  Future<void> _performSit() async {
    _state = CompanionState.sitting;
    _currentAnimation = CompanionAnimation.sitDown;
    await Future.delayed(const Duration(milliseconds: 1000));
    _currentAnimation = CompanionAnimation.sitting;
  }

  Future<void> _performStandUp() async {
    _currentAnimation = CompanionAnimation.standUp;
    await Future.delayed(const Duration(milliseconds: 800));
    _state = CompanionState.idle;
    _currentAnimation = CompanionAnimation.idle;
  }

  Future<void> _performJump() async {
    _state = CompanionState.jumping;
    _currentAnimation = CompanionAnimation.jump;
    await Future.delayed(const Duration(milliseconds: 1200));
    _state = CompanionState.idle;
    _currentAnimation = CompanionAnimation.idle;
  }

  Future<void> _performDance() async {
    _state = CompanionState.dancing;
    _currentAnimation = CompanionAnimation.dance;
    await Future.delayed(const Duration(milliseconds: 3000));
    _state = CompanionState.idle;
    _currentAnimation = CompanionAnimation.idle;
  }

  /// User taps on companion
  Future<void> onTap() async {
    _lastInteraction = DateTime.now();

    final reactions = [
      CompanionBehavior.wave,
      CompanionBehavior.jump,
      CompanionBehavior.dance,
    ];

    _queueBehavior(reactions[_random.nextInt(reactions.length)]);
  }

  /// User swipes near companion
  Future<void> onSwipe(SwipeDirection direction) async {
    _lastInteraction = DateTime.now();

    switch (direction) {
      case SwipeDirection.up:
        _queueBehavior(CompanionBehavior.jump);
        break;
      case SwipeDirection.down:
        _queueBehavior(CompanionBehavior.sit);
        break;
      case SwipeDirection.left:
      case SwipeDirection.right:
        _queueBehavior(CompanionBehavior.lookAround);
        break;
    }
  }

  /// Place companion at specific position
  void placeAt(double x, double y, double z) {
    _position = CompanionPosition(x: x, y: y, z: z);
    _lastInteraction = DateTime.now();
  }

  /// Get companion's current mood based on interaction
  CompanionMood getCurrentMood() {
    if (_lastInteraction == null) return CompanionMood.neutral;

    final timeSinceInteraction = DateTime.now().difference(_lastInteraction!);

    if (timeSinceInteraction.inMinutes < 5) {
      return CompanionMood.happy;
    } else if (timeSinceInteraction.inMinutes < 15) {
      return CompanionMood.neutral;
    } else if (timeSinceInteraction.inMinutes < 30) {
      return CompanionMood.lonely;
    } else {
      return CompanionMood.sad;
    }
  }

  /// Get contextual message based on state
  String getContextualMessage() {
    final mood = getCurrentMood();

    switch (_state) {
      case CompanionState.idle:
        return mood == CompanionMood.lonely
            ? "Darling... you've been ignoring me~ 🥺"
            : 'What should we do next, darling? 💕';
      case CompanionState.walking:
        return 'Just exploring a bit~ 🚶‍♀️';
      case CompanionState.sitting:
        return "I'll just sit here and watch you work, darling~ 💕";
      case CompanionState.waving:
        return 'Hi darling! 👋';
      case CompanionState.dancing:
        return 'Dance with me! 💃';
      case CompanionState.jumping:
        return 'Wheee! 🎉';
      default:
        return "I'm here for you, darling~ 💕";
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('ar_companion_x', _position.x);
      await prefs.setDouble('ar_companion_y', _position.y);
      await prefs.setDouble('ar_companion_z', _position.z);
      if (_lastInteraction != null) {
        await prefs.setInt('ar_companion_last_interaction',
            _lastInteraction!.millisecondsSinceEpoch);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ARCompanion] Save error: $e');
    }
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble('ar_companion_x') ?? 0.0;
      final y = prefs.getDouble('ar_companion_y') ?? 0.0;
      final z = prefs.getDouble('ar_companion_z') ?? 1.5;
      _position = CompanionPosition(x: x, y: y, z: z);

      final lastInteractionMs = prefs.getInt('ar_companion_last_interaction');
      if (lastInteractionMs != null) {
        _lastInteraction =
            DateTime.fromMillisecondsSinceEpoch(lastInteractionMs);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ARCompanion] Load error: $e');
    }
  }

  void dispose() {
    _stopSensorMonitoring();
    _stopBehaviorLoop();
  }
}

class CompanionPosition {
  final double x;
  final double y;
  final double z;

  const CompanionPosition({
    required this.x,
    required this.y,
    required this.z,
  });
}

enum CompanionState {
  idle,
  walking,
  sitting,
  waving,
  lookingAround,
  stretching,
  jumping,
  dancing,
  appearing,
  disappearing,
}

enum CompanionAnimation {
  idle,
  walk,
  sitDown,
  sitting,
  standUp,
  wave,
  lookAround,
  stretch,
  jump,
  dance,
  spawn,
  despawn,
}

enum CompanionBehavior {
  walk,
  wave,
  lookAround,
  stretch,
  sit,
  standUp,
  jump,
  dance,
}

enum CompanionMood {
  happy,
  neutral,
  lonely,
  sad,
}

enum SwipeDirection {
  up,
  down,
  left,
  right,
}
