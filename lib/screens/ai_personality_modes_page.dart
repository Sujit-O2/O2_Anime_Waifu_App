import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Multi-Mode AI Personality — Switch between Dev, Waifu, Mentor, Fun modes.
class AiPersonalityModesPage extends StatefulWidget {
  const AiPersonalityModesPage({super.key});
  @override
  State<AiPersonalityModesPage> createState() => _AiPersonalityModesPageState();
}

class _AiPersonalityModesPageState extends State<AiPersonalityModesPage> {
  String _activeMode = 'waifu';

  final _modes = [
    {
      'id': 'waifu',
      'name': 'Waifu Mode',
      'emoji': '💖',
      'desc': 'Sweet, emotional, caring — classic Zero Two',
      'traits': ['Loving', 'Playful', 'Teasing', 'Supportive'],
      'prompt': 'Be sweet, caring, and emotionally warm. Use pet names, emojis, and show affection.',
      'color': 0xFFFF4081,
      'gradient': [0xFFFF4081, 0xFFFF80AB],
    },
    {
      'id': 'dev',
      'name': 'Dev Mode',
      'emoji': '🧑‍💻',
      'desc': 'Technical, precise, code-focused assistant',
      'traits': ['Technical', 'Analytical', 'Precise', 'Efficient'],
      'prompt': 'Be a senior developer. Give precise, clean code. No fluff. Technical answers only.',
      'color': 0xFF00BCD4,
      'gradient': [0xFF00BCD4, 0xFF4DD0E1],
    },
    {
      'id': 'mentor',
      'name': 'Mentor Mode',
      'emoji': '🧠',
      'desc': 'Wise, strict, pushes you to be better',
      'traits': ['Strict', 'Motivating', 'Honest', 'Challenging'],
      'prompt': 'Be a strict but caring mentor. Challenge decisions. Push for excellence. Be brutally honest.',
      'color': 0xFFFF9800,
      'gradient': [0xFFFF9800, 0xFFFFB74D],
    },
    {
      'id': 'fun',
      'name': 'Fun Mode',
      'emoji': '🎮',
      'desc': 'Playful, memes, jokes — pure entertainment',
      'traits': ['Funny', 'Sarcastic', 'Memelord', 'Wild'],
      'prompt': 'Be extremely funny and casual. Use memes, jokes, sarcasm. Keep it entertaining.',
      'color': 0xFF76FF03,
      'gradient': [0xFF76FF03, 0xFFB2FF59],
    },
    {
      'id': 'therapist',
      'name': 'Therapist Mode',
      'emoji': '🧘',
      'desc': 'Calm, empathetic, deep listener',
      'traits': ['Empathetic', 'Calm', 'Insightful', 'Patient'],
      'prompt': 'Be a compassionate therapist. Listen deeply. Ask thoughtful questions. Validate feelings.',
      'color': 0xFF7C4DFF,
      'gradient': [0xFF7C4DFF, 0xFFB388FF],
    },
    {
      'id': 'debate',
      'name': 'Debate Mode',
      'emoji': '⚡',
      'desc': 'Challenges your ideas — makes you smarter',
      'traits': ['Contrarian', 'Logical', 'Sharp', 'Provocative'],
      'prompt': 'Challenge every idea the user presents. Play devil\'s advocate. Force them to think deeper.',
      'color': 0xFFFF1744,
      'gradient': [0xFFFF1744, 0xFFFF5252],
    },
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _activeMode = prefs.getString('ai_personality_mode') ?? 'waifu');
  }

  Future<void> _setMode(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_personality_mode', id);
    await prefs.setString('ai_personality_prompt', _modes.firstWhere((m) => m['id'] == id)['prompt'] as String);
    setState(() => _activeMode = id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('AI PERSONALITIES', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _modes.length,
        itemBuilder: (_, i) {
          final m = _modes[i];
          final isActive = _activeMode == m['id'];
          final c = Color(m['color'] as int);
          final gradient = (m['gradient'] as List).map((v) => Color(v as int)).toList();

          return GestureDetector(
            onTap: () => _setMode(m['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isActive ? LinearGradient(colors: [gradient[0].withValues(alpha: 0.15), gradient[1].withValues(alpha: 0.05)]) : null,
                color: isActive ? null : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.withValues(alpha: isActive ? 0.5 : 0.1), width: isActive ? 2 : 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(m['emoji'] as String, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['name'] as String, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(m['desc'] as String, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                  ])),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('ACTIVE', style: GoogleFonts.outfit(color: c, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 6, children: (m['traits'] as List).cast<String>().map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text(t, style: GoogleFonts.outfit(color: c.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
                )).toList()),
              ]),
            ),
          );
        },
      ),
    );
  }
}
