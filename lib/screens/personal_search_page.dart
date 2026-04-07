import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Personal Search Engine — Search across ALL your data: notes, thoughts, goals, errors, knowledge.
class PersonalSearchPage extends StatefulWidget {
  const PersonalSearchPage({super.key});
  @override
  State<PersonalSearchPage> createState() => _PersonalSearchPageState();
}

class _PersonalSearchPageState extends State<PersonalSearchPage> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String _query = '';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() { _searching = true; _query = query.toLowerCase(); });
    final prefs = await SharedPreferences.getInstance();
    final results = <Map<String, dynamic>>[];

    // Search Second Brain notes
    final brainData = prefs.getString('second_brain_notes');
    if (brainData != null) {
      for (final note in (jsonDecode(brainData) as List).cast<Map<String, dynamic>>()) {
        if ((note['title'] ?? '').toString().toLowerCase().contains(_query) ||
            (note['content'] ?? '').toString().toLowerCase().contains(_query)) {
          results.add({'source': '🧠 Second Brain', 'title': note['title'] ?? '', 'preview': _preview(note['content'] ?? ''), 'time': note['time'], 'color': 0xFF4FC3F7});
        }
      }
    }

    // Search Thought Capture
    final thoughtData = prefs.getString('thought_capture');
    if (thoughtData != null) {
      for (final t in (jsonDecode(thoughtData) as List).cast<Map<String, dynamic>>()) {
        if ((t['text'] ?? '').toString().toLowerCase().contains(_query)) {
          results.add({'source': '💭 Thought', 'title': t['text'] ?? '', 'preview': 'Tag: ${t['tag'] ?? 'none'}', 'time': t['time'], 'color': 0xFFCE93D8});
        }
      }
    }

    // Search Error Memory
    final errorData = prefs.getString('error_memory_entries');
    if (errorData != null) {
      for (final e in (jsonDecode(errorData) as List).cast<Map<String, dynamic>>()) {
        if ((e['error'] ?? '').toString().toLowerCase().contains(_query) ||
            (e['solution'] ?? '').toString().toLowerCase().contains(_query)) {
          results.add({'source': '🐛 Error Memory', 'title': _preview(e['error'] ?? ''), 'preview': '💡 ${_preview(e['solution'] ?? 'No solution')}', 'time': e['time'], 'color': 0xFFFF5252});
        }
      }
    }

    // Search Knowledge Graph
    final kgData = prefs.getString('knowledge_graph_data');
    if (kgData != null) {
      final decoded = jsonDecode(kgData) as Map<String, dynamic>;
      final nodes = (decoded['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final n in nodes) {
        if ((n['label'] ?? '').toString().toLowerCase().contains(_query)) {
          results.add({'source': '🔗 Knowledge', 'title': n['label'] ?? '', 'preview': 'Type: ${n['type'] ?? 'concept'}', 'time': DateTime.now().toIso8601String(), 'color': 0xFFFFD700});
        }
      }
    }

    // Search Memory Stack (Short-term chat history)
    final memStack = prefs.getString('memory_stack_data');
    if (memStack != null) {
      final decoded = jsonDecode(memStack) as Map<String, dynamic>;
      final short = (decoded['short'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final m in short) {
        if ((m['text'] ?? '').toString().toLowerCase().contains(_query)) {
          results.add({'source': '🧠 Short-Term', 'title': _preview(m['text'] ?? ''), 'preview': 'Importance: ${m['importance'] ?? 'low'}', 'time': m['time'], 'color': 0xFF4CAF50});
        }
      }
    }

    // Search Goals
    final goalData = prefs.getString('goal_tracker_goals');
    if (goalData != null) {
      for (final g in (jsonDecode(goalData) as List).cast<Map<String, dynamic>>()) {
        if ((g['title'] ?? '').toString().toLowerCase().contains(_query)) {
          results.add({'source': '🎯 Goal', 'title': g['title'] ?? '', 'preview': 'Progress: ${g['progress'] ?? 0}%', 'time': g['created'], 'color': 0xFFFFAB40});
        }
      }
    }

    // Search Digital Clone samples
    final cloneData = prefs.getString('digital_clone_samples');
    if (cloneData != null) {
      for (final s in (jsonDecode(cloneData) as List).cast<Map<String, dynamic>>()) {
        if ((s['input'] ?? '').toString().toLowerCase().contains(_query)) {
          results.add({'source': '🧬 Clone Data', 'title': s['input'] ?? '', 'preview': '', 'time': s['time'], 'color': 0xFF00BCD4});
        }
      }
    }

    setState(() { _searching = false; _results = results; });
  }

  String _preview(String text) => text.length > 80 ? '${text.substring(0, 80)}...' : text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('PERSONAL SEARCH', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Search input
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _ctrl,
              onChanged: _search,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              cursorColor: Colors.cyanAccent,
              decoration: InputDecoration(
                hintText: 'Search notes, ideas, errors, goals...',
                hintStyle: GoogleFonts.outfit(color: Colors.white24),
                border: InputBorder.none,
              ),
            )),
            if (_searching)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
          ]),
        ),

        // Results count
        if (_query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('${_results.length} results', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('across 6 data sources', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
            ]),
          ),

        // Results
        Expanded(
          child: _query.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🔍', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text('Your Personal Search Engine', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Search everything: notes, thoughts,\nerrors, goals, knowledge — all at once', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12)),
                ]))
              : _results.isEmpty
                  ? Center(child: Text('No results for "$_query"', style: GoogleFonts.outfit(color: Colors.white30)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final r = _results[i];
                        final c = Color(r['color'] as int);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.withValues(alpha: 0.15)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                child: Text(r['source'], style: GoogleFonts.outfit(color: c, fontSize: 9, fontWeight: FontWeight.w800)),
                              ),
                              const Spacer(),
                              if (r['time'] != null) Text(_formatTime(r['time']), style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
                            ]),
                            const SizedBox(height: 6),
                            Text(r['title'], style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                            if ((r['preview']?.toString() ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(r['preview'], style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                            ],
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  String _formatTime(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
