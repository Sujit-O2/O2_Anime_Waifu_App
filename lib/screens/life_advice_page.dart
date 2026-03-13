import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class LifeAdvicePage extends StatefulWidget {
  const LifeAdvicePage({super.key});
  @override
  State<LifeAdvicePage> createState() => _LifeAdvicePageState();
}

class _LifeAdvicePageState extends State<LifeAdvicePage> {
  final _ctrl = TextEditingController();
  final _modes = [
    'Supportive 💕',
    'Tough Love 🔥',
    'Philosophical 🌙',
    'Practical 💡',
    'Spiritual ✨',
    'Zero Two 🌸'
  ];
  String _mode = 'Supportive 💕', _advice = '';
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _getAdvice() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _advice = '';
    });
    try {
      final m = _mode.split(' ').first.toLowerCase();
      final prompt = _mode == 'Zero Two 🌸'
          ? 'You are Zero Two from DARLING in the FRANXX giving heartfelt advice to your Darling about: "$q". Be warm, bold, and uniquely Zero Two.'
          : 'Give $m life advice about: "$q". Be insightful, actionable, and warm. 3-4 paragraphs.';
      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt}
      ]);
      setState(() => _advice = reply);
      AffectionService.instance.addPoints(2);
    } catch (_) {
      setState(() =>
          _advice = 'A moment of silence for wisdom~ Try again, Darling!');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
              onPressed: () => Navigator.pop(context)),
          title: Text('LIFE ADVICE',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          centerTitle: true),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.cyanAccent.withValues(alpha: 0.07),
                    border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.2))),
                child: Row(children: [
                  const Text('🧠', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Share what\'s on your mind, Darling~ I\'m here to listen.',
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 12)))
                ])),
            Text('Advice Style',
                style: GoogleFonts.outfit(
                    color: Colors.white60, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _modes
                    .map((m) => GestureDetector(
                        onTap: () => setState(() => _mode = m),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: m == _mode
                                    ? Colors.cyanAccent.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.04),
                                border: Border.all(
                                    color: m == _mode
                                        ? Colors.cyanAccent
                                            .withValues(alpha: 0.6)
                                        : Colors.white12)),
                            child: Text(m,
                                style: GoogleFonts.outfit(
                                    color: m == _mode
                                        ? Colors.cyanAccent
                                        : Colors.white54,
                                    fontSize: 11)))))
                    .toList()),
            const SizedBox(height: 14),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.04),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: TextField(
                    controller: _ctrl,
                    maxLines: 5,
                    style: GoogleFonts.outfit(color: Colors.white),
                    cursorColor: Colors.cyanAccent,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                        hintText:
                            'What\'s bothering you? What decision are you facing?…',
                        hintStyle: GoogleFonts.outfit(color: Colors.white24)))),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [
                          Colors.cyanAccent.shade700,
                          Colors.teal.shade600
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 5))
                        ]),
                    child: ElevatedButton(
                        onPressed: _loading ? null : _getAdvice,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text('Get Advice 🧠',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15))))),
            if (_advice.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.2))),
                  child: Text(_advice,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 14, height: 1.7)))
            ],
          ])));
}
