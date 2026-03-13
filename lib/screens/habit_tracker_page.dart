import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/waifu_background.dart';

/// Habit Tracker — saves habits to Firestore (habits/{uid}) + local cache
/// Uses a local-first approach with background Firestore sync
class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});
  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _habitCtrl = TextEditingController();
  List<Map<String, dynamic>> _habits = [];
  bool _loading = true;
  late AnimationController _fadeCtrl;
  String _todayKey = '';

  static final _emojiOptions = [
    '💪',
    '📖',
    '🧘',
    '🏃',
    '💧',
    '🎨',
    '🎵',
    '🌿',
    '😴',
    '🍎'
  ];

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    final now = DateTime.now();
    _todayKey = '${now.year}-${now.month}-${now.day}';
    _loadHabits();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _habitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    setState(() => _loading = true);
    if (_uid != null) {
      try {
        final doc = await _db.collection('habits').doc(_uid).get();
        if (doc.exists) {
          final raw = doc.data()?['habits'] as String?;
          if (raw != null && raw.isNotEmpty) {
            final decoded = jsonDecode(raw) as List;
            _habits = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
            if (mounted) {
              setState(() => _loading = false);
              _fadeCtrl.forward();
            }
            return;
          }
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('habits_data') ?? '[]';
    try {
      _habits = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _saveHabits() async {
    final encoded = jsonEncode(_habits);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('habits_data', encoded);
    if (_uid != null) {
      try {
        await _db.collection('habits').doc(_uid).set({
          'habits': encoded,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  void _addHabit() {
    final name = _habitCtrl.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _habits.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'emoji': _emojiOptions[_habits.length % _emojiOptions.length],
        'completedOn': <String>[],
        'streak': 0,
        'longStreak': 0,
      });
    });
    _habitCtrl.clear();
    _saveHabits();
  }

  void _toggleHabit(int idx) {
    HapticFeedback.selectionClick();
    final habit = Map<String, dynamic>.from(_habits[idx]);
    final completedOn = List<String>.from(habit['completedOn'] as List);
    final isCompleted = completedOn.contains(_todayKey);

    if (isCompleted) {
      completedOn.remove(_todayKey);
    } else {
      completedOn.add(_todayKey);
      HapticFeedback.heavyImpact();
    }
    habit['completedOn'] = completedOn;
    // Recalculate streak
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      if (completedOn.contains(key)) {
        streak++;
      } else {
        break;
      }
    }
    habit['streak'] = streak;
    if (streak > (habit['longStreak'] as int? ?? 0)) {
      habit['longStreak'] = streak;
    }
    setState(() => _habits[idx] = habit);
    _saveHabits();
  }

  void _deleteHabit(int idx) {
    setState(() => _habits.removeAt(idx));
    _saveHabits();
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
                      Text('HABIT TRACKER',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      Text(
                          '${_habits.where((h) => (h['completedOn'] as List).contains(_todayKey)).length}/${_habits.length} done today',
                          style: GoogleFonts.outfit(
                              color: Colors.lightGreenAccent.withOpacity(0.6),
                              fontSize: 10)),
                    ]),
              ),
              GestureDetector(
                  onTap: _loadHabits,
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white38, size: 20)),
            ]),
          ),

          // Today's progress bar
          if (_habits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _habits.isEmpty
                      ? 0
                      : _habits
                              .where((h) => (h['completedOn'] as List)
                                  .contains(_todayKey))
                              .length /
                          _habits.length,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.lightGreenAccent),
                  minHeight: 5,
                ),
              ),
            ),

          // Add habit
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _habitCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  cursorColor: Colors.lightGreenAccent,
                  onSubmitted: (_) => _addHabit(),
                  decoration: InputDecoration(
                    hintText: 'Add a new habit…',
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
                      borderSide: BorderSide(
                          color: Colors.lightGreenAccent.withOpacity(0.2)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addHabit,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.lightGreenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.lightGreenAccent.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.lightGreenAccent, size: 22),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // Habit list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.lightGreenAccent))
                : _habits.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Text('💪', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Add your first habit above!',
                                style:
                                    GoogleFonts.outfit(color: Colors.white38)),
                          ]))
                    : FadeTransition(
                        opacity: _fadeCtrl,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _habits.length,
                          itemBuilder: (ctx, i) {
                            final h = _habits[i];
                            final done =
                                (h['completedOn'] as List).contains(_todayKey);
                            final streak = h['streak'] as int? ?? 0;
                            return Dismissible(
                              key: ValueKey(h['id']),
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
                              onDismissed: (_) => _deleteHabit(i),
                              child: GestureDetector(
                                onTap: () => _toggleHabit(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: done
                                        ? Colors.lightGreenAccent
                                            .withOpacity(0.08)
                                        : Colors.white.withOpacity(0.04),
                                    border: Border.all(
                                      color: done
                                          ? Colors.lightGreenAccent
                                              .withOpacity(0.35)
                                          : Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(children: [
                                    // Emoji + check
                                    Stack(children: [
                                      Text(h['emoji'] as String,
                                          style: const TextStyle(fontSize: 28)),
                                      if (done)
                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.lightGreenAccent,
                                            ),
                                            child: const Icon(
                                                Icons.check_rounded,
                                                size: 10,
                                                color: Colors.black87),
                                          ),
                                        ),
                                    ]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(h['name'] as String,
                                                style: GoogleFonts.outfit(
                                                    color: done
                                                        ? Colors.white
                                                        : Colors.white70,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    decoration: done
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null)),
                                            if (streak > 0)
                                              Text('🔥 $streak day streak',
                                                  style: GoogleFonts.outfit(
                                                      color:
                                                          Colors.orangeAccent,
                                                      fontSize: 11)),
                                          ]),
                                    ),
                                    // Tap to complete
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: done
                                            ? Colors.lightGreenAccent
                                                .withOpacity(0.15)
                                            : Colors.white.withOpacity(0.05),
                                        border: Border.all(
                                          color: done
                                              ? Colors.lightGreenAccent
                                              : Colors.white24,
                                        ),
                                      ),
                                      child: Icon(
                                        done
                                            ? Icons.check_rounded
                                            : Icons
                                                .radio_button_unchecked_rounded,
                                        color: done
                                            ? Colors.lightGreenAccent
                                            : Colors.white38,
                                        size: 18,
                                      ),
                                    ),
                                  ]),
                                ),
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
