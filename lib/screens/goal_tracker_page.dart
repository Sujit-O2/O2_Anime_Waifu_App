import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/waifu_background.dart';

/// Goal Tracker — saves goals to Firestore (vault/{uid} goals field) + local cache
class GoalTrackerPage extends StatefulWidget {
  const GoalTrackerPage({super.key});
  @override
  State<GoalTrackerPage> createState() => _GoalTrackerPageState();
}

class _GoalTrackerPageState extends State<GoalTrackerPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _goalCtrl = TextEditingController();
  List<Map<String, dynamic>> _goals = [];
  bool _loading = true;
  late AnimationController _fadeCtrl;

  static const _categories = [
    '🌟 Personal',
    '💼 Career',
    '💪 Fitness',
    '📚 Learning',
    '❤️ Relationship',
    '💰 Finance'
  ];
  int _selectedCat = 0;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _loadGoals();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    if (_uid != null) {
      try {
        final doc = await _db.collection('goals').doc(_uid).get();
        if (doc.exists) {
          final raw = doc.data()?['goals'] as String?;
          if (raw != null && raw.isNotEmpty) {
            _goals = (jsonDecode(raw) as List)
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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('goals_data') ?? '[]';
    try {
      _goals = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _saveGoals() async {
    final encoded = jsonEncode(_goals);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goals_data', encoded);
    if (_uid != null) {
      try {
        await _db.collection('goals').doc(_uid).set({
          'goals': encoded,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  void _addGoal() {
    final name = _goalCtrl.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _goals.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': name,
        'category': _categories[_selectedCat],
        'progress': 0, // 0-100
        'done': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
    _goalCtrl.clear();
    _saveGoals();
  }

  void _updateProgress(int idx, int progress) {
    HapticFeedback.selectionClick();
    setState(() {
      _goals[idx]['progress'] = progress;
      _goals[idx]['done'] = progress >= 100;
    });
    _saveGoals();
    if (progress >= 100) HapticFeedback.heavyImpact();
  }

  void _deleteGoal(int idx) {
    setState(() => _goals.removeAt(idx));
    _saveGoals();
  }

  static const _catColors = {
    '🌟 Personal': Colors.amberAccent,
    '💼 Career': Colors.blueAccent,
    '💪 Fitness': Colors.greenAccent,
    '📚 Learning': Colors.purpleAccent,
    '❤️ Relationship': Colors.pinkAccent,
    '💰 Finance': Colors.tealAccent,
  };

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
                      Text('GOAL TRACKER',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      Text(
                          '${_goals.where((g) => g['done'] == true).length}/${_goals.length} goals achieved',
                          style: GoogleFonts.outfit(
                              color: Colors.amberAccent.withOpacity(0.6),
                              fontSize: 10)),
                    ]),
              ),
              GestureDetector(
                  onTap: _loadGoals,
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white38, size: 20)),
            ]),
          ),

          // Add goal section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_categories.length, (i) {
                    final sel = _selectedCat == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCat = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: sel
                              ? Colors.amberAccent.withOpacity(0.15)
                              : Colors.white.withOpacity(0.04),
                          border: Border.all(
                              color: sel ? Colors.amberAccent : Colors.white12),
                        ),
                        child: Text(_categories[i],
                            style: GoogleFonts.outfit(
                                color:
                                    sel ? Colors.amberAccent : Colors.white38,
                                fontSize: 11)),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _goalCtrl,
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                    cursorColor: Colors.amberAccent,
                    onSubmitted: (_) => _addGoal(),
                    decoration: InputDecoration(
                      hintText: 'Add a goal…',
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.white30, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.amberAccent.withOpacity(0.2)),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addGoal,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.amberAccent.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.amberAccent, size: 22),
                  ),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 8),

          // Goals list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.amberAccent))
                : _goals.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Text('🌟', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Set your first goal above!',
                                style:
                                    GoogleFonts.outfit(color: Colors.white38)),
                          ]))
                    : FadeTransition(
                        opacity: _fadeCtrl,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _goals.length,
                          itemBuilder: (ctx, i) {
                            final g = _goals[i];
                            final progress = (g['progress'] as num).toInt();
                            final done = g['done'] == true;
                            final catColor =
                                _catColors[g['category'] as String] ??
                                    Colors.amberAccent;
                            return Dismissible(
                              key: ValueKey(g['id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.redAccent.withOpacity(0.15)),
                                child: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent),
                              ),
                              onDismissed: (_) => _deleteGoal(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: done
                                      ? catColor.withOpacity(0.08)
                                      : Colors.white.withOpacity(0.04),
                                  border: Border.all(
                                    color: done
                                        ? catColor.withOpacity(0.4)
                                        : Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: catColor.withOpacity(0.12),
                                            border: Border.all(
                                                color:
                                                    catColor.withOpacity(0.3)),
                                          ),
                                          child: Text(g['category'] as String,
                                              style: GoogleFonts.outfit(
                                                  color: catColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                        const Spacer(),
                                        if (done)
                                          const Icon(Icons.check_circle_rounded,
                                              color: Colors.greenAccent,
                                              size: 18),
                                      ]),
                                      const SizedBox(height: 8),
                                      Text(g['title'] as String,
                                          style: GoogleFonts.outfit(
                                              color: done
                                                  ? Colors.white70
                                                  : Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              decoration: done
                                                  ? TextDecoration.lineThrough
                                                  : null)),
                                      const SizedBox(height: 10),
                                      // Progress slider
                                      Row(children: [
                                        Text('$progress%',
                                            style: GoogleFonts.outfit(
                                                color: catColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderThemeData(
                                              activeTrackColor:
                                                  catColor.withOpacity(0.7),
                                              inactiveTrackColor: Colors.white
                                                  .withOpacity(0.08),
                                              thumbColor: catColor,
                                              overlayColor:
                                                  catColor.withOpacity(0.1),
                                              thumbShape:
                                                  const RoundSliderThumbShape(
                                                      enabledThumbRadius: 8),
                                              trackHeight: 4,
                                            ),
                                            child: Slider(
                                              value: progress.toDouble(),
                                              min: 0,
                                              max: 100,
                                              divisions: 10,
                                              onChanged: (v) =>
                                                  _updateProgress(i, v.round()),
                                            ),
                                          ),
                                        ),
                                      ]),
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
