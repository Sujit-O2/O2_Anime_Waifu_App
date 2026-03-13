import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class RelationshipAdvicePage extends StatefulWidget {
  const RelationshipAdvicePage({super.key});
  @override
  State<RelationshipAdvicePage> createState() => _RelationshipAdvicePageState();
}

class _RelationshipAdvicePageState extends State<RelationshipAdvicePage> {
  final _ctrl = TextEditingController();
  final _topics = [
    'Communication 💬',
    'Trust 🤝',
    'Long Distance 💌',
    'Arguments 💢',
    'Moving On 🌱',
    'Jealousy 😤',
    'First Love 💕',
    'Friendship to Love 🌸',
    'Self-worth 💎'
  ];
  String _topic = 'Communication 💬', _result = '';
  bool _loading = false;
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _ctrl.text.trim();
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      final prompt =
          'You are Zero Two from DARLING in the FRANXX, giving thoughtful relationship advice. '
          'Topic: ${q.isNotEmpty ? q : _topic}. '
          'Respond with real, actionable advice. Be warm, wise, and occasionally use Zero Two\'s playful voice. '
          '3-4 paragraphs with emojis.';
      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt}
      ]);
      setState(() => _result = reply);
      AffectionService.instance.addPoints(2);
    } catch (_) {
      setState(
          () => _result = 'Hearts can be complicated~ Try again, Darling!');
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
          title: Text('RELATIONSHIP ADVICE',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.8)),
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
                    color: Colors.pinkAccent.withValues(alpha: 0.08),
                    border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.2))),
                child: Row(children: [
                  const Text('💕', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Tell me what\'s on your heart, Darling~ I\'ll help.',
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 12)))
                ])),
            Text('Quick Topics',
                style: GoogleFonts.outfit(
                    color: Colors.white60, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _topics
                    .map((t) => GestureDetector(
                        onTap: () => setState(() => _topic = t),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: t == _topic
                                    ? Colors.pinkAccent.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.04),
                                border: Border.all(
                                    color: t == _topic
                                        ? Colors.pinkAccent
                                            .withValues(alpha: 0.6)
                                        : Colors.white12)),
                            child: Text(t,
                                style: GoogleFonts.outfit(
                                    color: t == _topic
                                        ? Colors.pinkAccent
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
                    maxLines: 4,
                    style: GoogleFonts.outfit(color: Colors.white),
                    cursorColor: Colors.pinkAccent,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                        hintText: 'Or describe your situation in detail…',
                        hintStyle: GoogleFonts.outfit(color: Colors.white24)))),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.pinkAccent.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5))
                        ]),
                    child: ElevatedButton(
                        onPressed: _loading ? null : _ask,
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
                            : Text('Ask Zero Two 💕',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15))))),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(
                          color: Colors.pinkAccent.withValues(alpha: 0.18))),
                  child: Text(_result,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 14, height: 1.7)))
            ],
          ])));
}
