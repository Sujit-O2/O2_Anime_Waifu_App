import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
/// Life Advice v2 — AI-powered life counsel with style selector,
/// history persistence, copy, staggered animations, and WaifuBackground.
class LifeAdvicePage extends StatefulWidget {
  const LifeAdvicePage({super.key});
  @override
  State<LifeAdvicePage> createState() => _LifeAdvicePageState();
}

class _LifeAdvicePageState extends State<LifeAdvicePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  final _ctrl = TextEditingController();

  static const _modes = [
    {'label': 'Supportive', 'emoji': '💕', 'color': 0xFFFF69B4},
    {'label': 'Tough Love', 'emoji': '🔥', 'color': 0xFFFF6B6B},
    {'label': 'Philosophical', 'emoji': '🌙', 'color': 0xFF6C5CE7},
    {'label': 'Practical', 'emoji': '💡', 'color': 0xFF4ECDC4},
    {'label': 'Spiritual', 'emoji': '✨', 'color': 0xFFFFD700},
    {'label': 'Zero Two', 'emoji': '🌸', 'color': 0xFFFF4D8D},
  ];

  int _selectedMode = 0;
  String _advice = '';
  bool _loading = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('life_advice_history_v2');
    if (raw != null && mounted) {
      try { setState(() => _history = (jsonDecode(raw) as List).cast<Map<String, dynamic>>()); } catch (_) {}
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('life_advice_history_v2', jsonEncode(_history.take(20).toList()));
  }

  Future<void> _getAdvice() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Tell me what\'s on your mind, Darling~', style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.cyanAccent.shade700, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _advice = ''; });
    try {
      final mode = _modes[_selectedMode];
      final m = mode['label'].toString().toLowerCase();
      final prompt = m == 'zero two'
          ? 'You are Zero Two from DARLING in the FRANXX giving heartfelt advice to your Darling about: "$q". Be warm, bold, and uniquely Zero Two.'
          : 'Give $m life advice about: "$q". Be insightful, actionable, and warm. 3-4 paragraphs.';
      final reply = await ApiService().sendConversation([{'role': 'user', 'content': prompt}]);
      if (!mounted) return;
      setState(() => _advice = reply);
      AffectionService.instance.addPoints(2);
      _history.insert(0, {
        'question': q,
        'mode': mode['label'],
        'answer': reply.length > 150 ? '${reply.substring(0, 150)}...' : reply,
        'time': DateTime.now().toIso8601String(),
      });
      _saveHistory();
    } catch (_) {
      setState(() => _advice = 'A moment of silence for wisdom~ Try again, Darling!');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyAdvice() {
    if (_advice.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _advice));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Advice copied~ 📋', style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: Colors.cyanAccent.shade700, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'LIFE ADVICE',
      subtitle: '${_history.length} questions answered • +2 XP',
      onBack: () => Navigator.pop(context),
      actions: [
        if (_advice.isNotEmpty)
          GestureDetector(
            onTap: _copyAdvice,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3))),
              child: const Icon(Icons.copy, color: Colors.cyanAccent, size: 16)),
          ),
      ],
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ── Intro Card ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.cyanAccent.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Text('🧠', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Share what\'s on your mind, Darling~ I\'m here to listen.', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // ── Mode Selection ──
                  Text('ADVICE STYLE', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: _modes.asMap().entries.map((e) {
                    final sel = e.key == _selectedMode;
                    final color = Color(e.value['color'] as int);
                    return GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedMode = e.key); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: sel ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                          border: Border.all(color: sel ? color.withValues(alpha: 0.5) : Colors.white12, width: sel ? 1.5 : 1),
                        ),
                        child: Text('${e.value['emoji']} ${e.value['label']}',
                          style: GoogleFonts.outfit(color: sel ? color : Colors.white54, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 14),

                  // ── Input ──
                  Text('YOUR QUESTION', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15))),
                    child: TextField(
                      controller: _ctrl, maxLines: 5,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      cursorColor: Colors.cyanAccent,
                      decoration: InputDecoration(border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
                        hintText: 'What\'s bothering you? What decision are you facing?…', hintStyle: GoogleFonts.outfit(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Button ──
                  GestureDetector(
                    onTap: _loading ? null : _getAdvice,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: [Colors.cyanAccent.shade700, Colors.teal.shade600]),
                        boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.25), blurRadius: 14)],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.psychology, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(_loading ? 'Thinking deeply...' : 'Get Advice 🧠',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Result ──
                  if (_advice.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.cyanAccent.withValues(alpha: 0.04),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('${_modes[_selectedMode]['emoji']} ${_modes[_selectedMode]['label']} Advice', style: GoogleFonts.outfit(color: Color(_modes[_selectedMode]['color'] as int), fontSize: 12, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text('+2 XP 💕', style: GoogleFonts.outfit(color: Colors.cyanAccent.withValues(alpha: 0.4), fontSize: 10)),
                        ]),
                        const SizedBox(height: 10),
                        Text(_advice, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.7)),
                      ]),
                    ),
                  ],

                  // ── History ──
                  if (_history.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('PAST QUESTIONS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    ..._history.take(5).toList().asMap().entries.map((entry) {
                      final h = entry.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 300 + entry.key * 60),
                        curve: Curves.easeOut,
                        builder: (_, val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 10 * (1 - val)), child: child)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                          child: Row(children: [
                            const Text('🧠', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(h['question']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('${h['mode']} style', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
                            ])),
                          ]),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 30),
                ]),
        ),
      ),
    );
  }
}




