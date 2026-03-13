import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class PoemGeneratorPage extends StatefulWidget {
  const PoemGeneratorPage({super.key});
  @override
  State<PoemGeneratorPage> createState() => _PoemGeneratorPageState();
}

class _PoemGeneratorPageState extends State<PoemGeneratorPage> {
  final _ctrl = TextEditingController();
  final _styles = [
    '💫 Haiku',
    '📜 Sonnet',
    '🌊 Free Verse',
    '🎵 Ballad',
    '✨ Acrostic'
  ];
  String _style = '💫 Haiku';
  final _themes = [
    'Our Love',
    'Spring Blossoms',
    'The Night Sky',
    'Missing You',
    'Courage',
    'Dreams',
    'Home'
  ];
  String _selectedTheme = 'Our Love';
  String _poem = '';
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final customTopic = _ctrl.text.trim();
    final topic = customTopic.isNotEmpty ? customTopic : _selectedTheme;
    setState(() {
      _loading = true;
      _poem = '';
    });
    try {
      final style = _style.replaceAll(RegExp(r'^[^ ]+ '), '');
      final prompt = 'You are Zero Two from DARLING in the FRANXX. '
          'Write a beautiful $style poem about: "$topic". '
          'Write it as Zero Two writing to her Darling. '
          'Be poetic, emotional, and uniquely Zero Two. '
          '${style == "Haiku" ? "Follow the 5-7-5 syllable structure strictly." : ""}'
          '${style == "Acrostic" ? "Use the first letters of each line to spell the topic." : ""}'
          '${style == "Sonnet" ? "14 lines with ABAB CDCD EFEF GG rhyme scheme." : ""}'
          'Just write the poem, no title or extra text.';
      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      setState(() => _poem = reply.trim());
      AffectionService.instance.addPoints(3);
    } catch (e) {
      setState(() =>
          _poem = 'Sorry Darling, inspiration fled for a moment~ Try again!');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copy() {
    if (_poem.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _poem));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Poem copied!', style: GoogleFonts.outfit()),
      backgroundColor: Colors.pinkAccent,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('POEM GENERATOR',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Style selector
          Text('Poem Style',
              style: GoogleFonts.outfit(
                  color: Colors.white60, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: _styles.map((s) {
              final sel = s == _style;
              return GestureDetector(
                onTap: () => setState(() => _style = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sel
                        ? Colors.pinkAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                        color: sel ? Colors.pinkAccent : Colors.white12),
                  ),
                  child: Text(s,
                      style: GoogleFonts.outfit(
                          color: sel ? Colors.pinkAccent : Colors.white54,
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 16),

          // Theme quick picks
          Text('Theme',
              style: GoogleFonts.outfit(
                  color: Colors.white60, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _themes.map((t) {
                final sel = t == _selectedTheme && _ctrl.text.isEmpty;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTheme = t;
                      _ctrl.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: sel
                          ? Colors.deepPurpleAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                          color: sel
                              ? Colors.deepPurpleAccent.withValues(alpha: 0.6)
                              : Colors.white12),
                    ),
                    child: Text(t,
                        style: GoogleFonts.outfit(
                            color:
                                sel ? Colors.deepPurpleAccent : Colors.white54,
                            fontSize: 12)),
                  ),
                );
              }).toList()),
          const SizedBox(height: 12),

          // Custom topic
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _ctrl,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              cursorColor: Colors.pinkAccent,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                hintText: 'Or type a custom topic…',
                hintStyle: GoogleFonts.outfit(color: Colors.white24),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white24, size: 18),
                        onPressed: () => setState(() => _ctrl.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 20),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
                boxShadow: [
                  BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6))
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_fix_high, size: 18),
                label: Text(
                    _loading ? 'Zero Two is composing~' : 'Generate Poem',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),

          // Result
          if (_poem.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E0A2E),
                    const Color(0xFF0A1A2E),
                  ],
                ),
                border:
                    Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.1),
                      blurRadius: 30)
                ],
              ),
              child: Column(children: [
                Row(children: [
                  Text(_style.split(' ').first,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(_style.replaceAll(RegExp(r'^[^ ]+ '), ''),
                      style: GoogleFonts.outfit(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined,
                        color: Colors.white38, size: 18),
                    onPressed: _copy,
                  ),
                ]),
                const Divider(color: Colors.white12, height: 16),
                Text(_poem,
                    style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.9,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('+3 XP 💕',
                    style: GoogleFonts.outfit(
                        color: Colors.pinkAccent.withValues(alpha: 0.6),
                        fontSize: 11)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
