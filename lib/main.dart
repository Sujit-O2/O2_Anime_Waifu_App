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
import 'package:anime_waifu/stt_selector.dart';
import 'package:anime_waifu/tts.dart';
import 'package:anime_waifu/widgets/animated_background.dart';
import 'package:anime_waifu/widgets/reactive_pulse.dart';
import 'package:anime_waifu/widgets/visual_effects_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

part 'screens/main_drawer.dart';
part 'screens/main_themes.dart';
part 'screens/main_dev_config.dart';
part 'screens/main_notifications.dart';
part 'screens/main_settings.dart';
part 'screens/main_debug.dart';
part 'screens/about_page.dart';
part 'screens/features_page.dart';

final ValueNotifier<AppThemeMode> themeNotifier =
    ValueNotifier(_defaultThemeMode);

const AppThemeMode _defaultThemeMode = AppThemeMode.neonSerpent;
const Set<AppThemeMode> _activeThemeModes = {
  AppThemeMode.neonSerpent,
  AppThemeMode.chromaStorm,
  AppThemeMode.goldenRuler,
  AppThemeMode.frozenDivine,
  AppThemeMode.infernoGod,
  AppThemeMode.shadowBlade,
  AppThemeMode.pinkChaos,
  AppThemeMode.abyssWatcher,
  AppThemeMode.solarFlare,
  AppThemeMode.demonSlayer,
  AppThemeMode.midnightSilk,
  AppThemeMode.obsidianRose,
  AppThemeMode.onyxEmerald,
  AppThemeMode.velvetCrown,
  AppThemeMode.platinumDawn,
  AppThemeMode.hypergate,
  AppThemeMode.xenoCore,
  AppThemeMode.dataStream,
  AppThemeMode.gravityBend,
  AppThemeMode.quartzPulse,
  AppThemeMode.midnightForest,
  AppThemeMode.volcanicSea,
  AppThemeMode.stormDesert,
  AppThemeMode.sakuraNight,
  AppThemeMode.arcticSoul,
};

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    // Load persisted theme
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('app_theme_index') ?? 0;
    final savedTheme = AppThemeMode.values[index % AppThemeMode.values.length];
    final migratedTheme =
        savedTheme == AppThemeMode.infernoGod ? _defaultThemeMode : savedTheme;
    themeNotifier.value = _activeThemeModes.contains(migratedTheme)
        ? migratedTheme
        : _defaultThemeMode;
    if (savedTheme == AppThemeMode.infernoGod) {
      await prefs.setInt(
          'app_theme_index', AppThemeMode.values.indexOf(_defaultThemeMode));
    }

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
  final SelectableSpeechService _speechService = SelectableSpeechService();
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
9. Response length preference: $_responseLengthInstruction
""";
  }

  String get _effectiveTtsApiKey {
    if (_devTtsApiKeyOverride.trim().isNotEmpty) {
      return _devTtsApiKeyOverride.trim();
    }
    return dotenv.env['GROQ_API_KEY_VOICE'] ?? (dotenv.env['API_KEY'] ?? "");
  }

  String get _effectiveTtsModel {
    if (_devTtsModelOverride.trim().isNotEmpty) {
      return _devTtsModelOverride.trim();
    }
    return "canopylabs/orpheus-arabic-saudi";
  }

  String get _effectiveTtsVoice {
    if (_devTtsVoiceOverride.trim().isNotEmpty) {
      return _devTtsVoiceOverride.trim();
    }
    return "aisha";
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
  Timer? _backgroundTransitionTimer;
  int _navIndex =
      0; // 0=Chat 1=Notification 2=Videos 3=Setting 4=Themes 5=DevConfig 6=Debug 7=About
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
  bool _pendingReplyDispatch = false;
  bool _pendingReplyNeedsVoice = false;
  bool _proactiveEnabled = true;
  bool _proactiveRandomEnabled = true;
  final bool _backgroundWakeEnabled = true;
  bool _liteModeEnabled = false;
  bool _notificationsAllowed = false;
  bool _dualVoiceEnabled = false;
  bool _useAltImagePack = false;
  bool _chatImageFromSystem = false;
  bool _appIconFromCustom = false;
  String? _customChatImagePath;
  String? _customAppIconPath;
  String _dualVoiceSecondary = "alloy";
  int _dualVoiceTurn = 0;

  // ── New Settings ────────────────────────────────────────────────────────────
  bool _showMessageTimestamps = false;
  bool _hapticFeedbackEnabled = true;
  bool _wakePopupEnabled = true;
  String _responseLengthMode = 'Normal'; // 'Short', 'Normal', 'Detailed'
  String _chatTextSize = 'Medium'; // 'Small', 'Medium', 'Large'
  bool _autoScrollChat = true;
  String _sttEngineMode = 'current';

  double get _chatFontSize {
    switch (_chatTextSize) {
      case 'Small':
        return 12.0;
      case 'Large':
        return 16.0;
      default:
        return 14.0;
    }
  }

  String get _responseLengthInstruction {
    switch (_responseLengthMode) {
      case 'Short':
        return ' Keep response under 10 words.';
      case 'Detailed':
        return ' Provide a detailed response, up to 100 words.';
      default:
        return '';
    }
  }

  static const String _showTimestampsPrefKey = 'show_msg_timestamps_v1';
  static const String _hapticFeedbackPrefKey = 'haptic_feedback_v1';
  static const String _wakePopupPrefKey = 'wake_popup_enabled';
  static const String _responseLengthPrefKey = 'response_length_mode_v1';
  static const String _chatTextSizePrefKey = 'chat_text_size_v1';
  static const String _autoScrollChatPrefKey = 'auto_scroll_chat_v1';
  static const String _sttEngineModePrefKey = 'stt_engine_mode_v1';
  // ── Extra new settings ───────────────────────────────────────────────────
  bool _soundOnWake = true;
  bool _showChatHint = true;
  double _wallpaperBrightness = 0.5; // 0.0 = dark overlay, 1.0 = bright
  static const String _soundOnWakePrefKey = 'sound_on_wake_v1';
  static const String _showChatHintPrefKey = 'show_chat_hint_v1';
  static const String _wallpaperBrightnessPrefKey = 'wallpaper_brightness_v1';

  List<Map<String, String>> _notifHistory = [];
  Timer? _inAppNotifHideTimer;
  bool _showInAppNotif = false;
  String _inAppNotifText = "";
  static const String _imagePackPrefKey = 'ui_image_pack_alt_v1';
  static const String _customChatImagePathPrefKey = 'custom_chat_image_path_v1';
  static const String _chatImageFromSystemPrefKey = 'chat_image_from_system_v1';
  static const String _customAppIconPathPrefKey = 'custom_app_icon_path_v1';
  static const String _appIconFromCustomPrefKey = 'app_icon_from_custom_v1';
  static const String _dualVoiceEnabledPrefKey = 'dual_voice_enabled_v1';
  static const String _dualVoiceSecondaryPrefKey = 'dual_voice_secondary_v1';
  static const String _liteModeEnabledPrefKey = 'lite_mode_enabled_v1';
  String get _chatImageAsset =>
      _useAltImagePack ? 'assets/img/logi.png' : 'assets/img/z2s.jpg';
  String get _appIconImageAsset => 'assets/img/logi.png';
  String get _imagePackLabel => _useAltImagePack ? 'Pack B' : 'Pack A';
  String? get _effectiveChatCustomPath =>
      _chatImageFromSystem ? _customChatImagePath : null;
  String? get _effectiveAppIconCustomPath =>
      _appIconFromCustom ? _customAppIconPath : null;

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
  bool _drainPendingInProgress = false;
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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _openingFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _openingController,
        curve: const Interval(0.68, 1.0, curve: Curves.easeOut),
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
        curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _openingController,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
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
    unawaited(_loadCustomImagePaths());
    unawaited(_loadNewSettings());
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

  // ── New Settings Load / Save ───────────────────────────────────────────────
  Future<void> _loadNewSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getBool(_showTimestampsPrefKey) ?? false;
    final hf = prefs.getBool(_hapticFeedbackPrefKey) ?? true;
    final popupEnabled = prefs.getBool(_wakePopupPrefKey) ?? true;
    final soundOnWake = prefs.getBool(_soundOnWakePrefKey) ?? true;
    final showChatHint = prefs.getBool(_showChatHintPrefKey) ?? true;
    final wallpaperBrightnessRaw =
        prefs.getDouble(_wallpaperBrightnessPrefKey) ?? 0.5;
    final wallpaperBrightness =
        wallpaperBrightnessRaw.clamp(0.0, 1.0).toDouble();
    final rl = prefs.getString(_responseLengthPrefKey) ?? 'Normal';
    final cs = prefs.getString(_chatTextSizePrefKey) ?? 'Medium';
    final as_ = prefs.getBool(_autoScrollChatPrefKey) ?? true;
    if (!mounted) {
      _showMessageTimestamps = ts;
      _hapticFeedbackEnabled = hf;
      _wakePopupEnabled = popupEnabled;
      _soundOnWake = soundOnWake;
      _showChatHint = showChatHint;
      _wallpaperBrightness = wallpaperBrightness;
      _responseLengthMode = rl;
      _chatTextSize = cs;
      _autoScrollChat = as_;
      return;
    }
    setState(() {
      _showMessageTimestamps = ts;
      _hapticFeedbackEnabled = hf;
      _wakePopupEnabled = popupEnabled;
      _soundOnWake = soundOnWake;
      _showChatHint = showChatHint;
      _wallpaperBrightness = wallpaperBrightness;
      _responseLengthMode = rl;
      _chatTextSize = cs;
      _autoScrollChat = as_;
    });
  }

  Future<void> _toggleShowTimestamps() async {
    final next = !_showMessageTimestamps;
    if (mounted) setState(() => _showMessageTimestamps = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTimestampsPrefKey, next);
  }

  Future<void> _toggleHapticFeedback() async {
    final next = !_hapticFeedbackEnabled;
    if (mounted) setState(() => _hapticFeedbackEnabled = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackPrefKey, next);
  }

  Future<void> _toggleWakePopupEnabled() async {
    final next = !_wakePopupEnabled;
    if (mounted) setState(() => _wakePopupEnabled = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wakePopupPrefKey, next);
    if (Platform.isAndroid && next) {
      final canOverlay = await _assistantModeService.canDrawOverlays();
      if (!canOverlay) {
        await _assistantModeService.requestOverlayPermission();
      }
    }
  }

  Future<void> _toggleSoundOnWake() async {
    final next = !_soundOnWake;
    if (mounted) {
      setState(() => _soundOnWake = next);
    } else {
      _soundOnWake = next;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundOnWakePrefKey, next);
  }

  Future<void> _toggleShowChatHint() async {
    final next = !_showChatHint;
    if (mounted) {
      setState(() => _showChatHint = next);
    } else {
      _showChatHint = next;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showChatHintPrefKey, next);
  }

  Future<void> _setWallpaperBrightness(
    double value, {
    bool persist = true,
  }) async {
    final next = value.clamp(0.0, 1.0).toDouble();
    if (mounted) {
      setState(() => _wallpaperBrightness = next);
    } else {
      _wallpaperBrightness = next;
    }
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_wallpaperBrightnessPrefKey, next);
  }

  Future<void> _setResponseLength(String mode) async {
    if (mounted) setState(() => _responseLengthMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_responseLengthPrefKey, mode);
  }

  Future<void> _setChatTextSize(String size) async {
    if (mounted) setState(() => _chatTextSize = size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatTextSizePrefKey, size);
  }

  Future<void> _toggleAutoScrollChat() async {
    final next = !_autoScrollChat;
    if (mounted) setState(() => _autoScrollChat = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoScrollChatPrefKey, next);
  }

  Future<void> _loadCustomImagePaths() async {
    final prefs = await SharedPreferences.getInstance();
    final chatPath = prefs.getString(_customChatImagePathPrefKey);
    final fromSystem = prefs.getBool(_chatImageFromSystemPrefKey) ?? false;
    final appIconPath = prefs.getString(_customAppIconPathPrefKey);
    final appIconFromCustom = prefs.getBool(_appIconFromCustomPrefKey) ?? false;
    if (!mounted) {
      _customChatImagePath = chatPath;
      _chatImageFromSystem = fromSystem;
      _customAppIconPath = appIconPath;
      _appIconFromCustom = appIconFromCustom;
      return;
    }
    setState(() {
      _customChatImagePath = chatPath;
      _chatImageFromSystem = fromSystem;
      _customAppIconPath = appIconPath;
      _appIconFromCustom = appIconFromCustom;
    });
  }

  Future<void> _pickImageFromGallery({required bool forChatImage}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) return;

      final path = picked.path.trim();
      if (path.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();

      if (forChatImage) {
        if (mounted) {
          setState(() {
            _customChatImagePath = path;
            _chatImageFromSystem = true;
          });
        } else {
          _customChatImagePath = path;
          _chatImageFromSystem = true;
        }
        await prefs.setString(_customChatImagePathPrefKey, path);
        await prefs.setBool(_chatImageFromSystemPrefKey, true);
      } else {
        if (mounted) {
          setState(() {
            _customAppIconPath = path;
            _appIconFromCustom = true;
          });
        } else {
          _customAppIconPath = path;
          _appIconFromCustom = true;
        }
        await prefs.setString(_customAppIconPathPrefKey, path);
        await prefs.setBool(_appIconFromCustomPrefKey, true);
      }

      _evictImageCaches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(forChatImage
                ? 'Chat image updated from gallery.'
                : 'Logo image updated from gallery.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Gallery image pick failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not pick image from gallery.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _evictImageCaches() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  Future<void> _resetCustomImages() async {
    if (mounted) {
      setState(() {
        _customChatImagePath = null;
        _chatImageFromSystem = false;
        _customAppIconPath = null;
        _appIconFromCustom = false;
      });
    } else {
      _customChatImagePath = null;
      _chatImageFromSystem = false;
      _customAppIconPath = null;
      _appIconFromCustom = false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customChatImagePathPrefKey);
    await prefs.remove(_customAppIconPathPrefKey);
    await prefs.setBool(_chatImageFromSystemPrefKey, false);
    await prefs.setBool(_appIconFromCustomPrefKey, false);
    _evictImageCaches();
  }

  ImageProvider _imageProviderFor({
    required String assetPath,
    required String? customPath,
  }) {
    if (customPath != null && customPath.trim().isNotEmpty) {
      if (customPath.startsWith('assets/')) {
        return AssetImage(customPath);
      }
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
    if (!mounted || _isDisposed || !_idleTimerEnabled) {
      return;
    }

    // Keep polling if we timed out during a transient state
    // (not on chat, app not foreground, or currently busy).
    if (_isBusy || !_isInForeground || _navIndex != 0) {
      _startIdleTimer();
      return;
    }

    if (_idleConsumedAtUserMessageCount == _userMessageCount) return;
    _idleConsumedAtUserMessageCount = _userMessageCount;
    _idleBlockedUntilUserMessage = true;
    _idleTimer?.cancel();
    debugPrint("In-app Idle timeout (Chat). Generating response...");

    try {
      final prompt = [
        {
          "role": "system",
          "content":
              "$_zeroTwoSystemPrompt\nI've been quiet for a while. Send me a short, reactionary check-up message (max 15 words) because you're bored or miss me. Use 'Honey' or 'Darling'."
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
      if (_proactiveEnabled &&
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
          "content":
              "$_zeroTwoSystemPrompt\nGenerate a very short, playful, and loving check-up message (max 10 words) because I haven't talked to you in a while. Use 'Honey' or 'Darling'."
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
          'assets/img/z2s.jpg',
          'assets/img/bg2.png',
        ];
        for (final asset in startupImages) {
          unawaited(precacheImage(AssetImage(asset), context));
        }
      }
    });
  }

  void _playAppOpenSound() {
    // Disabled: avoid unwanted sound when app process starts/restarts.
  }

  Future<bool> _ensureMicPermission({required bool requestIfNeeded}) async {
    try {
      var status = await Permission.microphone.status;
      debugPrint("Microphone permission status: $status");

      if (status.isGranted) {
        debugPrint("Microphone permission already granted");
        return true;
      }

      if (status.isDenied) {
        if (!requestIfNeeded) {
          debugPrint("Microphone permission denied (not requesting)");
          return false;
        }
        debugPrint("Permission denied, requesting now...");
        status = await Permission.microphone.request();
        debugPrint("Request result: $status");
      } else if (status.isPermanentlyDenied) {
        debugPrint("Microphone permission permanently denied");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Microphone is permanently disabled. Enable in Settings > Apps > Permissions.",
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return false;
      }

      if (status.isGranted) {
        debugPrint("Microphone permission granted after request");
        return true;
      }

      debugPrint("Microphone permission not granted. Status: $status");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Microphone permission is required for wake word."),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint("Mic permission check error: $e");
      return false;
    }
  }

  Future<bool> _ensureBatteryOptimizationBypass({
    required bool requestIfNeeded,
  }) async {
    if (!Platform.isAndroid) return true;
    try {
      var ignoring =
          await _assistantModeService.isIgnoringBatteryOptimizations();
      if (!ignoring && requestIfNeeded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Allow 'Unrestricted battery' for reliable background wake word.",
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        await _assistantModeService.requestIgnoreBatteryOptimizations();
        await Future.delayed(const Duration(milliseconds: 700));
        ignoring = await _assistantModeService.isIgnoringBatteryOptimizations();
      }
      return ignoring;
    } catch (e) {
      debugPrint("Battery optimization check error: $e");
      return false;
    }
  }

  void _appendMessage(ChatMessage message) {
    if (_isDisposed || !mounted) return;

    if (message.role == "user" && message.content.trim().isNotEmpty) {
      _userMessageCount += 1;
      _idleBlockedUntilUserMessage = false;
    }

    // Ensure we are updating state for basic list additions
    setState(() {
      final int insertIndex = _messages.length;
      _messages.add(message);
      _listKey.currentState?.insertItem(insertIndex,
          duration: const Duration(milliseconds: 280));
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
    final liteModeEnabled = prefs.getBool(_liteModeEnabledPrefKey) ?? false;
    final sttEngineRaw = prefs.getString(_sttEngineModePrefKey) ?? 'current';
    final sttEngine = sttEngineRaw == 'android' ? 'android' : 'current';
    if (mounted) {
      setState(() {
        _wakeWordEnabledByUser = enabled;
        _idleTimerEnabled = idleEnabled;
        _idleDurationSeconds = idleDuration;
        _proactiveIntervalSeconds = proactiveInterval;
        _proactiveRandomEnabled = proactiveRandom;
        _dualVoiceEnabled = dualVoiceEnabled;
        _dualVoiceSecondary = dualVoiceSecondary;
        _liteModeEnabled = liteModeEnabled;
        _sttEngineMode = sttEngine;
      });
    } else {
      _wakeWordEnabledByUser = enabled;
      _idleTimerEnabled = idleEnabled;
      _idleDurationSeconds = idleDuration;
      _proactiveIntervalSeconds = proactiveInterval;
      _proactiveRandomEnabled = proactiveRandom;
      _dualVoiceEnabled = dualVoiceEnabled;
      _dualVoiceSecondary = dualVoiceSecondary;
      _liteModeEnabled = liteModeEnabled;
      _sttEngineMode = sttEngine;
    }
    await _speechService.setMode(_sttEngineToMode(_sttEngineMode));
    _syncLiteModeRuntime();
    if (_idleTimerEnabled) {
      _startIdleTimer();
    } else {
      _idleTimer?.cancel();
    }
    // Ensure proactive scheduler uses loaded saved values immediately.
    _startProactiveTimer();
  }

  void _syncLiteModeRuntime() {
    if (_liteModeEnabled) {
      if (_floatController.isAnimating) {
        _floatController.stop();
      }
      return;
    }

    if (!_floatController.isAnimating) {
      _floatController.repeat();
    }
  }

  SttEngineMode _sttEngineToMode(String mode) {
    return mode == 'android' ? SttEngineMode.android : SttEngineMode.current;
  }

  Future<void> _setSttEngineMode(String mode) async {
    final safeMode = mode == 'android' ? 'android' : 'current';
    if (_sttEngineMode == safeMode) return;

    if (_speechService.listening) {
      await _speechService.cancel();
    }
    await _speechService.setMode(_sttEngineToMode(safeMode));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sttEngineModePrefKey, safeMode);

    if (mounted) {
      setState(() => _sttEngineMode = safeMode);
    } else {
      _sttEngineMode = safeMode;
    }

    if (!_isAutoListening) {
      _suspendWakeWord = false;
      await _ensureWakeWordActive();
    } else {
      await _startContinuousListening();
    }

    if (mounted) {
      final label = safeMode == 'android' ? 'Android STT' : 'Current STT';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$label selected (TTS unchanged)")),
      );
    }
  }

  Future<void> _toggleLiteMode() async {
    final next = !_liteModeEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_liteModeEnabledPrefKey, next);

    if (mounted) {
      setState(() => _liteModeEnabled = next);
    } else {
      _liteModeEnabled = next;
    }
    _syncLiteModeRuntime();
  }

  Future<void> _persistWakeWordEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wake_word_enabled', enabled);
  }

  Future<void> _toggleWakeWordEnabled() async {
    final next = !_wakeWordEnabledByUser;

    if (next) {
      final hasMic = await _ensureMicPermission(requestIfNeeded: true);
      if (!hasMic) return;
    }

    await _persistWakeWordEnabled(next);

    if (mounted) {
      setState(() => _wakeWordEnabledByUser = next);
    } else {
      _wakeWordEnabledByUser = next;
    }

    if (!_wakeWordEnabledByUser) {
      _wakeWordReady = false;
      await _wakeWordService.stop();
      if (_assistantModeEnabled) {
        await _assistantModeService.setWakeMode(false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wake word disabled")),
        );
      }
      return;
    }

    await _initWakeWord();
    await _ensureWakeWordActive();
    if (_assistantModeEnabled) {
      final hasMic = await _ensureMicPermission(requestIfNeeded: false);
      await _assistantModeService.setWakeMode(
        _backgroundWakeEnabled &&
            !_isInForeground &&
            hasMic &&
            _wakeWordEnabledByUser,
      );
    }
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
    _backgroundTransitionTimer?.cancel();
    _idleTimer?.cancel();
    _proactiveMessageTimer?.cancel();
    _wakeEffectTimer?.cancel();
    _wakeWatchdogTimer?.cancel();
    _titleTapResetTimer?.cancel();
    _logoTapResetTimer?.cancel();
    _wakeInitRetryTimer?.cancel();
    _inAppNotifHideTimer?.cancel();
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
    _backgroundTransitionTimer?.cancel();

    if (state == AppLifecycleState.resumed) {
      _suspendWakeWord = false;
      if (_assistantModeEnabled) {
        // Hand-off: stop native wake first, then restore Flutter wake.
        unawaited(() async {
          await _assistantModeService.setProactiveMode(false);
          await _assistantModeService.setWakeMode(false);
          if (!_wakeWordReady) {
            await _initWakeWord();
          }
          await _ensureWakeWordActive();
          await _drainPendingProactiveMessages();
        }());
        return;
      }

      if (!_wakeWordReady) {
        unawaited(_initWakeWord());
      }
      unawaited(_ensureWakeWordActive());
      unawaited(_drainPendingProactiveMessages());
      return;
    }

    // Ignore transient inactive state (e.g. notification shade, quick overlays)
    // to avoid false background wake/mic transitions and audible system cues.
    if (state == AppLifecycleState.inactive) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _backgroundTransitionTimer = Timer(const Duration(milliseconds: 450), () {
        if (_isDisposed || _isInForeground) return;
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
      });
    }
  }

  Future<void> _drainPendingProactiveMessages() async {
    if (_drainPendingInProgress) return;
    _drainPendingInProgress = true;
    final prefs = await SharedPreferences.getInstance();
    try {
      final snapshotRaw = prefs.getString('pending_proactive_messages') ?? "[]";
      final snapshot = _decodePendingQueue(snapshotRaw);
      final list = snapshot;
      if (list.isNotEmpty) {
        bool addedAny = false;
        for (var l in list) {
          final parsed = _parsePendingEntry(l);
          if (parsed == null) continue;
          final role = parsed['role'] ?? 'assistant';
          final text = parsed['content'] ?? '';

          if (text.isNotEmpty) {
            final safeRole = role == "user" ? "user" : "assistant";
            _appendMessage(ChatMessage(role: safeRole, content: text));
            if (safeRole == "assistant") {
              _addNotifToHistory(text);
            }
            addedAny = true;
          }
        }
        if (addedAny) {
          _scrollToBottom();
          await _saveMemory();
        }
        final latestRaw = prefs.getString('pending_proactive_messages') ?? "[]";
        final latest = _decodePendingQueue(latestRaw);
        final remaining =
            _subtractDrainedEntries(latest: latest, drained: list);
        await prefs.setString(
            'pending_proactive_messages', jsonEncode(remaining));
      }
    } catch (e) {
      debugPrint("Error reading pending messages: $e");
    } finally {
      _drainPendingInProgress = false;
    }
  }

  List<dynamic> _decodePendingQueue(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (_) {}
    return const [];
  }

  Map<String, String>? _parsePendingEntry(dynamic raw) {
    String role = "assistant";
    String text = "";
    if (raw is Map) {
      role = (raw['role'] ?? "assistant").toString().trim().toLowerCase();
      text = (raw['content'] ?? "").toString().trim();
    } else {
      text = raw.toString().trim();
    }
    if (text.isEmpty) return null;
    final safeRole = role == "user" ? "user" : "assistant";
    return {
      'role': safeRole,
      'content': text,
    };
  }

  String _pendingEntryKey(Map<String, String> entry) {
    return '${entry['role'] ?? 'assistant'}\u0001${entry['content'] ?? ''}';
  }

  List<Map<String, String>> _subtractDrainedEntries({
    required List<dynamic> latest,
    required List<dynamic> drained,
  }) {
    final drainedCount = <String, int>{};
    for (final item in drained) {
      final parsed = _parsePendingEntry(item);
      if (parsed == null) continue;
      final key = _pendingEntryKey(parsed);
      drainedCount[key] = (drainedCount[key] ?? 0) + 1;
    }

    final remaining = <Map<String, String>>[];
    for (final item in latest) {
      final parsed = _parsePendingEntry(item);
      if (parsed == null) continue;
      final key = _pendingEntryKey(parsed);
      final take = drainedCount[key] ?? 0;
      if (take > 0) {
        drainedCount[key] = take - 1;
      } else {
        remaining.add(parsed);
      }
    }
    return remaining;
  }

  Future<void> _enterBackgroundAssistantMode() async {
    // Background priority: native assistant service owns wake/STT while app is not foreground.
    await _speechService.stopListening();
    await _ttsService.stop();

    _isAutoListening = false;
    _isSpeaking = false;
    _isManualMicSession = false;
    _suspendWakeWord = true;

    try {
      await _assistantModeService.start(
        apiKey: _devApiKeyOverride.isNotEmpty
            ? _devApiKeyOverride
            : (dotenv.env['API_KEY'] ?? ""),
        apiUrl: _devApiUrlOverride.isNotEmpty
            ? _devApiUrlOverride
            : "https://api.groq.com/openai/v1/chat/completions",
        model: _devModelOverride.trim().isNotEmpty
            ? _devModelOverride.trim()
            : "moonshotai/kimi-k2-instruct",
        systemPrompt: _zeroTwoSystemPrompt,
        ttsApiKey: _effectiveTtsApiKey,
        ttsModel: _effectiveTtsModel,
        ttsVoice: _effectiveTtsVoice,
        intervalMs: _proactiveIntervalSeconds * 1000,
        proactiveRandomEnabled: _proactiveRandomEnabled,
        requireMicrophone: Platform.isAndroid && _wakeWordEnabledByUser,
      );
      // App is outside foreground now: allow proactive notifications if enabled.
      await _assistantModeService.setProactiveMode(_proactiveEnabled);
      final hasMic = await _ensureMicPermission(requestIfNeeded: false);
      await _assistantModeService.setWakeMode(
        _backgroundWakeEnabled && hasMic && _wakeWordEnabledByUser,
      );
      await _wakeWordService.stop();
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
        await _persistWakeWordEnabled(false);
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
        await _persistWakeWordEnabled(false);
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

      if (Platform.isAndroid && _wakePopupEnabled) {
        await _assistantModeService.showOverlay(
          status: "Wake word detected",
          transcript: wakeName.isNotEmpty ? wakeName : "Speak your command",
        );
      }

      await _showBackgroundListeningNotification(
        status: "Wake word detected",
        transcript: wakeName,
        pulse: _soundOnWake,
      );

      _suspendWakeWord = true;
      await _wakeWordService.stop();
      await Future.delayed(const Duration(milliseconds: 80));
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
    if (_hapticFeedbackEnabled) {
      HapticFeedback.mediumImpact();
    }
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

    // In background assistant mode, native service handles wake/STT for closed-app reliability.
    if (_assistantModeEnabled && !_isInForeground) {
      if (_wakeWordService.isRunning) {
        await _wakeWordService.stop();
      }
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
      unawaited(_setBackgroundIdleNotification());
    }
    if (status == 'notListening') {
      _suspendWakeWord = false;
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
    final nextStatus = key.isNotEmpty ? "Systems Online" : "API Key Error";
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
        systemPrompt: _zeroTwoSystemPrompt,
        ttsApiKey: _effectiveTtsApiKey,
        ttsModel: _effectiveTtsModel,
        ttsVoice: _effectiveTtsVoice,
        intervalMs: _proactiveInterval.inMilliseconds,
        proactiveRandomEnabled: proactiveRandom,
        requireMicrophone: Platform.isAndroid && _wakeWordEnabledByUser,
      );
      // App is in foreground during load: proactive OFF
      await _assistantModeService.setProactiveMode(false);
      await _assistantModeService.setWakeMode(false);
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
    _startProactiveTimer();

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
      _suspendWakeWord = true;
      _appendMessage(ChatMessage(role: "user", content: text));
      unawaited(_setBackgroundIdleNotification());
      unawaited(_sendToApiAndReply(readOutReply: true));
    } else {
      _suspendWakeWord = false;
      unawaited(_setBackgroundIdleNotification());
      unawaited(_ensureWakeWordActive());
    }

    _scrollToBottom();
  }

  Future<void> _handleTextInput() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isBusy) return;

    _idleBlockedUntilUserMessage = false;
    _resetIdleTimer();
    _suspendWakeWord = true;

    // Typed send should cancel any live mic session without producing a
    // transcription callback that can queue a duplicate API request.
    if (_speechService.listening) {
      await _speechService.cancel();
    }
    await _ttsService.stop();

    _textController.clear();
    _currentVoiceText = "";
    _appendMessage(ChatMessage(role: "user", content: text));

    _scrollToBottom();
    await _sendToApiAndReply(readOutReply: false);
  }

  Future<void> _sendToApiAndReply({required bool readOutReply}) async {
    if (_isDisposed) return;
    if (_isBusy) {
      _pendingReplyDispatch = true;
      _pendingReplyNeedsVoice = _pendingReplyNeedsVoice || readOutReply;
      return;
    }

    var schedulePendingDispatch = false;
    var pendingDispatchReadOut = false;
    var shouldEnsureWakeAfter = false;

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
        final shouldSpeak = readOutReply;
        if (!_isInForeground) {
          await _showBackgroundListeningNotification(
            status: "Zero Two replied",
            transcript: assistantText,
            pulse: true,
          );
        }
        if (shouldSpeak) {
          await _speakAssistantText(assistantText);
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
      final raw = e.toString().toLowerCase();
      final errorMsg = raw.contains('401')
          ? "CONNECTION_SYNC_ERROR: API key rejected (401). Check API key in .env / Dev Config."
          : raw.contains('429')
              ? "CONNECTION_SYNC_ERROR: Rate limit hit (429). Wait a bit and try again."
              : raw.contains('timeout')
                  ? "CONNECTION_SYNC_ERROR: Request timed out. Check internet and API latency."
                  : "CONNECTION_SYNC_ERROR: I'm having trouble reaching the neural cloud, Darling. Please check your link.";
      _appendMessage(ChatMessage(role: "assistant", content: errorMsg));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      } else {
        _isBusy = false;
      }
      _suspendWakeWord = false;
      _scrollToBottom();
      _startIdleTimer(); // Restart idle timer after AI replies

      final shouldDispatchPending = _pendingReplyDispatch;
      final pendingReadOut = _pendingReplyNeedsVoice;
      _pendingReplyDispatch = false;
      _pendingReplyNeedsVoice = false;

      schedulePendingDispatch = shouldDispatchPending && !_isDisposed;
      pendingDispatchReadOut = pendingReadOut;
      shouldEnsureWakeAfter =
          !schedulePendingDispatch && (!readOutReply || !_isSpeaking);
    }

    if (schedulePendingDispatch) {
      unawaited(_sendToApiAndReply(readOutReply: pendingDispatchReadOut));
      return;
    }

    if (shouldEnsureWakeAfter) {
      unawaited(_ensureWakeWordActive());
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
      // Explicitly re-arm idle flow when user turns timer back on.
      _idleBlockedUntilUserMessage = false;
      _idleConsumedAtUserMessageCount = -1;
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
    // Changing interval should restart idle flow from now.
    _idleBlockedUntilUserMessage = false;
    _idleConsumedAtUserMessageCount = -1;
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
        systemPrompt: _zeroTwoSystemPrompt,
        ttsApiKey: _effectiveTtsApiKey,
        ttsModel: _effectiveTtsModel,
        ttsVoice: _effectiveTtsVoice,
        intervalMs: seconds * 1000,
        proactiveRandomEnabled: _proactiveRandomEnabled,
        requireMicrophone: Platform.isAndroid && _wakeWordEnabledByUser,
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
        systemPrompt: _zeroTwoSystemPrompt,
        ttsApiKey: _effectiveTtsApiKey,
        ttsModel: _effectiveTtsModel,
        ttsVoice: _effectiveTtsVoice,
        intervalMs: _proactiveIntervalSeconds * 1000,
        proactiveRandomEnabled: randomEnabled,
        requireMicrophone: Platform.isAndroid && _wakeWordEnabledByUser,
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

  Future<bool> _ensureBackgroundWakeAccess({
    required bool requireOverlayForPopup,
    required bool requestIfNeeded,
  }) async {
    final hasMic = await _ensureMicPermission(requestIfNeeded: requestIfNeeded);
    if (!hasMic) return false;

    var canNotifications = await _assistantModeService.canPostNotifications();
    if (!canNotifications && requestIfNeeded) {
      await _assistantModeService.requestNotificationPermission();
      await Future.delayed(const Duration(milliseconds: 700));
      canNotifications = await _assistantModeService.canPostNotifications();
    }
    if (!canNotifications) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Notification permission is required. Opening settings...",
            ),
          ),
        );
      }
      await _assistantModeService.openNotificationSettings();
      return false;
    }

    if (Platform.isAndroid && requireOverlayForPopup) {
      var canOverlay = await _assistantModeService.canDrawOverlays();
      if (!canOverlay && requestIfNeeded) {
        await _assistantModeService.requestOverlayPermission();
        await Future.delayed(const Duration(milliseconds: 700));
        canOverlay = await _assistantModeService.canDrawOverlays();
      }
      if (!canOverlay) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Allow 'Display over other apps' for popup mic to work.",
              ),
            ),
          );
        }
        return false;
      }
    }

    final batteryAllowed = await _ensureBatteryOptimizationBypass(
        requestIfNeeded: requestIfNeeded);
    if (!batteryAllowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Set Battery to Unrestricted for reliable background wake word.",
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _refreshAssistantModeRuntime({required bool hasMic}) async {
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
      systemPrompt: _zeroTwoSystemPrompt,
      ttsApiKey: _effectiveTtsApiKey,
      ttsModel: _effectiveTtsModel,
      ttsVoice: _effectiveTtsVoice,
      intervalMs: _proactiveIntervalSeconds * 1000,
      proactiveRandomEnabled: _proactiveRandomEnabled,
      requireMicrophone: Platform.isAndroid && hasMic,
    );
    await _assistantModeService
        .setProactiveMode(_proactiveEnabled && !_isInForeground);
    await _assistantModeService.setWakeMode(
      _backgroundWakeEnabled &&
          !_isInForeground &&
          hasMic &&
          _wakeWordEnabledByUser,
    );
  }

  Future<void> _grantFullAccessForBackgroundWake() async {
    final accessOk = await _ensureBackgroundWakeAccess(
      requireOverlayForPopup: Platform.isAndroid && _wakePopupEnabled,
      requestIfNeeded: true,
    );
    if (!accessOk) return;

    final hasMic = await _ensureMicPermission(requestIfNeeded: false);
    if (_assistantModeEnabled) {
      await _refreshAssistantModeRuntime(hasMic: hasMic);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Full access ready. Background wake + popup mic active."),
          ),
        );
      }
      return;
    }
    await _toggleAssistantMode();
  }

  Future<void> _toggleAssistantMode() async {
    final next = !_assistantModeEnabled;

    try {
      if (next) {
        final accessOk = await _ensureBackgroundWakeAccess(
          requireOverlayForPopup: Platform.isAndroid && _wakePopupEnabled,
          requestIfNeeded: true,
        );
        if (!accessOk) return;
        final hasMic = await _ensureMicPermission(requestIfNeeded: false);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('assistant_mode_enabled', true);

        // Pass API config to background service for persistence after swipe
        await _refreshAssistantModeRuntime(hasMic: hasMic);
        await _ensureWakeWordActive();
        await _setBackgroundIdleNotification();
        await _showBackgroundListeningNotification(
          status: "Assistant mode enabled",
          transcript: (_backgroundWakeEnabled &&
                  !_isInForeground &&
                  hasMic &&
                  _wakeWordEnabledByUser)
              ? "Background wake active (assistant service)"
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
        await _assistantModeService.setWakeMode(false);
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

    if (!mounted) return;
    setState(() => _proactiveEnabled = next);
    _startProactiveTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next ? "Wife Mode: Enabled" : "Wife Mode: Disabled"),
        duration: const Duration(seconds: 1),
      ),
    );
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
    if (_isInForeground) return;
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
    if (_isInForeground) return;
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
        final wallpaperDimOpacity =
            ((1.0 - _wallpaperBrightness).clamp(0.0, 1.0) * 0.65).toDouble();
        return PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) {
            if (didPop) return;
            SystemNavigator.pop();
          },
          child: Scaffold(
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
                      shadows: [
                        Shadow(color: Colors.redAccent, blurRadius: 10)
                      ],
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
                  child: (_navIndex == 0 && !_liteModeEnabled)
                      ? RepaintBoundary(
                          child:
                              AnimatedBackground(controller: _scrollController),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: AppThemes.getGradient(themeMode),
                            ),
                          ),
                        ),
                ),
                if (_navIndex == 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: wallpaperDimOpacity,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: const ColoredBox(color: Colors.black),
                      ),
                    ),
                  ),
                (_navIndex == 0 && !_liteModeEnabled)
                    ? VisualEffectsOverlay(
                        themeMode: themeMode,
                        child: _buildNavBody(),
                      )
                    : _buildNavBody(),
                if (_inAppNotifText.isNotEmpty) _buildInAppNotificationPopup(),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Image.asset(
                      'assets/gif/add_incircular_mode_app_oppening style.gif',
                      width: 170,
                      height: 170,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 12),
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
    final primary = Theme.of(context).primaryColor;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 12;
    final statusText = _isSpeaking
        ? "DECODING SPEECH..."
        : _speechService.listening
            ? "INPUT DETECTED..."
            : !_wakeWordEnabledByUser
                ? "WAKE OFFLINE"
                : _wakeWordService.isRunning
                    ? "SYSTEM READY"
                    : _apiKeyStatus.toUpperCase();
    final avatarCore = Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white70,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.26),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image(
          image: _imageProviderFor(
            assetPath: _chatImageAsset,
            customPath: _effectiveChatCustomPath,
          ),
          width: 82,
          height: 82,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            width: 82,
            height: 82,
            color: Colors.white10,
            child: const Icon(
              Icons.person,
              color: Colors.white24,
            ),
          ),
        ),
      ),
    );
    final avatarWithPulse = _liteModeEnabled
        ? avatarCore
        : ReactivePulse(
            isSpeaking: _isSpeaking,
            isListening: _speechService.listening,
            baseColor: primary,
            child: avatarCore,
          );
    final avatarWidget = _liteModeEnabled
        ? avatarWithPulse
        : AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final v = _floatController.value;
              final float = math.sin(v * 2 * math.pi) * 7.5;
              final tilt = math.sin(v * 2 * math.pi) * 0.025;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(0.0, float)
                  ..rotateZ(tilt),
                child: child,
              );
            },
            child: avatarWithPulse,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(14, topInset, 14, 6),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onLogoTap,
            child: avatarWidget,
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroStatusChip(
                label: _wakeWordService.isRunning ? 'WAKE ON' : 'WAKE OFF',
                active: _wakeWordService.isRunning,
                accent: Colors.greenAccent,
              ),
              _buildHeroStatusChip(
                label: _speechService.listening ? 'MIC LIVE' : 'MIC IDLE',
                active: _speechService.listening,
                accent: primary,
              ),
              _buildHeroStatusChip(
                label: _assistantModeEnabled ? 'BG ACTIVE' : 'BG OFF',
                active: _assistantModeEnabled,
                accent: Colors.cyanAccent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 280),
            opacity: _wakeEffectVisible ? 1 : 0,
            child: Transform.scale(
              scale: _wakeEffectVisible ? 1.0 : 0.95,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "WAKE WORD ACTIVE",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatusChip({
    required String label,
    required bool active,
    required Color accent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color:
            active ? accent.withOpacity(0.22) : Colors.white.withOpacity(0.06),
        border: Border.all(
          color: active ? accent.withOpacity(0.8) : Colors.white12,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: active ? Colors.white : Colors.white70,
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
        child: Column(
          children: [
            Expanded(
              child: AnimatedList(
                key: _listKey,
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                initialItemCount: _messages.length,
                itemBuilder: (context, index, animation) {
                  if (index >= _messages.length) {
                    return const SizedBox.shrink();
                  }
                  final msg = _messages[index];
                  final isUser = msg.role == 'user';
                  final child = _buildBubble(context, msg, isGhost: false);
                  final offsetTween = Tween<Offset>(
                    begin: isUser
                        ? const Offset(0.07, 0.07)
                        : const Offset(-0.07, 0.07),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return RepaintBoundary(
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position: offsetTween,
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_currentVoiceText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 6, right: 6, bottom: 10),
                child: _buildBubble(
                  context,
                  ChatMessage(
                    role: 'user',
                    content: _currentVoiceText,
                  ),
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
    final isInferno = mode == AppThemeMode.infernoGod;
    final messageLength = msg.content.trim().runes.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final normalizedLength = (messageLength.clamp(0, 220)).toDouble() / 220.0;
    final widthFactor =
        0.54 + Curves.easeOut.transform(normalizedLength) * 0.30;
    final sideReserve = isUser ? 76.0 : 124.0;
    final maxW = math.max(
      170.0,
      math.min(screenWidth * widthFactor, screenWidth - sideReserve),
    );

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

    final isError = msg.content.contains("CONNECTION_SYNC_ERROR");
    final scaffold = Theme.of(context).scaffoldBackgroundColor;

    Color bubbleReadabilityColor() {
      Color tone;
      switch (style.bubbleStyle) {
        case BubbleStyle.terminal:
          tone = Color.alphaBlend(Colors.black.withOpacity(0.30), scaffold);
          break;
        case BubbleStyle.outlined:
          final fill = isUser
              ? primary.withOpacity(isGhost ? 0.12 : 0.18)
              : Colors.black.withOpacity(isGhost ? 0.16 : 0.26);
          tone = Color.alphaBlend(fill, scaffold);
          break;
        case BubbleStyle.luxury:
          final fill = isUser
              ? primary.withOpacity(isGhost ? 0.54 : 0.72)
              : const Color(0xFF151004).withOpacity(isGhost ? 0.85 : 0.96);
          tone = Color.alphaBlend(fill, scaffold);
          break;
        case BubbleStyle.solid:
          final fill = isUser
              ? primary.withOpacity(isGhost ? 0.5 : 0.9)
              : (isInferno
                  ? const Color(0xFF140906).withOpacity(isGhost ? 0.80 : 0.97)
                  : Colors.white.withOpacity(0.09));
          tone = Color.alphaBlend(fill, scaffold);
          break;
        case BubbleStyle.glassmorphic:
          final fill = isUser
              ? primary.withOpacity(isGhost ? 0.34 : 0.70)
              : Colors.black.withOpacity(isGhost ? 0.18 : 0.34);
          tone = Color.alphaBlend(fill, scaffold);
          break;
      }
      return tone;
    }

    final bubbleTone = bubbleReadabilityColor();
    final onBubble =
        ThemeData.estimateBrightnessForColor(bubbleTone) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final textColor = isError
        ? Colors.redAccent
        : onBubble.withOpacity(isGhost ? 0.86 : 0.96);

    final textWidget = Text(
      isError
          ? msg.content.replaceFirst("CONNECTION_SYNC_ERROR: ", "")
          : msg.content,
      style: style.font(_chatFontSize, textColor).copyWith(
            height: 1.34,
            shadows: isInferno
                ? [
                    Shadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 5,
                    ),
                  ]
                : null,
          ),
      softWrap: true,
    );

    final content = Column(
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
                Text(
                  "NEURAL_LINK_BROKEN",
                  style: style.font(9, Colors.redAccent).copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        textWidget,
        if (_showMessageTimestamps) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
              textAlign: TextAlign.right,
              style: style.font(8, textColor.withOpacity(0.68)).copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
        ],
        if (isGhost)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 14,
                  color: primary.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  "THINKING...",
                  style: style.font(9, primary.withOpacity(0.7)).copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
      ],
    );

    Widget bubble;
    switch (style.bubbleStyle) {
      case BubbleStyle.terminal:
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
        final outlinedFill = isUser
            ? primary.withOpacity(isGhost ? 0.12 : 0.18)
            : Colors.black.withOpacity(isGhost ? 0.16 : 0.26);
        bubble = Container(
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: outlinedFill,
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
        final bgColor = isUser
            ? primary.withOpacity(isGhost ? 0.5 : 0.9)
            : (isInferno
                ? const Color(0xFF140906).withOpacity(isGhost ? 0.80 : 0.97)
                : Colors.white.withOpacity(0.09));
        final borderColor = style.borderColor(primary);
        final hasAccentBar = style.leftAccentBar && !isUser;

        bubble = Container(
          constraints: BoxConstraints(maxWidth: maxW),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: bgColor,
            border: Border(
              top: BorderSide(color: borderColor, width: 1.0),
              right: BorderSide(color: borderColor, width: 1.0),
              bottom: BorderSide(color: borderColor, width: 1.0),
              left: BorderSide(
                color: hasAccentBar ? primary : borderColor,
                width: hasAccentBar ? 3.0 : 1.0,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: content,
          ),
        );
        break;

      case BubbleStyle.glassmorphic:
        final aiGlassTop = Colors.black.withOpacity(isGhost ? 0.20 : 0.38);
        final aiGlassBottom = Colors.black.withOpacity(isGhost ? 0.12 : 0.28);
        bubble = Container(
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUser
                  ? [
                      primary.withOpacity(isGhost ? 0.35 : 0.76),
                      primary.withOpacity(isGhost ? 0.23 : 0.60),
                    ]
                  : [
                      aiGlassTop,
                      aiGlassBottom,
                    ],
            ),
            border: Border.all(
              color: isUser ? Colors.white30 : style.borderColor(primary),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isUser ? primary : Colors.white)
                    .withOpacity(isGhost ? 0.08 : 0.14),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: content,
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
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth - 12),
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
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: bubbleWithSpacing,
    );
  }

  Widget _buildInputArea() {
    final style = AppThemes.getStyle(themeNotifier.value);
    final primary = Theme.of(context).primaryColor;
    final isListening = _speechService.listening;
    final hint =
        _showChatHint ? (isListening ? "Listening..." : "Type a message") : "";

    final inputTextStyle = style.font(15, Colors.white.withOpacity(0.96));
    final hintTextStyle = style.font(14, Colors.white54);

    Widget actionCircle({
      required VoidCallback onTap,
      required IconData icon,
      required List<Color> colors,
      required double size,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: colors),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
    }

    final inputPanel = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            const Color(0x22130A15),
            const Color(0x66140A18),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              style: inputTextStyle,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: hintTextStyle,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                isDense: true,
              ),
              onSubmitted: (_) => unawaited(_handleTextInput()),
            ),
          ),
          const SizedBox(width: 8),
          actionCircle(
            onTap: _toggleManualMic,
            icon: _isSpeaking
                ? Icons.stop_rounded
                : (isListening ? Icons.mic_rounded : Icons.mic_none_rounded),
            colors: isListening
                ? [primary.withOpacity(0.95), primary.withOpacity(0.62)]
                : [
                    Colors.white.withOpacity(0.22),
                    Colors.white.withOpacity(0.10),
                  ],
            size: 44,
          ),
          const SizedBox(width: 8),
          actionCircle(
            onTap: () => unawaited(_handleTextInput()),
            icon: Icons.arrow_upward_rounded,
            colors: [
              primary.withOpacity(0.92),
              primary.withOpacity(0.72),
            ],
            size: 44,
          ),
        ],
      ),
    );

    final inputWithBlur = _liteModeEnabled
        ? inputPanel
        : BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: inputPanel,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: inputWithBlur,
        ),
      ),
    );
  }

// ── Notification history helpers ──────────────────────────────────────────
  void _showInAppNotificationPopup(String message) {
    final text = message.trim();
    if (text.isEmpty || !_isInForeground || _isDisposed) return;

    _inAppNotifHideTimer?.cancel();
    if (mounted) {
      setState(() {
        _inAppNotifText = text;
        _showInAppNotif = true;
      });
    } else {
      _inAppNotifText = text;
      _showInAppNotif = true;
    }

    _inAppNotifHideTimer = Timer(const Duration(milliseconds: 2400), () {
      if (_isDisposed || !mounted) return;
      setState(() => _showInAppNotif = false);
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (_isDisposed || !mounted || _showInAppNotif) return;
        setState(() => _inAppNotifText = "");
      });
    });
  }

  Widget _buildInAppNotificationPopup() {
    final primary = Theme.of(context).primaryColor;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight + 6;
    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: IgnorePointer(
        ignoring: !_showInAppNotif,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          offset: _showInAppNotif ? Offset.zero : const Offset(0, -0.35),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showInAppNotif ? 1 : 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (!mounted) return;
                  _inAppNotifHideTimer?.cancel();
                  setState(() {
                    _showInAppNotif = false;
                    _inAppNotifText = "";
                    _navIndex = 1;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF22110E).withOpacity(0.94),
                        const Color(0xFF110A12).withOpacity(0.88),
                      ],
                    ),
                    border: Border.all(color: primary.withOpacity(0.65)),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withOpacity(0.18),
                          border: Border.all(color: primary.withOpacity(0.55)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Zero Two',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _inAppNotifText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.90),
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
    if (_navIndex != 1) {
      _showInAppNotificationPopup(message);
    }
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
        return _buildNotificationsPage();
      case 2:
        return _buildComingSoonPage();
      case 3:
        return _buildSettingsPage();
      case 4:
        return _buildThemesPage();
      case 5:
        return _buildDevConfigPage();
      case 6:
        return _buildDebugPage();
      case 7:
        return _buildAboutPage();
      default:
        return const SizedBox.shrink();
    }
  }
}
