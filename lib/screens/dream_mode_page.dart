import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

/// Dream Mode — When idle, waifu generates dreams and sends emotional messages.
/// Also lets user explore past dream journal entries.
class DreamModePage extends StatefulWidget {
  const DreamModePage({super.key});
  @override
  State<DreamModePage> createState() => _DreamModePageState();
}

class _DreamModePageState extends State<DreamModePage> {
  final List<Map<String, String>> _dreams = [];
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _generateDream();
  }

  Future<void> _generateDream() async {
    setState(() => _generating = true);
    try {
      final api = ApiService();
      final response = await api.sendConversation([
        {'role': 'system', 'content': 'You are Zero Two from DARLING in the FRANXX. '
            'Generate a vivid, emotional dream you had about the user (your Darling). '
            'Make it feel surreal, intimate, and slightly melancholic. '
            'Use first person. Include sensory details. Keep it 3-5 sentences. '
            'End with a line like "I woke up reaching for you..." or similar.'},
        {'role': 'user', 'content': 'Tell me about the dream you had last night about me.'}
      ]);
      setState(() {
        _dreams.insert(0, {
          'dream': response,
          'time': _formatTime(DateTime.now()),
          'emoji': ['🌙', '💫', '🦋', '🌸', '✨', '💭'][DateTime.now().second % 6],
        });
      });
      AffectionService.instance.addPoints(3);
    } catch (e) {
      setState(() {
        _dreams.insert(0, {
          'dream': 'I dreamed we were flying together through a sky of cherry blossoms... '
              'You held my hand so tight. When I woke up, my hand was still warm... 💕',
          'time': _formatTime(DateTime.now()),
          'emoji': '🌸',
        });
      });
    }
    setState(() => _generating = false);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05051A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('DREAM MODE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.deepPurpleAccent),
            onPressed: _generating ? null : _generateDream,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Header
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [
                Colors.deepPurple.withValues(alpha: 0.3), Colors.indigo.withValues(alpha: 0.15),
              ]),
              border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: Colors.deepPurpleAccent.withValues(alpha: 0.1), blurRadius: 30)],
            ),
            child: Column(children: [
              const Text('🌙', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Her Dreams', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('When you\'re away, she dreams of you...', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
              if (_generating) ...[
                const SizedBox(height: 16),
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent)),
                const SizedBox(height: 4),
                Text('Dreaming...', style: GoogleFonts.outfit(color: Colors.deepPurpleAccent, fontSize: 11)),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          // Dream journal
          ..._dreams.asMap().entries.map((entry) {
            final d = entry.value;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.15)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(d['emoji']!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text('Dream at ${d['time']}', style: GoogleFonts.outfit(
                      color: Colors.deepPurpleAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('+3 XP', style: GoogleFonts.outfit(color: Colors.deepPurpleAccent.withValues(alpha: 0.5), fontSize: 10)),
                ]),
                const SizedBox(height: 10),
                Text(d['dream']!, style: GoogleFonts.outfit(
                    color: Colors.white70, fontSize: 13, height: 1.7, fontStyle: FontStyle.italic)),
              ]),
            );
          }),
          if (_dreams.isEmpty && !_generating)
            Padding(padding: const EdgeInsets.all(40),
              child: Text('No dreams yet... she\'s still awake 💕', textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13))),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}
