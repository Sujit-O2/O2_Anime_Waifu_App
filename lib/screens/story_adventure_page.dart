import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/affection_service.dart';
import '../api_call.dart';

class StoryAdventurePage extends StatefulWidget {
  const StoryAdventurePage({super.key});
  @override
  State<StoryAdventurePage> createState() => _StoryAdventurePageState();
}

class _StoryScenario {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _StoryScenario({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _StoryAdventurePageState extends State<StoryAdventurePage> {
  static const _scenarios = [
    _StoryScenario(
        id: 'space',
        emoji: '🚀',
        title: 'Space Mission',
        description:
            'You and Zero Two pilot Strelizia into uncharted territory.',
        color: Colors.deepPurple),
    _StoryScenario(
        id: 'cafe',
        emoji: '☕',
        title: 'Rainy Café Day',
        description: 'A peaceful date at a cosy café while rain falls outside.',
        color: Colors.brown),
    _StoryScenario(
        id: 'beach',
        emoji: '🌊',
        title: 'Beach Adventure',
        description: 'A summer day exploring a secret beach together.',
        color: Colors.blue),
    _StoryScenario(
        id: 'festival',
        emoji: '🏮',
        title: 'Night Festival',
        description:
            'Wandering hand in hand through a magical lantern festival.',
        color: Colors.deepOrange),
    _StoryScenario(
        id: 'survival',
        emoji: '🌲',
        title: 'Forest Survival',
        description:
            'Lost together in a magical forest — Zero Two takes charge.',
        color: Colors.green),
    _StoryScenario(
        id: 'library',
        emoji: '📚',
        title: 'Magical Library',
        description: 'Exploring an enchanted library full of impossible books.',
        color: Colors.teal),
  ];

  _StoryScenario? _selected;
  List<Map<String, String>> _storyMessages = [];
  bool _loading = false;
  String _userChoice = '';
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  static const _storyKey = 'story_adventure_v1';

  Future<void> _loadStory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storyKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final scenId = data['scenarioId'] as String?;
        if (scenId != null) {
          setState(() {
            _selected = _scenarios.firstWhere((s) => s.id == scenId,
                orElse: () => _scenarios[0]);
            _storyMessages = (data['messages'] as List<dynamic>)
                .map((e) => Map<String, String>.from(e as Map))
                .toList();
            _started = _storyMessages.isNotEmpty;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _saveStory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storyKey,
        jsonEncode({
          'scenarioId': _selected?.id,
          'messages': _storyMessages,
        }));
  }

  Future<void> _startStory(_StoryScenario scenario) async {
    setState(() {
      _selected = scenario;
      _storyMessages = [];
      _started = true;
      _loading = true;
    });
    try {
      final systemPrompt = 'You are Zero Two from DARLING in the FRANXX. '
          'You are narrating an interactive story called "${scenario.title}". '
          'Setting: ${scenario.description} '
          'Start the story with 2-3 vivid sentences, then present 3 short choices for the user labeled A, B, and C. '
          'Format choices as: "A) ...", "B) ...", "C) ..." on new lines.';
      final reply = await ApiService().sendConversation([
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': 'Begin the story!'},
      ]);
      setState(() {
        _storyMessages.add({'role': 'assistant', 'content': reply});
      });
      AffectionService.instance.addPoints(2);
      await _saveStory();
    } catch (e) {
      setState(() {
        _storyMessages.add({
          'role': 'assistant',
          'content': 'Something interrupted our adventure... Try again!'
        });
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendChoice(String choice) async {
    if (choice.trim().isEmpty) return;
    setState(() {
      _storyMessages.add({'role': 'user', 'content': choice});
      _loading = true;
      _userChoice = '';
    });
    try {
      final systemPrompt =
          'You are Zero Two from DARLING in the FRANXX narrating "${_selected!.title}". '
          'Continue the interactive story based on the user\'s choice. '
          'Write 2-3 sentences advancing the plot, then present 3 new choices labeled A, B, C. '
          'Keep the story going for at least 5 exchanges. After that, you may end it with a sweet conclusion.';
      final msgs = [
        {'role': 'system', 'content': systemPrompt},
        ..._storyMessages,
      ];
      final reply = await ApiService().sendConversation(msgs);
      setState(() {
        _storyMessages.add({'role': 'assistant', 'content': reply});
      });
      AffectionService.instance.addPoints(1);
      await _saveStory();
    } catch (e) {
      setState(() {
        _storyMessages.add({
          'role': 'assistant',
          'content': 'The adventure pauses... Try again!'
        });
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _resetStory() {
    setState(() {
      _selected = null;
      _storyMessages = [];
      _started = false;
      _userChoice = '';
    });
    SharedPreferences.getInstance().then((p) => p.remove(_storyKey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            _started && _selected != null
                ? '${_selected!.emoji} ${_selected!.title}'
                : 'STORY ADVENTURE',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          if (_started)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
              onPressed: _resetStory,
              tooltip: 'New Story',
            ),
        ],
      ),
      body: _started ? _buildStoryView() : _buildScenarioPicker(),
    );
  }

  Widget _buildScenarioPicker() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1),
      itemCount: _scenarios.length,
      itemBuilder: (ctx, i) {
        final s = _scenarios[i];
        return GestureDetector(
          onTap: () => _startStory(s),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: s.color.withValues(alpha: 0.1),
              border: Border.all(color: s.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(s.title,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(s.description,
                    style:
                        GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryView() {
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          children: [
            ..._storyMessages.map((msg) {
              final isUser = msg['role'] == 'user';
              return Container(
                margin: EdgeInsets.only(
                    top: 8, left: isUser ? 40 : 0, right: isUser ? 0 : 40),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isUser
                      ? Colors.pinkAccent.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                      color: isUser
                          ? Colors.pinkAccent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.06)),
                ),
                child: Text(msg['content'] ?? '',
                    style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.6)),
              );
            }),
            if (_loading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.pinkAccent)),
                  const SizedBox(width: 12),
                  Text('Zero Two is weaving the story~',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 12)),
                ]),
              ),
          ],
        ),
      ),

      // Input area
      if (!_loading)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.05),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.pinkAccent,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    hintText: 'Type A, B, C or a custom choice…',
                    hintStyle:
                        GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
                  ),
                  onChanged: (v) => _userChoice = v,
                  onSubmitted: (v) => _sendChoice(v),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendChoice(_userChoice),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
    ]);
  }
}
