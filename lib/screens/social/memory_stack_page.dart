import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/widgets/waifu_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

/// Memory Stack v2 — Multi-layer memory system with animated cards,
/// search, and Zero Two context.
class MemoryStackPage extends StatefulWidget {
  const MemoryStackPage({super.key});
  @override
  State<MemoryStackPage> createState() => _MemoryStackPageState();
}

class _MemoryStackPageState extends State<MemoryStackPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late TabController _tabCtrl;
  final Map<String, List<Map<String, dynamic>>> _memories = {
    'short': [],
    'long': [],
    'emotional': [],
    'project': [],
  };
  String _searchQuery = '';
  final _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('memory_stack'));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _tabCtrl.dispose();
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('memory_stack_data');
    if (d != null) {
      final decoded = jsonDecode(d) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        for (final key in ['short', 'long', 'emotional', 'project']) {
          _memories[key] =
              (decoded[key] as List?)?.cast<Map<String, dynamic>>() ?? [];
        }
      });
    }
    if (_memories['emotional']!.isEmpty) {
      final pts = AffectionService.instance.points;
      final streak = AffectionService.instance.streakDays;
      setState(() {
        _memories['emotional'] = [
          {
            'text': 'Affection level: $pts points',
            'time': DateTime.now().toIso8601String(),
            'importance': 'high'
          },
          {
            'text': 'Current streak: $streak days',
            'time': DateTime.now().toIso8601String(),
            'importance': 'medium'
          },
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
    HapticFeedback.lightImpact();
    setState(() {
      _memories[layer]!.insert(0, {
        'text': text,
        'time': DateTime.now().toIso8601String(),
        'importance': 'medium'
      });
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
      {
        'key': 'short',
        'name': 'Short-Term',
        'emoji': '⚡',
        'color': Colors.amberAccent,
        'desc': 'Temporary context'
      },
      {
        'key': 'long',
        'name': 'Long-Term',
        'emoji': '🧠',
        'color': Colors.cyanAccent,
        'desc': 'Permanent memories'
      },
      {
        'key': 'emotional',
        'name': 'Emotional',
        'emoji': '💖',
        'color': Colors.pinkAccent,
        'desc': 'Feelings & bonds'
      },
      {
        'key': 'project',
        'name': 'Project',
        'emoji': '📁',
        'color': Colors.greenAccent,
        'desc': 'Active projects'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: WaifuBackground(
        opacity: 0.07,
        tint: const Color(0xFF080C18),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Column(children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12)),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white60, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('MEMORY STACK',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        Text('Multi-layer memory system',
                            style: GoogleFonts.outfit(
                                color: Colors.cyanAccent.withValues(alpha: 0.7),
                                fontSize: 10)),
                      ])),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.16),
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                    cursorColor: Colors.cyanAccent,
                    decoration: InputDecoration(
                      hintText: 'Search across memory layers...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white24),
                      border: InputBorder.none,
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white38,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Tab Bar ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14)),
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  indicatorColor: Colors.cyanAccent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800, fontSize: 11),
                  unselectedLabelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500, fontSize: 11),
                  labelColor: Colors.cyanAccent,
                  unselectedLabelColor: Colors.white38,
                  dividerColor: Colors.transparent,
                  tabs: layers
                      .map((l) => Tab(text: '${l['emoji']} ${l['name']}'))
                      .toList(),
                ),
              ),

              // ── Stats ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.deepPurpleAccent.withValues(alpha: 0.06),
                    Colors.transparent
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: layers.map((l) {
                      final c = l['color'] as Color;
                      return Column(children: [
                        Text('${l['emoji']}',
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                            '${_memories[l['key']?.toString() ?? '']?.length ?? 0}',
                            style: GoogleFonts.outfit(
                                color: c,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                        Text(l['name']?.toString() ?? '',
                            style: GoogleFonts.outfit(
                                color: Colors.white30, fontSize: 9)),
                      ]);
                    }).toList()),
              ),

              // ── Tab Views ──
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: layers.map((l) {
                    final key = l['key']?.toString() ?? '';
                    final c = l['color'] as Color;
                    final items = (_memories[key] ?? []).where((m) {
                      if (_searchQuery.isEmpty) return true;
                      return (m['text']?.toString() ?? '')
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                    }).toList();
                    return items.isEmpty
                        ? Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Text('${l['emoji']}',
                                    style: const TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text('No ${l['name']} memories yet',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white30, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Add one below~',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white24, fontSize: 12)),
                              ]))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: items.length,
                            itemBuilder: (_, i) =>
                                _buildMemoryCard(i, key, items[i], c),
                          );
                  }).toList(),
                ),
              ),

              // ── Add Memory Input ──
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                    controller: _addCtrl,
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                    cursorColor: Colors.cyanAccent,
                    decoration: InputDecoration(
                        hintText:
                            'Add to ${layers[_tabCtrl.index]['name']} memory...',
                        hintStyle: GoogleFonts.outfit(color: Colors.white24),
                        border: InputBorder.none),
                  )),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded,
                        color: Colors.cyanAccent, size: 28),
                    onPressed: () => _addMemory(
                        layers[_tabCtrl.index]['key']?.toString() ?? ''),
                  ),
                ]),
              ),

              // ── Waifu Card ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.pinkAccent.withValues(alpha: 0.06),
                  border: Border.all(
                      color: Colors.pinkAccent.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Text('💕', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                    '"My memory layers are growing, Darling~ Every moment with you gets saved~"',
                    style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.5),
                  )),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryCard(
      int index, String key, Map<String, dynamic> m, Color c) {
    final t = DateTime.tryParse(m['time'] ?? '');
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Dismissible(
        key: Key('$key-$index-${m['time']}'),
        onDismissed: (_) {
          HapticFeedback.lightImpact();
          setState(() => _memories[key]!.remove(m));
          _save();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withValues(alpha: 0.12)),
          ),
          child: Row(children: [
            Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(
                child: Text(m['text'] ?? '',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 13))),
            if (t != null)
              Text('${t.hour}:${t.minute.toString().padLeft(2, '0')}',
                  style:
                      GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}



