import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/waifu_background.dart';

/// Mood Tracker — saves mood entries to Firestore + local cache
/// Firestore: mood/{uid} → { entries: "[{...}]", updatedAt: Timestamp }
class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});
  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _noteCtrl = TextEditingController();
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  int _selectedMood = -1;
  late AnimationController _fadeCtrl;

  static const _moods = [
    {'emoji': '😄', 'label': 'Happy', 'color': 0xFF4CAF50},
    {'emoji': '😊', 'label': 'Good', 'color': 0xFF8BC34A},
    {'emoji': '😐', 'label': 'Meh', 'color': 0xFFFFEB3B},
    {'emoji': '😢', 'label': 'Sad', 'color': 0xFF2196F3},
    {'emoji': '😠', 'label': 'Angry', 'color': 0xFFF44336},
    {'emoji': '😴', 'label': 'Tired', 'color': 0xFF9C27B0},
  ];

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _loadEntries();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    // Try Firestore first
    if (_uid != null) {
      try {
        final doc = await _db.collection('mood').doc(_uid).get();
        if (doc.exists) {
          final raw = doc.data()?['entries'] as String?;
          if (raw != null && raw.isNotEmpty) {
            final decoded = jsonDecode(raw) as List;
            _entries =
                decoded.map((e) => Map<String, dynamic>.from(e)).toList();
            _entries
                .sort((a, b) => (b['time'] as int).compareTo(a['time'] as int));
            if (mounted) {
              setState(() => _loading = false);
              _fadeCtrl.forward();
            }
            return;
          }
        }
      } catch (_) {}
    }
    // Fallback: local cache
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mood_entries') ?? '[]';
    try {
      final decoded = jsonDecode(raw) as List;
      _entries = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      _entries.sort((a, b) => (b['time'] as int).compareTo(a['time'] as int));
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _saveEntry() async {
    if (_selectedMood < 0) return;
    HapticFeedback.mediumImpact();
    final mood = _moods[_selectedMood];
    final entry = {
      'emoji': mood['emoji'],
      'label': mood['label'],
      'note': _noteCtrl.text.trim(),
      'time': DateTime.now().millisecondsSinceEpoch,
    };
    final updated = [entry, ..._entries];
    setState(() {
      _entries = updated;
      _selectedMood = -1;
    });
    _noteCtrl.clear();

    final encoded = jsonEncode(updated);
    // Save local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mood_entries', encoded);
    // Save Firestore
    if (_uid != null) {
      try {
        await _db.collection('mood').doc(_uid).set({
          'entries': encoded,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
    _snack('Mood saved~ 💕');
  }

  Future<void> _deleteEntry(int idx) async {
    final updated = [..._entries]..removeAt(idx);
    setState(() => _entries = updated);
    final encoded = jsonEncode(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mood_entries', encoded);
    if (_uid != null) {
      try {
        await _db.collection('mood').doc(_uid).set({
          'entries': encoded,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.outfit(
              color: Colors.black87, fontWeight: FontWeight.w700)),
      backgroundColor: Colors.greenAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _timeAgo(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF0A0B14),
        child: SafeArea(
            child: Column(children: [
          // Header
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
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white60, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MOOD TRACKER',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      Text('${_entries.length} entries synced to cloud',
                          style: GoogleFonts.outfit(
                              color: Colors.greenAccent.withOpacity(0.6),
                              fontSize: 10)),
                    ]),
              ),
              GestureDetector(
                onTap: _loadEntries,
                child: const Icon(Icons.refresh_rounded,
                    color: Colors.white38, size: 20),
              ),
            ]),
          ),

          // Mood selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('How are you feeling?',
                  style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_moods.length, (i) {
                  final sel = _selectedMood == i;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMood = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 50,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: sel
                            ? Color(_moods[i]['color'] as int).withOpacity(0.2)
                            : Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color: sel
                              ? Color(_moods[i]['color'] as int)
                              : Colors.white12,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_moods[i]['emoji'] as String,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 2),
                            Text(_moods[i]['label'] as String,
                                style: GoogleFonts.outfit(
                                    color: sel
                                        ? Color(_moods[i]['color'] as int)
                                        : Colors.white38,
                                    fontSize: 8)),
                          ]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              // Note field
              TextField(
                controller: _noteCtrl,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                cursorColor: Colors.greenAccent,
                decoration: InputDecoration(
                  hintText: 'Add a note… (optional)',
                  hintStyle:
                      GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.greenAccent.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMood < 0 ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black87,
                    disabledBackgroundColor: Colors.white12,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Save Mood',
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),

          const Divider(color: Colors.white12, height: 24),

          // History
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.greenAccent))
                : _entries.isEmpty
                    ? Center(
                        child: Text('No moods tracked yet~',
                            style: GoogleFonts.outfit(color: Colors.white38)))
                    : FadeTransition(
                        opacity: _fadeCtrl,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _entries.length,
                          itemBuilder: (ctx, i) {
                            final e = _entries[i];
                            return Dismissible(
                              key: ValueKey(e['time']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.redAccent.withOpacity(0.15),
                                ),
                                child: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent),
                              ),
                              onDismissed: (_) => _deleteEntry(i),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.white.withOpacity(0.04),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.07)),
                                ),
                                child: Row(children: [
                                  Text(e['emoji'] as String,
                                      style: const TextStyle(fontSize: 28)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(e['label'] as String,
                                              style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700)),
                                          if ((e['note'] as String).isNotEmpty)
                                            Text(e['note'] as String,
                                                style: GoogleFonts.outfit(
                                                    color: Colors.white54,
                                                    fontSize: 12),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                        ]),
                                  ),
                                  Text(_timeAgo(e['time'] as int),
                                      style: GoogleFonts.outfit(
                                          color: Colors.white24, fontSize: 10)),
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
