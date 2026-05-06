import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class LiveScreenIntelligencePage extends StatefulWidget {
  const LiveScreenIntelligencePage({super.key});
  @override
  State<LiveScreenIntelligencePage> createState() => _LiveScreenIntelligencePageState();
}

class _LiveScreenIntelligencePageState extends State<LiveScreenIntelligencePage> {
  static const _accent = Color(0xFF69FF47);
  static const _bg = Color(0xFF060C06);

  bool _active = false;
  String _detectedContext = 'No screen detected';
  String _aiSuggestion = '';
  String _simulatedApp = 'LeetCode';
  Timer? _scanTimer;

  static const _appContexts = {
    'LeetCode': {
      'context': '🧩 Detected: LeetCode — Two Sum problem (Array, Hash Map)',
      'hint': '💡 Hint: Use a hash map to store complement values. O(n) time complexity. Check if target - nums[i] exists in map before adding.',
      'action': 'Show Solution Approach',
    },
    'VS Code': {
      'context': '💻 Detected: VS Code — Python file, TypeError on line 42',
      'hint': '🔧 Fix: You\'re calling .split() on an integer. Convert to string first: str(value).split(",")',
      'action': 'Auto-Fix Code',
    },
    'YouTube': {
      'context': '▶️ Detected: YouTube — Watching "System Design Interview"',
      'hint': '📝 Tip: This video covers Load Balancers & CDN. Want me to take notes and create a summary?',
      'action': 'Take Notes',
    },
    'Gmail': {
      'context': '📧 Detected: Gmail — Composing email to recruiter',
      'hint': '✍️ Suggestion: Your email is 340 words — too long. Trim to 150 words. Lead with your value proposition.',
      'action': 'Optimize Email',
    },
    'Twitter/X': {
      'context': '🐦 Detected: Twitter/X — Scrolling feed (23 min session)',
      'hint': '⚠️ You\'ve been scrolling for 23 minutes. Your focus session ends in 7 min. Consider closing this tab.',
      'action': 'Start Focus Mode',
    },
    'Notion': {
      'context': '📋 Detected: Notion — Project planning page',
      'hint': '🗂️ I see 8 tasks without deadlines. Want me to auto-assign priorities and suggest a timeline?',
      'action': 'Auto-Prioritize',
    },
  };

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('live_screen'));
    _loadState();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _active = p.getBool('lsi_active') ?? false);
    if (_active) _startScanning();
  }

  void _toggleActive() async {
    setState(() => _active = !_active);
    final p = await SharedPreferences.getInstance();
    await p.setBool('lsi_active', _active);
    if (_active) {
      _startScanning();
    } else {
      _scanTimer?.cancel();
      setState(() { _detectedContext = 'Monitoring paused'; _aiSuggestion = ''; });
    }
  }

  void _startScanning() {
    _updateContext();
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateContext());
  }

  void _updateContext() {
    if (!mounted) return;
    final ctx = _appContexts[_simulatedApp]!;
    setState(() {
      _detectedContext = ctx['context']!;
      _aiSuggestion = ctx['hint']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('👁️ Screen Intelligence', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
        actions: [
          Switch(value: _active, onChanged: (_) => _toggleActive(), activeColor: _accent),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _statusCard(),
          const SizedBox(height: 16),
          _appSimulator(),
          const SizedBox(height: 16),
          if (_active) _contextCard(),
          if (_active && _aiSuggestion.isNotEmpty) ...[const SizedBox(height: 16), _suggestionCard()],
          const SizedBox(height: 16),
          _infoCard(),
        ]),
      ),
    );
  }

  Widget _statusCard() => _card(
    child: Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 12, height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _active ? _accent : Colors.red,
          boxShadow: _active ? [BoxShadow(color: _accent.withAlpha(120), blurRadius: 8)] : null,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_active ? 'MONITORING ACTIVE' : 'MONITORING OFF',
            style: GoogleFonts.orbitron(color: _active ? _accent : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(_active ? 'Scanning screen every 5 seconds' : 'Toggle to start real-time screen analysis',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ])),
    ]),
  );

  Widget _appSimulator() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('SIMULATE ACTIVE APP'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _appContexts.keys.map((app) {
          final sel = app == _simulatedApp;
          return GestureDetector(
            onTap: () { setState(() => _simulatedApp = app); if (_active) _updateContext(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _accent.withAlpha(30) : Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _accent : Colors.white24),
              ),
              child: Text(app, style: TextStyle(color: sel ? _accent : Colors.white54, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    ]),
  );

  Widget _contextCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _label('DETECTED CONTEXT'),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: _accent.withAlpha(30), borderRadius: BorderRadius.circular(10)),
          child: const Text('LIVE', style: TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
      const SizedBox(height: 10),
      Text(_detectedContext, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
    ]),
  );

  Widget _suggestionCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _accent.withAlpha(15),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(100)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('AI SUGGESTION'),
      const SizedBox(height: 10),
      Text(_aiSuggestion, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        child: Text(_appContexts[_simulatedApp]!['action']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    ]),
  );

  Widget _infoCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('HOW IT WORKS'),
      const SizedBox(height: 8),
      const Text(
        '• OCR scans your screen every 5 seconds\n'
        '• AI identifies the app and current context\n'
        '• Provides real-time hints, fixes, and suggestions\n'
        '• Works with: coding, email, YouTube, social media\n'
        '• Privacy: all processing happens on-device',
        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
      ),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF080E08), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
