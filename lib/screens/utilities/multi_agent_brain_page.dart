import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MultiAgentBrainPage extends StatefulWidget {
  const MultiAgentBrainPage({super.key});
  @override
  State<MultiAgentBrainPage> createState() => _MultiAgentBrainPageState();
}

class _MultiAgentBrainPageState extends State<MultiAgentBrainPage> {
  static const _accent = Color(0xFF00E5FF);
  static const _bg = Color(0xFF060A0C);

  final _queryCtrl = TextEditingController();
  bool _processing = false;
  List<Map<String, dynamic>> _agentOutputs = [];
  String _finalAnswer = '';
  final Random _rng = Random();

  static const _agents = [
    {'name': 'Planner AI', 'role': 'Breaks down the problem into steps', 'icon': Icons.account_tree, 'color': 0xFF79C0FF},
    {'name': 'Memory AI', 'role': 'Retrieves relevant past context', 'icon': Icons.memory, 'color': 0xFFB388FF},
    {'name': 'Critic AI', 'role': 'Evaluates quality and accuracy', 'icon': Icons.rate_review, 'color': 0xFFFFAB40},
    {'name': 'Emotional AI', 'role': 'Adds empathy and tone calibration', 'icon': Icons.favorite, 'color': 0xFFFF4FA8},
  ];

  static const _plannerResponses = [
    'Breaking into 3 sub-tasks: (1) Understand context, (2) Generate options, (3) Evaluate best path.',
    'Identified 4 key components. Sequencing: research → analyze → synthesize → respond.',
    'Problem decomposed. Priority: address core question first, then edge cases.',
  ];

  static const _memoryResponses = [
    'Retrieved 3 relevant memories: previous discussion on this topic, user preference for concise answers.',
    'Found 2 related past conversations. User tends to prefer practical over theoretical answers.',
    'No direct memory match. Using general knowledge base. Confidence: 78%.',
  ];

  static const _criticResponses = [
    'Draft response quality: 8.5/10. Suggestion: add one concrete example for clarity.',
    'Logic check passed. No contradictions detected. Tone: appropriate. Score: 9/10.',
    'Found 1 potential gap in reasoning. Flagging for improvement. Overall: 7.8/10.',
  ];

  static const _emotionalResponses = [
    'Detected neutral query. Calibrating tone: informative + warm. Adding encouragement.',
    'User seems curious. Matching energy: enthusiastic but grounded. Tone set.',
    'Query has slight urgency. Prioritizing directness. Reducing filler words.',
  ];

  static const _finalResponses = [
    'After multi-agent synthesis: The optimal approach combines structured planning with emotional awareness. Here\'s what I recommend based on all agent inputs...',
    'Consensus reached across all 4 agents. The answer is nuanced but clear: focus on the fundamentals first, then layer complexity gradually.',
    'All agents agree: this requires a two-phase approach. Phase 1: immediate action. Phase 2: long-term strategy. Details below...',
  ];

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    if (_queryCtrl.text.trim().isEmpty) return;
    setState(() { _processing = true; _agentOutputs = []; _finalAnswer = ''; });

    // Simulate agents processing sequentially
    for (int i = 0; i < _agents.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final agent = _agents[i];
      final responses = i == 0 ? _plannerResponses : i == 1 ? _memoryResponses : i == 2 ? _criticResponses : _emotionalResponses;
      setState(() {
        _agentOutputs.add({
          'agent': agent['name'],
          'icon': agent['icon'],
          'color': agent['color'],
          'output': responses[_rng.nextInt(responses.length)],
          'confidence': 75 + _rng.nextInt(25),
        });
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _finalAnswer = _finalResponses[_rng.nextInt(_finalResponses.length)];
      _processing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('🧠 Multi-Agent Brain', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _agentGrid(),
          const SizedBox(height: 16),
          _queryCard(),
          const SizedBox(height: 16),
          _processButton(),
          if (_agentOutputs.isNotEmpty) ...[const SizedBox(height: 16), _outputsCard()],
          if (_finalAnswer.isNotEmpty) ...[const SizedBox(height: 16), _finalCard()],
        ]),
      ),
    );
  }

  Widget _agentGrid() => GridView.count(
    crossAxisCount: 2, shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.8,
    children: _agents.map((a) {
      final active = _agentOutputs.any((o) => o['agent'] == a['name']);
      final color = Color(a['color'] as int);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(25) : const Color(0xFF0C1014),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? color : Colors.white12),
        ),
        child: Row(children: [
          Icon(a['icon'] as IconData, color: active ? color : Colors.white24, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(a['name'] as String, style: TextStyle(color: active ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
            if (active) Text('✓ Done', style: TextStyle(color: color, fontSize: 9)),
          ])),
        ]),
      );
    }).toList(),
  );

  Widget _queryCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('ASK THE BRAIN'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _queryCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ask anything complex...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true, fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => _process(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: _process, icon: const Icon(Icons.send), color: _accent),
      ]),
    ]),
  );

  Widget _processButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _processing ? null : _process,
      icon: _processing
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.psychology),
      label: Text(_processing ? 'Agents thinking...' : '🧠 Activate All Agents', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent, foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _outputsCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('AGENT OUTPUTS'),
      const SizedBox(height: 12),
      ..._agentOutputs.map((o) {
        final color = Color(o['color'] as int);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(o['icon'] as IconData, color: color, size: 16),
              const SizedBox(width: 6),
              Text(o['agent'] as String, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Text('${o['confidence']}%', style: TextStyle(color: color, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(o['output'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
            const Divider(color: Colors.white12, height: 16),
          ]),
        );
      }),
    ]),
  );

  Widget _finalCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _accent.withAlpha(15), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(100)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.auto_awesome, color: _accent, size: 16),
        const SizedBox(width: 6),
        _label('SYNTHESIZED ANSWER'),
      ]),
      const SizedBox(height: 10),
      Text(_finalAnswer, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0C1014), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
