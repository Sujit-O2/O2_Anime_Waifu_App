import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class ThoughtToTextPage extends StatefulWidget {
  const ThoughtToTextPage({super.key});
  @override
  State<ThoughtToTextPage> createState() => _ThoughtToTextPageState();
}

class _ThoughtToTextPageState extends State<ThoughtToTextPage> {
  static const _accent = Color(0xFFB388FF);
  static const _bg = Color(0xFF0A080F);

  final _rawCtrl = TextEditingController();
  String _structured = '';
  bool _processing = false;
  String _outputType = 'Startup Idea';
  final List<Map<String, String>> _history = [];

  static const _types = ['Startup Idea', 'Task List', 'Study Notes', 'Journal Entry', 'Code Plan'];

  // Simulated AI structuring templates
  static const _templates = {
    'Startup Idea': '📌 **Concept:** {core}\n\n🎯 **Problem:** Users need a better way to {action}\n\n💡 **Solution:** An app that {solution}\n\n🚀 **Next Steps:**\n• Validate with 10 users\n• Build MVP in 2 weeks\n• Launch on Product Hunt',
    'Task List': '✅ **Tasks Extracted:**\n\n1. {t1}\n2. {t2}\n3. {t3}\n\n⏰ **Priority:** High\n📅 **Deadline:** This week',
    'Study Notes': '📚 **Topic:** {core}\n\n🔑 **Key Points:**\n• {p1}\n• {p2}\n• {p3}\n\n💭 **Summary:** {core} is important because it helps understand the bigger picture.',
    'Journal Entry': '📓 **{date}**\n\nToday I was thinking about {core}. It made me realize that {action}. I want to explore this more by {solution}.',
    'Code Plan': '💻 **Feature:** {core}\n\n🏗️ **Architecture:**\n• Input: {action}\n• Process: {solution}\n• Output: Result\n\n📝 **Steps:**\n1. Define data model\n2. Build service layer\n3. Create UI\n4. Test & deploy',
  };

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('thought_to_text'));
    _loadHistory();
  }

  @override
  void dispose() {
    _rawCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('t2t_history') ?? [];
    setState(() {
      _history.addAll(raw.map((e) {
        final parts = e.split('|||');
        return {'raw': parts[0], 'structured': parts.length > 1 ? parts[1] : ''};
      }));
    });
  }

  Future<void> _process() async {
    final raw = _rawCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() { _processing = true; _structured = ''; });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Extract key words from raw input
    final words = raw.split(' ').where((w) => w.length > 3).toList();
    final core = words.take(3).join(' ');
    final action = words.skip(3).take(3).join(' ').isEmpty ? 'do things better' : words.skip(3).take(3).join(' ');
    final solution = words.skip(6).take(4).join(' ').isEmpty ? 'automates the process' : words.skip(6).take(4).join(' ');

    final template = _templates[_outputType] ?? _templates['Startup Idea']!;
    final result = template
        .replaceAll('{core}', core.isEmpty ? 'your idea' : core)
        .replaceAll('{action}', action)
        .replaceAll('{solution}', solution)
        .replaceAll('{t1}', words.isNotEmpty ? words[0] : 'Task 1')
        .replaceAll('{t2}', words.length > 1 ? words[1] : 'Task 2')
        .replaceAll('{t3}', words.length > 2 ? words[2] : 'Task 3')
        .replaceAll('{p1}', core)
        .replaceAll('{p2}', action)
        .replaceAll('{p3}', solution)
        .replaceAll('{date}', DateTime.now().toString().substring(0, 10));

    setState(() { _structured = result; _processing = false; });

    // Save to history
    _history.insert(0, {'raw': raw, 'structured': result});
    if (_history.length > 10) _history.removeLast();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('t2t_history', _history.map((e) => '${e['raw']}|||${e['structured']}').toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('🧠 Thought → Text', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _inputCard(),
          const SizedBox(height: 16),
          _typeSelector(),
          const SizedBox(height: 16),
          _processButton(),
          if (_structured.isNotEmpty) ...[const SizedBox(height: 16), _outputCard()],
          if (_history.isNotEmpty) ...[const SizedBox(height: 16), _historyCard()],
        ]),
      ),
    );
  }

  Widget _inputCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('DUMP YOUR RAW THOUGHTS'),
      const SizedBox(height: 10),
      TextField(
        controller: _rawCtrl,
        maxLines: 5,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'uh bro idea like app where people can... idk like track stuff and AI helps...',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          filled: true, fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ]),
  );

  Widget _typeSelector() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('OUTPUT FORMAT'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _types.map((t) {
          final sel = t == _outputType;
          return GestureDetector(
            onTap: () => setState(() => _outputType = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _accent.withAlpha(40) : Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _accent : Colors.white24),
              ),
              child: Text(t, style: TextStyle(color: sel ? _accent : Colors.white54, fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    ]),
  );

  Widget _processButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _processing ? null : _process,
      icon: _processing
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.auto_fix_high),
      label: Text(_processing ? 'Structuring...' : '✨ Structure My Thoughts',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent, foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _outputCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label('STRUCTURED OUTPUT'),
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.white54, size: 18),
          onPressed: () => Clipboard.setData(ClipboardData(text: _structured)),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
      ]),
      const SizedBox(height: 10),
      Text(_structured, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
    ]),
  );

  Widget _historyCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('RECENT (${_history.length})'),
      const SizedBox(height: 8),
      ..._history.take(3).map((h) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => setState(() { _rawCtrl.text = h['raw']!; _structured = h['structured']!; }),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Text('"${h['raw']!.length > 60 ? '${h['raw']!.substring(0, 60)}...' : h['raw']}"',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
        ),
      )),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF100D18), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
