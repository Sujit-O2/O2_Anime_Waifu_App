import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thought Capture — Quick capture ideas, thoughts, and snippets. Auto-tagged.
class ThoughtCapturePage extends StatefulWidget {
  const ThoughtCapturePage({super.key});
  @override
  State<ThoughtCapturePage> createState() => _ThoughtCapturePageState();
}

class _ThoughtCapturePageState extends State<ThoughtCapturePage> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _thoughts = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('thought_capture');
    if (d != null) setState(() => _thoughts = (jsonDecode(d) as List).cast<Map<String, dynamic>>());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('thought_capture', jsonEncode(_thoughts));
  }

  void _capture() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    final tag = t.contains('idea') || t.contains('startup') ? 'idea' : t.contains('bug') || t.contains('error') ? 'error' : t.contains('todo') || t.contains('task') ? 'task' : 'thought';
    final emojis = {'idea': '💡', 'error': '🐛', 'task': '✅', 'thought': '💭'};
    setState(() => _thoughts.insert(0, {'text': t, 'tag': tag, 'emoji': emojis[tag], 'time': DateTime.now().toIso8601String()}));
    _ctrl.clear(); _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('THOUGHT CAPTURE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)), centerTitle: true),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3))),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, onSubmitted: (_) => _capture(), style: GoogleFonts.outfit(color: Colors.white), cursorColor: Colors.deepPurpleAccent, decoration: InputDecoration(hintText: 'Capture a thought...', hintStyle: GoogleFonts.outfit(color: Colors.white24), border: InputBorder.none))),
            IconButton(icon: const Icon(Icons.send_rounded, color: Colors.deepPurpleAccent), onPressed: _capture),
          ])),
        Expanded(child: _thoughts.isEmpty
          ? Center(child: Text('No thoughts captured yet 💭', style: GoogleFonts.outfit(color: Colors.white30)))
          : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _thoughts.length, itemBuilder: (_, i) {
            final t = _thoughts[i];
            return Dismissible(key: Key(t['time']), onDismissed: (_) { setState(() => _thoughts.removeAt(i)); _save(); },
              child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.deepPurpleAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.15))),
                child: Row(children: [
                  Text(t['emoji'] ?? '💭', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t['text'], style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13))),
                ])));
          })),
      ]),
    );
  }
}
