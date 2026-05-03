import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CognitiveLoadDetectorPage extends StatefulWidget {
  const CognitiveLoadDetectorPage({super.key});
  @override
  State<CognitiveLoadDetectorPage> createState() => _CognitiveLoadDetectorPageState();
}

class _CognitiveLoadDetectorPageState extends State<CognitiveLoadDetectorPage>
    with TickerProviderStateMixin {
  static const _bg = Color(0xFF080A0F);

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  double _loadScore = 0.35; // 0.0 = relaxed, 1.0 = overwhelmed
  String _state = 'Focused';
  bool _monitoring = false;
  Timer? _monitorTimer;
  final List<Map<String, dynamic>> _history = [];
  final Random _rng = Random();

  static const _states = {
    'Relaxed': {'color': 0xFF4CAF50, 'icon': Icons.spa, 'range': [0.0, 0.3]},
    'Focused': {'color': 0xFF79C0FF, 'icon': Icons.psychology, 'range': [0.3, 0.55]},
    'Stressed': {'color': 0xFFFFAB40, 'icon': Icons.warning_amber, 'range': [0.55, 0.75]},
    'Overwhelmed': {'color': 0xFFFF5252, 'icon': Icons.crisis_alert, 'range': [0.75, 1.0]},
  };

  static const _suggestions = {
    'Relaxed': ['Great time for deep work 🎯', 'Tackle your hardest task now', 'You\'re in flow state — keep going'],
    'Focused': ['Maintain current pace 👍', 'Take a 5-min break in 25 min', 'Good focus — avoid distractions'],
    'Stressed': ['Take a 10-min break now ⏸️', 'Drink water and breathe deeply', 'Simplifying responses for you...', 'Consider a short walk'],
    'Overwhelmed': ['Stop. Breathe. 5 deep breaths 🫁', 'Close unnecessary tabs', 'Break tasks into smaller pieces', 'Rest is productive — take 20 min'],
  };

  Color get _stateColor => Color(_states[_state]!['color'] as int);
  IconData get _stateIcon => _states[_state]!['icon'] as IconData;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _monitorTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _loadScore = p.getDouble('cld_score') ?? 0.35;
      _monitoring = p.getBool('cld_monitoring') ?? false;
      _updateState();
    });
    if (_monitoring) _startMonitoring();
  }

  void _updateState() {
    for (final entry in _states.entries) {
      final range = entry.value['range'] as List;
      if (_loadScore >= (range[0] as double) && _loadScore < (range[1] as double)) {
        _state = entry.key;
        return;
      }
    }
    _state = 'Overwhelmed';
  }

  void _toggleMonitoring() async {
    setState(() => _monitoring = !_monitoring);
    final p = await SharedPreferences.getInstance();
    await p.setBool('cld_monitoring', _monitoring);
    if (_monitoring) {
      _startMonitoring();
    } else {
      _monitorTimer?.cancel();
    }
  }

  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      // Simulate load fluctuation
      final delta = (_rng.nextDouble() - 0.45) * 0.08;
      setState(() {
        _loadScore = (_loadScore + delta).clamp(0.0, 1.0);
        _updateState();
        _history.insert(0, {'score': _loadScore, 'state': _state, 'time': DateTime.now().toString().substring(11, 16)});
        if (_history.length > 10) _history.removeLast();
      });
    });
  }

  void _manualSet(double val) {
    setState(() { _loadScore = val; _updateState(); });
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions[_state]!;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('🧠 Cognitive Load', style: GoogleFonts.orbitron(color: _stateColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: _stateColor),
        actions: [
          Switch(value: _monitoring, onChanged: (_) => _toggleMonitoring(), activeColor: _stateColor),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _gaugeCard(),
          const SizedBox(height: 16),
          _stateCard(suggestions),
          const SizedBox(height: 16),
          _manualSlider(),
          const SizedBox(height: 16),
          _signalsCard(),
          if (_history.isNotEmpty) ...[const SizedBox(height: 16), _historyCard()],
        ]),
      ),
    );
  }

  Widget _gaugeCard() => AnimatedBuilder(
    animation: _pulseAnim,
    builder: (_, __) => Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _stateColor.withAlpha(80)),
        gradient: RadialGradient(colors: [_stateColor.withAlpha((30 * _pulseAnim.value).toInt()), const Color(0xFF0C0E14)]),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_stateIcon, color: _stateColor, size: 52 * _pulseAnim.value),
          const SizedBox(height: 8),
          Text(_state, style: GoogleFonts.orbitron(color: _stateColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Load: ${(_loadScore * 100).toInt()}%', style: TextStyle(color: _stateColor.withAlpha(180), fontSize: 14)),
          const SizedBox(height: 8),
          SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _loadScore,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(_stateColor),
              ),
            ),
          ),
        ]),
      ),
    ),
  );

  Widget _stateCard(List<String> suggestions) => _card(
    color: _stateColor,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('AI RECOMMENDATIONS', _stateColor),
      const SizedBox(height: 10),
      ...suggestions.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(Icons.arrow_right, color: _stateColor, size: 16),
          const SizedBox(width: 4),
          Expanded(child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ]),
      )),
    ]),
  );

  Widget _manualSlider() => _card(
    color: _stateColor,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('MANUAL CALIBRATION', _stateColor),
      const SizedBox(height: 4),
      const Text('How stressed are you right now?', style: TextStyle(color: Colors.white54, fontSize: 12)),
      Slider(
        value: _loadScore,
        onChanged: _manualSet,
        activeColor: _stateColor,
        inactiveColor: Colors.white12,
        divisions: 20,
      ),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('😌 Relaxed', style: TextStyle(color: Colors.white38, fontSize: 11)),
        Text('😰 Overwhelmed', style: TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    ]),
  );

  Widget _signalsCard() => _card(
    color: _stateColor,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('DETECTED SIGNALS', _stateColor),
      const SizedBox(height: 10),
      _signal('Typing speed', _loadScore > 0.6 ? 'Erratic' : 'Normal', _loadScore > 0.6),
      _signal('Session length', _loadScore > 0.5 ? '3h 20min (long)' : '45min', _loadScore > 0.5),
      _signal('App switches', _loadScore > 0.7 ? 'High (12/hr)' : 'Low (3/hr)', _loadScore > 0.7),
      _signal('Response delay', _loadScore > 0.65 ? 'Slow (8s avg)' : 'Fast (2s avg)', _loadScore > 0.65),
    ]),
  );

  Widget _signal(String label, String value, bool alert) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      Text(value, style: TextStyle(color: alert ? Colors.orange : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _historyCard() => _card(
    color: _stateColor,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('LOAD HISTORY', _stateColor),
      const SizedBox(height: 8),
      ..._history.take(5).map((h) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Text(h['time'] as String, style: const TextStyle(color: Colors.white24, fontSize: 10)),
          const SizedBox(width: 8),
          Text(h['state'] as String, style: TextStyle(color: Color(_states[h['state']]!['color'] as int), fontSize: 11, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${((h['score'] as double) * 100).toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      )),
    ]),
  );

  Widget _card({required Widget child, required Color color}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0C0E14), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t, Color c) => Text(t, style: GoogleFonts.orbitron(color: c, fontSize: 11, fontWeight: FontWeight.bold));
}
