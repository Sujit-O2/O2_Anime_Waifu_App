import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class PersonalityEvolutionV2Page extends StatefulWidget {
  const PersonalityEvolutionV2Page({super.key});
  @override
  State<PersonalityEvolutionV2Page> createState() => _PersonalityEvolutionV2PageState();
}

class _PersonalityEvolutionV2PageState extends State<PersonalityEvolutionV2Page> {
  static const _accent = Color(0xFFFF4FA8);
  static const _bg = Color(0xFF0F060C);

  final Map<String, double> _traits = {
    'Affection': 0.65,
    'Playfulness': 0.72,
    'Seriousness': 0.40,
    'Empathy': 0.80,
    'Curiosity': 0.68,
    'Confidence': 0.55,
  };

  final List<Map<String, dynamic>> _events = [];
  int _totalInteractions = 0;
  int _evolutionLevel = 1;
  String _currentPersona = 'Warm Companion';

  static const _personas = {
    1: 'Warm Companion',
    2: 'Playful Partner',
    3: 'Trusted Confidant',
    4: 'Soul Mirror',
    5: 'Evolved Soulmate',
  };

  static const _traitColors = {
    'Affection': Color(0xFFFF4FA8),
    'Playfulness': Color(0xFFFFD700),
    'Seriousness': Color(0xFF79C0FF),
    'Empathy': Color(0xFF4CAF50),
    'Curiosity': Color(0xFFFF9800),
    'Confidence': Color(0xFFB388FF),
  };

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('personality_evo'));
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _totalInteractions = p.getInt('pe_interactions') ?? 0;
      _evolutionLevel = ((_totalInteractions / 50).floor() + 1).clamp(1, 5);
      _currentPersona = _personas[_evolutionLevel]!;
      for (final k in _traits.keys) {
        _traits[k] = p.getDouble('pe_trait_$k') ?? _traits[k]!;
      }
    });
  }

  Future<void> _simulateInteraction(String type) async {
    setState(() {
      _totalInteractions++;
      // Drift traits based on interaction type
      switch (type) {
        case 'Deep Talk':
          _traits['Empathy'] = (_traits['Empathy']! + 0.03).clamp(0.0, 1.0);
          _traits['Seriousness'] = (_traits['Seriousness']! + 0.02).clamp(0.0, 1.0);
          break;
        case 'Joke':
          _traits['Playfulness'] = (_traits['Playfulness']! + 0.04).clamp(0.0, 1.0);
          _traits['Affection'] = (_traits['Affection']! + 0.01).clamp(0.0, 1.0);
          break;
        case 'Advice':
          _traits['Confidence'] = (_traits['Confidence']! + 0.03).clamp(0.0, 1.0);
          _traits['Curiosity'] = (_traits['Curiosity']! + 0.02).clamp(0.0, 1.0);
          break;
        case 'Vent':
          _traits['Empathy'] = (_traits['Empathy']! + 0.05).clamp(0.0, 1.0);
          _traits['Affection'] = (_traits['Affection']! + 0.02).clamp(0.0, 1.0);
          break;
      }
      _evolutionLevel = ((_totalInteractions / 50).floor() + 1).clamp(1, 5);
      _currentPersona = _personas[_evolutionLevel]!;
      _events.insert(0, {
        'type': type,
        'time': DateTime.now().toString().substring(11, 16),
        'drift': _getDriftDesc(type),
      });
      if (_events.length > 8) _events.removeLast();
    });
    final p = await SharedPreferences.getInstance();
    await p.setInt('pe_interactions', _totalInteractions);
    for (final k in _traits.keys) {
      await p.setDouble('pe_trait_$k', _traits[k]!);
    }
  }

  String _getDriftDesc(String type) {
    switch (type) {
      case 'Deep Talk': return 'Empathy +3%, Seriousness +2%';
      case 'Joke': return 'Playfulness +4%, Affection +1%';
      case 'Advice': return 'Confidence +3%, Curiosity +2%';
      case 'Vent': return 'Empathy +5%, Affection +2%';
      default: return 'Minor drift';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('🧬 Personality Evolution', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _personaCard(),
          const SizedBox(height: 16),
          _traitsCard(),
          const SizedBox(height: 16),
          _interactionButtons(),
          const SizedBox(height: 16),
          _evolutionTimeline(),
          if (_events.isNotEmpty) ...[const SizedBox(height: 16), _eventLog()],
        ]),
      ),
    );
  }

  Widget _personaCard() => _card(
    child: Column(children: [
      Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [_accent.withAlpha(80), _accent.withAlpha(20)]),
            border: Border.all(color: _accent, width: 2),
          ),
          child: Center(child: Text('$_evolutionLevel', style: GoogleFonts.orbitron(color: _accent, fontSize: 24, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_currentPersona, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Evolution Level $_evolutionLevel / 5', style: const TextStyle(color: _accent, fontSize: 12)),
          Text('$_totalInteractions total interactions', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
      ]),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_totalInteractions % 50) / 50,
          minHeight: 6,
          backgroundColor: Colors.white10,
          valueColor: const AlwaysStoppedAnimation<Color>(_accent),
        ),
      ),
      const SizedBox(height: 4),
      Text('${50 - (_totalInteractions % 50)} interactions to next evolution',
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]),
  );

  Widget _traitsCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('PERSONALITY TRAITS'),
      const SizedBox(height: 12),
      ..._traits.entries.map((e) {
        final color = _traitColors[e.key] ?? _accent;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(e.key, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${(e.value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: e.value,
                minHeight: 7,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ]),
        );
      }),
    ]),
  );

  Widget _interactionButtons() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('SIMULATE INTERACTION'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: ['Deep Talk', 'Joke', 'Advice', 'Vent'].map((t) => ElevatedButton(
          onPressed: () => _simulateInteraction(t),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent.withAlpha(30),
            foregroundColor: _accent,
            side: BorderSide(color: _accent.withAlpha(80)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Text(t, style: const TextStyle(fontSize: 12)),
        )).toList(),
      ),
    ]),
  );

  Widget _evolutionTimeline() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('EVOLUTION PATH'),
      const SizedBox(height: 12),
      Row(
        children: _personas.entries.map((e) {
          final reached = e.key <= _evolutionLevel;
          final current = e.key == _evolutionLevel;
          return Expanded(
            child: Column(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached ? _accent.withAlpha(current ? 80 : 40) : Colors.white10,
                  border: Border.all(color: reached ? _accent : Colors.white24, width: current ? 2 : 1),
                ),
                child: Center(child: Text('${e.key}', style: TextStyle(color: reached ? _accent : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 4),
              Text(e.value.split(' ').first, style: TextStyle(color: reached ? _accent : Colors.white24, fontSize: 8), textAlign: TextAlign.center),
            ]),
          );
        }).toList(),
      ),
    ]),
  );

  Widget _eventLog() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('DRIFT LOG'),
      const SizedBox(height: 8),
      ..._events.take(5).map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Text(e['time'] as String, style: const TextStyle(color: Colors.white24, fontSize: 10)),
          const SizedBox(width: 8),
          Text(e['type'] as String, style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(child: Text('→ ${e['drift']}', style: const TextStyle(color: Colors.white38, fontSize: 11))),
        ]),
      )),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF140A10), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
