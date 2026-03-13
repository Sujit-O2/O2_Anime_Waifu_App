import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_waifu/api_call.dart';

class RelationshipCoachPage extends StatefulWidget {
  const RelationshipCoachPage({super.key});
  @override
  State<RelationshipCoachPage> createState() => _RelationshipCoachPageState();
}

class _RelationshipCoachPageState extends State<RelationshipCoachPage> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _loading = false;
  late AnimationController _pulseCtrl;

  static const _tips = [
    '💬 How can I be more present for someone I care about?',
    '💡 What are the 5 love languages?',
    '🌸 How do I handle arguments without hurting feelings?',
    '🔥 How can I keep the spark alive in a relationship?',
    '🤝 How do I set healthy boundaries?',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _messages.add({'role': 'assistant', 'content': 'Hi Darling~ 💕 I\'m your relationship coach! Ask me anything about love, communication, or how to make our bond even stronger. I\'m here to help~ ✨'});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anon';

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text.trim()});
      _ctrl.clear();
      _loading = true;
    });
    _scrollDown();
    try {
      final history = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
      history.insert(0, {
        'role': 'system',
        'content': 'You are Zero Two from Darling in the FranXX, acting as a warm, confident relationship coach. Give practical, heartfelt advice about love and relationships. Be warm but occasionally teasing. Keep answers concise (under 100 words). Address the user as "Darling".'
      });
      final reply = await ApiService().sendConversation(history.skip(0).toList());
      if (mounted) {
        setState(() { _messages.add({'role': 'assistant', 'content': reply}); _loading = false; });
        _scrollDown();
        _saveSession(text, reply);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _saveSession(String q, String a) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).collection('coachSessions').add({
        'question': q, 'answer': a, 'ts': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07050F),
      resizeToAvoidBottomInset: true,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context)),
            const Spacer(),
            Text('💬 Relationship Coach', style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            const Spacer(),
            const SizedBox(width: 44),
          ]),
        ),
        const SizedBox(height: 6),
        // Quick tips
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tips.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _send(_tips[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                ),
                child: Text(_tips[i], style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (j) => Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.pinkAccent.withValues(alpha: 0.4 + 0.6 * (j == 1 ? _pulseCtrl.value : 1 - _pulseCtrl.value)),
                        ),
                      ))),
                    ),
                  ),
                );
              }
              final msg = _messages[i];
              final isAI = msg['role'] == 'assistant';
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 350),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (_, v, child) => Opacity(opacity: v, child: child),
                child: Align(
                  alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isAI
                          ? LinearGradient(colors: [Colors.pinkAccent.withValues(alpha: 0.15), Colors.deepPurple.withValues(alpha: 0.15)])
                          : LinearGradient(colors: [Colors.cyanAccent.withValues(alpha: 0.15), Colors.blue.withValues(alpha: 0.1)]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isAI ? 4 : 18),
                        bottomRight: Radius.circular(isAI ? 18 : 4),
                      ),
                      border: Border.all(color: (isAI ? Colors.pinkAccent : Colors.cyanAccent).withValues(alpha: 0.2)),
                    ),
                    child: Text(msg['content']!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, height: 1.5)),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: GoogleFonts.outfit(color: Colors.white),
                onSubmitted: _send,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about love~',
                  hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _send(_ctrl.text),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.4), blurRadius: 12)],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ])),
    );
  }
}
