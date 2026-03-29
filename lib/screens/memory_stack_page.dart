import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/affection_service.dart';

/// Context Memory Stack — Multi-layer memory system like a real brain.
/// Short-term, long-term, emotional, and project memory.
class MemoryStackPage extends StatefulWidget {
  const MemoryStackPage({super.key});
  @override
  State<MemoryStackPage> createState() => _MemoryStackPageState();
}

class _MemoryStackPageState extends State<MemoryStackPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, List<Map<String, dynamic>>> _memories = {
    'short': [], 'long': [], 'emotional': [], 'project': [],
  };

  final _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('memory_stack_data');
    if (d != null) {
      final decoded = jsonDecode(d) as Map<String, dynamic>;
      setState(() {
        for (final key in ['short', 'long', 'emotional', 'project']) {
          _memories[key] = (decoded[key] as List?)?.cast<Map<String, dynamic>>() ?? [];
        }
      });
    }

    // Auto-populate emotional memory from affection
    if (_memories['emotional']!.isEmpty) {
      final pts = AffectionService.instance.points;
      final streak = AffectionService.instance.streakDays;
      setState(() {
        _memories['emotional'] = [
          {'text': 'Affection level: $pts points', 'time': DateTime.now().toIso8601String(), 'importance': 'high'},
          {'text': 'Current streak: $streak days', 'time': DateTime.now().toIso8601String(), 'importance': 'medium'},
        ];
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('memory_stack_data', jsonEncode(_memories));
  }

  void _addMemory(String layer) {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _memories[layer]!.insert(0, {
        'text': text,
        'time': DateTime.now().toIso8601String(),
        'importance': 'medium',
      });
      // Short-term auto-expires (keep only 20)
      if (layer == 'short' && _memories['short']!.length > 20) {
        _memories['short'] = _memories['short']!.sublist(0, 20);
      }
    });
    _addCtrl.clear();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final layers = [
      {'key': 'short', 'name': 'Short-Term', 'emoji': '⚡', 'color': Colors.amberAccent, 'desc': 'Temporary context (auto-expires)'},
      {'key': 'long', 'name': 'Long-Term', 'emoji': '🧠', 'color': Colors.cyanAccent, 'desc': 'Permanent core memories'},
      {'key': 'emotional', 'name': 'Emotional', 'emoji': '💖', 'color': Colors.pinkAccent, 'desc': 'Feelings, bonds, attachments'},
      {'key': 'project', 'name': 'Project', 'emoji': '📁', 'color': Colors.greenAccent, 'desc': 'Active project context'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('MEMORY STACK', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: Colors.cyanAccent,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 11),
          tabs: layers.map((l) => Tab(text: '${l['emoji']} ${l['name']}')).toList(),
        ),
      ),
      body: Column(children: [
        // Stats
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.deepPurpleAccent.withValues(alpha: 0.08), Colors.transparent]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: layers.map((l) {
            final c = l['color'] as Color;
            return Column(children: [
              Text('${l['emoji']}', style: const TextStyle(fontSize: 18)),
              Text('${_memories[l['key'] as String]?.length ?? 0}', style: GoogleFonts.outfit(color: c, fontSize: 16, fontWeight: FontWeight.w900)),
              Text(l['name'] as String, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
            ]);
          }).toList()),
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: layers.map((l) {
              final key = l['key'] as String;
              final c = l['color'] as Color;
              final items = _memories[key] ?? [];
              return items.isEmpty
                  ? Center(child: Text('No ${l['name']} memories yet', style: GoogleFonts.outfit(color: Colors.white30)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final m = items[i];
                        final t = DateTime.tryParse(m['time'] ?? '');
                        return Dismissible(
                          key: Key('$key-$i-${m['time']}'),
                          onDismissed: (_) { setState(() => _memories[key]!.removeAt(i)); _save(); },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.withValues(alpha: 0.12)),
                            ),
                            child: Row(children: [
                              Container(width: 4, height: 30, decoration: BoxDecoration(color: c.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 10),
                              Expanded(child: Text(m['text'] ?? '', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))),
                              if (t != null) Text('${t.hour}:${t.minute.toString().padLeft(2, '0')}', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                            ]),
                          ),
                        );
                      },
                    );
            }).toList(),
          ),
        ),

        // Add memory input
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _addCtrl,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              cursorColor: Colors.cyanAccent,
              decoration: InputDecoration(hintText: 'Add to ${layers[_tabCtrl.index]['name']} memory...', hintStyle: GoogleFonts.outfit(color: Colors.white24), border: InputBorder.none),
            )),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Colors.cyanAccent),
              onPressed: () => _addMemory(layers[_tabCtrl.index]['key'] as String),
            ),
          ]),
        ),
      ]),
    );
  }
}
