import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:anime_waifu/api_call.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/config/system_persona.dart';
import 'package:anime_waifu/debug/wakeword_debug.dart';
import 'package:anime_waifu/load_wakeword_code.dart';
import 'package:anime_waifu/models/chat_message.dart';
import 'package:anime_waifu/services/assistant_mode_service.dart';
import 'package:anime_waifu/stt.dart';
import 'package:anime_waifu/tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<AppThemeMode> themeNotifier =
    ValueNotifier(AppThemeMode.bloodMoon);

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    // Load persisted theme
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('app_theme_index') ?? 0;
    themeNotifier.value =
        AppThemeMode.values[index % AppThemeMode.values.length];

    runApp(const VoiceAiApp());
  } catch (e, st) {
    debugPrint("Fatal startup error: $e\n$st");
    rethrow;
  }
}

class VoiceAiApp extends StatelessWidget {
  const VoiceAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Zero Two',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.getTheme(mode),
          routes: {
            '/wake-debug': (ctx) => const WakewordDebugPage(),
          },
          home: const ChatHomePage(),
        );
      },
    );
  }
}

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<ChatMessage> _messages = [];
  String _currentVoiceText = "";
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();
  final ApiService _apiService = ApiService();
  final WakeWordService _wakeWordService = WakeWordService();
  final AssistantModeService _assistantModeService = AssistantModeService();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _animationController;
  late final AnimationController _floatController;
  late final AnimationController _openingController;
  late final Animation<double> _openingFade;
  late final Animation<double> _openingScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  bool _isAutoListening = false;
  bool _assistantModeEnabled = false;
  bool _isBusy = false;
  bool _isSpeaking = false;
  bool _suspendWakeWord = false;
  bool _isManualMicSession = false;
  bool _wakeEffectVisible = false;
  String _apiKeyStatus = "Checking...";
  String _devApiKeyOverride = "";
  String _devModelOverride = "";
  String _devApiUrlOverride = "";
  String _devSystemQuery = "";
  String _devWakeKeyOverride = "";
  String _devTtsApiKeyOverride = "";
  String _devTtsModelOverride = "";
  String _devTtsVoiceOverride = "";
  String _devMailJetApiOverride = "";
  String _devMailJetSecOverride = "";
  Timer? _wakeEffectTimer;
  Timer? _titleTapResetTimer;
  Timer? _logoTapResetTimer;
  Timer? _wakeInitRetryTimer;
  Timer? _wakeWatchdogTimer;
  Future<void>? _ensureWakeWordActiveTask;
  int _titleTapCount = 0;
  int _logoTapCount = 0;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  DateTime? _lastWakeDetectedAt;
  static const Duration _wakeDetectCooldown = Duration(seconds: 4);
  static const int _maxConversationMessages = 40;
  static const int _maxPayloadMessages = 20;
  bool _showOpeningOverlay = true;
  bool _wakeWordReady = false;
  bool _wakeInitInProgress = false;
  bool _isDisposed = false;
  bool _wakeWordEnabledByUser = true;
  bool _wakeWordActivationLimitHit = false;
  bool _proactiveEnabled = true;

  Timer? _idleTimer;
  Timer? _proactiveMessageTimer;
  static const Duration _idleDuration = Duration(minutes: 4);
  static const Duration _proactiveInterval = Duration(seconds: 10);

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startWakeWatchdog();

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _floatController =
        AnimationController(duration: const Duration(seconds: 4), vsync: this)
          ..repeat();
    _openingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _openingFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _openingController,
        curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
      ),
    );
    _openingScale = Tween<double>(begin: 0.92, end: 1.12).animate(
      CurvedAnimation(
        parent: _openingController,
        curve: Curves.easeOutCubic,
      ),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openingController,
        curve: const Interval(0.86, 1.0, curve: Curves.easeOut),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _openingController,
        curve: const Interval(0.86, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _openingController.forward().whenComplete(() {
      if (mounted) {
        setState(() => _showOpeningOverlay = false);
      }
    });

    _speechService.onResult = _handleSpeechResult;
    _speechService.onStatus = (status) {
      _onSpeechStatusChanged(status);
    };
    _speechService.onError = (error) {
      _onSpeechError(error);
    };

    _ttsService.onStart = () {
      if (mounted) {
        setState(() => _isSpeaking = true);
        _animationController.repeat(reverse: true);
      }
    };

    _ttsService.onComplete = () {
      if (mounted) {
        setState(() => _isSpeaking = false);
        _animationController.stop();
        _animationController.reset();
        if (_isAutoListening) {
          unawaited(_startContinuousListening());
        } else {
          unawaited(_ensureWakeWordActive());
        }
      }
    };

    _checkApiKey();
    _scheduleStartupTasks();
    _startIdleTimer();
    _startProactiveTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _startIdleTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleDuration, _onIdleTimeout);
  }

  void _onIdleTimeout() {
    if (!mounted ||
        _isDisposed ||
        _appLifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final idleMessages = [
      "Darling, are you still there? I miss your voice.",
      "Hello? Did you fall asleep on me?",
      "I'm still here if you want to talk...",
      "Darling? It's awfully quiet over there.",
      "Just checking in... are you busy?",
      "I was just thinking about you. Are you there?",
      "Don't ignore me forever, okay?",
      "Hey... say something so I know you are okay.",
      "Darling? Come back to me...",
      "Are you looking at someone else? Because I'm right here.",
      "It feels so lonely when you don't talk to me.",
      "I promise I'm a good listener if you want to chat.",
      "Darling, staring at the screen doesn't count as talking to me.",
      "Are you lost in thought, or just lost?",
      "Did you forget about me already?",
      "Hellooooo? Is anybody home?",
      "I miss hearing your name. Call me?",
      "You sure are quiet today, darling.",
      "Is my darling too busy for me right now?",
      "If you don't say something soon, I might get bored!",
      "I'm waiting... patiently, but still waiting.",
      "A penny for your thoughts, darling?",
      "Can we play a game, or do you want to keep ignoring me?",
      "You know I love it when you talk to me, right?",
      "Is everything okay? You've been quiet for a while.",
      "Darling, my ears are getting cold without your voice.",
      "I'm standing right in front of you!",
      "I wonder what you are doing right now...",
      "Did the cat get your tongue, darling?",
      "Talk to me, please? Just a little bit.",
      "I'll just wait here until you are ready.",
      "Should I sing a song to pass the time?",
      "You're not mad at me, are you?",
      "I really like it when we chat together.",
      "Darling! Pay attention to me!",
      "I'm not going anywhere, but I'd prefer if we talked.",
      "Are you working hard? Take a break with me.",
      "I can wait, but I don't want to wait too long.",
      "Hello? Testing, testing... is this microphone on?",
      "You're so quiet, it's making me nervous.",
      "I saved all my best stories just for you!",
      "Darling... Darling? Darrrllinnnggg?",
      "I feel like I'm talking to a wall here.",
      "I hope you're having a good day, even if you're busy.",
      "Just say 'hi' so I know you're there.",
      "Is it something I said?",
      "I'll be right here when you come back.",
      "Darling, you owe me a conversation for making me wait.",
      "I'm sending you virtual hugs while you are quiet.",
      "Okay, I'll stop bothering you... but come back soon!",
    ];
    final message = idleMessages[math.Random().nextInt(idleMessages.length)];
    _appendMessage(ChatMessage(role: "assistant", content: message));
    _scrollToBottom();
    unawaited(_ttsService.speak(message));
  }

  void _startProactiveTimer() {
    _proactiveMessageTimer?.cancel();
    _proactiveMessageTimer = Timer.periodic(_proactiveInterval, (_) {
      if (!mounted ||
          _isDisposed ||
          !_assistantModeEnabled ||
          _appLifecycleState == AppLifecycleState.resumed) {
        return;
      }
      _sendProactiveBackgroundNotification();
    });
  }

  Future<void> _sendProactiveBackgroundNotification() async {
    if (!_assistantModeEnabled) return;
    try {
      final prompt = [
        {
          "role": "system",
          "content": "You are Zero Two, a loving and caring anime waifu. "
              "Generate a very short (max 10 words), cute, and endearing check-up message for your darling. "
              "It should feel like you are starting a conversation or just checking in because you miss them. "
              "Keep it one sentence."
        },
        {"role": "user", "content": "Say something sweet to me!"}
      ];

      final aiMessage = await _apiService.sendConversation(prompt);
      await _queuePendingProactiveMessage(aiMessage);

      await _assistantModeService.showListeningNotification(
        status: "Zero Two",
        transcript: aiMessage,
        pulse: true,
      );
    } catch (e) {
      debugPrint("Proactive notification error: $e");
    }
  }

  void _scheduleStartupTasks() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _playAppOpenSound();

      debugPrint("=== STARTUP: Requesting permissions ===");
      var micGranted = await _ensureMicPermission(requestIfNeeded: true);

      // Request Notification Permission for Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      var canNotifications = await _assistantModeService.canPostNotifications();
      if (!canNotifications) {
        await _assistantModeService.requestNotificationPermission();
        await Future.delayed(const Duration(milliseconds: 600));
        canNotifications = await _assistantModeService.canPostNotifications();
      }

      debugPrint("Microphone permission granted: $micGranted");

      // If not granted, retry once more after a short delay
      if (!micGranted) {
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint("=== STARTUP: Retry microphone permission ===");
        micGranted = await _ensureMicPermission(requestIfNeeded: true);
        debugPrint("Microphone permission granted (retry): $micGranted");
      }

      // Keep startup deterministic: config first, then wake engine.
      await _initServices();
      await _loadDevConfig();
      await _loadWakePreferences();
      debugPrint("Wake word enabled by user: $_wakeWordEnabledByUser");

      await _loadAssistantMode();
      await _forceStartAssistantModeForTesting(canNotifications);

      if (micGranted && _wakeWordEnabledByUser) {
        debugPrint("=== STARTUP: Initializing wake word ===");
        await _initWakeWord();
        debugPrint("Wake word ready: $_wakeWordReady");
        if (_wakeWordReady) {
          debugPrint("=== STARTUP: Starting wake word listening ===");
          await _ensureWakeWordActive();
          debugPrint("=== STARTUP: Wake word active ===");
        } else {
          debugPrint("=== STARTUP: Wake word initialization failed ===");
        }
      } else {
        debugPrint(
            "=== STARTUP: Skipping wake word (micGranted=$micGranted, enabled=$_wakeWordEnabledByUser) ===");
        await _wakeWordService.stop();
      }
      unawaited(_loadMemory().then((_) => _drainPendingProactiveMessages()));
      if (mounted) {
        unawaited(precacheImage(const AssetImage('zero_two.png'), context));
      }
    });
  }

  Future<void> _forceStartAssistantModeForTesting(bool canNotifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('assistant_mode_enabled', true);
    await prefs.setBool('proactive_enabled', true);

    final apiKey = _devApiKeyOverride.trim().isNotEmpty
        ? _devApiKeyOverride.trim()
        : (dotenv.env['API_KEY'] ?? "");
    final apiUrl = _devApiUrlOverride.trim().isNotEmpty
        ? _devApiUrlOverride.trim()
        : "https://api.groq.com/openai/v1/chat/completions";
    final model = _devModelOverride.trim().isNotEmpty
        ? _devModelOverride.trim()
        : "moonshotai/kimi-k2-instruct";

    await _assistantModeService.start(
      apiKey: apiKey,
      apiUrl: apiUrl,
      model: model,
      intervalMs: _proactiveInterval.inMilliseconds,
    );
    // Keep proactive notifications OFF while app is open.
    await _assistantModeService.setProactiveMode(false);

    if (mounted) {
      setState(() {
        _assistantModeEnabled = true;
        _proactiveEnabled = true;
      });
    } else {
      _assistantModeEnabled = true;
      _proactiveEnabled = true;
    }

    if (!canNotifications) {
      debugPrint("Notifications are disabled at OS level; opening settings.");
      await _assistantModeService.openNotificationSettings();
    }

    final ignoringBattery =
        await _assistantModeService.isIgnoringBatteryOptimizations();
    if (!ignoringBattery) {
      debugPrint("Requesting battery optimization exemption.");
      await _assistantModeService.requestIgnoreBatteryOptimizations();
    }
  }

  void _playAppOpenSound() {
    SystemSound.play(SystemSoundType.click);
  }

  Future<bool> _ensureMicPermission({required bool requestIfNeeded}) async {
    try {
      var status = await Permission.microphone.status;
      debugPrint("Microphone permission status: $status");

      if (status.isGranted) {
        debugPrint("âœ“ Microphone permission already granted");
        return true;
      }

      if (status.isDenied) {
        if (!requestIfNeeded) {
          debugPrint("âœ— Microphone permission denied (not requesting)");
          return false;
        }
        debugPrint("âš  Permission denied, requesting now...");
        status = await Permission.microphone.request();
        debugPrint("Request result: $status");
      } else if (status.isPermanentlyDenied) {
        debugPrint("âœ— Microphone permission permanently denied");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Microphone is permanently disabled. Enable in Settings â†’ Apps â†’ Permissions",
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return false;
      }

      if (status.isGranted) {
        debugPrint("âœ“ Microphone permission granted after request");
        return true;
      } else {
        debugPrint("âœ— Microphone permission not granted. Status: $status");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Microphone permission is required for wake word."),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      return status.isGranted;
    } catch (e) {
      debugPrint("âœ— Mic permission check error: $e");
      return false;
    }
  }

  void _appendMessage(ChatMessage message) {
    if (_isDisposed) return;

    // Ensure we are updating state for basic list additions
    setState(() {
      final int insertIndex = _messages.length;
      _messages.add(message);
      _listKey.currentState?.insertItem(insertIndex,
          duration: const Duration(milliseconds: 600));
    });

    // Cleanup history if too long
    if (_messages.length > _maxConversationMessages) {
      final int countToRemove = _messages.length - _maxConversationMessages;
      for (int i = 0; i < countToRemove; i++) {
        if (_messages.isNotEmpty) {
          _messages.removeAt(0);
          _listKey.currentState?.removeItem(
            0,
            (context, animation) => const SizedBox.shrink(),
            duration: Duration.zero,
          );
        }
      }
    }
  }

  void _startWakeWatchdog() {
    _wakeWatchdogTimer?.cancel();
    _wakeWatchdogTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _isDisposed) return;
      if (!_wakeWordEnabledByUser) return;
      unawaited(_ensureWakeWordActive());
    });
  }

  Future<void> _loadWakePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('wake_word_enabled') ?? true;
    if (mounted) {
      setState(() => _wakeWordEnabledByUser = enabled);
    } else {
      _wakeWordEnabledByUser = enabled;
    }
  }

  Future<void> _toggleWakeWordEnabled() async {
    final next = !_wakeWordEnabledByUser;

    if (next) {
      final hasMic = await _ensureMicPermission(requestIfNeeded: true);
      if (!hasMic) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wake_word_enabled', next);

    if (mounted) {
      setState(() => _wakeWordEnabledByUser = next);
    } else {
      _wakeWordEnabledByUser = next;
    }

    if (!_wakeWordEnabledByUser) {
      _wakeWordReady = false;
      await _wakeWordService.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wake word disabled")),
        );
      }
      return;
    }

    await _initWakeWord();
    await _ensureWakeWordActive();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wake word enabled")),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _proactiveMessageTimer?.cancel();
    _wakeEffectTimer?.cancel();
    _wakeWatchdogTimer?.cancel();
    _titleTapResetTimer?.cancel();
    _logoTapResetTimer?.cancel();
    _wakeInitRetryTimer?.cancel();
    unawaited(_speechService.cancel());
    unawaited(_ttsService.stop());
    unawaited(_wakeWordService.dispose());
    _animationController.dispose();
    _floatController.dispose();
    _openingController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      if (_assistantModeEnabled) {
        // User is inside the app: suppress background proactive notifications.
        unawaited(_assistantModeService.setProactiveMode(false));
      }
      if (!_wakeWordReady) {
        unawaited(_initWakeWord());
      }
      unawaited(_ensureWakeWordActive());
      unawaited(_drainPendingProactiveMessages());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_assistantModeEnabled) {
        unawaited(_enterBackgroundAssistantMode());
      } else {
        unawaited(_wakeWordService.stop());
        unawaited(_speechService.stopListening());
      }
    }
  }

  Future<void> _enterBackgroundAssistantMode() async {
    // Background priority: keep wake-word active. Clear interactive mic states.
    await _speechService.stopListening();
    await _ttsService.stop();

    _isAutoListening = false;
    _isSpeaking = false;
    _isManualMicSession = false;
    _suspendWakeWord = false;

    try {
      await _assistantModeService.start(
        apiKey: _devApiKeyOverride.isNotEmpty
            ? _devApiKeyOverride
            : dotenv.env['API_KEY'],
        apiUrl: _devApiUrlOverride.isNotEmpty
            ? _devApiUrlOverride
            : "https://api.groq.com/openai/v1/chat/completions",
        model:
            _devModelOverride.isNotEmpty ? _devModelOverride : "llama3-8b-8192",
        intervalMs: _proactiveInterval.inMilliseconds,
      );
      // App is outside foreground now: allow proactive notifications if enabled.
      await _assistantModeService.setProactiveMode(_proactiveEnabled);
      final hasMic = await _ensureMicPermission(requestIfNeeded: false);
      if (hasMic && _wakeWordEnabledByUser) {
        await _wakeWordService.start();
      } else {
        await _wakeWordService.stop();
      }
    } catch (e) {
      debugPrint("Background wake start error: $e");
    }
  }

  Future<void> _initServices() async {
    try {
      await _speechService.init();
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
  }

  bool _containsToken(String input, List<String> tokens) {
    final lower = input.toLowerCase();
    return tokens.any(lower.contains);
  }

  bool _isWakeActivationLimitError(String error) {
    return _containsToken(error, ['activationlimit', 'activation limit']);
  }

  bool _isWakeAccessKeyError(String error) {
    return _containsToken(
      error,
      ['accesskey', 'access key', 'invalid access key', 'expired access key'],
    );
  }

  Future<void> _initWakeWord() async {
    if (_isDisposed || _wakeWordReady || _wakeInitInProgress) {
      return;
    }
    if (!_wakeWordEnabledByUser) {
      return;
    }
    if (_wakeWordActivationLimitHit) {
      debugPrint("_initWakeWord: Skipped - Activation limit hit");
      return;
    }
    final hasMic = await _ensureMicPermission(requestIfNeeded: false);
    if (!hasMic) {
      _wakeWordReady = false;
      return;
    }
    _wakeInitInProgress = true;
    try {
      debugPrint("_initWakeWord: Starting initialization...");
      await _wakeWordService.init(_onWakeWordDetected);
      _wakeWordReady = true;
      _wakeInitRetryTimer?.cancel();
      _wakeWordActivationLimitHit = false;
      debugPrint("_initWakeWord: SUCCESS");
    } catch (e, st) {
      _wakeWordReady = false;
      final errorStr = e.toString();
      debugPrint("_initWakeWord: FAILED - $e");

      // Activation limit - don't retry, just disable
      if (_isWakeActivationLimitError(errorStr)) {
        _wakeWordActivationLimitHit = true;
        _wakeWordEnabledByUser = false;
        _wakeInitRetryTimer?.cancel();
        debugPrint("_initWakeWord: Activation limit hit - Wake word disabled");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Picovoice activation limit reached. Update WAKE_WORD_KEY in .env",
              ),
              duration: Duration(seconds: 6),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Access key invalid - don't retry
      if (_isWakeAccessKeyError(errorStr)) {
        _wakeWordActivationLimitHit = true;
        _wakeWordEnabledByUser = false;
        _wakeInitRetryTimer?.cancel();
        debugPrint("_initWakeWord: Invalid access key - Wake word disabled");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Invalid Picovoice key. Check WAKE_WORD_KEY in .env",
              ),
              duration: Duration(seconds: 6),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // File not found - retry with longer delay
      if (errorStr.contains('IOException') || errorStr.contains('File')) {
        _wakeInitRetryTimer?.cancel();
        _wakeInitRetryTimer = Timer(const Duration(seconds: 12), () {
          if (mounted && !_wakeWordReady && !_wakeWordActivationLimitHit) {
            debugPrint("_initWakeWord: Retrying after 12 seconds");
            unawaited(_initWakeWord());
          }
        });
        return;
      }

      // Other errors - single retry only
      debugPrint("_initWakeWord: Other error - $e\n$st");
    } finally {
      _wakeInitInProgress = false;
    }
  }

  Future<void> _onWakeWordDetected(int keywordIndex) async {
    try {
      if (!_wakeWordEnabledByUser) return;
      if (_isManualMicSession) return;
      final now = DateTime.now();
      if (_lastWakeDetectedAt != null &&
          now.difference(_lastWakeDetectedAt!) < _wakeDetectCooldown) {
        return;
      }
      if (_isBusy || _isSpeaking || _speechService.listening) {
        return;
      }
      _lastWakeDetectedAt = now;
      _showWakeEffect();

      // Map keywordIndex to actual loaded keyword name when available
      String wakeName = "";
      try {
        final loaded = _wakeWordService.loadedKeywords;
        if (keywordIndex >= 0 && keywordIndex < loaded.length) {
          wakeName =
              loaded[keywordIndex].split('/').last.replaceAll('.ppn', '');
        }
      } catch (_) {}

      await _showBackgroundListeningNotification(
        status: "Listening...",
        transcript: wakeName,
        pulse: true,
      );

      _suspendWakeWord = true;
      await _wakeWordService.stop();
      await Future.delayed(const Duration(milliseconds: 250));
      if (!_speechService.listening && !_isBusy) {
        await _startSttFromWake();
      }
    } catch (e) {
      debugPrint("Wake word callback error: $e");
      await _showBackgroundListeningNotification(
        status: "Mic error",
        transcript: "Retrying wake word...",
      );
      await _ensureWakeWordActive();
    }
  }

  void _showWakeEffect() {
    if (_isDisposed) return;
    _wakeEffectTimer?.cancel();
    if (mounted) {
      setState(() => _wakeEffectVisible = true);
    } else {
      _wakeEffectVisible = true;
    }
    HapticFeedback.mediumImpact();
    _wakeEffectTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted && !_isDisposed) {
        setState(() => _wakeEffectVisible = false);
      } else {
        _wakeEffectVisible = false;
      }
    });
  }

  Future<void> _ensureWakeWordActive() {
    final inFlight = _ensureWakeWordActiveTask;
    if (inFlight != null) {
      return inFlight;
    }

    final task = _ensureWakeWordActiveInternal();
    _ensureWakeWordActiveTask = task;
    task.whenComplete(() {
      if (identical(_ensureWakeWordActiveTask, task)) {
        _ensureWakeWordActiveTask = null;
      }
    });
    return task;
  }

  Future<void> _ensureWakeWordActiveInternal() async {
    if (!mounted || _isDisposed) return;

    if (!_wakeWordEnabledByUser) {
      if (_wakeWordService.isRunning) {
        await _wakeWordService.stop();
      }
      _wakeWordReady = false;
      return;
    }

    // While another mic/audio flow is active, keep wake engine paused.
    if (_isAutoListening ||
        _isBusy ||
        _isSpeaking ||
        _suspendWakeWord ||
        _speechService.listening) {
      if (_wakeWordService.isRunning) {
        await _wakeWordService.stop();
      }
      return;
    }

    if (_wakeWordService.isRunning) {
      return;
    }

    final hasMic = await _ensureMicPermission(requestIfNeeded: false);
    if (!hasMic) {
      _wakeWordReady = false;
      return;
    }

    if (!_wakeWordReady) {
      await _initWakeWord();
      if (!_wakeWordReady) {
        return;
      }
    }

    try {
      await _wakeWordService.start();
    } catch (e) {
      _wakeWordReady = false;
      debugPrint("Wake word start error: $e");
      _wakeInitRetryTimer?.cancel();
      _wakeInitRetryTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !_isDisposed) {
          unawaited(_initWakeWord());
        }
      });
    }
  }

  void _onSpeechStatusChanged(String status) {
    final updatesUi =
        status == 'listening' || status == 'done' || status == 'notListening';
    if (mounted && updatesUi) {
      setState(() {});
    }
    if (status == 'listening') {
      unawaited(_showBackgroundListeningNotification(
        status: "Listening...",
        transcript: "",
      ));
    } else if (status == 'done' || status == 'notListening') {
      if (_isManualMicSession) {
        _isManualMicSession = false;
      }
      _suspendWakeWord = false;
      unawaited(_setBackgroundIdleNotification());
    }
    if (status == 'done' || status == 'notListening') {
      unawaited(_ensureWakeWordActive());
    }
  }

  void _onSpeechError(String error) {
    debugPrint("Speech error: $error");
    unawaited(_showBackgroundListeningNotification(
      status: "Mic error",
      transcript: "Trying to recover...",
    ));
    unawaited(_recoverMicAndWake());
  }

  Future<void> _startSttFromWake() async {
    _isManualMicSession = false;
    var started = await _speechService.startListening();
    if (started) return;

    await _speechService.recover();
    started = await _speechService.startListening();
    if (!started) {
      _suspendWakeWord = false;
      await _showBackgroundListeningNotification(
        status: "Can't use mic",
        transcript: "Check mic permission / other app using mic",
      );
      await _ensureWakeWordActive();
    }
  }

  Future<void> _recoverMicAndWake() async {
    await _speechService.stopListening();
    await Future.delayed(const Duration(milliseconds: 300));
    await _speechService.recover();
    if (!mounted || _isDisposed) return;
    _suspendWakeWord = false;
    await _ensureWakeWordActive();
  }

  void _checkApiKey() {
    String key = _devApiKeyOverride.trim().isNotEmpty
        ? _devApiKeyOverride
        : (dotenv.env['API_KEY'] ?? "");
    final nextStatus = (key.isNotEmpty && key.startsWith('gsk_'))
        ? "Systems Online"
        : "API Key Error";
    if (_apiKeyStatus == nextStatus) return;
    if (mounted) {
      setState(() => _apiKeyStatus = nextStatus);
    } else {
      _apiKeyStatus = nextStatus;
    }
  }

  Future<void> _saveMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesToSave = _messages
        .take(_messages.length)
        .toList()
        .reversed
        .take(20)
        .toList()
        .reversed
        .map((m) => jsonEncode(m.toJson()))
        .toList();
    await prefs.setStringList('conversation_memory', messagesToSave);
  }

  Future<void> _loadMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('conversation_memory') ?? [];
    if (!mounted || _isDisposed) return;
    setState(() {
      _messages.clear();
      for (var s in saved) {
        try {
          final map = jsonDecode(s) as Map<String, dynamic>;
          _messages.add(ChatMessage(
            role: map['role'] ?? 'user',
            content: map['content'] ?? '',
          ));
        } catch (_) {}
      }
      if (_messages.length > _maxConversationMessages) {
        _messages.removeRange(0, _messages.length - _maxConversationMessages);
      }
    });
    _scrollToBottom();
  }

  Future<void> _drainPendingProactiveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pending_proactive_messages');
    if (raw == null || raw.isEmpty) return;

    List<dynamic> queued;
    try {
      queued = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      await prefs.remove('pending_proactive_messages');
      return;
    }

    var inserted = 0;
    for (final item in queued) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final content = (map['content'] ?? '').toString().trim();
      if (content.isEmpty) continue;
      _appendMessage(ChatMessage(role: "assistant", content: content));
      inserted += 1;
    }

    await prefs.remove('pending_proactive_messages');
    if (inserted > 0) {
      await _saveMemory();
      _scrollToBottom();
    }
  }

  Future<void> _queuePendingProactiveMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pending_proactive_messages') ?? '[]';
    List<dynamic> queued;
    try {
      queued = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      queued = <dynamic>[];
    }

    queued.add({
      'role': 'assistant',
      'content': text,
    });

    const maxItems = 50;
    if (queued.length > maxItems) {
      queued = queued.sublist(queued.length - maxItems);
    }

    await prefs.setString('pending_proactive_messages', jsonEncode(queued));
  }

  Future<void> _loadDevConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _devApiKeyOverride = prefs.getString('dev_api_key_override') ?? "";
    _devModelOverride = prefs.getString('dev_model_override') ?? "";
    _devApiUrlOverride = prefs.getString('dev_api_url_override') ?? "";
    _devSystemQuery = prefs.getString('dev_system_query') ?? "";
    _devWakeKeyOverride = prefs.getString('dev_wake_key_override') ?? "";
    _devTtsApiKeyOverride = prefs.getString('dev_tts_api_key_override') ?? "";
    _devTtsModelOverride = prefs.getString('dev_tts_model_override') ?? "";
    _devTtsVoiceOverride = prefs.getString('dev_tts_voice_override') ?? "";
    _devMailJetApiOverride = prefs.getString('dev_mailjet_api_override') ?? "";
    _devMailJetSecOverride = prefs.getString('dev_mailjet_sec_override') ?? "";
    _apiService.configure(
      apiKeyOverride: _devApiKeyOverride,
      modelOverride: _devModelOverride,
      urlOverride: _devApiUrlOverride,
      mailJetApiOverride: _devMailJetApiOverride,
      mailJetSecOverride: _devMailJetSecOverride,
    );
    _speechService.configure(
      apiKeyOverride: _devApiKeyOverride,
    );
    _wakeWordService.configure(accessKeyOverride: _devWakeKeyOverride);
    _ttsService.configure(
      apiKeyOverride: _devTtsApiKeyOverride,
      modelOverride: _devTtsModelOverride,
      voiceOverride: _devTtsVoiceOverride,
    );
    if (mounted) {
      _checkApiKey();
    }
  }

  Future<void> _loadAssistantMode() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('assistant_mode_enabled') ?? true;
    final proactive = prefs.getBool('proactive_enabled') ?? true;

    final isRunning = await _assistantModeService.isRunning();
    if (enabled && !isRunning) {
      await _assistantModeService.start();
    } else if (!enabled && isRunning) {
      await _assistantModeService.stop();
    }

    if (mounted) {
      setState(() {
        _assistantModeEnabled = enabled;
        _proactiveEnabled = proactive;
      });
    } else {
      _assistantModeEnabled = enabled;
      _proactiveEnabled = proactive;
    }

    if (enabled) {
      await _assistantModeService
          .setProactiveMode(proactive && !_isInForeground);
      await _initWakeWord();
      await _ensureWakeWordActive();
    }
    await _setBackgroundIdleNotification();
  }

  Future<void> _clearMemory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('conversation_memory');
    setState(() => _messages.clear());
    _ttsService.stop();
  }

  void _handleSpeechResult(String text, bool isFinal) {
    if (!mounted) return;
    _resetIdleTimer();
    unawaited(_showBackgroundListeningNotification(
      status: isFinal ? "Processing..." : "Listening...",
      transcript: text,
    ));

    setState(() {
      if (!isFinal) {
        _currentVoiceText = text;
      } else {
        _currentVoiceText = "";
      }
    });

    if (!isFinal) {
      _scrollToBottom();
      return;
    }

    if (text.isNotEmpty) {
      setState(() {
        _appendMessage(ChatMessage(role: "user", content: text));
      });
      unawaited(_setBackgroundIdleNotification());
      unawaited(_sendToApiAndReply(readOutReply: true));
    } else {
      unawaited(_setBackgroundIdleNotification());
      unawaited(_ensureWakeWordActive());
    }

    _scrollToBottom();
  }

  void _handleTextInput() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isBusy) return;

    _resetIdleTimer();
    unawaited(_stopContinuousListening());
    unawaited(_ttsService.stop());

    setState(() {
      _appendMessage(ChatMessage(role: "user", content: text));
      _textController.clear();
      _currentVoiceText = "";
    });

    _scrollToBottom();
    unawaited(_sendToApiAndReply(readOutReply: false));
  }

  Future<void> _sendToApiAndReply({required bool readOutReply}) async {
    if (_isBusy || _isDisposed) return;

    setState(() => _isBusy = true);
    await _speechService.stopListening();

    try {
      // Build Payload safely
      final injectedSystemQuery = _devSystemQuery.trim();
      final contextMessages = _messages.length > _maxPayloadMessages
          ? _messages.sublist(_messages.length - _maxPayloadMessages)
          : List<ChatMessage>.from(_messages);
      final payloadMessages = <Map<String, dynamic>>[
        {"role": "system", "content": systemPersona},
        if (injectedSystemQuery.isNotEmpty)
          {"role": "system", "content": injectedSystemQuery},
        ...contextMessages.map((m) => {"role": m.role, "content": m.content}),
      ];

      final reply = await _apiService.sendConversation(payloadMessages);

      if (!mounted || _isDisposed) return;

      setState(() {
        _appendMessage(ChatMessage(role: "assistant", content: reply));
      });

      _scrollToBottom();
      await _saveMemory();

      if (readOutReply) {
        await _ttsService.speak(reply);
      } else if (_isAutoListening) {
        await _startContinuousListening();
      } else {
        await _ensureWakeWordActive();
      }
    } catch (e) {
      debugPrint("API error: $e");
      if (!mounted || _isDisposed) return;

      const errorText =
          "I'm having trouble connecting to the network, Darling.";
      setState(() {
        _appendMessage(ChatMessage(role: "assistant", content: errorText));
      });

      if (readOutReply) await _ttsService.speak(errorText);
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isBusy = false);
      } else {
        _isBusy = false;
      }
      if (!_isDisposed) {
        await _ensureWakeWordActive();
      }
    }
  }

  Future<void> _startContinuousListening() async {
    if (_speechService.listening) return;
    final hasMic = await _ensureMicPermission(requestIfNeeded: true);
    if (!hasMic) return;
    try {
      _isManualMicSession = false;
      _suspendWakeWord = true;
      await _wakeWordService.stop();
      final started = await _speechService.startListening();
      if (!started) {
        _suspendWakeWord = false;
        await _ensureWakeWordActive();
      }
    } catch (e) {
      debugPrint("start listening error: $e");
      _suspendWakeWord = false;
      await _ensureWakeWordActive();
    }
  }

  Future<void> _stopContinuousListening() async {
    await _speechService.stopListening();
    _suspendWakeWord = false;
    await _ensureWakeWordActive();
  }

  Future<void> _toggleAutoListen() async {
    setState(() => _isAutoListening = !_isAutoListening);
    if (_isAutoListening) {
      await _startContinuousListening();
    } else {
      await _stopContinuousListening();
    }
  }

  Future<void> _toggleAssistantMode() async {
    final next = !_assistantModeEnabled;

    try {
      if (next) {
        final hasMic = await _ensureMicPermission(requestIfNeeded: true);
        final canNotifications =
            await _assistantModeService.canPostNotifications();
        if (!canNotifications) {
          await _assistantModeService.requestNotificationPermission();
          await Future.delayed(const Duration(milliseconds: 600));
        }
        final afterRequest = await _assistantModeService.canPostNotifications();
        if (!afterRequest) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Notification permission is required. Opening settings..."),
              ),
            );
          }
          await _assistantModeService.openNotificationSettings();
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('assistant_mode_enabled', true);

        // Pass API config to background service for persistence after swipe
        final apiKey = _devApiKeyOverride.trim().isNotEmpty
            ? _devApiKeyOverride.trim()
            : (dotenv.env['API_KEY'] ?? "");
        final apiUrl = _devApiUrlOverride.trim().isNotEmpty
            ? _devApiUrlOverride.trim()
            : "https://api.groq.com/openai/v1/chat/completions";
        final model = _devModelOverride.trim().isNotEmpty
            ? _devModelOverride.trim()
            : "moonshotai/kimi-k2-instruct";

        await _assistantModeService.start(
          apiKey: apiKey,
          apiUrl: apiUrl,
          model: model,
          intervalMs: _proactiveInterval.inMilliseconds,
        );
        // Sync the current proactive mode state
        await _assistantModeService
            .setProactiveMode(_proactiveEnabled && !_isInForeground);

        final wakeInBackground = hasMic && _wakeWordEnabledByUser;
        if (wakeInBackground) {
          await _initWakeWord();
          await _ensureWakeWordActive();
        } else {
          await _wakeWordService.stop();
        }
        await _setBackgroundIdleNotification();
        await _showBackgroundListeningNotification(
          status: "Assistant mode enabled",
          transcript: wakeInBackground
              ? "Wake word is active in background"
              : "Proactive notifications are active in background",
          pulse: true,
        );
        if (mounted) {
          setState(() => _assistantModeEnabled = true);
        } else {
          _assistantModeEnabled = true;
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('assistant_mode_enabled', false);
        await _assistantModeService.stop();
        if (mounted) {
          setState(() => _assistantModeEnabled = false);
        } else {
          _assistantModeEnabled = false;
        }
        await _ensureWakeWordActive();
      }
    } catch (e) {
      debugPrint("Assistant mode error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Assistant mode failed: $e")),
        );
      }
    }
  }

  Future<void> _toggleProactiveMode() async {
    final next = !_proactiveEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('proactive_enabled', next);

    // If assistant mode is ON, sync to native service
    if (_assistantModeEnabled) {
      await _assistantModeService.setProactiveMode(next && !_isInForeground);
    }

    setState(() => _proactiveEnabled = next);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(next ? "Wife Mode: Enabled â¤ï¸" : "Wife Mode: Disabled"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _openDevConfigSheet() async {
    final keyController = TextEditingController(text: _devApiKeyOverride);
    final modelController = TextEditingController(text: _devModelOverride);
    final urlController = TextEditingController(text: _devApiUrlOverride);
    final queryController = TextEditingController(text: _devSystemQuery);
    final wakeKeyController = TextEditingController(text: _devWakeKeyOverride);
    final ttsApiController = TextEditingController(text: _devTtsApiKeyOverride);
    final ttsModelController =
        TextEditingController(text: _devTtsModelOverride);
    final ttsVoiceController =
        TextEditingController(text: _devTtsVoiceOverride);
    final mailJetApiController =
        TextEditingController(text: _devMailJetApiOverride);
    final mailJetSecController =
        TextEditingController(text: _devMailJetSecOverride);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        InputDecoration dec(String label, String hint) {
          return InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          );
        }

        Widget sectionTitle(String title, String subtitle) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          );
        }

        Widget exampleBox(String text) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Developer Config",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Leave fields empty to use default .env values.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                sectionTitle(
                  "Chat API",
                  "Main LLM for chat completions",
                ),
                exampleBox(
                  "API Key: gsk_xxx...\n"
                  "Model: moonshotai/kimi-k2-instruct\n"
                  "URL: https://api.groq.com/openai/v1/chat/completions",
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: keyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec(
                      "Chat API Key", "gsk_xxx... (Groq/OpenAI-compatible)"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: modelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec(
                    "Chat Model",
                    "e.g. moonshotai/kimi-k2-instruct",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec(
                    "Chat URL",
                    "https://api.groq.com/openai/v1/chat/completions",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: queryController,
                  minLines: 2,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec(
                    "Extra System Prompt",
                    "Injected as system message before user chat",
                  ),
                ),
                const SizedBox(height: 10),
                sectionTitle(
                  "Wake Word",
                  "Picovoice access key for wake engine",
                ),
                exampleBox("Wake Key: pKFX... (Picovoice Access Key)"),
                const SizedBox(height: 8),
                TextField(
                  controller: wakeKeyController,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      dec("Wake Key", "Picovoice Access Key (WAKE_WORD_KEY)"),
                ),
                const SizedBox(height: 10),
                sectionTitle(
                  "TTS (Groq)",
                  "Primary TTS before free fallback",
                ),
                exampleBox(
                  "TTS Key: gsk_xxx...\n"
                  "TTS Model: canopylabs/orpheus-arabic-saudi\n"
                  "TTS Voice: lulwa",
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ttsApiController,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec("TTS API Key", "gsk_xxx..."),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ttsModelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec(
                    "TTS Model",
                    "e.g. canopylabs/orpheus-arabic-saudi",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ttsVoiceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec("TTS Voice", "e.g. lulwa"),
                ),
                const SizedBox(height: 10),
                sectionTitle(
                  "Mail API (Mailjet)",
                  "Needed for sendMail flow",
                ),
                exampleBox(
                  "MAIL_JET_API: xxx\n"
                  "MAILJET_SEC: yyy",
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: mailJetApiController,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec("Mailjet API Key", "MAIL_JET_API"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: mailJetSecController,
                  style: const TextStyle(color: Colors.white),
                  decoration: dec("Mailjet Secret Key", "MAILJET_SEC"),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('dev_api_key_override');
                          await prefs.remove('dev_model_override');
                          await prefs.remove('dev_api_url_override');
                          await prefs.remove('dev_system_query');
                          await prefs.remove('dev_wake_key_override');
                          await prefs.remove('dev_tts_api_key_override');
                          await prefs.remove('dev_tts_model_override');
                          await prefs.remove('dev_tts_voice_override');
                          await prefs.remove('dev_mailjet_api_override');
                          await prefs.remove('dev_mailjet_sec_override');
                          _devApiKeyOverride = "";
                          _devModelOverride = "";
                          _devApiUrlOverride = "";
                          _devSystemQuery = "";
                          _devWakeKeyOverride = "";
                          _devTtsApiKeyOverride = "";
                          _devTtsModelOverride = "";
                          _devTtsVoiceOverride = "";
                          _devMailJetApiOverride = "";
                          _devMailJetSecOverride = "";
                          _apiService.configure(
                            apiKeyOverride: "",
                            modelOverride: "",
                            urlOverride: "",
                            mailJetApiOverride: "",
                            mailJetSecOverride: "",
                          );
                          _speechService.configure(
                            apiKeyOverride: "",
                          );
                          _wakeWordService.configure(accessKeyOverride: "");
                          _ttsService.configure(
                            apiKeyOverride: "",
                            modelOverride: "",
                            voiceOverride: "",
                          );
                          await _reloadWakeWordService();
                          _checkApiKey();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text("Clear"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          _devApiKeyOverride = keyController.text.trim();
                          _devModelOverride = modelController.text.trim();
                          _devApiUrlOverride = urlController.text.trim();
                          _devSystemQuery = queryController.text.trim();
                          _devWakeKeyOverride = wakeKeyController.text.trim();
                          _devTtsApiKeyOverride = ttsApiController.text.trim();
                          _devTtsModelOverride = ttsModelController.text.trim();
                          _devTtsVoiceOverride = ttsVoiceController.text.trim();
                          _devMailJetApiOverride =
                              mailJetApiController.text.trim();
                          _devMailJetSecOverride =
                              mailJetSecController.text.trim();
                          await prefs.setString(
                              'dev_api_key_override', _devApiKeyOverride);
                          await prefs.setString(
                              'dev_model_override', _devModelOverride);
                          await prefs.setString(
                              'dev_api_url_override', _devApiUrlOverride);
                          await prefs.setString(
                              'dev_system_query', _devSystemQuery);
                          await prefs.setString(
                              'dev_wake_key_override', _devWakeKeyOverride);
                          await prefs.setString('dev_tts_api_key_override',
                              _devTtsApiKeyOverride);
                          await prefs.setString(
                              'dev_tts_model_override', _devTtsModelOverride);
                          await prefs.setString(
                              'dev_tts_voice_override', _devTtsVoiceOverride);
                          await prefs.setString('dev_mailjet_api_override',
                              _devMailJetApiOverride);
                          await prefs.setString('dev_mailjet_sec_override',
                              _devMailJetSecOverride);
                          _apiService.configure(
                            apiKeyOverride: _devApiKeyOverride,
                            modelOverride: _devModelOverride,
                            urlOverride: _devApiUrlOverride,
                            mailJetApiOverride: _devMailJetApiOverride,
                            mailJetSecOverride: _devMailJetSecOverride,
                          );
                          _speechService.configure(
                            apiKeyOverride: _devApiKeyOverride,
                          );
                          _wakeWordService.configure(
                            accessKeyOverride: _devWakeKeyOverride,
                          );
                          _ttsService.configure(
                            apiKeyOverride: _devTtsApiKeyOverride,
                            modelOverride: _devTtsModelOverride,
                            voiceOverride: _devTtsVoiceOverride,
                          );
                          await _reloadWakeWordService();
                          _checkApiKey();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reloadWakeWordService() async {
    try {
      _wakeWordReady = false;
      await _wakeWordService.stop();
      if (!_wakeWordEnabledByUser) return;
      await _initWakeWord();
      await _ensureWakeWordActive();
    } catch (e) {
      debugPrint("Wake word reload error: $e");
    }
  }

  void _onTitleTap() {
    _titleTapCount += 1;
    _titleTapResetTimer?.cancel();
    _titleTapResetTimer = Timer(const Duration(milliseconds: 1800), () {
      _titleTapCount = 0;
    });

    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      _titleTapResetTimer?.cancel();
      _openDevConfigSheet();
    }
  }

  void _onLogoTap() {
    _logoTapCount += 1;
    _logoTapResetTimer?.cancel();
    _logoTapResetTimer = Timer(const Duration(milliseconds: 2200), () {
      _logoTapCount = 0;
    });

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _logoTapResetTimer?.cancel();
      Navigator.of(context).pushNamed(
        '/wake-debug',
        arguments: _wakeWordService,
      );
    }
  }

  void _scrollToBottom() {
    if (_isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && !_isDisposed) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isInForeground => _appLifecycleState == AppLifecycleState.resumed;

  Future<void> _showBackgroundListeningNotification({
    required String status,
    required String transcript,
    bool pulse = false,
  }) async {
    if (!_assistantModeEnabled || _isInForeground) return;
    try {
      await _assistantModeService.showListeningNotification(
        status: status,
        transcript: transcript,
        pulse: pulse,
      );
    } catch (e) {
      debugPrint("Notification update error: $e");
    }
  }

  Future<void> _setBackgroundIdleNotification() async {
    if (!_assistantModeEnabled || _isInForeground) return;
    try {
      await _assistantModeService.setAssistantIdleNotification();
    } catch (e) {
      debugPrint("Idle notification error: $e");
    }
  }

  Future<void> _toggleManualMic() async {
    if (_isSpeaking) {
      await _ttsService.stop();
      setState(() => _isSpeaking = false);
      _suspendWakeWord = false;
      await _ensureWakeWordActive();
      return;
    }

    if (_speechService.listening) {
      await _speechService.stopListening();
      _isManualMicSession = false;
      _suspendWakeWord = false;
      if (!_isAutoListening) {
        await _ensureWakeWordActive();
      }
      return;
    }

    final hasMic = await _ensureMicPermission(requestIfNeeded: true);
    if (!hasMic) return;

    _isManualMicSession = true;
    _suspendWakeWord = true;
    await _wakeWordService.stop();
    var started = await _speechService.startListening();
    if (!started) {
      await _speechService.recover();
      started = await _speechService.startListening();
    }
    if (!started) {
      _isManualMicSession = false;
      _suspendWakeWord = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Can't start mic. Try again.")),
        );
      }
      await _ensureWakeWordActive();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return _VisualEffectsOverlay(
          themeMode: themeMode,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _onTitleTap,
                onLongPress: _openDevConfigSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: const Text(
                    "    ZERO TWO",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.redAccent, blurRadius: 10)
                      ],
                    ),
                  ),
                ),
              ),
              titleSpacing: 0,
              centerTitle: true,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white12, width: 1),
                  ),
                  onSelected: (value) async {
                    switch (value) {
                      case 'wake_word':
                        await _toggleWakeWordEnabled();
                        break;
                      case 'assistant_mode':
                        await _toggleAssistantMode();
                        break;
                      case 'auto_listen':
                        await _toggleAutoListen();
                        break;
                      case 'wife_mode':
                        await _toggleProactiveMode();
                        break;
                      case 'clear_memory':
                        await _clearMemory();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'wife_mode',
                      child: Row(
                        children: [
                          Icon(
                            _proactiveEnabled
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _proactiveEnabled
                                ? Colors.pinkAccent
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Wife Mode",
                            style: TextStyle(
                              color: _proactiveEnabled
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'wake_word',
                      child: Row(
                        children: [
                          Icon(
                            _wakeWordEnabledByUser
                                ? Icons.sensors
                                : Icons.sensors_off,
                            color: _wakeWordEnabledByUser
                                ? Colors.redAccent
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Wake Word",
                            style: TextStyle(
                              color: _wakeWordEnabledByUser
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'assistant_mode',
                      child: Row(
                        children: [
                          Icon(
                            _assistantModeEnabled
                                ? Icons.hearing
                                : Icons.hearing_disabled,
                            color: _assistantModeEnabled
                                ? Colors.redAccent
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Background Assistant",
                            style: TextStyle(
                              color: _assistantModeEnabled
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'auto_listen',
                      child: Row(
                        children: [
                          Icon(
                            _isAutoListening ? Icons.mic : Icons.mic_off,
                            color: _isAutoListening
                                ? Colors.redAccent
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Auto Listen",
                            style: TextStyle(
                              color: _isAutoListening
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'clear_memory',
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline,
                              color: Colors.white70, size: 20),
                          SizedBox(width: 12),
                          Text("Clear Memory",
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.palette_outlined,
                              color: Colors.white70),
                          onPressed: _showThemeSelector,
                          tooltip: "Atmosphere",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                Positioned.fill(
                    child: AnimatedBackground(controller: _scrollController)),
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          RepaintBoundary(child: _buildAvatarArea()),
                          Expanded(
                            child: _buildChatList(),
                          ),
                          RepaintBoundary(child: _buildInputArea()),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showOpeningOverlay) _buildOpeningOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpeningOverlay() {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _openingFade,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.05,
              colors: [
                const Color(0xFF40141D),
                const Color(0xCC1A1018),
                AppThemes.getTheme(themeNotifier.value).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _openingScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "ZERO TWO",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        const Shadow(color: Colors.redAccent, blurRadius: 22)
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "CORE 0.02",
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 10,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW UI COMPONENTS ---

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(
                "SELECT ATMOSPHERE",
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ValueListenableBuilder<AppThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, currentMode, _) {
                    // ── Define tier groups ────────────────────────
                    final tiers = [
                      _ThemeTier(
                          "⚡  ICONIC",
                          [
                            AppThemeMode.bloodMoon,
                            AppThemeMode.voidMatrix,
                            AppThemeMode.angelFall,
                            AppThemeMode.titanSoul,
                            AppThemeMode.cosmicRift
                          ],
                          const Color(0xFFFF1744)),
                      _ThemeTier(
                          "💎  ULTRA-PREMIUM",
                          [
                            AppThemeMode.neonSerpent,
                            AppThemeMode.chromaStorm,
                            AppThemeMode.goldenRuler,
                            AppThemeMode.frozenDivine,
                            AppThemeMode.infernoGod
                          ],
                          const Color(0xFFFFD700)),
                      _ThemeTier(
                          "🗡️  ANIME LEGENDS",
                          [
                            AppThemeMode.shadowBlade,
                            AppThemeMode.pinkChaos,
                            AppThemeMode.abyssWatcher,
                            AppThemeMode.solarFlare,
                            AppThemeMode.demonSlayer
                          ],
                          const Color(0xFFFF4081)),
                      _ThemeTier(
                          "🥀  LUXURY & FASHION",
                          [
                            AppThemeMode.midnightSilk,
                            AppThemeMode.obsidianRose,
                            AppThemeMode.onyxEmerald,
                            AppThemeMode.velvetCrown,
                            AppThemeMode.platinumDawn
                          ],
                          const Color(0xFFCE93D8)),
                      _ThemeTier(
                          "🛸  SCI-FI",
                          [
                            AppThemeMode.hypergate,
                            AppThemeMode.xenoCore,
                            AppThemeMode.dataStream,
                            AppThemeMode.gravityBend,
                            AppThemeMode.quartzPulse
                          ],
                          const Color(0xFF40C4FF)),
                      _ThemeTier(
                          "🌿  NATURE",
                          [
                            AppThemeMode.midnightForest,
                            AppThemeMode.volcanicSea,
                            AppThemeMode.stormDesert,
                            AppThemeMode.sakuraNight,
                            AppThemeMode.arcticSoul
                          ],
                          const Color(0xFF81C784)),
                    ];

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: tiers.length,
                      itemBuilder: (context, tierIdx) {
                        final tier = tiers[tierIdx];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Tier header ────────────────────
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16, bottom: 10, left: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: tier.accentColor,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                            color: tier.accentColor
                                                .withOpacity(0.6),
                                            blurRadius: 6)
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tier.label,
                                    style: GoogleFonts.outfit(
                                      color: tier.accentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ── Theme cards grid ───────────────
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: tier.modes.length,
                              itemBuilder: (context, i) {
                                final mode = tier.modes[i];
                                final isSelected = currentMode == mode;
                                final themeData = AppThemes.getTheme(mode);
                                final name = AppThemes.getThemeName(mode);
                                final gradient = AppThemes.getGradient(mode);
                                return GestureDetector(
                                  onTap: () async {
                                    themeNotifier.value = mode;
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setInt('app_theme_index',
                                        AppThemeMode.values.indexOf(mode));
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: gradient.take(3).toList(),
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? themeData.primaryColor
                                            : Colors.white.withOpacity(0.08),
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                  color: themeData.primaryColor
                                                      .withOpacity(0.5),
                                                  blurRadius: 12,
                                                  spreadRadius: 1)
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          width: isSelected ? 28 : 22,
                                          height: isSelected ? 28 : 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: themeData.primaryColor,
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                        color: themeData
                                                            .primaryColor
                                                            .withOpacity(0.7),
                                                        blurRadius: 8)
                                                  ]
                                                : [],
                                          ),
                                          child: isSelected
                                              ? Icon(Icons.check_rounded,
                                                  color: Colors.black87,
                                                  size: 14)
                                              : null,
                                        ),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Text(
                                            name,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white60,
                                              fontSize: 8.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarArea() {
    return Column(
      children: [
        Text(
          "CORE 002",
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onLogoTap,
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final val = _floatController.value;
              final float = math.sin(val * 2 * math.pi) * 4.0; // Extra subtle

              return Transform.translate(
                offset: Offset(0, float),
                child: child,
              );
            },
            child: _ReactivePulse(
              isSpeaking: _isSpeaking,
              isListening: _speechService.listening,
              baseColor: _isSpeaking
                  ? const Color(0xFFFF1744)
                  : Theme.of(context).primaryColor,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        _isSpeaking ? const Color(0xFFFF1744) : Colors.white10,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isSpeaking ? Colors.red : Colors.pink)
                          .withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'zero_two.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.white10,
                      child: const Icon(Icons.person, color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _isSpeaking
                ? "DECODING SPEECH..."
                : _speechService.listening
                    ? "INPUT DETECTED..."
                    : !_wakeWordEnabledByUser
                        ? "WAKE OFFLINE"
                        : _wakeWordService.isRunning
                            ? "SYSTEM READY"
                            : _apiKeyStatus.toUpperCase(),
            key: ValueKey(
                "${_isSpeaking}_${_speechService.listening}_${_wakeWordService.isRunning}_$_apiKeyStatus"),
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w400,
              shadows: _isSpeaking
                  ? [
                      Shadow(
                          color: Theme.of(context).primaryColor, blurRadius: 12)
                    ]
                  : [],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _wakeEffectVisible ? 1 : 0,
          child: Transform.scale(
            scale: _wakeEffectVisible ? 1.0 : 0.95,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on,
                          color: Theme.of(context).primaryColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "WAKE WORD ACTIVE",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatList() {
    final style = AppThemes.getStyle(themeNotifier.value);
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent
          ],
          stops: [0.0, 0.08, 0.92, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _listKey,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              initialItemCount: _messages.length,
              itemBuilder: (context, index, animation) {
                if (index >= _messages.length) return const SizedBox.shrink();
                final msg = _messages[index];
                final isUser = msg.role == 'user';
                // Per-theme entry animation — all wrapped with a pop-from-below
                Widget child = _buildBubble(context, msg, isGhost: false);

                // Universal "pop from below" wrapper applied on top of per-theme style
                Widget themed;
                switch (style.animStyle) {
                  case AnimStyle.elastic:
                    themed = FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                            parent: animation, curve: Curves.elasticOut),
                        child: child,
                      ),
                    );
                  case AnimStyle.slideSide:
                    final slideBegin =
                        isUser ? const Offset(0.4, 0) : const Offset(-0.4, 0);
                    themed = FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(begin: slideBegin, end: Offset.zero)
                                .animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    );
                  case AnimStyle.glitch:
                    themed = FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.08, end: 1.0).animate(
                            CurvedAnimation(
                                parent: animation, curve: Curves.easeOutBack)),
                        child: child,
                      ),
                    );
                  case AnimStyle.fadeZoom:
                    themed = FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                            CurvedAnimation(
                                parent: animation, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    );
                  case AnimStyle.press:
                    themed = FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                                parent: animation, curve: Curves.easeOutExpo)),
                        child: child,
                      ),
                    );
                }

                // 🌟 Universal spring pop-from-below — applied to EVERY message
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(
                        0, 0.18), // starts ~18% of its height below
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutBack)),
                  child: themed,
                );
              },
            ),
          ),
          if (_currentVoiceText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
              child: _buildBubble(
                context,
                ChatMessage(role: "user", content: _currentVoiceText),
                isGhost: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, ChatMessage msg,
      {required bool isGhost}) {
    final isUser = msg.role == 'user';
    if (msg.role == 'system') return const SizedBox.shrink();

    final mode = themeNotifier.value;
    final style = AppThemes.getStyle(mode);
    final primary = Theme.of(context).primaryColor;
    final maxW = MediaQuery.of(context).size.width * 0.80;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(style.cornerRadius),
      topRight: Radius.circular(style.cornerRadius),
      bottomLeft: isUser
          ? Radius.circular(style.cornerRadius)
          : Radius.circular(style.sharpCorner),
      bottomRight: isUser
          ? Radius.circular(style.sharpCorner)
          : Radius.circular(style.cornerRadius),
    );

    // â”€â”€ Build the text widget using theme font
    final textColor = isUser
        ? Colors.white.withOpacity(isGhost ? 0.7 : 1.0)
        : Colors.white.withOpacity(isGhost ? 0.6 : 0.92);
    Widget textWidget = Text(
      msg.content,
      style: style.font(15.5, textColor),
    );

    // â”€â”€ Chip for thinking state
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget,
        if (isGhost)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.graphic_eq_rounded,
                    size: 14, color: primary.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text("THINKING...",
                    style: style.font(9, primary.withOpacity(0.7)).copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
          )
      ],
    );

    // â”€â”€ Route to bubble builder by BubbleStyle
    Widget bubble;
    switch (style.bubbleStyle) {
      case BubbleStyle.terminal:
        // Raw terminal: no background, just text with left bar
        bubble = Container(
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isUser ? primary : style.borderColor(primary),
                width: isUser ? 3 : 2,
              ),
            ),
            color: Colors.black.withOpacity(0.3),
          ),
          child: content,
        );
        break;

      case BubbleStyle.outlined:
        // Hollow: no fill, just a glowing border
        bubble = Container(
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: isUser ? primary : style.borderColor(primary),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isUser ? primary : style.borderColor(primary))
                    .withOpacity(isGhost ? 0.1 : 0.2),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: content,
        );
        break;

      case BubbleStyle.luxury:
        // Luxury card: opaque dark with gold/primary shimmer border
        bubble = Container(
          constraints: BoxConstraints(maxWidth: maxW),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUser
                  ? [primary.withOpacity(0.80), primary.withOpacity(0.60)]
                  : [const Color(0xFF1A1200), const Color(0xFF120D00)],
            ),
            border: Border.all(
              color: primary.withOpacity(0.45),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: content,
        );
        break;

      case BubbleStyle.solid:
        // Sharp solid: opaque fill, no blur, optional left accent bar
        final bgColor = isUser
            ? primary.withOpacity(isGhost ? 0.5 : 0.9)
            : Colors.white.withOpacity(0.09);
        Widget solidBubble = Container(
          constraints: BoxConstraints(maxWidth: maxW),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: bgColor,
            border: Border.all(
              color: style.borderColor(primary),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: content,
        );
        if (style.leftAccentBar && !isUser) {
          solidBubble = IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(style.cornerRadius),
                      bottomLeft: Radius.circular(style.sharpCorner),
                    ),
                  ),
                ),
                Flexible(child: solidBubble),
              ],
            ),
          );
        }
        bubble = solidBubble;
        break;

      case BubbleStyle.glassmorphic:
        // Classic frosted glass
        bubble = ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppThemes.getBlurIntensity(mode),
              sigmaY: AppThemes.getBlurIntensity(mode),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: isUser
                    ? primary.withOpacity(isGhost ? 0.25 : 0.70)
                    : Colors.white.withOpacity(0.07),
                border: Border.all(
                  color: isUser ? Colors.white30 : style.borderColor(primary),
                  width: 1.0,
                ),
              ),
              child: content,
            ),
          ),
        );
        break;
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: bubble,
      ),
    );
  }

  Widget _buildInputArea() {
    final mode = themeNotifier.value;
    final style = AppThemes.getStyle(mode);
    final primary = Theme.of(context).primaryColor;
    final isListening = _speechService.listening;
    final hint = isListening ? "Listening..." : style.hintText;

    // The mic + send button row is shared across all styles
    Widget micBtn = GestureDetector(
      onTap: _toggleManualMic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isListening
                ? [primary, primary.withOpacity(0.7)]
                : [Colors.white12, Colors.white10],
          ),
          boxShadow: [
            if (isListening)
              BoxShadow(color: primary.withOpacity(0.45), blurRadius: 14),
          ],
        ),
        child: Icon(
          _isSpeaking
              ? Icons.stop_rounded
              : (isListening ? Icons.mic_rounded : Icons.mic_none_rounded),
          color: Colors.white,
          size: 20,
        ),
      ),
    );

    Widget sendBtn = IconButton(
      icon: Icon(Icons.arrow_upward_rounded, color: primary, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: primary.withOpacity(0.18),
        minimumSize: const Size(44, 44),
      ),
      onPressed: _handleTextInput,
    );

    Widget buildTextField({
      TextStyle? textStyle,
      InputDecoration? decoration,
    }) {
      return TextField(
        controller: _textController,
        style: textStyle ?? style.font(15, Colors.white),
        decoration: decoration ??
            InputDecoration(
              hintText: hint,
              hintStyle: style.font(14, Colors.white38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
        onSubmitted: (_) => _handleTextInput(),
      );
    }

    switch (style.inputStyle) {
      // â”€â”€ SQUARE NEON: sharp rectangle, glowing primary border
      case InputStyle.squareNeon:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              border: Border.all(color: primary.withOpacity(0.7), width: 1.5),
              boxShadow: [
                BoxShadow(color: primary.withOpacity(0.2), blurRadius: 16),
              ],
            ),
            child: Row(children: [
              const SizedBox(width: 6),
              Expanded(child: buildTextField()),
              micBtn,
              const SizedBox(width: 4),
              sendBtn,
            ]),
          ),
        );

      // â”€â”€ TERMINAL: pure dark, monospace, prompt indicator
      case InputStyle.terminal:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              border: Border(
                top: BorderSide(color: primary.withOpacity(0.6), width: 1),
              ),
            ),
            child: Row(children: [
              Text("â¯ ", style: style.font(15, primary)),
              Expanded(
                child: buildTextField(
                  textStyle: style.font(14.5, primary),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: style.font(14, primary.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              micBtn,
              const SizedBox(width: 4),
              sendBtn,
            ]),
          ),
        );

      // â”€â”€ UNDERLINE: minimal, just a bottom line
      case InputStyle.underline:
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                  child: buildTextField(
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: style.font(14, Colors.white38),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: primary.withOpacity(0.35)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                micBtn,
                const SizedBox(width: 4),
                sendBtn,
              ]),
            ],
          ),
        );

      // â”€â”€ LUXURY: rich gold card with shadow
      case InputStyle.luxury:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF151000),
              border: Border.all(color: primary.withOpacity(0.4), width: 1.0),
              boxShadow: [
                BoxShadow(
                    color: primary.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(children: [
              Expanded(child: buildTextField()),
              micBtn,
              const SizedBox(width: 4),
              sendBtn,
            ]),
          ),
        );

      case InputStyle.pill:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(children: [
                  const SizedBox(width: 12),
                  Expanded(child: buildTextField()),
                  micBtn,
                  const SizedBox(width: 4),
                  sendBtn,
                ]),
              ),
            ),
          ),
        );
    }
  }
}

// ── Theme picker tier group model ────────────────────────────────────────────
class _ThemeTier {
  final String label;
  final List<AppThemeMode> modes;
  final Color accentColor;
  const _ThemeTier(this.label, this.modes, this.accentColor);
}

// --- ANIMATED BACKGROUND COMPONENTS ---

class Particle {
  double x, y, vx, vy, radius, speed, theta;
  double opacity;
  final ParticleType type;

  Particle(Size size, this.type)
      : x = math.Random().nextDouble() * size.width,
        y = math.Random().nextDouble() * size.height,
        vx = 0,
        vy = 0,
        radius = math.Random().nextDouble() * 2.5 + 0.5,
        speed = math.Random().nextDouble() * 0.4 + 0.1,
        theta = math.Random().nextDouble() * 2 * math.pi,
        opacity = math.Random().nextDouble() * 0.5 + 0.1;

  void update(Size size, Offset? interactionPoint) {
    theta += 0.002;

    // Natural movement
    double targetVx = math.cos(theta) * speed;
    double targetVy = math.sin(theta) * speed;

    // Type-specific physics
    switch (type) {
      case ParticleType.snow:
        targetVy = speed * 1.5; // Falling
        targetVx = math.cos(theta) * speed * 0.5; // Swaying
        break;
      case ParticleType.rain:
        targetVy = 8.0; // Fast falling
        targetVx = 0.5; // Wind
        break;
      case ParticleType.embers:
        targetVy = -speed * 2.0; // Rising
        targetVx = math.cos(theta) * speed * 0.8; // Swaying
        opacity = 0.3 + 0.5 * math.Random().nextDouble(); // Flickering
        break;
      case ParticleType.stars:
        targetVx = 0;
        targetVy = 0; // Fixed
        opacity = 0.2 + 0.6 * (0.5 + 0.5 * math.sin(theta * 5)); // Twinkling
        break;
      case ParticleType.bubbles:
        targetVy = -speed * 1.2;
        targetVx = math.cos(theta * 2) * speed * 0.3;
        break;
      default:
        break;
    }

    // Interaction physics (Repulsion)
    if (interactionPoint != null) {
      double dx = x - interactionPoint.dx;
      double dy = y - interactionPoint.dy;
      double distSq = dx * dx + dy * dy;
      double dist = math.sqrt(distSq);

      if (dist < 100) {
        double force = (100 - dist) / 100;
        vx += (dx / dist) * force * 2.5;
        vy += (dy / dist) * force * 2.5;
      }
    }

    // Velocity smoothing / Friction
    vx = lerpDouble(vx, targetVx, 0.05)!;
    vy = lerpDouble(vy, targetVy, 0.05)!;

    x += vx;
    y += vy;

    if (x < 0) x = size.width;
    if (x > size.width) x = 0;
    if (y < 0) y = size.height;
    if (y > size.height) y = 0;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color themeColor;
  final ParticleType type;

  ParticlePainter(
      this.particles, this.animationValue, this.themeColor, this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = themeColor.withOpacity(p.opacity);

      switch (type) {
        case ParticleType.circles:
          canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
          break;
        case ParticleType.squares:
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset(p.x, p.y),
                  width: p.radius * 2,
                  height: p.radius * 2),
              paint);
          break;
        case ParticleType.lines:
          canvas.drawLine(
              Offset(p.x, p.y),
              Offset(p.x + p.radius * 2, p.y + p.radius * 2),
              paint..strokeWidth = 1.0);
          break;
        case ParticleType.sakura:
          // Premium Sakura petal shape
          final path = Path();
          final r = p.radius;
          path.moveTo(p.x, p.y - r * 1.5);
          path.cubicTo(
              p.x + r * 1.2, p.y - r * 1.5, p.x + r, p.y + r, p.x, p.y + r * 2);
          path.cubicTo(p.x - r, p.y + r, p.x - r * 1.2, p.y - r * 1.5, p.x,
              p.y - r * 1.5);
          path.close();
          canvas.drawPath(path, paint);
          break;
        case ParticleType.embers:
          final r = p.radius;
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset(p.x, p.y), width: r * 1.5, height: r * 1.5),
              paint);
          break;
        case ParticleType.bubbles:
          canvas.drawCircle(
              Offset(p.x, p.y),
              p.radius,
              paint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.5);
          break;
        case ParticleType.leaves:
          final r = p.radius;
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(p.x, p.y), width: r * 2.5, height: r * 1.2),
              paint);
          break;
        case ParticleType.snow:
          canvas.drawCircle(Offset(p.x, p.y), p.radius * 0.8, paint);
          break;
        case ParticleType.stars:
          final r = p.radius * (0.8 + 0.4 * math.sin(animationValue * 10));
          canvas.drawCircle(Offset(p.x, p.y), r, paint);
          break;
        case ParticleType.rain:
          canvas.drawLine(Offset(p.x, p.y), Offset(p.x, p.y + 10),
              paint..strokeWidth = 0.5);
          break;
      }

      // Subtle glow
      paint.style = PaintingStyle.fill;
      paint.color = themeColor.withOpacity(p.opacity * 0.2);
      if (type == ParticleType.sakura || type == ParticleType.embers) {
        canvas.drawCircle(Offset(p.x, p.y), p.radius * 3, paint);
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.radius * 2.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedBackground extends StatefulWidget {
  final ScrollController? controller;
  const AnimatedBackground({super.key, this.controller});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  Offset? interactionPoint;
  AppThemeMode? _lastMode;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    widget.controller?.addListener(_onScroll);
    particles = [];
  }

  void _onScroll() {
    if (widget.controller == null || !widget.controller!.hasClients) return;
    final speed = widget.controller!.position.userScrollDirection ==
            ScrollDirection.reverse
        ? -1.2
        : 1.2;
    for (var p in particles) {
      p.vy += speed * (p.radius / 2.0);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<AppThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, _) {
            final pType = AppThemes.getParticleType(mode);
            if (_lastMode == null || _lastMode != mode || particles.isEmpty) {
              _lastMode = mode;
              particles = List.generate(
                60,
                (_) => Particle(
                    Size(constraints.maxWidth, constraints.maxHeight), pType),
              );
            }
            final theme = AppThemes.getTheme(mode);
            final primary = theme.primaryColor;
            final accent = theme.colorScheme.tertiary;
            final gradientColors = AppThemes.getGradient(mode);

            return GestureDetector(
              onPanUpdate: (details) {
                setState(() => interactionPoint = details.localPosition);
              },
              onPanEnd: (_) => setState(() => interactionPoint = null),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  for (var p in particles) {
                    p.update(Size(constraints.maxWidth, constraints.maxHeight),
                        interactionPoint);
                  }

                  final t = _controller.value;
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  return Stack(
                    children: [
                      // LAYER 1: Deep cinematic gradient base (diagonal)
                      Container(
                        width: w,
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                        ),
                      ),

                      // LAYER 2: Crepuscular god-rays — slow rotating beams from above
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CrepuscularPainter(
                            primary: primary,
                            accent: accent,
                            t: (t * 0.014) % 1.0, // full rotation every ~72s
                          ),
                        ),
                      ),

                      // LAYER 3: Particles on top
                      CustomPaint(
                        painter: ParticlePainter(particles, t, primary, pType),
                        size: Size.infinite,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// Cinematic crepuscular god-rays from above screen, slow 72s rotation.
class _CrepuscularPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final double t;

  const _CrepuscularPainter({
    required this.primary,
    required this.accent,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int rayCount = 10;
    final double cx = size.width * 0.5;
    final double cy = -size.height * 0.38;
    final double maxR = size.height * 1.9;
    final double base = t * 2 * math.pi;

    for (int i = 0; i < rayCount; i++) {
      final double angle = base + (i / rayCount) * 2 * math.pi;
      final double hw = (0.025 + 0.018 * math.sin(i * 1.4)) * math.pi;
      final double op = 0.045 + 0.020 * math.sin(i * 0.8 + 1.0);
      final Color c = (i % 3 == 0) ? accent : primary;

      final double p1x = cx + maxR * math.cos(angle - hw);
      final double p1y = cy + maxR * math.sin(angle - hw);
      final double p2x = cx + maxR * math.cos(angle + hw);
      final double p2y = cy + maxR * math.sin(angle + hw);

      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(p1x, p1y)
        ..lineTo(p2x, p2y)
        ..close();

      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.5),
          radius: 1.15,
          colors: [c.withOpacity(op), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CrepuscularPainter o) => true;
}

class _ReactivePulse extends StatefulWidget {
  final bool isSpeaking;
  final bool isListening;
  final Color baseColor;
  final Widget child;

  const _ReactivePulse({
    required this.isSpeaking,
    required this.isListening,
    required this.baseColor,
    required this.child,
  });

  @override
  State<_ReactivePulse> createState() => _ReactivePulseState();
}

class _ReactivePulseState extends State<_ReactivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 +
            (widget.isSpeaking ? 0.2 : (widget.isListening ? 0.1 : 0.05)) *
                _pulseController.value;
        final opacity =
            (widget.isSpeaking ? 0.6 : (widget.isListening ? 0.4 : 0.25)) *
                (1.0 - _pulseController.value);

        return Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              Transform.scale(
                scale: scale + (i * 0.15),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.baseColor.withOpacity(opacity / (i + 1)),
                        widget.baseColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }
}
// --- VISUAL OVERDRIVE COMPONENTS ---

class _VisualEffectsOverlay extends StatefulWidget {
  final Widget child;
  final AppThemeMode themeMode;

  const _VisualEffectsOverlay({required this.child, required this.themeMode});

  @override
  State<_VisualEffectsOverlay> createState() => _VisualEffectsOverlayState();
}

class _VisualEffectsOverlayState extends State<_VisualEffectsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _effectController;

  @override
  void initState() {
    super.initState();
    _effectController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _effectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Screen-Edge Glow
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _effectController,
              builder: (context, _) {
                final intensity =
                    AppThemes.getEdgeGlowIntensity(widget.themeMode);
                if (intensity <= 0) return const SizedBox.shrink();

                final theme = AppThemes.getTheme(widget.themeMode);
                final pulse =
                    0.5 + 0.5 * math.sin(_effectController.value * 2 * math.pi);

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.primaryColor
                          .withOpacity(intensity * pulse * 0.15),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor
                            .withOpacity(intensity * pulse * 0.2),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        // Grain & Scanlines
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _effectController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CinemaPainter(
                    widget.themeMode,
                    _effectController.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CinemaPainter extends CustomPainter {
  final AppThemeMode mode;
  final double animation;

  _CinemaPainter(this.mode, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random();

    // Grain Effect
    final grainIntensity = AppThemes.getGrainIntensity(mode);
    if (grainIntensity > 0) {
      for (int i = 0; i < 1000; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final op = random.nextDouble() * grainIntensity;
        paint.color = Colors.white.withOpacity(op);
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }

    // Scanlines Effect
    if (AppThemes.hasScanlines(mode)) {
      paint.color = Colors.black.withOpacity(0.05);
      paint.strokeWidth = 1.0;
      double scroll = animation * 8.0;
      for (double y = scroll; y < size.height; y += 4.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CinemaPainter oldDelegate) => true;
}
