import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';

class AiStoryGamePage extends StatefulWidget {
  const AiStoryGamePage({super.key});

  @override
  State<AiStoryGamePage> createState() => _AiStoryGamePageState();
}

class _AiStoryGamePageState extends State<AiStoryGamePage> {
  static const String _historyKey = 'ai_story_game_history_v2';

  final List<Map<String, dynamic>> _storyLog = <Map<String, dynamic>>[];
  bool _loading = false;
  int _turnCount = 0;

  static const List<Map<String, String>> _scenarios =
      <Map<String, String>>[
    <String, String>{
      'title': 'Cyber City',
      'prompt':
          'We are stuck in a neon-lit cyber city at midnight. Strange things are happening. Start the story.',
    },
    <String, String>{
      'title': 'Stranded Island',
      'prompt':
          'We washed up on a mysterious island together. It is just us. Start the story.',
    },
    <String, String>{
      'title': 'Space Station',
      'prompt':
          'We are aboard a drifting space station. The AI systems are failing. Start the story.',
    },
    <String, String>{
      'title': 'Fantasy Kingdom',
      'prompt':
          'We must save a fantasy kingdom from an ancient curse. Start the story.',
    },
    <String, String>{
      'title': 'Tokyo Mystery',
      'prompt':
          'Strange disappearances in Tokyo. Only we can solve the mystery. Start the story.',
    },
    <String, String>{
      'title': 'Time Loop',
      'prompt':
          'We are stuck in the same day, living it over and over. Start the story.',
    },
  ];

  String get _commentaryMood {
    if (_turnCount >= 4) {
      return 'achievement';
    }
    if (_storyLog.isNotEmpty) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_historyKey) ?? '[]';
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      _storyLog
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
                (Map entry) => entry.map(
                  (dynamic key, dynamic value) =>
                      MapEntry(key.toString(), value),
                ),
              ),
        );
      _turnCount = _storyLog.where((entry) => entry['role'] == 'ai').length;
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(_storyLog.take(25).toList()));
  }

  Future<void> _startScenario(Map<String, String> scenario) async {
    setState(() {
      _storyLog.clear();
      _turnCount = 0;
      _loading = true;
    });
    await _sendAction(scenario['prompt'] ?? '', isStart: true);
  }

  Future<void> _sendAction(String action, {bool isStart = false}) async {
    if (!isStart) {
      _storyLog.add(<String, dynamic>{'role': 'user', 'text': action});
    }
    setState(() => _loading = true);

    try {
      final ApiService api = ApiService();
      final List<Map<String, String>> messages = <Map<String, String>>[
        <String, String>{
          'role': 'system',
          'content':
              'You are Zero Two, the narrator of an interactive story game. '
                  'You and the user are characters in the story together. '
                  'After each narrative segment (2-3 paragraphs), give EXACTLY 3 choices formatted as:\n'
                  '1) [choice]\n2) [choice]\n3) [choice]\n\n'
                  'Be dramatic, emotional, and immersive. React differently based on choices.',
        },
      ];

      for (final Map<String, dynamic> entry in _storyLog.take(10)) {
        messages.add(
          <String, String>{
            'role': entry['role'] == 'user' ? 'user' : 'assistant',
            'content': entry['text']?.toString() ?? '',
          },
        );
      }
      messages.add(<String, String>{'role': 'user', 'content': action});

      final String response = await api.sendConversation(messages);
      _storyLog.add(<String, dynamic>{'role': 'ai', 'text': response});
      _turnCount++;
      AffectionService.instance.addPoints(2);
    } catch (_) {
      _storyLog.add(<String, dynamic>{
        'role': 'ai',
        'text': 'The story pauses. Something went wrong. Try again when ready.',
      });
    }
    await _saveHistory();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: _storyLog.isEmpty ? _buildScenarioPicker() : _buildStoryView(),
      ),
    );
  }

  Widget _buildScenarioPicker() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI STORY GAME',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Pick a scenario to begin',
                    style: GoogleFonts.outfit(
                      color: V2Theme.secondaryColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedEntry(
          index: 0,
          child: GlassCard(
            margin: EdgeInsets.zero,
            glow: true,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your adventure',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Start a new story run',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Each choice changes the story. Pick a setting and dive in.',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const ProgressRing(
                  progress: 0.3,
                  foreground: V2Theme.primaryColor,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: V2Theme.primaryColor,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedEntry(
          index: 1,
          child: WaifuCommentary(mood: _commentaryMood),
        ),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Scenarios',
                value: '${_scenarios.length}',
                icon: Icons.map_rounded,
                color: V2Theme.primaryColor,
              ),
            ),
            Expanded(
              child: StatCard(
                title: 'Runs',
                value: '$_turnCount',
                icon: Icons.auto_stories_rounded,
                color: V2Theme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._scenarios.asMap().entries.map(
          (entry) {
            final Map<String, String> scenario = entry.value;
            return AnimatedEntry(
              index: entry.key + 2,
              child: GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                onTap: () => _startScenario(scenario),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: V2Theme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: V2Theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        scenario['title'] ?? '',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white24,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStoryView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                ),
              ),
              Expanded(
                child: Text(
                  'Story run in progress',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_storyLog.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                    color: Colors.orangeAccent,
                  ),
                  onPressed: () => setState(() {
                    _storyLog.clear();
                    _turnCount = 0;
                  }),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _storyLog.length,
            itemBuilder: (_, int i) {
              final Map<String, dynamic> entry = _storyLog[i];
              final bool isUser = entry['role'] == 'user';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser
                      ? V2Theme.secondaryColor.withValues(alpha: 0.08)
                      : V2Theme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isUser
                            ? V2Theme.secondaryColor
                            : V2Theme.primaryColor)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUser ? 'Your choice' : 'Narration',
                      style: GoogleFonts.outfit(
                        color: isUser
                            ? V2Theme.secondaryColor
                            : V2Theme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry['text']?.toString() ?? '',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_loading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: V2Theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Writing story...',
                  style: GoogleFonts.outfit(
                    color: V2Theme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        if (!_loading)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: V2Theme.surfaceDark,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: (String value) {
                      if (value.trim().isNotEmpty) {
                        _sendAction(value.trim());
                      }
                    },
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                    cursorColor: V2Theme.primaryColor,
                    decoration: InputDecoration(
                      hintText: 'Type your choice or action...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: V2Theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Turn $_turnCount',
                    style: GoogleFonts.outfit(
                      color: V2Theme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}




