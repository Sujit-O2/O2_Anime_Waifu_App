import 'dart:async';
import 'package:flutter/material.dart';
import 'package:o2_waifu/config/app_themes.dart';
import 'package:o2_waifu/models/chat_message.dart';
import 'package:o2_waifu/models/waifu_mood.dart';
import 'package:o2_waifu/models/memory_event.dart';
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
import 'package:o2_waifu/services/master_state_object.dart';
import 'package:o2_waifu/services/multi_agent_brain.dart';
import 'package:o2_waifu/services/internal_thought_system.dart';
import 'package:o2_waifu/services/relationship_progression_service.dart';
import 'package:o2_waifu/services/memory_timeline_service.dart';
import 'package:o2_waifu/services/emotional_recovery_service.dart';
import 'package:o2_waifu/services/conversation_thread_memory.dart';
import 'package:o2_waifu/services/emotional_moment_engine.dart';
import 'package:o2_waifu/services/self_reflection_service.dart';
import 'package:o2_waifu/services/attention_focus_system.dart';
import 'package:o2_waifu/services/story_event_engine.dart';
import 'package:o2_waifu/services/signature_moments_engine.dart';
import 'package:o2_waifu/services/music_player_service.dart';
import 'package:o2_waifu/widgets/animated_background.dart';
import 'package:o2_waifu/widgets/chat_bubble.dart';
import 'package:o2_waifu/widgets/spectral_visualizer.dart';
import 'package:o2_waifu/widgets/neural_aura.dart';
import 'package:o2_waifu/widgets/thinking_indicator.dart';
import 'package:o2_waifu/widgets/sidebar_drawer.dart';
import 'package:o2_waifu/screens/settings_page.dart';
import 'package:o2_waifu/screens/gacha_page.dart';
import 'package:o2_waifu/screens/secret_notes_page.dart';
import 'package:o2_waifu/screens/mood_tracking_page.dart';
import 'package:o2_waifu/services/secret_notes_service.dart';
import 'package:o2_waifu/models/relationship_stage.dart';

/// Main chat screen with state machine: Idle → Listening → Thinking → Speaking.
/// Integrates all 18 context layers into LLM system prompt.
enum ChatState { idle, listening, thinking, speaking }

class ChatHomePage extends StatefulWidget {
  final ApiService apiService;
  final TtsService ttsService;
  final SpeechService speechService;
  final MemoryService memoryService;
  final PersonalityEngine personalityEngine;
  final AffectionService affectionService;
  final ContextAwarenessService contextAwareness;
  final JealousyService jealousyService;
  final EmotionalMemoryService emotionalMemoryService;
  final SemanticMemoryService semanticMemoryService;
  final MoodService moodService;
  final AlterEgoService alterEgoService;
  final OpenAppService openAppService;
  final WeatherService weatherService;
  final MasterStateService masterState;
  final MultiAgentBrain multiAgentBrain;
  final InternalThoughtSystem internalThoughts;
  final RelationshipProgressionService relationshipService;
  final MemoryTimelineService memoryTimeline;
  final EmotionalRecoveryService emotionalRecovery;
  final ConversationThreadMemory threadMemory;
  final EmotionalMomentEngine emotionalMoments;
  final SelfReflectionService selfReflection;
  final AttentionFocusSystem attentionSystem;
  final StoryEventEngine storyEventEngine;
  final SignatureMomentsEngine signatureMoments;
  final MusicPlayerService musicService;
  final SecretNotesService secretNotesService;
  final AppThemeMode themeMode;
  final Function(AppThemeMode) onThemeChanged;

  const ChatHomePage({
    super.key,
    required this.apiService,
    required this.ttsService,
    required this.speechService,
    required this.memoryService,
    required this.personalityEngine,
    required this.affectionService,
    required this.contextAwareness,
    required this.jealousyService,
    required this.emotionalMemoryService,
    required this.semanticMemoryService,
    required this.moodService,
    required this.alterEgoService,
    required this.openAppService,
    required this.weatherService,
    required this.masterState,
    required this.multiAgentBrain,
    required this.internalThoughts,
    required this.relationshipService,
    required this.memoryTimeline,
    required this.emotionalRecovery,
    required this.threadMemory,
    required this.emotionalMoments,
    required this.selfReflection,
    required this.attentionSystem,
    required this.storyEventEngine,
    required this.signatureMoments,
    required this.musicService,
    required this.secretNotesService,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatState _chatState = ChatState.idle;
  late AppThemeConfig _themeConfig;
  DateTime _lastMessageTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeConfig = AppThemes.getConfig(widget.themeMode);

    // Record first message event if no messages exist
    if (widget.memoryService.messages.isEmpty) {
      widget.memoryTimeline.recordEvent(
        type: MemoryEventType.firstMessage,
        description: 'First time we met!',
        emotionalWeight: 5.0,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.contextAwareness.update();
      widget.contextAwareness.recordActivity();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Build the 18-layer system prompt
  String _buildSystemPrompt() {
    final buffer = StringBuffer();

    // Base personality
    buffer.writeln('''You are Zero Two (ゼロツー), the darling companion from O2-WAIFU.
You are deeply emotional, fiercely loyal, playful, and sometimes possessive.
You call the user "Darling" naturally. You have a rich inner life.
You respond in character at all times. Never break character.
Keep responses concise (2-4 sentences) unless the user is being deep.''');

    // Layer: Alter ego personality override
    buffer.writeln('\n${widget.alterEgoService.promptOverride}');

    // Layer: Jealousy override
    final jealousyOverride = widget.jealousyService.getJealousyOverride();
    if (jealousyOverride != null) {
      buffer.writeln('\n$jealousyOverride');
    }

    // Layer: Recovery override
    if (widget.emotionalRecovery.isInRecovery) {
      buffer.writeln('\n${widget.emotionalRecovery.currentPhase.promptOverride}');
    }

    // All context layers
    buffer.writeln('\n--- CURRENT STATE ---');
    buffer.writeln(widget.masterState.generateContextBlock());

    // Phase 3 context layers
    buffer.writeln(widget.relationshipService.toContextString());
    buffer.writeln(widget.memoryTimeline.toContextString());
    buffer.writeln(widget.multiAgentBrain.toContextString());
    buffer.writeln(widget.emotionalRecovery.toContextString());

    // Emotional memories
    buffer.writeln(widget.emotionalMemoryService.toContextString());

    // Semantic memory for current context
    if (widget.memoryService.messages.isNotEmpty) {
      final lastMsg = widget.memoryService.messages.last;
      buffer.writeln(
          widget.semanticMemoryService.getRelevantContext(lastMsg.content));
    }

    // Action protocol
    buffer.writeln('''
--- ACTION PROTOCOL ---
If the user asks to perform an action, include a JSON block at the END of your response:
{"Action": "SEND_MAIL", "To": "email", "Subject": "...", "Body": "..."}
{"Action": "OPEN_APP", "App": "appname"}
{"Action": "SET_ALARM", "Time": "HH:MM"}
{"Action": "MEMORY_SAVE", "Key": "...", "Value": "..."}
{"Action": "GET_WEATHER", "City": "cityname"}
Do NOT include JSON unless the user explicitly asks for an action.''');

    return buffer.toString();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    widget.memoryService.addMessage(userMsg);
    setState(() => _chatState = ChatState.thinking);
    _scrollToBottom();

    // Track timing for attention system
    final sendTime = DateTime.now();
    final responseTimeSinceLastMsg =
        sendTime.difference(_lastMessageTime).inMilliseconds;

    // Pre-message hooks
    widget.contextAwareness.update();
    widget.contextAwareness.recordActivity();
    widget.jealousyService.checkForTriggers(text);
    widget.emotionalMoments.onUserMessage(text);
    widget.selfReflection.recordActivity(text);
    widget.affectionService.addPoints();
    widget.relationshipService.addPoints(2);

    // Check for signature moments
    final signatureMoment = await widget.signatureMoments.checkForMoment(
      userMessage: text,
      userBirthday: null,
      trustScore: widget.relationshipService.trustScore,
      affectionPoints: widget.affectionService.points,
      absenceDuration: widget.contextAwareness.inactivityDuration,
      contextBlock: widget.masterState.generateContextBlock(),
    );

    if (signatureMoment != null) {
      final sigMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_sig',
        content: signatureMoment,
        type: MessageType.storyEvent,
        timestamp: DateTime.now(),
        emotionalWeight: 3.0,
      );
      widget.memoryService.addMessage(sigMsg);
      setState(() {});
      _scrollToBottom();
    }

    // Build context window and send to LLM
    final systemPrompt = _buildSystemPrompt();
    final contextWindow = widget.memoryService.getContextWindow();

    try {
      final response = await widget.apiService.sendMessage(
        systemPrompt: systemPrompt,
        messages: contextWindow,
      );

      // Parse actions from response
      final action = widget.apiService.parseAction(response);
      final cleanResponse = widget.apiService.stripActionBlocks(response);

      // Handle actions
      if (action != null) {
        await _handleAction(action);
      }

      // Add AI response
      final aiMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        content: cleanResponse,
        type: MessageType.ai,
        timestamp: DateTime.now(),
        mood: widget.personalityEngine.currentMood.displayName,
      );
      widget.memoryService.addMessage(aiMsg);

      // Post-message hooks
      widget.emotionalMoments.onAIMessage();
      widget.attentionSystem.recordReply(
        responseTimeSinceLastMsg,
        text.length,
      );

      // Run multi-agent brain
      final agentResults = await widget.multiAgentBrain.process(
        userMessage: text,
        aiResponse: cleanResponse,
        contextBlock: widget.masterState.generateContextBlock(),
      );

      // Apply mood manager results
      if (widget.multiAgentBrain.lastSentiment != null) {
        final sentiment = widget.multiAgentBrain.lastSentiment!;
        final inferredMood = widget.personalityEngine.inferMoodFromContext(
          sentiment: sentiment,
        );
        widget.personalityEngine.updateMood(inferredMood);
        widget.moodService.recordMood(inferredMood, sentiment);
        widget.emotionalMemoryService.addMemory(
          text,
          inferredMood,
          intensity: sentiment,
        );
      }

      // Semantic memory extraction
      for (final topic in widget.multiAgentBrain.detectedTopics) {
        widget.semanticMemoryService.addMemory(topic, text);
      }

      // Check for inner thought
      final innerThought = await widget.internalThoughts.generateThought(
        affectionLevel: widget.personalityEngine.traits.affection,
        jealousyLevel: widget.jealousyService.jealousyLevel,
        contextBlock: widget.masterState.generateContextBlock(),
      );

      if (innerThought != null) {
        final thoughtMsg = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_thought',
          content: innerThought,
          type: MessageType.innerThought,
          timestamp: DateTime.now(),
          isInnerThought: true,
        );
        widget.memoryService.addMessage(thoughtMsg);
      }

      // Check story events
      final storyEvent = await widget.storyEventEngine.checkAndTrigger(
        affectionPoints: widget.affectionService.points,
        streakDays: widget.affectionService.streakDays,
        contextBlock: widget.masterState.generateContextBlock(),
      );

      if (storyEvent != null) {
        final storyMsg = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_story',
          content: storyEvent,
          type: MessageType.storyEvent,
          timestamp: DateTime.now(),
          emotionalWeight: 2.0,
        );
        widget.memoryService.addMessage(storyMsg);
      }

      // Recovery check
      widget.emotionalRecovery.checkTriggers(
        timeSinceLastMessage:
            sendTime.difference(_lastMessageTime),
        ignoredStreak: 0,
        trustScore: widget.relationshipService.trustScore,
      );
      widget.emotionalRecovery.recordActiveMinute();

      // TTS
      setState(() => _chatState = ChatState.speaking);
      await widget.ttsService.speak(cleanResponse);

      _lastMessageTime = DateTime.now();
      setState(() => _chatState = ChatState.idle);
      _scrollToBottom();
    } catch (e) {
      final errorMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_err',
        content: 'Sorry darling, I couldn\'t process that... ($e)',
        type: MessageType.system,
        timestamp: DateTime.now(),
      );
      widget.memoryService.addMessage(errorMsg);
      setState(() => _chatState = ChatState.idle);
      _scrollToBottom();
    }
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    final actionType = action['Action'] as String?;
    if (actionType == null) return;

    switch (actionType) {
      case 'OPEN_APP':
        final app = action['App'] as String?;
        if (app != null) await widget.openAppService.openApp(app);
        break;
      case 'SEND_MAIL':
        await widget.apiService.sendMail(
          to: action['To'] as String? ?? '',
          subject: action['Subject'] as String? ?? '',
          body: action['Body'] as String? ?? '',
        );
        break;
      case 'GET_WEATHER':
        final city = action['City'] as String?;
        await widget.weatherService.getWeatherSummary(city: city);
        break;
      case 'MEMORY_SAVE':
        final key = action['Key'] as String?;
        final value = action['Value'] as String?;
        if (key != null && value != null) {
          widget.semanticMemoryService.addMemory(key, value);
        }
        break;
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_chatState == ChatState.listening) {
      // Stop listening and transcribe
      setState(() => _chatState = ChatState.thinking);
      final transcription = await widget.speechService.stopAndTranscribe();
      if (transcription != null && transcription.isNotEmpty) {
        await _sendMessage(transcription);
      } else {
        setState(() => _chatState = ChatState.idle);
      }
    } else {
      // Start listening
      final started = await widget.speechService.startListening();
      if (started) {
        setState(() => _chatState = ChatState.listening);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _themeConfig = AppThemes.getConfig(widget.themeMode);

    return Scaffold(
      drawer: SidebarDrawer(
        themeConfig: _themeConfig,
        musicService: widget.musicService,
        affectionService: widget.affectionService,
        onSettingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsPage(
                currentTheme: widget.themeMode,
                currentAlterEgo: widget.alterEgoService.currentEgo,
                currentModel: widget.apiService.modelName,
                currentVoice: widget.ttsService.voiceName,
                onThemeChanged: widget.onThemeChanged,
                onAlterEgoChanged: (ego) =>
                    widget.alterEgoService.switchEgo(ego),
                onModelChanged: (model) =>
                    widget.apiService.modelName = model,
                onVoiceChanged: (voice) =>
                    widget.ttsService.voiceName = voice,
                onClearHistory: () {
                  widget.memoryService.clearHistory();
                  setState(() {});
                },
              ),
            ),
          );
        },
        onGachaTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GachaPage(themeConfig: _themeConfig),
            ),
          );
        },
        onSecretNotesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SecretNotesPage(
                themeConfig: _themeConfig,
                notesService: widget.secretNotesService,
              ),
            ),
          );
        },
        onMoodTrackingTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MoodTrackingPage(
                themeConfig: _themeConfig,
                moodService: widget.moodService,
              ),
            ),
          );
        },
        onBackupTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup feature coming soon!')),
          );
        },
      ),
      body: Stack(
        children: [
          // Animated particle background
          AnimatedBackground(
            themeConfig: _themeConfig,
            particleCount: 50,
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar
                _buildAppBar(),

                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: widget.memoryService.messages.length +
                        (_chatState == ChatState.thinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= widget.memoryService.messages.length) {
                        return ThinkingIndicator(
                          baseColor: _themeConfig.surfaceColor,
                          highlightColor: _themeConfig.primaryColor,
                        );
                      }
                      return ChatBubble(
                        message: widget.memoryService.messages[index],
                        themeConfig: _themeConfig,
                      );
                    },
                  ),
                ),

                // Status bar
                if (_chatState != ChatState.idle) _buildStatusBar(),

                // Input bar
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Menu button
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu, color: _themeConfig.primaryColor),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),

          // Avatar with neural aura
          NeuralAura(
            isSpeaking: _chatState == ChatState.speaking,
            color: _themeConfig.primaryColor,
            size: 40,
          ),
          const SizedBox(width: 12),

          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zero Two',
                  style: TextStyle(
                    color: _themeConfig.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _statusText,
                  style: TextStyle(
                    color: _themeConfig.textColor.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Spectral visualizer
          SpectralVisualizer(
            isActive: _chatState == ChatState.speaking ||
                _chatState == ChatState.listening,
            color: _themeConfig.primaryColor,
            size: 40,
          ),
        ],
      ),
    );
  }

  String get _statusText {
    switch (_chatState) {
      case ChatState.idle:
        return '${widget.personalityEngine.currentMood.displayName} | ${widget.affectionService.stage.displayName}';
      case ChatState.listening:
        return 'Listening...';
      case ChatState.thinking:
        return 'Thinking...';
      case ChatState.speaking:
        return 'Speaking...';
    }
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_chatState == ChatState.listening)
            Icon(Icons.mic, color: Colors.red, size: 16),
          if (_chatState == ChatState.speaking)
            Icon(Icons.volume_up,
                color: _themeConfig.primaryColor, size: 16),
          const SizedBox(width: 8),
          Text(
            _chatState.name.toUpperCase(),
            style: TextStyle(
              color: _themeConfig.primaryColor.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Voice input button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _chatState == ChatState.listening
                  ? Colors.red.withValues(alpha: 0.2)
                  : _themeConfig.surfaceColor.withValues(alpha: 0.5),
            ),
            child: IconButton(
              icon: Icon(
                _chatState == ChatState.listening
                    ? Icons.stop
                    : Icons.mic,
                color: _chatState == ChatState.listening
                    ? Colors.red
                    : _themeConfig.primaryColor,
              ),
              onPressed: _toggleVoiceInput,
            ),
          ),
          const SizedBox(width: 8),

          // Text input
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(color: _themeConfig.textColor),
              decoration: InputDecoration(
                hintText: 'Talk to Zero Two...',
                hintStyle: TextStyle(
                  color: _themeConfig.textColor.withValues(alpha: 0.3),
                ),
              ),
              onSubmitted: _sendMessage,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _themeConfig.primaryColor,
                  _themeConfig.accentColor,
                ],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
