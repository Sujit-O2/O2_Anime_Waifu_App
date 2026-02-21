import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:anime_waifu/api_call.dart';
import 'package:anime_waifu/config/app_theme.dart';
import 'package:anime_waifu/config/system_persona.dart';
import 'package:anime_waifu/load_wakeword_code.dart';
import 'package:anime_waifu/models/chat_message.dart';
import 'package:anime_waifu/services/assistant_mode_service.dart';
import 'package:anime_waifu/stt.dart';
import 'package:anime_waifu/tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const VoiceAiApp());
}

class VoiceAiApp extends StatelessWidget {
  const VoiceAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zero Two',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const ChatHomePage(),
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
  Timer? _restartListenTimer;
  Timer? _wakeEffectTimer;
  Timer? _titleTapResetTimer;
  Timer? _wakeInitRetryTimer;
  int _titleTapCount = 0;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  DateTime? _lastWakeDetectedAt;
  static const Duration _wakeDetectCooldown = Duration(seconds: 4);
  bool _showOpeningOverlay = true;
  bool _wakeWordReady = false;
  bool _wakeInitInProgress = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _openingController = AnimationController(
      duration: const Duration(milliseconds: 3800),
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
  }

  void _scheduleStartupTasks() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _playAppOpenSound();
      // Request microphone permission first — CRITICAL for release mode.
      // On debug builds Android usually auto-grants it, but a signed
      // release APK requires an explicit runtime permission dialog.
      await Permission.microphone.request();
      // Keep startup deterministic: config first, then wake engine.
      await _initServices();
      await _loadDevConfig();
      await _loadAssistantMode();
      await _initWakeWord();
      await _ensureWakeWordActive();
      unawaited(_loadMemory());
      if (mounted) {
        unawaited(precacheImage(const AssetImage('zero_two.png'), context));
      }
    });
  }

  void _playAppOpenSound() {
    SystemSound.play(SystemSoundType.click);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _restartListenTimer?.cancel();
    _wakeEffectTimer?.cancel();
    _titleTapResetTimer?.cancel();
    _wakeInitRetryTimer?.cancel();
    unawaited(_speechService.cancel());
    unawaited(_ttsService.stop());
    unawaited(_wakeWordService.dispose());
    _animationController.dispose();
    _openingController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      if (!_wakeWordReady) {
        unawaited(_initWakeWord());
      }
      unawaited(_ensureWakeWordActive());
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

    await _setBackgroundIdleNotification();
    try {
      if (!_wakeWordReady) {
        await _initWakeWord();
      }
      await _wakeWordService.start();
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

  Future<void> _initWakeWord() async {
    if (_isDisposed || _wakeWordReady || _wakeInitInProgress) return;
    _wakeInitInProgress = true;
    try {
      await _wakeWordService.init(_onWakeWordDetected);
      _wakeWordReady = true;
      _wakeInitRetryTimer?.cancel();
    } catch (e) {
      _wakeWordReady = false;
      debugPrint("Wake word init error: $e");
      _wakeInitRetryTimer?.cancel();
      _wakeInitRetryTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && !_wakeWordReady) {
          unawaited(_initWakeWord());
        }
      });
    } finally {
      _wakeInitInProgress = false;
    }
  }

  Future<void> _onWakeWordDetected(int keywordIndex) async {
    try {
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
      await _showBackgroundListeningNotification(
        status: "Listening...",
        transcript: "",
        pulse: true,
      );

      _suspendWakeWord = true;
      await _wakeWordService.stop();
      await Future.delayed(const Duration(milliseconds: 250));
      if (!_speechService.listening && !_isBusy) {
        await _startSttFromWake();
      }
      if (mounted) setState(() {});
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
    _wakeEffectTimer?.cancel();
    if (mounted) {
      setState(() => _wakeEffectVisible = true);
    } else {
      _wakeEffectVisible = true;
    }
    HapticFeedback.mediumImpact();
    _wakeEffectTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _wakeEffectVisible = false);
      } else {
        _wakeEffectVisible = false;
      }
    });
  }

  Future<void> _ensureWakeWordActive() async {
    if (!mounted || _isDisposed) return;
    // Allow wake word in foreground always.
    // In background, require assistant mode.
    if (!_isInForeground && !_assistantModeEnabled) {
      await _wakeWordService.stop();
      return;
    }
    if (!_wakeWordReady) {
      await _initWakeWord();
      return;
    }
    if (_isAutoListening ||
        _isBusy ||
        _isSpeaking ||
        _suspendWakeWord ||
        _speechService.listening) {
      return;
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
    if (mounted) {
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
    setState(() {
      if (key.isNotEmpty && key.startsWith('gsk_')) {
        _apiKeyStatus = "Systems Online";
      } else {
        _apiKeyStatus = "API Key Error";
      }
    });
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
    });
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
    final enabled = prefs.getBool('assistant_mode_enabled') ?? false;
    final isRunning = await _assistantModeService.isRunning();
    if (enabled && !isRunning) {
      await _assistantModeService.start();
    } else if (!enabled && isRunning) {
      await _assistantModeService.stop();
    }
    if (mounted) {
      setState(() => _assistantModeEnabled = enabled);
    } else {
      _assistantModeEnabled = enabled;
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
        _messages.add(ChatMessage(role: "user", content: text));
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

    unawaited(_stopContinuousListening());
    unawaited(_ttsService.stop());

    setState(() {
      _messages.add(ChatMessage(role: "user", content: text));
      _textController.clear();
      _currentVoiceText = "";
    });

    _scrollToBottom();
    unawaited(_sendToApiAndReply(readOutReply: false));
  }

  Future<void> _sendToApiAndReply({required bool readOutReply}) async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    await _speechService.stopListening();

    try {
      // Build Payload safely
      final injectedSystemQuery = _devSystemQuery.trim();
      final payloadMessages = <Map<String, dynamic>>[
        {"role": "system", "content": systemPersona},
        if (injectedSystemQuery.isNotEmpty)
          {"role": "system", "content": injectedSystemQuery},
        ..._messages.map((m) => {"role": m.role, "content": m.content}),
      ];

      final reply = await _apiService.sendConversation(payloadMessages);

      if (!mounted) return;

      setState(() {
        _messages.add(ChatMessage(role: "assistant", content: reply));
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
      if (!mounted) return;

      const errorText =
          "I'm having trouble connecting to the network, Darling.";
      setState(() {
        _messages.add(ChatMessage(role: "assistant", content: errorText));
      });

      if (readOutReply) await _ttsService.speak(errorText);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      } else {
        _isBusy = false;
      }
      await _ensureWakeWordActive();
    }
  }

  Future<void> _startContinuousListening() async {
    if (_speechService.listening) return;
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
    _restartListenTimer?.cancel();
    await _speechService.stopListening();
    _suspendWakeWord = false;
    await _ensureWakeWordActive();
    if (mounted) setState(() {});
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
        await _assistantModeService.start();
        await _initWakeWord();
        await _setBackgroundIdleNotification();
        await _showBackgroundListeningNotification(
          status: "Assistant mode enabled",
          transcript: "Wake word is active in background",
          pulse: true,
        );
        await _ensureWakeWordActive();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
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
      setState(() {});
      return;
    }

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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _onTitleTap,
          onLongPress: _openDevConfigSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Text(
              "    ZERO TWO",
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
        actions: [
          IconButton(
            icon: Icon(
              _assistantModeEnabled ? Icons.hearing : Icons.hearing_disabled,
              color: _assistantModeEnabled ? Colors.redAccent : Colors.grey,
            ),
            tooltip: _assistantModeEnabled
                ? "Assistant mode ON (background)"
                : "Assistant mode OFF",
            onPressed: _toggleAssistantMode,
          ),
          IconButton(
            icon: Icon(
              _isAutoListening ? Icons.mic : Icons.mic_off,
              color: _isAutoListening ? Colors.redAccent : Colors.grey,
            ),
            onPressed: _toggleAutoListen,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearMemory,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2B1015),
                  Color(0xFF121212),
                  Color(0xFF0F1520),
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: _contentFade,
            child: SlideTransition(
              position: _contentSlide,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildAvatarArea(),
                    Expanded(child: _buildChatList()),
                    _buildInputArea(),
                  ],
                ),
              ),
            ),
          ),
          if (_showOpeningOverlay) _buildOpeningOverlay(),
        ],
      ),
    );
  }

  Widget _buildOpeningOverlay() {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _openingFade,
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.05,
              colors: [
                Color(0xFF40141D),
                Color(0xCC1A1018),
                Color(0xFF0E0D12),
              ],
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _openingScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "ZERO TWO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(color: Colors.redAccent, blurRadius: 22)
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "002",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Assistant Booting...",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.8,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Dev by Sujit Swain",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.2,
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
    return Column(
      children: [
        const Text(
          "002",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        AvatarGlow(
          glowColor: _isSpeaking ? Colors.redAccent : Colors.pinkAccent,
          animate: _isSpeaking || _speechService.listening,
          glowRadiusFactor: 0.4,
          duration: const Duration(milliseconds: 2000),
          repeat: true,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isSpeaking ? Colors.redAccent : Colors.white24,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (_isSpeaking ? Colors.red : Colors.pink).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              backgroundImage: AssetImage('zero_two.png'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isSpeaking
                ? "Speaking..."
                : _speechService.listening
                    ? "Listening..."
                    : _wakeWordService.isRunning
                        ? "Wake Ready"
                        : _apiKeyStatus,
            key: ValueKey(
                "${_isSpeaking}_${_speechService.listening}_${_wakeWordService.isRunning}_$_apiKeyStatus"),
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w300,
              shadows: _isSpeaking
                  ? [const Shadow(color: Colors.redAccent, blurRadius: 8)]
                  : [],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _wakeEffectVisible ? 1 : 0,
          child: Transform.scale(
            scale: _wakeEffectVisible ? 1.0 : 0.96,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withOpacity(0.65)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on, color: Colors.redAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "Wake Word Detected",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Dev by Sujit Swain",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildChatList() {
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
          stops: [0.0, 0.05, 0.95, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _messages.length + (_currentVoiceText.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) {
            return _buildBubble(
              context,
              ChatMessage(role: "user", content: _currentVoiceText),
              isGhost: true,
            );
          }

          return _buildBubble(context, _messages[index], isGhost: false);
        },
      ),
    );
  }

  Widget _buildBubble(BuildContext context, ChatMessage msg,
      {required bool isGhost}) {
    final isUser = msg.role == 'user';
    final isSystem = msg.role == 'system';

    if (isSystem) return const SizedBox.shrink();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.redAccent.withOpacity(isGhost ? 0.3 : 0.8)
              : const Color(0xFF2C2C2C).withOpacity(0.9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          border: Border.all(
            color: isUser ? Colors.redAccent : Colors.white10,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              if (isGhost)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.mic, size: 12, color: Colors.white70),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _speechService.listening
                        ? "Listening..."
                        : "Type message...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  onSubmitted: (_) => _handleTextInput(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _toggleManualMic,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _speechService.listening
                          ? [Colors.redAccent, Colors.deepOrange]
                          : [Colors.blueGrey.shade800, Colors.black],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _speechService.listening
                            ? Colors.redAccent.withOpacity(0.5)
                            : Colors.black26,
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Icon(
                    _isSpeaking
                        ? Icons.stop
                        : (_speechService.listening
                            ? Icons.mic
                            : Icons.mic_none),
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.redAccent),
                onPressed: _handleTextInput,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
