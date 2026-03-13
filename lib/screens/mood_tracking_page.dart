import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

/// 7-day mood tracking with Zero Two's daily emotional check-in — Firebase synced.
class MoodTrackingPage extends StatefulWidget {
  const MoodTrackingPage({super.key});

  @override
  State<MoodTrackingPage> createState() => _MoodTrackingPageState();
}

class _MoodTrackingPageState extends State<MoodTrackingPage> {
  List<_MoodEntry> _entries = [];
  int _selectedMood = -1;
  bool _loading = true;

  final _moods = [
    {'emoji': '😄', 'label': 'Happy', 'color': Colors.yellowAccent},
    {'emoji': '😊', 'label': 'Good', 'color': Colors.greenAccent},
    {'emoji': '😐', 'label': 'Neutral', 'color': Colors.blueAccent},
    {'emoji': '😔', 'label': 'Sad', 'color': Colors.indigoAccent},
    {'emoji': '😤', 'label': 'Angry', 'color': Colors.redAccent},
  ];

  final _thoughts = TextEditingController();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';
  CollectionReference get _col =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('moodEntries');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _thoughts.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final snap = await _col.orderBy('date', descending: true).limit(30).get();
      if (mounted) {
        setState(() {
          _entries = snap.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return _MoodEntry(
              id: d.id,
              date: (data['date'] as Timestamp).toDate(),
              moodIndex: data['moodIndex'] as int,
              emoji: data['emoji'] as String,
              label: data['label'] as String,
              note: data['note'] as String? ?? '',
            );
          }).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logMood() async {
    if (_selectedMood < 0) return;
    final doc = _col.doc();
    final entry = _MoodEntry(
      id: doc.id,
      date: DateTime.now(),
      moodIndex: _selectedMood,
      emoji: _moods[_selectedMood]['emoji'] as String,
      label: _moods[_selectedMood]['label'] as String,
      note: _thoughts.text.trim(),
    );
    setState(() {
      _entries.insert(0, entry);
      _selectedMood = -1;
      _thoughts.clear();
    });
    try {
      await doc.set({
        'date': Timestamp.fromDate(entry.date),
        'moodIndex': entry.moodIndex,
        'emoji': entry.emoji,
        'label': entry.label,
        'note': entry.note,
      });
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mood logged! 💕', style: GoogleFonts.outfit()),
          backgroundColor: Colors.pinkAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteEntry(String id, int index) async {
    setState(() => _entries.removeAt(index));
    try {
      await _col.doc(id).delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayEntries = _entries.where((e) =>
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day).toList();

    final last7 = _entries.take(7).toList();
    final avgMood = last7.isEmpty ? 2.0 : last7.fold<double>(0, (s, e) => s + e.moodIndex) / last7.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0613),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mood Tracker',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.pinkAccent, strokeWidth: 2)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF6C1B7A), Color(0xFF1A0D2E)],
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('How are you feeling today? 💕',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                last7.isEmpty ? 'No data yet — log your first mood!' :
                avgMood < 1.5 ? 'You\'ve been really happy lately~ 😄'
                : avgMood < 2.5 ? 'You seem to be doing well 😊'
                : avgMood < 3.5 ? 'Feeling neutral this week 😐'
                : 'You seem a bit down. I\'m here for you 💕',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          // Mood selector
          Text('Select your mood:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_moods.length, (i) {
              final mood = _moods[i];
              final isSelected = _selectedMood == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (mood['color'] as Color).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? mood['color'] as Color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(children: [
                    Text(mood['emoji'] as String, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(mood['label'] as String,
                        style: GoogleFonts.outfit(
                            color: isSelected ? mood['color'] as Color : Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Note field
          TextField(
            controller: _thoughts,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'What\'s on your mind? (optional)',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _selectedMood >= 0 ? _logMood : null,
              child: Text('Log Mood 💕', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          if (todayEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Already logged today: ${todayEntries.map((e) => e.emoji).join(' ')}',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          // 7-day mood graph
          if (last7.isNotEmpty) ...[
            Text('📊 7-Day Mood Trend',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: last7.reversed.map((e) {
                  final normalHeight = ((4 - e.moodIndex) / 4 * 50 + 10).toDouble();
                  final c = _moods[e.moodIndex]['color'] as Color;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(e.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 2),
                        Container(
                          height: max(10, normalHeight),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Recent entries
          if (_entries.isNotEmpty) ...[
            Text('📝 Recent Logs',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ..._entries.take(10).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return Dismissible(
                key: Key(e.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteEntry(e.id, i),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(children: [
                    Text(e.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.label,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        if (e.note.isNotEmpty)
                          Text(e.note, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                      ],
                    )),
                    Text(
                      '${e.date.day}/${e.date.month} ${e.date.hour.toString().padLeft(2,'0')}:${e.date.minute.toString().padLeft(2,'0')}',
                      style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10),
                    ),
                  ]),
                ),
              );
            }),
          ],
        ]),
      ),
    );
  }
}

class _MoodEntry {
  final String id;
  final DateTime date;
  final int moodIndex;
  final String emoji;
  final String label;
  final String note;

  const _MoodEntry({
    required this.id,
    required this.date,
    required this.moodIndex,
    required this.emoji,
    required this.label,
    required this.note,
  });
}
