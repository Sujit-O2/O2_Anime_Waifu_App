import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/affection_service.dart';

class GlobalQuestBoardPage extends StatefulWidget {
  const GlobalQuestBoardPage({super.key});
  @override
  State<GlobalQuestBoardPage> createState() => _GlobalQuestBoardPageState();
}

class _GlobalQuestBoardPageState extends State<GlobalQuestBoardPage> {
  List<Map<String, dynamic>> _globalQuests = [];
  List<String> _completedIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _completedIds = prefs.getStringList('global_quests_done') ?? [];

      // Create default global quests if none
      final snap = await FirebaseFirestore.instance
          .collection('global_quests')
          .orderBy('createdAt', descending: false)
          .limit(20)
          .get();

      if (snap.docs.isEmpty) {
        await _seedDefaultQuests();
        setState(() => _loading = false);
        _load();
        return;
      }

      setState(() {
        _globalQuests = snap.docs.map((d) {
          final data = d.data();
          data['docId'] = d.id;
          return data;
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _seedDefaultQuests() async {
    final now = FieldValue.serverTimestamp();
    final quests = [
      {
        'title': '💬 Send 10 messages to Zero Two',
        'xp': 50,
        'icon': '💬',
        'type': 'social'
      },
      {
        'title': '🌸 Reach "Darling" level',
        'xp': 100,
        'icon': '🌸',
        'type': 'milestone'
      },
      {
        'title': '🔥 Maintain a 7-day streak',
        'xp': 70,
        'icon': '🔥',
        'type': 'streak'
      },
      {
        'title': '🎯 Complete 5 daily quests',
        'xp': 60,
        'icon': '🎯',
        'type': 'achievement'
      },
      {'title': '🎮 Play Truth or Dare', 'xp': 30, 'icon': '🎮', 'type': 'fun'},
      {
        'title': '📖 Record 3 dreams',
        'xp': 45,
        'icon': '📖',
        'type': 'journal'
      },
      {
        'title': '💕 Set your anniversary date',
        'xp': 25,
        'icon': '💕',
        'type': 'relationship'
      },
      {
        'title': '🏆 Unlock 5 achievements',
        'xp': 80,
        'icon': '🏆',
        'type': 'achievement'
      },
      {
        'title': '🌍 Use the Translator feature',
        'xp': 20,
        'icon': '🌍',
        'type': 'explore'
      },
      {
        'title': '✍️ Write an AI poem',
        'xp': 35,
        'icon': '✍️',
        'type': 'creative'
      },
    ];
    final batch = FirebaseFirestore.instance.batch();
    for (final q in quests) {
      final ref = FirebaseFirestore.instance.collection('global_quests').doc();
      batch.set(ref, {...q, 'createdAt': now, 'completions': 0});
    }
    await batch.commit();
  }

  Future<void> _complete(Map<String, dynamic> quest) async {
    final id = quest['docId'] as String;
    if (_completedIds.contains(id)) return;

    setState(() => _completedIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('global_quests_done', _completedIds);

    // Update global completion count
    try {
      await FirebaseFirestore.instance
          .collection('global_quests')
          .doc(id)
          .update({
        'completions': FieldValue.increment(1),
      });
      // Record this user completed it
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('quest_completions')
            .doc('${user.uid}_$id')
            .set({
          'uid': user.uid,
          'questId': id,
          'questTitle': quest['title'],
          'xp': quest['xp'],
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
      AffectionService.instance.addPoints((quest['xp'] as int?) ?? 30);
    } catch (_) {}

    if (mounted) {
      _snack('Quest complete! +${quest['xp']} XP 🎉');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: Colors.pinkAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final done = _completedIds.length;
    final total = _globalQuests.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('GLOBAL QUEST BOARD',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('$done/$total',
                  style: GoogleFonts.outfit(
                      color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : Column(children: [
              // Progress
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: _globalQuests.length,
                  itemBuilder: (ctx, i) {
                    final q = _globalQuests[i];
                    final id = q['docId'] as String;
                    final done = _completedIds.contains(id);
                    final completions = q['completions'] as int? ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: done
                            ? Colors.greenAccent.withValues(alpha: 0.07)
                            : Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                            color: done
                                ? Colors.greenAccent.withValues(alpha: 0.3)
                                : Colors.white12),
                      ),
                      child: Row(children: [
                        Text(q['icon'] as String? ?? '🎯',
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(q['title'] as String? ?? '',
                                    style: GoogleFonts.outfit(
                                        color: done
                                            ? Colors.white54
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        decoration: done
                                            ? TextDecoration.lineThrough
                                            : null)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Text('+${q['xp']} XP',
                                      style: GoogleFonts.outfit(
                                          color: Colors.pinkAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text('$completions completed globally',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white24, fontSize: 10)),
                                ]),
                              ]),
                        ),
                        const SizedBox(width: 8),
                        done
                            ? const Icon(Icons.check_circle_rounded,
                                color: Colors.greenAccent, size: 28)
                            : GestureDetector(
                                onTap: () => _complete(q),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.pinkAccent
                                        .withValues(alpha: 0.15),
                                    border: Border.all(
                                        color: Colors.pinkAccent
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text('Done',
                                      style: GoogleFonts.outfit(
                                          color: Colors.pinkAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                              ),
                      ]),
                    );
                  },
                ),
              ),
            ]),
    );
  }
}
