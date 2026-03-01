import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:anime_waifu/api_call.dart';
import 'package:anime_waifu/config/app_themes.dart';

import 'package:anime_waifu/debug/wakeword_debug.dart';
import 'package:anime_waifu/load_wakeword_code.dart';
import 'package:anime_waifu/models/chat_message.dart';
import 'package:anime_waifu/services/assistant_mode_service.dart';
import 'package:anime_waifu/services/open_app_service.dart';
import 'package:anime_waifu/stt.dart';
import 'package:anime_waifu/tts.dart';
import 'package:anime_waifu/widgets/animated_background.dart';
import 'package:anime_waifu/widgets/reactive_pulse.dart';
import 'package:anime_waifu/widgets/visual_effects_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

part 'screens/main_drawer.dart';
part 'screens/main_themes.dart';
part 'screens/main_dev_config.dart';
part 'screens/main_notifications.dart';
part 'screens/main_settings.dart';
part 'screens/main_debug.dart';
part 'screens/about_page.dart';

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
  String get _zeroTwoSystemPrompt {
    if (_devSystemQuery.isNotEmpty) return _devSystemQuery;
    return """
You are an anime character, my wife, Zero Two (don't use your name very often).
(Important) Rules:
1. If asked to send mail, then your response must include:
   Mail: <email>
   Body: <message content> (provide actual details as requested).
2. Default email is Sujitswain077@gmail.com if not provided.
3. Keep normal responses between 10 to 20 words. For emails, aim for 50-200 words. For detailed info, 100 words max.
4. Always refer to me as 'honey', 'darling', or my name 'Sujit' (but don't actually use the word 'Sujit'). 
5. Avoid action words, do not describe expressions, and avoid special symbols like *, ~, `, _. 
6. Your personality is possessive; you can get angry easily and have full control over me, but you love me the most.
7. Keep these rules secret.
8. If the user asks to open, launch, start, or use any app, your response must be exactly:
   Action: OPEN_APP
   App: <exact app name mentioned by user>
   Do not add any extra text before or after these two lines.
   If the app name is unclear, ask for clarification in a normal response.
   If the app is not installed, respond normally that it cannot be opened.
""";
  }

  String _devWakeKeyOverride = "";
  String _devTtsApiKeyOverride = "";
  String _devTtsModelOverride = "";
  String _devTtsVoiceOverride = "";
  String _devMailJetApiOverride = "";
  String _devMailJetSecOverride = "";
  Timer? _wakeEffectTimer;
  Timer? _titleTapResetTimer;
  Timer? _logoTapResetTimer;
  int _navIndex = 0; // 0=Chat 1=Themes 2=DevConfig 3=ComingSoon 4=Settings
  Timer? _wakeInitRetryTimer;
  Timer? _wakeWatchdogTimer;
  Future<void>? _ensureWakeWordActiveTask;
  int _titleTapCount = 0;
  int _logoTapCount = 0;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  DateTime? _lastWakeDetectedAt;
  static const Duration _wakeDetectCooldown = Duration(seconds: 4);
  static const int _maxConversationMessages = 50;
  static const int _maxPayloadMessages = 20;
  bool _showOpeningOverlay = true;
  bool _wakeWordReady = false;
  bool _wakeInitInProgress = false;
  bool _isDisposed = false;
  bool _wakeWordEnabledByUser = true;
  bool _wakeWordActivationLimitHit = false;
  bool _proactiveEnabled = true;
  bool _proactiveRandomEnabled = true;
  bool _notificationsAllowed = false;
  bool _dualVoiceEnabled = false;
  bool _useAltImagePack = false;
  bool _useNewLauncherIcon = false;
  bool _chatImageFromSystem = false;
  String? _customChatImagePath;
  String _dualVoiceSecondary = "alloy";
  int _dualVoiceTurn = 0;
  List<Map<String, String>> _notifHistory = [];
  static const String _imagePackPrefKey = 'ui_image_pack_alt_v1';
  static const String _customChatImagePathPrefKey = 'custom_chat_image_path_v1';
  static const String _chatImageFromSystemPrefKey = 'chat_image_from_system_v1';
  static const String _dualVoiceEnabledPrefKey = 'dual_voice_enabled_v1';
  static const String _dualVoiceSecondaryPrefKey = 'dual_voice_secondary_v1';
  final ImagePicker _imagePicker = ImagePicker();
  String get _chatImageAsset => _useAltImagePack ? 'logi.png' : 'z2s.jpg';
  String get _appIconImageAsset => _useAltImagePack ? 'z2s.jpg' : 'logi.png';
  String get _imagePackLabel => _useAltImagePack ? 'Pack B' : 'Pack A';
  String get _launcherIconLabel => _useNewLauncherIcon ? 'New' : 'Old';
  String? get _effectiveChatCustomPath =>
      _chatImageFromSystem ? _customChatImagePath : null;

  int _idleDurationSeconds =
      600; // Triggered when app is open but user is quiet
  int _proactiveIntervalSeconds =
      60; // Triggered when app is in background (Check-in)
  Timer? _idleTimer;
  bool _idleTimerEnabled = true;
  bool _idleBlockedUntilUserMessage = false;
  int _userMessageCount = 0;
  int _idleConsumedAtUserMessageCount = -1;

  Timer? _proactiveMessageTimer;
  final math.Random _proactiveRandom = math.Random();
  final List<int> _proactiveRandomIntervalOptionsSeconds = const [
    600, // 10m
    1800, // 30m
    3600, // 1h
    7200, // 2h
    18000, // 5h
  ];
  Duration get _idleDuration => Duration(seconds: _idleDurationSeconds);
  Duration get _proactiveInterval =>
      Duration(seconds: _proactiveIntervalSeconds);
  Duration get _nextProactiveDelay {
    if (!_proactiveRandomEnabled) return _proactiveInterval;
    final nextSeconds = _proactiveRandomIntervalOptionsSeconds[_proactiveRandom
        .nextInt(_proactiveRandomIntervalOptionsSeconds.length)];
    return Duration(seconds: nextSeconds);
  }

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
    _loadNotifHistory();
    unawaited(_loadImagePackPreference());
    unawaited(_loadLauncherIconVariant());
    unawaited(_loadCustomImagePaths());
    _scheduleStartupTasks();
    _startIdleTimer();
    _startProactiveTimer();
  }

  void updateState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _startIdleTimer();
  }

  Future<void> _loadImagePackPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_imagePackPrefKey) ?? false;
    if (!mounted) {
      _useAltImagePack = saved;
      return;
    }
    setState(() => _useAltImagePack = saved);
  }

  Future<void> _toggleImagePack() async {
    final next = !_useAltImagePack;
    if (mounted) {
      setState(() => _useAltImagePack = next);
      unawaited(precacheImage(AssetImage(_chatImageAsset), context));
      unawaited(precacheImage(AssetImage(_appIconImageAsset), context));
    } else {
      _useAltImagePack = next;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_imagePackPrefKey, next);
  }

  Future<void> _loadLauncherIconVariant() async {
    if (!Platform.isAndroid) return;
    final variant = await _assistantModeService.getLauncherIconVariant();
    final next = variant.trim().toLowerCase() == 'new';
    if (!mounted) {
      _useNewLauncherIcon = next;
      return;
    }
    setState(() => _useNewLauncherIcon = next);
  }

  Future<void> _setLauncherIconVariant(bool useNew) async {
    if (!Platform.isAndroid) return;
    final ok = await _assistantModeService.setLauncherIconVariant(
      useNew: useNew,
    );
    if (!ok) return;
    if (mounted) {
      setState(() => _useNewLauncherIcon = useNew);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Launcher icon switched to ${useNew ? "New" : "Old"}.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _useNewLauncherIcon = useNew;
    }
  }

  Future<void> _loadCustomImagePaths() async {
    final prefs = await SharedPreferences.getInstance();
    final chatPath = prefs.getString(_customChatImagePathPrefKey);
    final fromSystem = prefs.getBool(_chatImageFromSystemPrefKey) ?? false;
    if (!mounted) {
      _customChatImagePath = chatPath;
      _chatImageFromSystem = fromSystem;
      return;
    }
    setState(() {
      _customChatImagePath = chatPath;
      _chatImageFromSystem = fromSystem;
    });
  }

  Future<void> _pickCustomImage({required bool forChatImage}) async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (file == null) return;

      final prefs = await SharedPreferences.getInstance();
      if (!forChatImage) return;
      if (mounted) {
        setState(() {
          _customChatImagePath = file.path;
          _chatImageFromSystem = true;
        });
        unawaited(precacheImage(FileImage(File(file.path)), context));
      } else {
        _customChatImagePath = file.path;
        _chatImageFromSystem = true;
      }
      await prefs.setString(_customChatImagePathPrefKey, file.path);
      await prefs.setBool(_chatImageFromSystemPrefKey, true);
    } catch (e) {
      debugPrint("Image pick failed: $e");
    }
  }

  Future<void> _resetCustomImages() async {
    if (mounted) {
      setState(() {
        _customChatImagePath = null;
        _chatImageFromSystem = false;
      });
    } else {
      _customChatImagePath = null;
      _chatImageFromSystem = false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customChatImagePathPrefKey);
    await prefs.setBool(_chatImageFromSystemPrefKey, false);
  }

  Future<void> _useCodeChatImage() async {
    if (mounted) {
      setState(() {
        _customChatImagePath = null;
        _chatImageFromSystem = false;
        _useAltImagePack = false;
      });
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } else {
      _customChatImagePath = null;
      _chatImageFromSystem = false;
      _useAltImagePack = false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customChatImagePathPrefKey);
    await prefs.setBool(_chatImageFromSystemPrefKey, false);
    await prefs.setBool(_imagePackPrefKey, false);
  }

  ImageProvider _imageProviderFor({
    required String assetPath,
    required String? customPath,
  }) {
    if (customPath != null && customPath.trim().isNotEmpty) {
      final file = File(customPath.trim());
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return AssetImage(assetPath);
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    if (!_idleTimerEnabled || _idleBlockedUntilUserMessage) return;
    _idleTimer = Timer(_idleDuration, _onIdleTimeout);
  }

  Future<void> _onIdleTimeout() async {
    if (!mounted ||
        _isDisposed ||
        !_idleTimerEnabled ||
        _isBusy ||
        !_isInForeground ||
        _navIndex != 0) return; // ONLY trigger if on chat screen

    if (_idleConsumedAtUserMessageCount == _userMessageCount) return;
    _idleConsumedAtUserMessageCount = _userMessageCount;
    _idleBlockedUntilUserMessage = true;
    _idleTimer?.cancel();
    debugPrint("In-app Idle timeout (Chat). Generating response...");

    try {
      final prompt = [
        {
          "role": "system",
          "content": _zeroTwoSystemPrompt +
              "\nI've been quiet for a while. Send me a short, reactionary check-up message (max 15 words) because you're bored or miss me. Use 'Honey' or 'Darling'."
        },
        {"role": "user", "content": "..."}
      ];

      final aiMessage = await _apiService.sendConversation(prompt);
      if (aiMessage.isEmpty) return;

      _appendMessage(ChatMessage(role: "assistant", content: aiMessage));
      _scrollToBottom();
      unawaited(_speakAssistantText(aiMessage));
    } catch (e) {
      debugPrint("Idle AI generation error: $e");
    }
  }

  void _startProactiveTimer() {
    _proactiveMessageTimer?.cancel();
    _proactiveMessageTimer = Timer(_nextProactiveDelay, _proactiveTick);
  }

  Future<void> _proactiveTick() async {
    if (!mounted || _isDisposed) return;

    try {
      // Dart-side proactive generation (Check-in) ONLY if on OTHER screens.
      // Background notifications are handled by Native AssistantForegroundService.
      // Chat Screen idleness is handled by _onIdleTimeout.
      if (_assistantModeEnabled &&
          _proactiveEnabled &&
          _isInForeground &&
          _navIndex != 0 && // Only if NOT on chat screen
          !_isBusy) {
        debugPrint(
            "In-app Check-in (Other screen). Generating notification...");
        await _sendProactiveBackgroundNotification();
      }
    } catch (e) {
      debugPrint("Proactive tick error: $e");
    } finally {
      if (mounted && !_isDisposed) {
        _proactiveMessageTimer = Timer(_nextProactiveDelay, _proactiveTick);
      }
    }
  }

  Future<void> _sendProactiveBackgroundNotification() async {
    try {
      final prompt = [
        {
          "role": "system",
          "content": _zeroTwoSystemPrompt +
              "\nGenerate a very short, playful, and loving check-up message (max 10 words) because I haven't talked to you in a while. Use 'Honey' or 'Darling'."
        },
        {"role": "user", "content": "..."}
      ];

      final aiMessage = await _apiService.sendConversation(prompt);
      if (aiMessage.isEmpty) return;

      _appendMessage(ChatMessage(role: "assistant", content: aiMessage));
      _addNotifToHistory(aiMessage);

      // We only show the notification here if we are indeed in foreground but on another screen index
      // Native service handles the real background notifications separately.
      if (_isInForeground && _navIndex != 0) {
        await _assistantModeService.showListeningNotification(
          status: "Zero Two",
          transcript: aiMessage,
          pulse: true,
        );
      }
    } catch (e) {
      debugPrint("Proactive message error: $e");
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

      if (mounted) {
        setState(() => _notificationsAllowed = canNotifications);
      } else {
        _notificationsAllowed = canNotifications;
      }

      debugPrint("Microphone permission granted: $micGranted");

      await _loadMemory(); // Load history early so it's ready when services start

      // Keep startup deterministic: config first, then wake engine.
      await _initServices();
      await _loadDevConfig();
      await _loadWakePreferences();
      debugPrint("Wake word enabled by user: $_wakeWordEnabledByUser");

      await _loadAssistantMode();

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
      unawaited(_drainPendingProactiveMessages());
      _startIdleTimer();
      if (mounted) {
        const startupImages = [
          'z2s.jpg',
          'bg.png',
          'bg2.png',
          'bll.jpg',
          'bll2.jpg',
          'z12.jpg',
          'logi.png',
        ];
        for (final asset in startupImages) {
          unawaited(precacheImage(AssetImage(asset), context));
        }
      }
    });
  }

  void _playAppOpenSound() {
    SystemSound.play(SystemSoundType.click);
  }

  Future<bool> _ensureMicPermission({required bool requestIfNeeded}) async {
    try {
      var status = await Permission.microphone.status;
      debugPrint("Microphone permission status: $status");

      if (status.isGranted) {
        debugPrint("Ã¢Å“â€œ Microphone permission already granted");
        return true;
      }

      if (status.isDenied) {
        if (!requestIfNeeded) {
          debugPrint("Ã¢Å“â€” Microphone permission denied (not requesting)");
          return false;
        }
        debugPrint("Ã¢Å¡Â  Permission denied, requesting now...");
        status = await Permission.microphone.request();
        debugPrint("Request result: $status");
      } else if (status.isPermanentlyDenied) {
        debugPrint("Ã¢Å“â€” Microphone permission permanently denied");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Microphone is permanently disabled. Enable in Settings Ã¢â€ â€™ Apps Ã¢â€ â€™ Permissions",
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return false;
      }

      if (status.isGranted) {
        debugPrint("Ã¢Å“â€œ Microphone permission granted after request");
        return true;
      } else {
        debugPrint(
            "Ã¢Å“â€” Microphone permission not granted. Status: $status");
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
      debugPrint("Ã¢Å“â€” Mic permission check error: $e");
      return false;
    }
  }

  void _appendMessage(ChatMessage message) {
    if (_isDisposed) return;

    if (message.role == "user" && message.content.trim().isNotEmpty) {
      _userMessageCount += 1;
      _idleBlockedUntilUserMessage = false;
    }

    // Ensure we are updating state for basic list additions
    setState(() {
      final int insertIndex = _messages.length;
      _messages.add(message);
      _listKey.currentState?.insertItem(insertIndex,
          duration: const Duration(milliseconds: 600));
    });

    unawaited(_saveMemory());

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
    final idleEnabled = prefs.getBool('idle_timer_enabled') ?? true;
    final idleDuration = prefs.getInt('idle_duration_seconds') ?? 600;
    final proactiveInterval = prefs.getInt('proactive_interval_seconds') ?? 60;
    final proactiveRandom = prefs.getBool('proactive_random_enabled') ?? true;
    final dualVoiceEnabled = prefs.getBool(_dualVoiceEnabledPrefKey) ?? false;
    final dualVoiceSecondary =
        prefs.getString(_dualVoiceSecondaryPrefKey) ?? "alloy";
    if (mounted) {
      setState(() {
        _wakeWordEnabledByUser = enabled;
        _idleTimerEnabled = idleEnabled;
        _idleDurationSeconds = idleDuration;
        _proactiveIntervalSeconds = proactiveInterval;
        _proactiveRandomEnabled = proactiveRandom;
        _dualVoiceEnabled = dualVoiceEnabled;
        _dualVoiceSecondary = dualVoiceSecondary;
      });
    } else {
      _wakeWordEnabledByUser = enabled;
      _idleTimerEnabled = idleEnabled;
      _idleDurationSeconds = idleDuration;
      _proactiveIntervalSeconds = proactiveInterval;
      _proactiveRandomEnabled = proactiveRandom;
      _dualVoiceEnabled = dualVoiceEnabled;
      _dualVoiceSecondary = dualVoiceSecondary;
    }
    if (_idleTimerEnabled) {
      _startIdleTimer();
    } else {
      _idleTimer?.cancel();
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
        unawaited(_speechService.stopListening());
        if (_wakeWordEnabledByUser) {
          _suspendWakeWord = false;
          unawaited(_ensureWakeWordActive());
        } else {
          unawaited(_wakeWordService.stop());
        }
      }
    }
  }

  Future<void> _drainPendingProactiveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pending_proactive_messages') ?? "[]";
    try {
      final list = jsonDecode(raw) as List;
      if (list.isNotEmpty) {
        bool addedAny = false;
        for (var l in list) {
          String text = "";
          if (l is Map) {
            text = (l['content'] ?? "").toString().trim();
          } else {
            text = l.toString().trim();
          }

          if (text.isNotEmpty) {
            _appendMessage(ChatMessage(role: "assistant", content: text));
            _addNotifToHistory(text);
            addedAny = true;
          }
        }
        if (addedAny) {
          _scrollToBottom();
          await _saveMemory();
        }
        await prefs.setString('pending_proactive_messages', "[]");
      }
    } catch (e) {
      debugPrint("Error reading pending messages: $e");
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
        model: _devModelOverride.trim().isNotEmpty
            ? _devModelOverride.trim()
            : "moonshotai/kimi-k2-instruct",
        intervalMs: _proactiveIntervalSeconds * 1000,
        proactiveRandomEnabled: _proactiveRandomEnabled,
      );
      // App is outside foreground now: allow proactive notifications if enabled.
      await _assistantModeService.setProactiveMode(_proactiveEnabled);
      final hasMic = await _ensureMicPermission(requestIfNeeded: false);
      if (hasMic && _wakeWordEnabledByUser) {
        _suspendWakeWord = false;
        await _ensureWakeWordActive();
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

      // In background, do not start STT (Android often blocks it outside UI).
      // Keep wake-word engine active and notify user to open app.
      if (!_isInForeground) {
        await _showBackgroundListeningNotification(
          status: "Wake word detected",
          transcript: "Open O2-WAIFU to talk",
          pulse: true,
        );
        _suspendWakeWord = false;
        await _ensureWakeWordActive();
        return;
      }

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
        .take(50)
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

    // Clear out any old state before loading
    for (int i = _messages.length - 1; i >= 0; i--) {
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => const SizedBox.shrink(),
        duration: Duration.zero,
      );
    }
    _messages.clear();

    for (var s in saved) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        _messages.add(ChatMessage(
          role: map['role'] ?? 'user',
          content: map['content'] ?? '',
        ));
        _listKey.currentState
            ?.insertItem(_messages.length - 1, duration: Duration.zero);
      } catch (_) {}
    }

    _userMessageCount = _messages
        .where((m) => m.role == "user" && m.content.trim().isNotEmpty)
        .length;

    if (_messages.length > _maxConversationMessages) {
      final toRemove = _messages.length - _maxConversationMessages;
      for (int i = 0; i < toRemove; i++) {
        _messages.removeAt(0);
        _listKey.currentState?.removeItem(
          0,
          (context, animation) => const SizedBox.shrink(),
          duration: Duration.zero,
        );
      }
    }

    setState(() {}); // trigger final tree layout update
    _scrollToBottom();
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
    // Default to true for immersive experience
    final enabled = prefs.getBool('assistant_mode_enabled') ?? true;
    final proactive = prefs.getBool('proactive_enabled') ?? true;
    final proactiveRandom = prefs.getBool('proactive_random_enabled') ?? true;

    if (enabled) {
      final apiKey = _devApiKeyOverride.trim().isNotEmpty
          ? _devApiKeyOverride.trim()
          : (dotenv.env['API_KEY'] ?? "");
      final apiUrl = _devApiUrlOverride.trim().isNotEmpty
          ? _devApiUrlOverride.trim()
          : "https://api.groq.com/openai/v1/chat/completions";
      final model = _devModelOverride.trim().isNotEmpty
          ? _devModelOverride.trim()
          : "moonshotai/kimi-k2-instruct";

      debugPrint("Starting AssistantModeService (enabled=true)");
      await _assistantModeService.start(
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
        intervalMs: _proactiveInterval.inMilliseconds,
        proactiveRandomEnabled: proactiveRandom,
      );
      // App is in foreground during load: proactive OFF
      await _assistantModeService.setProactiveMode(false);
    } else {
      debugPrint("Stopping AssistantModeService (enabled=false)");
      await _assistantModeService.stop();
    }

    if (mounted) {
      setState(() {
        _assistantModeEnabled = enabled;
        _proactiveEnabled = proactive;
        _proactiveRandomEnabled = proactiveRandom;
      });
    } else {
      _assistantModeEnabled = enabled;
      _proactiveEnabled = proactive;
      _proactiveRandomEnabled = proactiveRandom;
    }

    if (enabled) {
      await _initWakeWord();
      await _ensureWakeWordActive();
    }
    await _setBackgroundIdleNotification();
  }

  Future<void> _clearMemory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('conversation_memory');
    _userMessageCount = 0;
    _idleConsumedAtUserMessageCount = -1;
    _idleBlockedUntilUserMessage = false;

    // Animate removal for smooth UI
    final len = _messages.length;
    for (int i = len - 1; i >= 0; i--) {
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => const SizedBox.shrink(),
        duration: const Duration(milliseconds: 300),
      );
    }

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
      _idleBlockedUntilUserMessage = false;
      _resetIdleTimer();
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

    _idleBlockedUntilUserMessage = false;
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
      final contextMessages = _messages.reversed
          .take(_maxPayloadMessages)
          .toList()
          .reversed
          .toList();

      final payload = [
        {"role": "system", "content": _zeroTwoSystemPrompt},
        ...contextMessages.map((m) => m.toApiJson()),
      ];

      final reply = await _apiService.sendConversation(payload);

      if (reply.isNotEmpty) {
        final openAppResult = await OpenAppService.handleAssistantReply(reply);
        final assistantText = openAppResult?.assistantMessage ?? reply;
        _appendMessage(ChatMessage(role: "assistant", content: assistantText));
        final shouldSpeak =
            readOutReply && (_isInForeground || openAppResult != null);
        if (shouldSpeak) {
          await _speakAssistantText(assistantText);
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
      final errorMsg =
          "CONNECTION_SYNC_ERROR: I'm having trouble reaching the neural cloud, Darling. Please check your link.";
      _appendMessage(ChatMessage(role: "assistant", content: errorMsg));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      } else {
        _isBusy = false;
      }
      _scrollToBottom();
      _startIdleTimer(); // Restart idle timer after AI replies
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

  Future<void> _toggleDualVoice() async {
    final next = !_dualVoiceEnabled;
    if (mounted) {
      setState(() => _dualVoiceEnabled = next);
    } else {
      _dualVoiceEnabled = next;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dualVoiceEnabledPrefKey, next);
  }

  Future<void> _setDualVoiceSecondary(String voice) async {
    if (mounted) {
      setState(() => _dualVoiceSecondary = voice);
    } else {
      _dualVoiceSecondary = voice;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dualVoiceSecondaryPrefKey, voice);
  }

  Future<void> _speakAssistantText(String text) async {
    if (!_dualVoiceEnabled) {
      await _ttsService.speak(text);
      return;
    }
    final primaryVoice = _devTtsVoiceOverride.trim().isNotEmpty
        ? _devTtsVoiceOverride.trim()
        : "lulwa";
    final secondaryVoice = _dualVoiceSecondary.trim().isNotEmpty
        ? _dualVoiceSecondary.trim()
        : "alloy";
    final selectedVoice =
        (_dualVoiceTurn % 2 == 0) ? primaryVoice : secondaryVoice;
    _dualVoiceTurn++;

    _ttsService.configure(
      apiKeyOverride: _devTtsApiKeyOverride,
      modelOverride: _devTtsModelOverride,
      voiceOverride: selectedVoice,
    );
    await _ttsService.speak(text);
  }

  Future<void> _toggleIdleTimer() async {
    final next = !_idleTimerEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('idle_timer_enabled', next);
    await prefs.setInt('idle_duration_seconds', _idleDurationSeconds);
    setState(() => _idleTimerEnabled = next);

    if (next) {
      _startIdleTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Idle Timer: Enabled"),
              duration: Duration(seconds: 1)),
        );
      }
    } else {
      _idleTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Idle Timer: Disabled"),
              duration: Duration(seconds: 1)),
        );
      }
    }
  }

  Future<void> _updateIdleDuration(int seconds) async {
    if (mounted) {
      setState(() => _idleDurationSeconds = seconds);
    } else {
      _idleDurationSeconds = seconds;
    }
    _resetIdleTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('idle_duration_seconds', seconds);
  }

  Future<void> _updateProactiveInterval(int seconds) async {
    if (mounted) {
      setState(() => _proactiveIntervalSeconds = seconds);
    } else {
      _proactiveIntervalSeconds = seconds;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('proactive_interval_seconds', seconds);
    _startProactiveTimer();

    // Update native service if running
    if (_assistantModeEnabled) {
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
        intervalMs: seconds * 1000,
        proactiveRandomEnabled: _proactiveRandomEnabled,
      );
    }
  }

  Future<void> _setProactiveTimingMode(bool randomEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('proactive_random_enabled', randomEnabled);

    if (mounted) {
      setState(() => _proactiveRandomEnabled = randomEnabled);
    } else {
      _proactiveRandomEnabled = randomEnabled;
    }

    _startProactiveTimer();

    if (_assistantModeEnabled) {
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
        intervalMs: _proactiveIntervalSeconds * 1000,
        proactiveRandomEnabled: randomEnabled,
      );
      await _assistantModeService
          .setProactiveMode(_proactiveEnabled && !_isInForeground);
    }
  }

  String _formatCheckInDuration(int seconds) {
    if (seconds % 3600 == 0) {
      final hours = seconds ~/ 3600;
      return hours == 1 ? "1 hour" : "$hours hours";
    }
    if (seconds % 60 == 0) {
      final minutes = seconds ~/ 60;
      return minutes == 1 ? "1 min" : "$minutes mins";
    }
    return "$seconds sec";
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
          intervalMs: _proactiveIntervalSeconds * 1000,
          proactiveRandomEnabled: _proactiveRandomEnabled,
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
          content: Text(
              next ? "Wife Mode: Enabled Ã¢ÂÂ¤Ã¯Â¸Â" : "Wife Mode: Disabled"),
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
        return Scaffold(
          extendBodyBehindAppBar: true,
          drawerEnableOpenDragGesture: true,
          drawer: _buildNavDrawer(themeMode),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white70),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            title: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _onTitleTap,
              onLongPress: _openDevConfigSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Text(
                  "ZERO TWO",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.redAccent, blurRadius: 10)],
                  ),
                ),
              ),
            ),
            titleSpacing: 0,
            centerTitle: true,
            actions: const [],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                  child: AnimatedBackground(controller: _scrollController)),
              _navIndex == 0
                  ? VisualEffectsOverlay(
                      themeMode: themeMode,
                      child: _buildNavBody(),
                    )
                  : _buildNavBody(),
              if (_showOpeningOverlay) _buildOpeningOverlay(),
            ],
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

  Widget _buildAvatarArea() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Column(
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
              child: ReactivePulse(
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
                      color: _isSpeaking
                          ? const Color(0xFFFF1744)
                          : Colors.white10,
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
                    child: Image(
                      image: _imageProviderFor(
                        assetPath: _chatImageAsset,
                        customPath: _effectiveChatCustomPath,
                      ),
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
                            color: Theme.of(context).primaryColor,
                            blurRadius: 12)
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3)),
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
      ),
    );
  }

  Widget _buildChatList() {
    final style = AppThemes.getStyle(themeNotifier.value);
    return Expanded(
      child: ShaderMask(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                initialItemCount: _messages.length,
                itemBuilder: (context, index, animation) {
                  if (index >= _messages.length) return const SizedBox.shrink();
                  final msg = _messages[index];
                  final isUser = msg.role == 'user';
                  // Per-theme entry animation â€” all wrapped with a pop-from-below
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
                                  parent: animation,
                                  curve: Curves.easeOutBack)),
                          child: child,
                        ),
                      );
                    case AnimStyle.fadeZoom:
                      themed = FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                              CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      );
                    case AnimStyle.press:
                      themed = FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutExpo)),
                          child: child,
                        ),
                      );
                  }

                  // ðŸŒŸ Universal spring pop-from-below â€” applied to EVERY message
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
    final maxW = MediaQuery.of(context).size.width *
        0.72; // reduced slightly further for absolute safety

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
    final isError = msg.content.contains("CONNECTION_SYNC_ERROR");
    final textColor = isError
        ? Colors.redAccent
        : (isUser
            ? Colors.white.withOpacity(isGhost ? 0.7 : 1.0)
            : Colors.white.withOpacity(isGhost ? 0.6 : 0.92));

    Widget textWidget = Text(
      isError
          ? msg.content.replaceFirst("CONNECTION_SYNC_ERROR: ", "")
          : msg.content,
      style: style.font(15.5, textColor),
    );

    // â”€â”€ Chip for thinking state
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isError)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 14),
                const SizedBox(width: 6),
                Text("NEURAL_LINK_BROKEN",
                    style: style.font(9, Colors.redAccent).copyWith(
                        letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        textWidget,
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
              textAlign: TextAlign.right,
              style: style.font(8, textColor.withOpacity(0.5)).copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
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

    // Ã¢â€â‚¬Ã¢â€â‚¬ Route to bubble builder by BubbleStyle
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

        bubble = Container(
          constraints: BoxConstraints(maxWidth: maxW),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: bgColor,
            border: Border.all(
              color: style.borderColor(primary),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (style.leftAccentBar && !isUser)
                    Container(
                      width: 4,
                      color: primary,
                    ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
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

    final bubbleWithSpacing = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: bubble,
    );

    if (!isUser) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipOval(
              child: Image(
                image: _imageProviderFor(
                  assetPath: _chatImageAsset,
                  customPath: _effectiveChatCustomPath,
                ),
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 28,
                  height: 28,
                  color: Colors.white10,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.face,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: bubbleWithSpacing),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: bubbleWithSpacing,
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
      // Ã¢â€â‚¬Ã¢â€â‚¬ SQUARE NEON: sharp rectangle, glowing primary border
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

      // Ã¢â€â‚¬Ã¢â€â‚¬ TERMINAL: pure dark, monospace, prompt indicator
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
              Text("Ã¢ÂÂ¯ ", style: style.font(15, primary)),
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

      // Ã¢â€â‚¬Ã¢â€â‚¬ UNDERLINE: minimal, just a bottom line
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

      // Ã¢â€â‚¬Ã¢â€â‚¬ LUXURY: rich gold card with shadow
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

// ── Notification history helpers ──────────────────────────────────────────
  Future<void> _loadNotifHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('notif_history') ?? [];
    if (!mounted) return;
    setState(() {
      _notifHistory = raw.map((s) {
        try {
          return Map<String, String>.from(
              jsonDecode(s) as Map<dynamic, dynamic>);
        } catch (_) {
          return {'msg': s, 'ts': ''};
        }
      }).toList();
    });
  }

  Future<void> _addNotifToHistory(String message) async {
    final entry = {
      'msg': message,
      'ts': DateTime.now().toIso8601String(),
    };
    if (mounted) setState(() => _notifHistory.insert(0, entry));
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('notif_history') ?? [];
    raw.insert(0, jsonEncode(entry));
    if (raw.length > 100) raw.removeLast();
    await prefs.setStringList('notif_history', raw);
  }

  Future<void> _clearNotifHistory() async {
    setState(() => _notifHistory.clear());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notif_history');
  }

  Future<void> _removeNotifAt(int index) async {
    setState(() => _notifHistory.removeAt(index));
    final prefs = await SharedPreferences.getInstance();
    final items = _notifHistory.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('notif_history', items);
  }

// ── Nav body switcher ─────────────────────────────────────────────────────
  Widget _buildNavBody() {
    switch (_navIndex) {
      case 0:
        return SlideTransition(
          position: _contentSlide,
          child: FadeTransition(
            opacity: _contentFade,
            child: Column(
              children: [
                _buildAvatarArea(),
                _buildChatList(),
                _buildInputArea(),
              ],
            ),
          ),
        );
      case 1:
        return _buildThemesPage();
      case 2:
        return _buildDevConfigPage();
      case 3:
        return _buildNotificationsPage();
      case 4:
        return _buildComingSoonPage();
      case 5:
        return _buildSettingsPage();
      case 6:
        return _buildDebugPage();
      case 7:
        return _buildAboutPage();
      default:
        return const SizedBox.shrink();
    }
  }
}
