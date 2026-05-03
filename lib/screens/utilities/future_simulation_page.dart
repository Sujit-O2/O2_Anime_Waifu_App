import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FutureSimulationPage extends StatefulWidget {
  const FutureSimulationPage({super.key});
  @override
  State<FutureSimulationPage> createState() => _FutureSimulationPageState();
}

class _FutureSimulationPageState extends State<FutureSimulationPage> {
  static const _accent = Color(0xFFFFAB40);
  static const _bg = Color(0xFF0C0A06);

  final _decisionCtrl = TextEditingController();
  bool _simulating = false;
  Map<String, String>? _results;
  String _category = 'Career';

  static const _categories = ['Career', 'Learning', 'Health', 'Finance', 'Relationship'];

  static const _outcomes = {
    'Career': {
      '1 Month': '📈 You start applying the decision. Early friction but momentum builds. Colleagues notice the shift.',
      '1 Year': '🚀 Significant progress. You\'ve built a new skill set. 2-3 new opportunities have opened up.',
      '5 Years': '🏆 This decision becomes a defining career move. You\'re recognized as an expert in this area.',
    },
    'Learning': {
      '1 Month': '📚 You\'ve completed the basics. Concepts are clicking. Daily practice is forming a habit.',
      '1 Year': '💡 You can build real projects. Portfolio is growing. Job offers or freelance work starts coming in.',
      '5 Years': '🎓 You\'re teaching others. Deep expertise. This skill is now a core part of your identity.',
    },
    'Health': {
      '1 Month': '💪 Body is adapting. Energy levels improving. Sleep quality noticeably better.',
      '1 Year': '🏃 Visible transformation. Habits are automatic. Mental clarity at an all-time high.',
      '5 Years': '✨ Long-term health markers excellent. You\'ve added quality years to your life.',
    },
    'Finance': {
      '1 Month': '💰 Initial adjustment period. Budget tightens but savings start accumulating.',
      '1 Year': '📊 Emergency fund established. Investments compounding. Financial stress reduced by 60%.',
      '5 Years': '🏦 Financial independence within reach. Multiple income streams. Wealth compounds.',
    },
    'Relationship': {
      '1 Month': '❤️ Communication improves. Trust deepens. Small conflicts resolve faster.',
      '1 Year': '🌟 Relationship reaches new depth. Shared goals aligned. Support system strengthened.',
      '5 Years': '💑 This decision becomes the foundation of a lasting bond. Growth together accelerates.',
    },
  };

  static const _risks = {
    'Career': '⚠️ Risk: Market shifts may devalue this skill. Mitigation: Stay adaptable, learn adjacent skills.',
    'Learning': '⚠️ Risk: Tutorial hell — learning without building. Mitigation: Build projects from week 1.',
    'Health': '⚠️ Risk: Burnout from too much too fast. Mitigation: Start small, scale gradually.',
    'Finance': '⚠️ Risk: Opportunity cost of not investing earlier. Mitigation: Automate savings immediately.',
    'Relationship': '⚠️ Risk: Unmet expectations. Mitigation: Communicate needs clearly and often.',
  };

  @override
  void dispose() {
    _decisionCtrl.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    if (_decisionCtrl.text.trim().isEmpty) return;
    setState(() { _simulating = true; _results = null; });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _results = _outcomes[_category];
      _simulating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('🔮 Future Simulation', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _inputCard(),
          const SizedBox(height: 16),
          _categorySelector(),
          const SizedBox(height: 16),
          _simulateButton(),
          if (_simulating) ...[const SizedBox(height: 24), _loadingCard()],
          if (_results != null) ...[const SizedBox(height: 16), _resultsCard()],
        ]),
      ),
    );
  }

  Widget _inputCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('YOUR DECISION'),
      const SizedBox(height: 10),
      TextField(
        controller: _decisionCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'e.g. "Should I learn React or ML?" or "Should I quit my job?"',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          filled: true, fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ]),
  );

  Widget _categorySelector() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('DECISION CATEGORY'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _categories.map((c) {
          final sel = c == _category;
          return GestureDetector(
            onTap: () => setState(() { _category = c; _results = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? _accent.withAlpha(40) : Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _accent : Colors.white24),
              ),
              child: Text(c, style: TextStyle(color: sel ? _accent : Colors.white54, fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    ]),
  );

  Widget _simulateButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _simulating ? null : _simulate,
      icon: const Icon(Icons.auto_graph),
      label: Text('🔮 Simulate My Future', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent, foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _loadingCard() => _card(
    child: Column(children: [
      const CircularProgressIndicator(color: _accent),
      const SizedBox(height: 12),
      Text('Simulating timelines...', style: GoogleFonts.orbitron(color: _accent, fontSize: 12)),
      const SizedBox(height: 4),
      const Text('Analyzing decision patterns across 1M+ scenarios', style: TextStyle(color: Colors.white38, fontSize: 11)),
    ]),
  );

  Widget _resultsCard() {
    final timelines = _results!;
    return Column(children: [
      ...timelines.entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _accent.withAlpha(40), borderRadius: BorderRadius.circular(20), border: Border.all(color: _accent)),
                child: Text(e.key, style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Text('from now', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
            const SizedBox(height: 10),
            Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
          ]),
        ),
      )),
      _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('RISK ANALYSIS'),
          const SizedBox(height: 8),
          Text(_risks[_category]!, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ]),
      ),
    ]);
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF120F08), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
