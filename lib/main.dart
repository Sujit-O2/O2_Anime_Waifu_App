import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/config/app_themes.dart';
import 'package:o2_waifu/services/api_service.dart';
import 'package:o2_waifu/services/tts_service.dart';
import 'package:o2_waifu/services/speech_service.dart';
import 'package:o2_waifu/services/memory_service.dart';
import 'package:o2_waifu/services/personality_engine.dart';
import 'package:o2_waifu/services/affection_service.dart';
import 'package:o2_waifu/services/context_awareness_service.dart';
import 'package:o2_waifu/services/jealousy_service.dart';
import 'package:o2_waifu/services/emotional_memory_service.dart';
import 'package:o2_waifu/services/semantic_memory_service.dart';
import 'package:o2_waifu/services/mood_service.dart';
import 'package:o2_waifu/services/alter_ego_service.dart';
import 'package:o2_waifu/services/open_app_service.dart';
import 'package:o2_waifu/services/weather_service.dart';
import 'package:o2_waifu/services/music_player_service.dart';
import 'package:o2_waifu/services/proactive_ai_service.dart';
import 'package:o2_waifu/services/life_events_service.dart';
import 'package:o2_waifu/services/secret_notes_service.dart';
import 'package:o2_waifu/services/real_world_presence_engine.dart';
import 'package:o2_waifu/services/emotional_moment_engine.dart';
import 'package:o2_waifu/services/self_reflection_service.dart';
import 'package:o2_waifu/services/habit_life_service.dart';
import 'package:o2_waifu/services/simulated_life_loop.dart';
import 'package:o2_waifu/services/conversation_thread_memory.dart';
import 'package:o2_waifu/services/attention_focus_system.dart';
import 'package:o2_waifu/services/self_initiated_topics.dart';
import 'package:o2_waifu/services/personal_world_builder.dart';
import 'package:o2_waifu/services/master_state_object.dart';
import 'package:o2_waifu/services/presence_message_generator.dart';
import 'package:o2_waifu/services/relationship_progression_service.dart';
import 'package:o2_waifu/services/memory_timeline_service.dart';
import 'package:o2_waifu/services/multi_agent_brain.dart';
import 'package:o2_waifu/services/internal_thought_system.dart';
import 'package:o2_waifu/services/story_event_engine.dart';
import 'package:o2_waifu/services/emotional_recovery_service.dart';
import 'package:o2_waifu/services/signature_moments_engine.dart';
import 'package:o2_waifu/screens/chat_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env file may not exist in release builds
  }

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const O2WaifuApp());
}

class O2WaifuApp extends StatefulWidget {
  const O2WaifuApp({super.key});

  @override
  State<O2WaifuApp> createState() => _O2WaifuAppState();
}

class _O2WaifuAppState extends State<O2WaifuApp> {
  AppThemeMode _themeMode = AppThemeMode.cyberPink;
  bool _isInitialized = false;

  // Core services
  late final ApiService _apiService;
  late final TtsService _ttsService;
  late final SpeechService _speechService;
  late final MemoryService _memoryService;

  // Phase 0 services
  late final PersonalityEngine _personalityEngine;
  late final AffectionService _affectionService;
  late final ContextAwarenessService _contextAwareness;
  late final JealousyService _jealousyService;
  late final EmotionalMemoryService _emotionalMemoryService;
  late final SemanticMemoryService _semanticMemoryService;
  late final MoodService _moodService;
  late final AlterEgoService _alterEgoService;
  late final OpenAppService _openAppService;
  late final WeatherService _weatherService;
  late final MusicPlayerService _musicService;
  late final ProactiveAIService _proactiveAIService;
  late final LifeEventsService _lifeEventsService;
  late final SecretNotesService _secretNotesService;

  // Phase 1 services
  late final RealWorldPresenceEngine _presenceEngine;
  late final EmotionalMomentEngine _emotionalMoments;
  late final SelfReflectionService _selfReflection;
  late final HabitLifeService _habitLife;

  // Phase 2 services
  late final SimulatedLifeLoop _lifeLoop;
  late final ConversationThreadMemory _threadMemory;
  late final AttentionFocusSystem _attentionSystem;
  late final SelfInitiatedTopics _selfInitiatedTopics;
  late final PersonalWorldBuilder _worldBuilder;
  late final MasterStateService _masterState;

  // Phase 3 services
  late final PresenceMessageGenerator _presenceMessageGenerator;
  late final RelationshipProgressionService _relationshipService;
  late final MemoryTimelineService _memoryTimeline;
  late final MultiAgentBrain _multiAgentBrain;
  late final InternalThoughtSystem _internalThoughts;
  late final StoryEventEngine _storyEventEngine;
  late final EmotionalRecoveryService _emotionalRecovery;
  late final SignatureMomentsEngine _signatureMoments;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Core services (no async init needed)
    _apiService = ApiService();
    _ttsService = TtsService();
    _speechService = SpeechService();
    _openAppService = OpenAppService();
    _weatherService = WeatherService();

    // Services that need async init
    _memoryService = MemoryService();
    _personalityEngine = PersonalityEngine();
    _affectionService = AffectionService();
    _contextAwareness = ContextAwarenessService();
    _jealousyService = JealousyService();
    _emotionalMemoryService = EmotionalMemoryService();
    _semanticMemoryService = SemanticMemoryService();
    _moodService = MoodService();
    _alterEgoService = AlterEgoService();
    _musicService = MusicPlayerService();
    _proactiveAIService = ProactiveAIService();
    _lifeEventsService = LifeEventsService();
    _secretNotesService = SecretNotesService();

    // Phase 1
    _presenceEngine = RealWorldPresenceEngine();
    _emotionalMoments = EmotionalMomentEngine();
    _selfReflection = SelfReflectionService();
    _habitLife = HabitLifeService();

    // Phase 2
    _lifeLoop = SimulatedLifeLoop();
    _threadMemory = ConversationThreadMemory();
    _attentionSystem = AttentionFocusSystem();
    _selfInitiatedTopics = SelfInitiatedTopics();
    _worldBuilder = PersonalWorldBuilder();

    // Phase 3
    _presenceMessageGenerator = PresenceMessageGenerator();
    _relationshipService = RelationshipProgressionService();
    _memoryTimeline = MemoryTimelineService();
    _multiAgentBrain = MultiAgentBrain();
    _internalThoughts = InternalThoughtSystem();
    _emotionalRecovery = EmotionalRecoveryService();

    // Initialize all async services
    await Future.wait([
      _memoryService.init(),
      _personalityEngine.init(),
      _affectionService.init(),
      _jealousyService.init(),
      _emotionalMemoryService.init(),
      _semanticMemoryService.init(),
      _moodService.init(),
      _alterEgoService.init(),
      _musicService.init(),
      _lifeEventsService.init(),
      _secretNotesService.init(),
      _selfReflection.init(),
      _habitLife.init(),
      _threadMemory.init(),
      _worldBuilder.init(),
      _relationshipService.init(),
      _memoryTimeline.init(),
      _emotionalRecovery.init(),
    ]);

    // Context awareness initial update
    await _contextAwareness.update();

    // Build master state (depends on all other services)
    _masterState = MasterStateService(
      personalityEngine: _personalityEngine,
      affectionService: _affectionService,
      contextAwareness: _contextAwareness,
      presenceEngine: _presenceEngine,
      emotionalMoments: _emotionalMoments,
      selfReflection: _selfReflection,
      habitLife: _habitLife,
      lifeLoop: _lifeLoop,
      threadMemory: _threadMemory,
      attentionSystem: _attentionSystem,
      worldBuilder: _worldBuilder,
      moodService: _moodService,
      jealousyService: _jealousyService,
    );

    // Services that depend on other services
    _storyEventEngine = StoryEventEngine(_presenceMessageGenerator);
    _signatureMoments = SignatureMomentsEngine(_presenceMessageGenerator);

    await _storyEventEngine.init();
    await _signatureMoments.init();

    // Start background services
    _lifeLoop.start();
    _presenceEngine.start();
    _proactiveAIService.start();
    _habitLife.recordAppOpen();

    // Load saved theme
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('app_theme') ?? 0;
    _themeMode = AppThemeMode
        .values[themeIndex.clamp(0, AppThemeMode.values.length - 1)];

    setState(() => _isInitialized = true);
  }

  void _onThemeChanged(AppThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme', mode.index);
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _speechService.dispose();
    _musicService.dispose();
    _proactiveAIService.dispose();
    _lifeLoop.dispose();
    _presenceEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.buildTheme(_themeMode),
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A1A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  color: AppThemes.getConfig(_themeMode).primaryColor,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading Zero Two...',
                  style: TextStyle(
                    color: AppThemes.getConfig(_themeMode).primaryColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: const Color(0xFF1A1A2E),
                    valueColor: AlwaysStoppedAnimation(
                      AppThemes.getConfig(_themeMode).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'O2-WAIFU',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.buildTheme(_themeMode),
      home: ChatHomePage(
        apiService: _apiService,
        ttsService: _ttsService,
        speechService: _speechService,
        memoryService: _memoryService,
        personalityEngine: _personalityEngine,
        affectionService: _affectionService,
        contextAwareness: _contextAwareness,
        jealousyService: _jealousyService,
        emotionalMemoryService: _emotionalMemoryService,
        semanticMemoryService: _semanticMemoryService,
        moodService: _moodService,
        alterEgoService: _alterEgoService,
        openAppService: _openAppService,
        weatherService: _weatherService,
        masterState: _masterState,
        multiAgentBrain: _multiAgentBrain,
        internalThoughts: _internalThoughts,
        relationshipService: _relationshipService,
        memoryTimeline: _memoryTimeline,
        emotionalRecovery: _emotionalRecovery,
        threadMemory: _threadMemory,
        emotionalMoments: _emotionalMoments,
        selfReflection: _selfReflection,
        attentionSystem: _attentionSystem,
        storyEventEngine: _storyEventEngine,
        signatureMoments: _signatureMoments,
        musicService: _musicService,
        secretNotesService: _secretNotesService,
        themeMode: _themeMode,
        onThemeChanged: _onThemeChanged,
      ),
    );
  }
}
