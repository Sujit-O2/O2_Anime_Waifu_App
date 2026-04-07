import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

/// AI Story Game — Interactive decision-based storytelling with waifu.
/// Users make choices that affect the story and relationship.
class AiStoryGamePage extends StatefulWidget {
  const AiStoryGamePage({super.key});
  @override
  State<AiStoryGamePage> createState() => _AiStoryGamePageState();
}

class _AiStoryGamePageState extends State<AiStoryGamePage> {
  final List<Map<String, dynamic>> _storyLog = [];
  bool _loading = false;
  int _turnCount = 0;

  static const _scenarios = [
    {'title': '🏙️ Cyber City', 'prompt': 'We are stuck in a neon-lit cyber city at midnight. Strange things are happening. Start the story.'},
    {'title': '🏝️ Stranded Island', 'prompt': 'We washed up on a mysterious island together. It\'s just us. Start the story.'},
    {'title': '🌌 Space Station', 'prompt': 'We\'re aboard a drifting space station. The AI systems are failing. Start the story.'},
    {'title': '🏰 Fantasy Kingdom', 'prompt': 'We must save a fantasy kingdom from an ancient curse. Start the story.'},
    {'title': '🎭 Tokyo Mystery', 'prompt': 'Strange disappearances in Tokyo. Only we can solve the mystery. Start the story.'},
    {'title': '🌸 Time Loop', 'prompt': 'We\'re stuck in the same day, living it over and over. Start the story.'},
  ];

  Future<void> _startScenario(Map<String, dynamic> scenario) async {
    setState(() { _storyLog.clear(); _turnCount = 0; _loading = true; });
    await _sendAction(scenario['prompt']?.toString() ?? '', isStart: true);
  }

  Future<void> _sendAction(String action, {bool isStart = false}) async {
    if (!isStart) {
      _storyLog.add({'role': 'user', 'text': action});
    }
    setState(() => _loading = true);

    try {
      final api = ApiService();
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': 'You are Zero Two, the narrator of an interactive story game. '
            'You and the user (Darling) are characters in the story together. '
            'After each narrative segment (2-3 paragraphs), give EXACTLY 3 choices formatted as:\n'
            '① [choice text]\n② [choice text]\n③ [choice text]\n\n'
            'Be dramatic, emotional, and immersive. Use vivid descriptions. '
            'React differently based on user choices. The story should feel personal and bonding.'},
        {'role': 'user', 'content': action},
      ];

      // Add context from previous turns
      for (final entry in _storyLog.take(10)) {
        messages.add({'role': entry['role'] == 'user' ? 'user' : 'assistant', 'content': entry['text']?.toString() ?? ''});
      }
      messages.add({'role': 'user', 'content': action});

      final response = await api.sendConversation(messages);
      _storyLog.add({'role': 'ai', 'text': response});
      _turnCount++;
      AffectionService.instance.addPoints(2);
    } catch (e) {
      _storyLog.add({'role': 'ai', 'text': '*The story pauses...* Something went wrong, Darling. Shall we try again? 💕'});
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('AI STORY GAME', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          if (_storyLog.isNotEmpty)
            IconButton(icon: const Icon(Icons.restart_alt_rounded, color: Colors.orangeAccent),
              onPressed: () => setState(() { _storyLog.clear(); _turnCount = 0; })),
        ],
      ),
      body: _storyLog.isEmpty ? _buildScenarioPicker() : _buildStoryView(),
    );
  }

  Widget _buildScenarioPicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const Text('🎮', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Choose Your Adventure', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        Text('Make choices that shape the story', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),
        ..._scenarios.map((s) => GestureDetector(
          onTap: () => _startScenario(s),
          child: Container(
            width: double.infinity, margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
            ),
            child: Text(s['title']!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        )),
      ]),
    );
  }

  Widget _buildStoryView() {
    return Column(children: [
      // Story log
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _storyLog.length,
        itemBuilder: (_, i) {
          final entry = _storyLog[i];
          final isUser = entry['role'] == 'user';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser ? Colors.cyanAccent.withValues(alpha: 0.08) : Colors.pinkAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (isUser ? Colors.cyanAccent : Colors.pinkAccent).withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isUser ? '👤 Your Choice' : '💕 Zero Two narrates...',
                  style: GoogleFonts.outfit(color: isUser ? Colors.cyanAccent : Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(entry['text']?.toString() ?? '', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.6)),
            ]),
          );
        },
      )),
      if (_loading)
        Padding(padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent)),
            const SizedBox(width: 8),
            Text('Writing story...', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 12)),
          ])),
      // Quick choice input
      if (!_loading) Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
        child: Row(children: [
          Expanded(child: TextField(
            onSubmitted: (v) { if (v.trim().isNotEmpty) _sendAction(v.trim()); },
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
            cursorColor: Colors.pinkAccent,
            decoration: InputDecoration(
              hintText: 'Type your choice or action...',
              hintStyle: GoogleFonts.outfit(color: Colors.white24),
              border: InputBorder.none,
            ),
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('Turn $_turnCount', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    ]);
  }
}
