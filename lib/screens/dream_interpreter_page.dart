import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_waifu/api_call.dart';

class DreamInterpreterPage extends StatefulWidget {
  const DreamInterpreterPage({super.key});
  @override
  State<DreamInterpreterPage> createState() => _DreamInterpreterPageState();
}

class _DreamInterpreterPageState extends State<DreamInterpreterPage>
    with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, String>> _history = [];
  bool _loading = false;
  late AnimationController _starCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _loadHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _starCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<void> _loadHistory() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(_uid).collection('dreamInterpretations')
          .orderBy('ts', descending: true).limit(20).get();
      if (mounted) {
        setState(() {
          _history = snap.docs.map((d) => {
            'dream': d['dream'] as String,
            'interpretation': d['interpretation'] as String,
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _interpret() async {
    final dream = _ctrl.text.trim();
    if (dream.isEmpty) return;
    setState(() => _loading = true);
    try {
      final prompt =
          "You are Zero Two from Darling in the FranXX. The user just described their dream to you. Interpret it in a mystical, romantic, and slightly teasing way — speak as Zero Two would, with warmth and mischief. Keep it under 120 words. Dream: \"$dream\"";
      final result = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt}
      ]);
      final entry = {'dream': dream, 'interpretation': result};
      await FirebaseFirestore.instance
          .collection('users').doc(_uid).collection('dreamInterpretations')
          .add({...entry, 'ts': FieldValue.serverTimestamp()});
      setState(() {
        _history.insert(0, entry);
        _ctrl.clear();
      });
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060312),
      body: Stack(children: [
        // Animated starfield
        AnimatedBuilder(
          animation: _starCtrl,
          builder: (_, __) => CustomPaint(
            painter: _StarfieldPainter(_starCtrl.value),
            size: Size.infinite,
          ),
        ),
        SafeArea(child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Text('🌙 Dream Interpreter',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              const SizedBox(width: 44),
            ]),
          ),
          const SizedBox(height: 12),
          // Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: 3,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe your dream to me, Darling~',
                  hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent))
                        : GestureDetector(
                            onTap: _interpret,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // History
          Expanded(
            child: _history.isEmpty
                ? Center(child: Text('Tell me your dreams~\nI\'ll reveal their secrets 🔮',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 15, height: 1.6)))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _history.length,
                    itemBuilder: (_, i) {
                      final e = _history[i];
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + i * 60),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple.withValues(alpha: 0.3), Colors.pink.withValues(alpha: 0.1)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Text('💭', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e['dream']!, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            ]),
                            const Divider(color: Colors.white12, height: 16),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('🔮', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e['interpretation']!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, height: 1.5))),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ])),
      ]),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double t;
  _StarfieldPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final rng = List.generate(60, (i) => i);
    for (final i in rng) {
      final x = (i * 137.5 % size.width);
      final y = (i * 89.3 % size.height);
      final r = (i % 3 == 0) ? 1.5 : 0.8;
      final alpha = (0.3 + 0.5 * (0.5 + 0.5 * _sin(t * 2 * 3.14159 + i))).clamp(0.1, 1.0);
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }
  double _sin(double x) => (x - x.floor()) < 0.5 ? 2 * (x - x.floor()) : 2 * (1 - (x - x.floor()));
  @override
  bool shouldRepaint(_StarfieldPainter old) => old.t != t;
}
