import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Second Brain — Personal knowledge database with notes, ideas, code snippets,
/// and semantic search. Never lose an idea again.
class SecondBrainPage extends StatefulWidget {
  const SecondBrainPage({super.key});
  @override
  State<SecondBrainPage> createState() => _SecondBrainPageState();
}

class _SecondBrainPageState extends State<SecondBrainPage> {
  List<Map<String, dynamic>> _notes = [];
  final _searchCtrl = TextEditingController();
  String _filter = 'all';

  static const _tags = ['all', 'idea', 'code', 'note', 'thought', 'error', 'project'];
  static const _tagColors = {'idea': Colors.amberAccent, 'code': Colors.cyanAccent, 'note': Colors.greenAccent, 'thought': Colors.pinkAccent, 'error': Colors.redAccent, 'project': Colors.orangeAccent};
  static const _tagEmojis = {'idea': '💡', 'code': '💻', 'note': '📝', 'thought': '💭', 'error': '🐛', 'project': '📂'};

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('second_brain_notes');
    if (data != null) {
      try {
        setState(() => _notes = (jsonDecode(data) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('second_brain_notes', jsonEncode(_notes));
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _filter == 'all' ? _notes : _notes.where((n) => n['tag'] == _filter).toList();
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) list = list.where((n) => (n['title']?.toString() ?? '').toLowerCase().contains(q) || (n['content']?.toString() ?? '').toLowerCase().contains(q)).toList();
    return list;
  }

  void _addNote() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String tag = 'note';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('New Entry', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, style: GoogleFonts.outfit(color: Colors.white), cursorColor: Colors.cyanAccent, decoration: InputDecoration(hintText: 'Title', hintStyle: GoogleFonts.outfit(color: Colors.white24), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 10),
        TextField(controller: contentCtrl, maxLines: 5, style: GoogleFonts.outfit(color: Colors.white), cursorColor: Colors.cyanAccent, decoration: InputDecoration(hintText: 'Content...', hintStyle: GoogleFonts.outfit(color: Colors.white24), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 10),
        Wrap(spacing: 6, children: _tags.where((t) => t != 'all').map((t) => GestureDetector(
          onTap: () => setS(() => tag = t),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: (tag == t ? (_tagColors[t] ?? Colors.white) : Colors.white12).withValues(alpha: tag == t ? 0.2 : 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: (tag == t ? (_tagColors[t] ?? Colors.white) : Colors.white24).withValues(alpha: 0.5))),
            child: Text('${_tagEmojis[t]} $t', style: GoogleFonts.outfit(color: tag == t ? (_tagColors[t] ?? Colors.white) : Colors.white54, fontSize: 11, fontWeight: FontWeight.w600))),
        )).toList()),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54))),
        TextButton(onPressed: () {
          if (titleCtrl.text.isNotEmpty) {
            setState(() => _notes.insert(0, {'title': titleCtrl.text, 'content': contentCtrl.text, 'tag': tag, 'time': DateTime.now().toIso8601String()}));
            _save(); Navigator.pop(ctx);
          }
        }, child: Text('SAVE', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.w700))),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('SECOND BRAIN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)), centerTitle: true),
      floatingActionButton: FloatingActionButton(onPressed: _addNote, backgroundColor: Colors.cyanAccent, child: const Icon(Icons.add, color: Colors.black)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: TextField(
          controller: _searchCtrl, onChanged: (_) => setState(() {}),
          style: GoogleFonts.outfit(color: Colors.white), cursorColor: Colors.cyanAccent,
          decoration: InputDecoration(hintText: 'Search your brain...', hintStyle: GoogleFonts.outfit(color: Colors.white24), prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
        SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: _tags.map((t) => GestureDetector(
          onTap: () => setState(() => _filter = t),
          child: Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: (_filter == t ? Colors.cyanAccent : Colors.white12).withValues(alpha: _filter == t ? 0.15 : 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: (_filter == t ? Colors.cyanAccent : Colors.white24).withValues(alpha: 0.5))),
            child: Text(t == 'all' ? '📋 All' : '${_tagEmojis[t]} $t', style: GoogleFonts.outfit(color: _filter == t ? Colors.cyanAccent : Colors.white54, fontSize: 11, fontWeight: FontWeight.w600))),
        )).toList())),
        const SizedBox(height: 8),
        Expanded(child: items.isEmpty
          ? Center(child: Text('Your brain is empty. Start adding! 🧠', style: GoogleFonts.outfit(color: Colors.white30)))
          : ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (_, i) {
            final n = items[i];
            final c = _tagColors[n['tag']] ?? Colors.white54;
            return Dismissible(key: Key(n['time']?.toString() ?? '$i'), onDismissed: (_) { setState(() => _notes.remove(n)); _save(); }, background: Container(color: Colors.redAccent.withValues(alpha: 0.2), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.redAccent)),
              child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withValues(alpha: 0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text('${_tagEmojis[n['tag']]} ', style: const TextStyle(fontSize: 16)), Expanded(child: Text(n['title']?.toString() ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(n['tag']?.toString() ?? '', style: GoogleFonts.outfit(color: c, fontSize: 9, fontWeight: FontWeight.w700)))]),
                  if ((n['content']?.toString() ?? '').isNotEmpty) ...[const SizedBox(height: 6), Text(n['content'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12))],
                ])));
          })),
      ]),
    );
  }
}
