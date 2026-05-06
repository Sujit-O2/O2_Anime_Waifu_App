import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';


/// Gratitude Journal — Firestore: gratitude/{uid}
class GratitudeJournalPage extends StatefulWidget {
  const GratitudeJournalPage({super.key});
  @override
  State<GratitudeJournalPage> createState() => _GratitudeJournalPageState();
}

class _GratitudeJournalPageState extends State<GratitudeJournalPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  late AnimationController _fadeCtrl;
  String? get _uid => _auth.currentUser?.uid;

  // Prompts to inspire
  static const _prompts = [
    'What made you smile today?',
    'Who are you grateful for?',
    'What\'s something small that brought you joy?',
    'What\'s a challenge you overcame?',
    'What beauty did you notice today?',
    'What are you thankful for about yourself?',
    'What moment would you relive today?',
    'What simple pleasure are you grateful for?',
  ];
  int _promptIdx = 0;
  int get _weeklyEntries => _entries.where((entry) {
        final time = entry['time'] as int? ?? 0;
        return DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(time))
                .inDays <
            7;
      }).length;

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('gratitude_journal'));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _load();
    _promptIdx = DateTime.now().day % _prompts.length;
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_uid != null) {
      try {
        final doc = await _db.collection('gratitude').doc(_uid).get();
        if (doc.exists) {
          final raw = doc.data()?['entries'] as String?;
          if (raw != null) {
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
      _entries = (jsonDecode(p.getString('gratitude') ?? '[]') as List)
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
    (await SharedPreferences.getInstance()).setString('gratitude', encoded);
    if (_uid != null) {
      try {
        await _db.collection('gratitude').doc(_uid).set(
            {'entries': encoded, 'updatedAt': FieldValue.serverTimestamp()});
      } catch (_) {}
    }
  }

  void _add() {
    if (_ctrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _entries.insert(0, {
        'text': _ctrl.text.trim(),
        'time': DateTime.now().millisecondsSinceEpoch,
        'prompt': _prompts[_promptIdx]
      });
      _promptIdx = (_promptIdx + 1) % _prompts.length;
    });
    _ctrl.clear();
    _sync();
    if (mounted) {
      showSuccessSnackbar(context, 'Gratitude entry saved.');
    }
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const m = [
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
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${m[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'GRATITUDE JOURNAL',
      subtitle: '${_entries.length} entries • streak: ${_calcStreak()} days 🔥',
      onBack: () => Navigator.pop(context),
      actions: [
        GestureDetector(
            onTap: _load,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 20),
            )),
      ],
      content: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
                GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily gratitude',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _entries.isEmpty
                                  ? 'Start your gratitude rhythm'
                                  : '${_calcStreak()} day gratitude streak',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _entries.isEmpty
                                  ? 'Save one small thankful moment and this journal will start building a calmer history for you.'
                                  : 'You added $_weeklyEntries entries in the last week. Small moments count just as much as the big ones.',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ProgressRing(
                        progress: (_calcStreak().clamp(0, 14)) / 14,
                        foreground: Colors.orangeAccent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🙏', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 6),
                            Text(
                              '${_calcStreak()}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Streak',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Entries',
                        value: '${_entries.length}',
                        icon: Icons.menu_book_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'This Week',
                        value: '$_weeklyEntries',
                        icon: Icons.calendar_view_week_rounded,
                        color: V2Theme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Streak',
                        value: '${_calcStreak()}d',
                        icon: Icons.local_fire_department_rounded,
                        color: V2Theme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Storage',
                        value: _uid == null ? 'Local' : 'Cloud',
                        icon: Icons.cloud_done_outlined,
                        color: Colors.lightGreenAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Daily prompt
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.orangeAccent.withValues(alpha: 0.07),
                border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY\'S PROMPT ✨',
                        style: GoogleFonts.outfit(
                            color: Colors.orangeAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(_prompts[_promptIdx],
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
          ),
          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              const Text('🙏', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _ctrl,
                      style:
                          GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      cursorColor: Colors.orangeAccent,
                      onSubmitted: (_) => _add(),
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                          hintText: 'I\'m grateful for…',
                          hintStyle: GoogleFonts.outfit(
                              color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.orangeAccent
                                      .withValues(alpha: 0.2))),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)))),
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: _add,
                  child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  Colors.orangeAccent.withValues(alpha: 0.4))),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.orangeAccent, size: 20))),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.orangeAccent))
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const Text('🙏', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Start your gratitude streak~',
                                style:
                                    GoogleFonts.outfit(color: Colors.white38))
                          ]))
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
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.12)),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent)),
                              onDismissed: (_) {
                                setState(() => _entries.removeAt(i));
                                _sync();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.orangeAccent
                                      .withValues(alpha: 0.04),
                                  border: Border.all(
                                      color: Colors.orangeAccent
                                          .withValues(alpha: 0.12)),
                                ),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('🙏',
                                          style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(e['text']?.toString() ?? '',
                                                style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    height: 1.5)),
                                            const SizedBox(height: 4),
                                            Text(_date(e['time'] as int),
                                                style: GoogleFonts.outfit(
                                                    color: Colors.white24,
                                                    fontSize: 10)),
                                          ])),
                                    ]),
                              ),
                            );
                          },
                        ),
                      ),
        ),
      ]),
    );
  }

  int _calcStreak() {
    if (_entries.isEmpty) return 0;
    int streak = 1;
    final now = DateTime.now();
    for (int i = 0; i < _entries.length - 1; i++) {
      final d = DateTime.fromMillisecondsSinceEpoch(_entries[i]['time'] as int);
      final prev =
          DateTime.fromMillisecondsSinceEpoch(_entries[i + 1]['time'] as int);
      if (now.difference(d).inDays > 1 && i == 0) return 0;
      if (d.difference(prev).inDays <= 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}



