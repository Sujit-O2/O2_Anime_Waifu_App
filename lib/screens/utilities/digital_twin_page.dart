import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DigitalTwinPage extends StatefulWidget {
  const DigitalTwinPage({super.key});
  @override
  State<DigitalTwinPage> createState() => _DigitalTwinPageState();
}

class _DigitalTwinPageState extends State<DigitalTwinPage> {
  static const _accent = Color(0xFF00E5FF);
  static const _bg = Color(0xFF080C14);

  bool _twinActive = false;
  int _trainingProgress = 0;
  bool _training = false;
  final List<Map<String, String>> _styleLog = [];
  final List<Map<String, String>> _replyLog = [];
  final _inputCtrl = TextEditingController();

  // Simulated learned style traits
  final Map<String, dynamic> _traits = {
    'tone': 'Casual & direct',
    'avg_length': 'Short (< 20 words)',
    'emoji_use': 'Moderate',
    'response_speed': 'Fast',
    'topics': ['tech', 'ideas', 'anime'],
    'trained_on': 0,
  };

  static const _sampleInputs = [
    'bro that idea is fire ngl',
    'yeah makes sense, let me think',
    'nah I disagree, here\'s why',
    'lol okay okay fair point',
    'interesting, tell me more',
  ];

  static const _twinReplies = [
    'bro same, was thinking that too 🔥',
    'yeah makes sense tbh',
    'nah I see it differently — here\'s my take',
    'lol okay you got me there',
    'interesting angle, hadn\'t thought of that',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _trainingProgress = p.getInt('twin_progress') ?? 0;
      _twinActive = p.getBool('twin_active') ?? false;
      _traits['trained_on'] = _trainingProgress;
    });
  }

  Future<void> _trainTwin() async {
    if (_training) return;
    setState(() => _training = true);
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _trainingProgress = (_trainingProgress + 4).clamp(0, 100);
        _traits['trained_on'] = _trainingProgress;
        _styleLog.insert(0, {
          'sample': _sampleInputs[i],
          'learned': 'tone, length, emoji pattern',
        });
        if (_styleLog.length > 6) _styleLog.removeLast();
      });
    }
    final p = await SharedPreferences.getInstance();
    await p.setInt('twin_progress', _trainingProgress);
    if (!mounted) return;
    setState(() => _training = false);
  }

  void _toggleTwin() async {
    setState(() => _twinActive = !_twinActive);
    final p = await SharedPreferences.getInstance();
    await p.setBool('twin_active', _twinActive);
  }

  void _simulateReply() {
    final msg = _inputCtrl.text.trim();
    if (msg.isEmpty) return;
    final idx = msg.length % _twinReplies.length;
    setState(() {
      _replyLog.insert(0, {'you': msg, 'twin': _twinReplies[idx]});
      if (_replyLog.length > 5) _replyLog.removeLast();
    });
    _inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('🤖 Digital Twin', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
        actions: [
          Switch(value: _twinActive, onChanged: (_) => _toggleTwin(), activeColor: _accent),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _statusCard(),
          const SizedBox(height: 16),
          _trainingCard(),
          const SizedBox(height: 16),
          _traitsCard(),
          const SizedBox(height: 16),
          _simulateCard(),
          const SizedBox(height: 16),
          _styleLogCard(),
        ]),
      ),
    );
  }

  Widget _statusCard() => _card(
    child: Row(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _twinActive ? _accent.withAlpha(30) : Colors.white10,
          border: Border.all(color: _twinActive ? _accent : Colors.white24, width: 2),
        ),
        child: Icon(Icons.person_pin, color: _twinActive ? _accent : Colors.white38, size: 28),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your Digital Twin', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_twinActive ? '🟢 Active — replying as you' : '⚫ Inactive — toggle to enable',
            style: TextStyle(color: _twinActive ? _accent : Colors.white38, fontSize: 12)),
        Text('Training: $_trainingProgress%', style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ])),
    ]),
  );

  Widget _trainingCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('STYLE TRAINING'),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _trainingProgress / 100,
          minHeight: 10,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(_trainingProgress >= 80 ? Colors.greenAccent : _accent),
        ),
      ),
      const SizedBox(height: 8),
      Text('$_trainingProgress / 100 style samples learned',
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _training || _trainingProgress >= 100 ? null : _trainTwin,
          icon: _training ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.model_training),
          label: Text(_training ? 'Training...' : _trainingProgress >= 100 ? 'Fully Trained ✓' : 'Train on My Style'),
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
        ),
      ),
    ]),
  );

  Widget _traitsCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('LEARNED TRAITS'),
      const SizedBox(height: 10),
      _traitRow('Tone', _traits['tone'] as String),
      _traitRow('Avg Length', _traits['avg_length'] as String),
      _traitRow('Emoji Use', _traits['emoji_use'] as String),
      _traitRow('Response Speed', _traits['response_speed'] as String),
      _traitRow('Top Topics', (_traits['topics'] as List).join(', ')),
    ]),
  );

  Widget _traitRow(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      Text(v, style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _simulateCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('SIMULATE TWIN REPLY'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _inputCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type a message someone sent you...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true, fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => _simulateReply(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: _simulateReply, icon: const Icon(Icons.send), color: _accent),
      ]),
      if (_replyLog.isNotEmpty) ...[
        const SizedBox(height: 12),
        ..._replyLog.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Them: ${r['you']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text('Twin: ${r['twin']}', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        )),
      ],
    ]),
  );

  Widget _styleLogCard() {
    if (_styleLog.isEmpty) return const SizedBox.shrink();
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('TRAINING LOG'),
        const SizedBox(height: 8),
        ..._styleLog.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text('"${s['sample']}" → ${s['learned']}',
                style: const TextStyle(color: Colors.white54, fontSize: 11))),
          ]),
        )),
      ]),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0E1420),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
