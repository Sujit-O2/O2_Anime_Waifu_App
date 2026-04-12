import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class DreamInterpreterPage extends StatefulWidget {
  const DreamInterpreterPage({super.key});
  @override
  State<DreamInterpreterPage> createState() => _DreamInterpreterPageState();
}

class _DreamInterpreterPageState extends State<DreamInterpreterPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, String>> _history = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<void> _loadHistory() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('dreamInterpretations')
          .orderBy('ts', descending: true)
          .limit(20)
          .get();
      if (mounted) {
        setState(() {
          _history = snap.docs
              .map((d) => <String, String>{
                    'dream': d['dream']?.toString() ?? '',
                    'interpretation': d['interpretation']?.toString() ?? '',
                  })
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _interpret() async {
    final dream = _ctrl.text.trim();
    if (dream.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      final prompt =
          'You are Zero Two from Darling in the FranXX. Interpret the dream in a mystical, romantic, slightly teasing tone. Keep it under 120 words. Dream: "$dream"';
      final result = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt}
      ]);
      final entry = {'dream': dream, 'interpretation': result};
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('dreamInterpretations')
          .add({...entry, 'ts': FieldValue.serverTimestamp()});
      if (!mounted) return;
      setState(() {
        _history.insert(0, entry);
        _ctrl.clear();
      });
      showSuccessSnackbar(context, 'Dream reading saved.');
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              const Color(0xFF0E1023),
              V2Theme.surfaceDark,
              const Color(0xFF1A0F2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text('Dream Interpreter',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                const SizedBox(width: 44),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Dream archive',
                        style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Mystic readings with memory',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: StatCard(
                      title: 'Saved entries',
                      value: '${_history.length}',
                      icon: Icons.auto_stories_rounded,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Status',
                      value: _loading ? 'Reading' : 'Ready',
                      icon: _loading
                          ? Icons.hourglass_top_rounded
                          : Icons.auto_awesome_rounded,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: WaifuCommentary(
                mood: _history.length >= 5 ? 'achievement' : 'neutral',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: _ctrl,
                  maxLines: 3,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Describe your dream...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.deepPurpleAccent),
                            )
                          : GestureDetector(
                              onTap: _interpret,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _history.isEmpty
                  ? const EmptyState(
                      icon: Icons.nights_stay_rounded,
                      title: 'No dream readings yet',
                      subtitle:
                          'Describe a dream and Zero Two will craft a short mystical interpretation you can revisit later.',
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _history.length,
                      itemBuilder: (_, i) {
                        final e = _history[i];
                        return AnimatedEntry(
                          index: i,
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Dream',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white54,
                                        fontSize: 11,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(e['dream'] ?? '',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.4,
                                        fontStyle: FontStyle.italic)),
                                const Divider(color: Colors.white12, height: 20),
                                Text(e['interpretation'] ?? '',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.5)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}



