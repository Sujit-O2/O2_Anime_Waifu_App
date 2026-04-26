import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
/// Knowledge Graph — Link ideas, chats, projects, bugs, and solutions together.
/// Visual web of connected thoughts.
class KnowledgeGraphPage extends StatefulWidget {
  const KnowledgeGraphPage({super.key});
  @override
  State<KnowledgeGraphPage> createState() => _KnowledgeGraphPageState();
}

class _KnowledgeGraphPageState extends State<KnowledgeGraphPage> {
  final _ctrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  List<Map<String, dynamic>> _nodes = [];
  String _selectedTag = 'all';

  final _nodeTypes = [
    {'type': 'idea', 'emoji': '💡', 'color': 0xFFFFD700},
    {'type': 'project', 'emoji': '📁', 'color': 0xFF4FC3F7},
    {'type': 'bug', 'emoji': '🐛', 'color': 0xFFFF5252},
    {'type': 'solution', 'emoji': '✅', 'color': 0xFF69F0AE},
    {'type': 'note', 'emoji': '📝', 'color': 0xFFCE93D8},
    {'type': 'person', 'emoji': '👤', 'color': 0xFFFFAB40},
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('knowledge_graph_nodes');
    if (d != null && mounted) {
      try {
        if (!mounted) return;
        setState(() => _nodes = (jsonDecode(d) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('knowledge_graph_nodes', jsonEncode(_nodes));
  }

  void _addNode(String type) {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final tags = _tagCtrl.text.trim().split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final nodeType = _nodeTypes.firstWhere((n) => n['type'] == type);
    setState(() {
      _nodes.insert(0, {
        'text': text,
        'type': type,
        'emoji': nodeType['emoji'],
        'color': nodeType['color'],
        'tags': tags,
        'links': <String>[],
        'time': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    });
    _ctrl.clear();
    _tagCtrl.clear();
    _save();
  }

  Set<String> get _allTags {
    final tags = <String>{'all'};
    for (final n in _nodes) {
      for (final t in (n['tags'] as List? ?? [])) {
        tags.add(t.toString());
      }
    }
    return tags;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedTag == 'all') return _nodes;
    return _nodes.where((n) => (n['tags'] as List? ?? []).contains(_selectedTag)).toList();
  }

  

  @override
  void dispose() {
    _ctrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'KNOWLEDGE GRAPH',
      subtitle: 'Link ideas, chats, projects, bugs, and solutions together',
      onBack: () => Navigator.pop(context),
      content: Column(children: [
        // Stats bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.deepPurpleAccent.withValues(alpha: 0.08), Colors.cyanAccent.withValues(alpha: 0.04)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('🧠', '${_nodes.length}', 'Nodes'),
            _stat('🔗', '${_allTags.length - 1}', 'Tags'),
            _stat('💡', '${_nodes.where((n) => n['type'] == 'idea').length}', 'Ideas'),
            _stat('🐛', '${_nodes.where((n) => n['type'] == 'bug').length}', 'Bugs'),
          ]),
        ),

        // Tag filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _allTags.map((tag) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(tag, style: GoogleFonts.outfit(color: _selectedTag == tag ? Colors.black : Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                selected: _selectedTag == tag,
                selectedColor: Colors.cyanAccent,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                onSelected: (_) => setState(() => _selectedTag = tag),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Nodes list
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🧠', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 6),
                  Text('Your knowledge graph is empty', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13)),
                  Text('Add ideas, bugs, notes & link them together', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final n = _filtered[i];
                    final c = Color(n['color'] as int);
                    return Dismissible(
                      key: Key(n['id'] ?? '$i'),
                      onDismissed: (_) { setState(() => _nodes.removeWhere((nd) => nd['id'] == n['id'])); _save(); },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.withValues(alpha: 0.2)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(n['emoji'] ?? '📝', style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(n['text'], style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600))),
                            Text(n['type'].toString().toUpperCase(), style: GoogleFonts.outfit(color: c, fontSize: 9, fontWeight: FontWeight.w800)),
                          ]),
                          if ((n['tags'] as List?)?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 4),
                            Wrap(spacing: 4, children: (n['tags'] as List).map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text('#$t', style: GoogleFonts.outfit(color: c.withValues(alpha: 0.7), fontSize: 9)),
                            )).toList()),
                          ],
                        ]),
                      ),
                    );
                  },
                ),
        ),

        // Input area
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            TextField(
              controller: _ctrl,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              cursorColor: Colors.deepPurpleAccent,
              decoration: InputDecoration(hintText: 'Add to your knowledge graph...', hintStyle: GoogleFonts.outfit(color: Colors.white24), border: InputBorder.none, isDense: true),
            ),
            TextField(
              controller: _tagCtrl,
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
              cursorColor: Colors.cyanAccent,
              decoration: InputDecoration(hintText: 'Tags: startup, api, flutter (comma separated)', hintStyle: GoogleFonts.outfit(color: Colors.white12, fontSize: 10), border: InputBorder.none, isDense: true),
            ),
            const SizedBox(height: 6),
            Row(children: _nodeTypes.map((nt) => Expanded(
              child: GestureDetector(
                onTap: () => _addNode(nt['type']?.toString() ?? ''),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(nt['color'] as int).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: Text('${nt['emoji']}', style: const TextStyle(fontSize: 16))),
                ),
              ),
            )).toList()),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String emoji, String val, String label) {
    return Column(children: [
      Text('$emoji $val', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
      Text(label, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
    ]);
  }
}



