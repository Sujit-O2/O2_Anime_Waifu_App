import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/waifu_background.dart';

/// Dream Journal — Firestore: dreams/{uid} → { entries: "[...]" }
class DreamJournalPage extends StatefulWidget {
  const DreamJournalPage({super.key});
  @override
  State<DreamJournalPage> createState() => _DreamJournalPageState();
}

class _DreamJournalPageState extends State<DreamJournalPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  late AnimationController _fadeCtrl;
  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_uid != null) {
      try {
        final doc = await _db.collection('dreams').doc(_uid).get();
        if (doc.exists) {
          final raw = doc.data()?['entries'] as String?;
          if (raw != null && raw.isNotEmpty) {
            _entries = (jsonDecode(raw) as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            if (mounted) {
              setState(() => _loading = false);
              _fadeCtrl.forward();
              return;
            }
          }
        }
      } catch (_) {}
    }
    final p = await SharedPreferences.getInstance();
    try {
      _entries = (jsonDecode(p.getString('dreams') ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _sync() async {
    final encoded = jsonEncode(_entries);
    final p = await SharedPreferences.getInstance();
    await p.setString('dreams', encoded);
    if (_uid != null) {
      try {
        await _db.collection('dreams').doc(_uid).set(
            {'entries': encoded, 'updatedAt': FieldValue.serverTimestamp()});
      } catch (_) {}
    }
  }

  void _addEntry() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String mood = '😴';
    final moods = ['😴', '😨', '😊', '🌟', '😱', '🌈', '🌀', '💜'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setBS) => Container(
                height: MediaQuery.of(ctx).size.height * 0.85,
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                decoration: const BoxDecoration(
                  color: Color(0xFF12101E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(children: [
                  Row(children: [
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38),
                        onPressed: () => Navigator.pop(ctx)),
                    Expanded(
                        child: Text('New Dream Entry',
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 13),
                            textAlign: TextAlign.center)),
                    IconButton(
                      icon: const Icon(Icons.check_rounded,
                          color: Colors.purpleAccent),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty &&
                            bodyCtrl.text.trim().isEmpty) { return; }
                        HapticFeedback.mediumImpact();
                        setState(() => _entries.insert(0, {
                              'title': titleCtrl.text.trim().isEmpty
                                  ? 'Untitled Dream'
                                  : titleCtrl.text.trim(),
                              'body': bodyCtrl.text.trim(),
                              'mood': mood,
                              'time': DateTime.now().millisecondsSinceEpoch,
                            }));
                        _sync();
                        Navigator.pop(ctx);
                      },
                    ),
                  ]),
                  // Mood picker
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                        children: moods
                            .map((m) => GestureDetector(
                                  onTap: () => setBS(() => mood = m),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 36,
                                    height: 36,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: mood == m
                                            ? Colors.purpleAccent
                                                .withOpacity(0.2)
                                            : Colors.white.withOpacity(0.04),
                                        border: Border.all(
                                            color: mood == m
                                                ? Colors.purpleAccent
                                                : Colors.white12)),
                                    child: Center(
                                        child: Text(m,
                                            style:
                                                const TextStyle(fontSize: 18))),
                                  ),
                                ))
                            .toList()),
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                        controller: titleCtrl,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        cursorColor: Colors.purpleAccent,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Dream title…',
                            hintStyle: GoogleFonts.outfit(
                                color: Colors.white24, fontSize: 17))),
                  ),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                        controller: bodyCtrl,
                        maxLines: null,
                        expands: true,
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 14, height: 1.6),
                        cursorColor: Colors.purpleAccent,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Describe your dream…',
                            hintStyle:
                                GoogleFonts.outfit(color: Colors.white24))),
                  )),
                ]),
              )),
    );
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF080814),
        child: SafeArea(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white60, size: 16))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('DREAM JOURNAL',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    Text('${_entries.length} dreams logged ✨',
                        style: GoogleFonts.outfit(
                            color: Colors.purpleAccent.withOpacity(0.6),
                            fontSize: 10)),
                  ])),
              GestureDetector(
                  onTap: _load,
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white38, size: 20)),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.purpleAccent))
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Text('🌙', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No dreams logged yet~',
                                style:
                                    GoogleFonts.outfit(color: Colors.white38)),
                            const SizedBox(height: 8),
                            Text('Tap + to write your first dream',
                                style: GoogleFonts.outfit(
                                    color: Colors.white24, fontSize: 12)),
                          ]))
                    : FadeTransition(
                        opacity: _fadeCtrl,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _entries.length,
                          itemBuilder: (ctx, i) {
                            final e = _entries[i];
                            return Dismissible(
                              key: ValueKey(e['time']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color:
                                          Colors.redAccent.withOpacity(0.12)),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent)),
                              onDismissed: (_) {
                                setState(() => _entries.removeAt(i));
                                _sync();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.purpleAccent.withOpacity(0.04),
                                  border: Border.all(
                                      color: Colors.purpleAccent
                                          .withOpacity(0.15)),
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text(e['mood'] as String,
                                            style:
                                                const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(e['title'] as String,
                                                style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                        Text(_date(e['time'] as int),
                                            style: GoogleFonts.outfit(
                                                color: Colors.white24,
                                                fontSize: 10)),
                                      ]),
                                      if ((e['body'] as String).isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(e['body'] as String,
                                            style: GoogleFonts.outfit(
                                                color: Colors.white54,
                                                fontSize: 12,
                                                height: 1.5),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ])),
      ),
    );
  }
}
