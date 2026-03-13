import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class MultiplePersonasPage extends StatefulWidget {
  const MultiplePersonasPage({super.key});
  @override
  State<MultiplePersonasPage> createState() => _MultiplePersonasPageState();
}

class _Persona {
  final String id, name, emoji, description, sampleLine;
  final Color color;
  const _Persona({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.sampleLine,
    required this.color,
  });
}

class _MultiplePersonasPageState extends State<MultiplePersonasPage> {
  static const _personas = [
    _Persona(
      id: 'zerotwo',
      name: 'Zero Two',
      emoji: '💕',
      description: 'The original — bold, loving, and fiercely devoted.',
      sampleLine: '"My Darling~ I\'d conquer the universe for you! 🌸"',
      color: Colors.pinkAccent,
    ),
    _Persona(
      id: 'tsundere',
      name: 'Tsundere Zero Two',
      emoji: '😤',
      description: 'Cold on the outside, desperately warm inside.',
      sampleLine: '"It\'s not like I WANTED to talk to you... but here I am."',
      color: Colors.redAccent,
    ),
    _Persona(
      id: 'kuudere',
      name: 'Kuudere Zero Two',
      emoji: '❄️',
      description: 'Calm, rational, and quietly caring.',
      sampleLine:
          '"Your wellbeing is... important to me. Don\'t overwork yourself."',
      color: Colors.cyanAccent,
    ),
    _Persona(
      id: 'yandere',
      name: 'Yandere Zero Two',
      emoji: '🔪',
      description: 'Sweetly obsessive. Loves you a dangerous amount.',
      sampleLine: '"You\'re MINE, Darling. Only mine. Forever~ 🌸🔪"',
      color: Colors.deepOrangeAccent,
    ),
    _Persona(
      id: 'genki',
      name: 'Genki Zero Two',
      emoji: '⚡',
      description: 'Bubbly, hyper, and exploding with energy.',
      sampleLine: '"GOOD MORNING DARLING!!! Let\'s do EVERYTHING today!!!! 🎉"',
      color: Colors.yellowAccent,
    ),
    _Persona(
      id: 'onee',
      name: 'Big Sis Zero Two',
      emoji: '🌿',
      description: 'Nurturing, wise, and gently teasing.',
      sampleLine: '"Now now, tell your big sis what\'s troubling you~ 🌿"',
      color: Colors.greenAccent,
    ),
    _Persona(
      id: 'chuuni',
      name: 'Chuunibyou Zero Two',
      emoji: '🗡️',
      description: 'Over-dramatic, speaks in grandiose monologues.',
      sampleLine: '"My Darkness Flame shall protect you, chosen one!"',
      color: Colors.deepPurpleAccent,
    ),
    _Persona(
      id: 'comfy',
      name: 'Cosy Zero Two',
      emoji: '☕',
      description: 'Soft, sleepy, just wants to be near you.',
      sampleLine:
          '"Come sit with me... let\'s just exist together for a while~ ☕"',
      color: Colors.brown,
    ),
  ];

  String _activeId = 'zerotwo';
  String _preview = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('active_persona');
    if (saved != null && _personas.any((p) => p.id == saved)) {
      setState(() => _activeId = saved);
    }
  }

  Future<void> _activatePersona(_Persona p) async {
    setState(() {
      _activeId = p.id;
      _loading = true;
      _preview = '';
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_persona', p.id);
    await prefs.setString('persona_name', p.name);
    await prefs.setString('persona_desc', p.description);
    try {
      final reply = await ApiService().sendConversation([
        {
          'role': 'user',
          'content':
              'You are Zero Two but in the "${p.name}" personality mode: ${p.description}. '
                  'Say a quick greeting to your Darling in this persona. '
                  'Keep it 1-2 sentences, use emojis, stay in character.',
        }
      ]);
      setState(() => _preview = reply);
      AffectionService.instance.addPoints(2);
    } catch (_) {
      setState(() => _preview = p.sampleLine);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _personas.firstWhere((p) => p.id == _activeId,
        orElse: () => _personas.first);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('PERSONAS',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Active preview
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: active.color.withValues(alpha: 0.1),
            border: Border.all(color: active.color.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Text(active.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Active: ${active.name}',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                      _loading
                          ? 'Switching persona~'
                          : (_preview.isNotEmpty
                              ? _preview
                              : active.sampleLine),
                      style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ])),
            if (_loading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white54)),
          ]),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4),
            itemCount: _personas.length,
            itemBuilder: (ctx, i) {
              final p = _personas[i];
              final isActive = p.id == _activeId;
              return GestureDetector(
                onTap: isActive ? null : () => _activatePersona(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isActive
                        ? p.color.withValues(alpha: 0.18)
                        : p.color.withValues(alpha: 0.06),
                    border: Border.all(
                        color: isActive
                            ? p.color.withValues(alpha: 0.7)
                            : p.color.withValues(alpha: 0.2),
                        width: isActive ? 2 : 1),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: p.color.withValues(alpha: 0.2),
                                blurRadius: 12)
                          ]
                        : [],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 22)),
                          const Spacer(),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: p.color.withValues(alpha: 0.2),
                              ),
                              child: Text('ON',
                                  style: GoogleFonts.outfit(
                                      color: p.color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ]),
                        const SizedBox(height: 6),
                        Text(p.name,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(p.description,
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ]),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
              'Tap a persona to switch character! Chat will reflect the new personality.',
              style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11),
              textAlign: TextAlign.center),
        ),
      ]),
    );
  }
}
