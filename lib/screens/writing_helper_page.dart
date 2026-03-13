import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class WritingHelperPage extends StatefulWidget {
  const WritingHelperPage({super.key});
  @override
  State<WritingHelperPage> createState() => _WritingHelperPageState();
}

class _WritingHelperPageState extends State<WritingHelperPage> {
  final _inputCtrl = TextEditingController();
  final _types = [
    'Essay ✍️',
    'Story 📖',
    'Email 📧',
    'Cover Letter 💼',
    'Speech 🎤',
    'Poem 🌸',
    'Tweet/Caption 📱',
    'Apology Letter 💌'
  ];
  final _tones = [
    'Formal 👔',
    'Casual 😊',
    'Romantic 💕',
    'Persuasive 🔥',
    'Poetic ✨',
    'Funny 😂'
  ];
  String _type = 'Essay ✍️', _tone = 'Casual 😊', _result = '';
  bool _loading = false;
  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _inputCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Enter a topic, Darling!', style: GoogleFonts.outfit()),
          backgroundColor: Colors.pinkAccent,
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      final t = _type.split(' ').first;
      final prompt =
          'You are Zero Two, brilliant writer. Write a ${_tone.split(' ').first.toLowerCase()} $t about: "$topic". '
          'Make it high-quality, engaging, and in character where appropriate. Use proper structure.';
      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt}
      ]);
      setState(() => _result = reply);
      AffectionService.instance.addPoints(3);
    } catch (_) {
      setState(() => _result = 'Quill slipped, Darling~ Try again!');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                onPressed: () => Navigator.pop(context)),
            title: Text('WRITING HELPER',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
            centerTitle: true),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _section('Type of Writing'),
              _chips(_types, _type, Colors.purpleAccent,
                  (v) => setState(() => _type = v)),
              const SizedBox(height: 14),
              _section('Tone'),
              _chips(_tones, _tone, Colors.pinkAccent,
                  (v) => setState(() => _tone = v)),
              const SizedBox(height: 14),
              _section('Topic or Prompt'),
              _field(_inputCtrl, 'What should I write about?…', lines: 4),
              const SizedBox(height: 20),
              _btn(),
              if (_result.isNotEmpty) ...[
                const SizedBox(height: 20),
                _card(_result, Colors.purpleAccent)
              ],
            ])),
      );
  Widget _section(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t,
          style: GoogleFonts.outfit(
              color: Colors.white60, fontSize: 11, letterSpacing: 1.5)));
  Widget _chips(List<String> items, String sel, Color col, ValueChanged<String> fn) =>
      Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .map((i) => GestureDetector(
                  onTap: () => fn(i),
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: i == sel
                              ? col.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                              color: i == sel
                                  ? col.withValues(alpha: 0.6)
                                  : Colors.white12)),
                      child: Text(i,
                          style: GoogleFonts.outfit(
                              color: i == sel ? col : Colors.white54,
                              fontSize: 11,
                              fontWeight:
                                  i == sel ? FontWeight.bold : FontWeight.normal)))))
              .toList());
  Widget _field(TextEditingController c, String h, {int lines = 1}) =>
      Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: TextField(
              controller: c,
              maxLines: lines,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              cursorColor: Colors.purpleAccent,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  hintText: h,
                  hintStyle: GoogleFonts.outfit(color: Colors.white24))));
  Widget _btn() => SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B44FD), Color(0xFFFF4D8D)]),
              boxShadow: [
                BoxShadow(
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5))
              ]),
          child: ElevatedButton(
              onPressed: _loading ? null : _generate,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Write for me ✔️',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 15)))));
  Widget _card(String t, Color col) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: col.withValues(alpha: 0.2))),
      child: Text(t,
          style: GoogleFonts.outfit(
              color: Colors.white70, fontSize: 13, height: 1.7)));
}
