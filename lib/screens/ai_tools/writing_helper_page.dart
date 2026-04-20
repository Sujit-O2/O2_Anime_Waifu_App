import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/widgets/waifu_background.dart';

/// Writing Helper v2 — AI-powered writing assistant with type/tone selection,
/// history persistence, copy-to-clipboard, word stats, and Zero Two voice.
class WritingHelperPage extends StatefulWidget {
  const WritingHelperPage({super.key});
  @override
  State<WritingHelperPage> createState() => _WritingHelperPageState();
}

class _WritingHelperPageState extends State<WritingHelperPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  final _inputCtrl = TextEditingController();

  static const _types = [
    {'label': 'Essay', 'emoji': '✍️', 'color': 0xFF8B44FD},
    {'label': 'Story', 'emoji': '📖', 'color': 0xFFFF6B6B},
    {'label': 'Email', 'emoji': '📧', 'color': 0xFF4ECDC4},
    {'label': 'Cover Letter', 'emoji': '💼', 'color': 0xFF45B7D1},
    {'label': 'Speech', 'emoji': '🎤', 'color': 0xFFFF8C42},
    {'label': 'Poem', 'emoji': '🌸', 'color': 0xFFFF4D8D},
    {'label': 'Caption', 'emoji': '📱', 'color': 0xFF6C5CE7},
    {'label': 'Apology', 'emoji': '💌', 'color': 0xFFE17055},
  ];

  static const _tones = [
    {'label': 'Formal', 'emoji': '👔'},
    {'label': 'Casual', 'emoji': '😊'},
    {'label': 'Romantic', 'emoji': '💕'},
    {'label': 'Persuasive', 'emoji': '🔥'},
    {'label': 'Poetic', 'emoji': '✨'},
    {'label': 'Funny', 'emoji': '😂'},
  ];

  int _selectedType = 0;
  int _selectedTone = 1;
  String _result = '';
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
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('writing_helper_history_v2');
    if (raw != null && mounted) {
      try { setState(() => _history = (jsonDecode(raw) as List).cast<Map<String, dynamic>>()); } catch (_) {}
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('writing_helper_history_v2', jsonEncode(_history.take(20).toList()));
  }

  Future<void> _generate() async {
    final topic = _inputCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter a topic, Darling!', style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.pinkAccent, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _result = ''; });
    try {
      final type = _types[_selectedType];
      final tone = _tones[_selectedTone];
      final prompt = 'You are Zero Two, a brilliant writer. Write a ${tone['label'].toString().toLowerCase()} ${type['label']} about: "$topic". '
          'Make it high-quality, engaging, and in character where appropriate. Use proper structure.';
      final reply = await ApiService().sendConversation([{'role': 'user', 'content': prompt}]);
      if (!mounted) return;
      setState(() => _result = reply);
      AffectionService.instance.addPoints(3);
      _history.insert(0, {
        'topic': topic,
        'type': type['label'],
        'tone': tone['label'],
        'result': reply.length > 200 ? '${reply.substring(0, 200)}...' : reply,
        'time': DateTime.now().toIso8601String(),
      });
      _saveHistory();
    } catch (_) {
      setState(() => _result = 'Quill slipped, Darling~ Try again!');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyResult() {
    if (_result.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _result));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied to clipboard~ 📋', style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: Colors.purpleAccent.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WaifuBackground(
        opacity: 0.07,
        tint: const Color(0xFF0A0612),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Column(children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('WRITING HELPER', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text('${_history.length} pieces written • +3 XP each', style: GoogleFonts.outfit(color: Colors.purpleAccent.withValues(alpha: 0.7), fontSize: 10)),
                  ])),
                  if (_result.isNotEmpty)
                    GestureDetector(
                      onTap: _copyResult,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3))),
                        child: const Icon(Icons.copy, color: Colors.purpleAccent, size: 16)),
                    ),
                ]),
              ),

              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ── Type Selection ──
                  Text('TYPE OF WRITING', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _types.length,
                      itemBuilder: (_, i) {
                        final t = _types[i];
                        final sel = i == _selectedType;
                        final color = Color(t['color'] as int);
                        return GestureDetector(
                          onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedType = i); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: sel ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                              border: Border.all(color: sel ? color.withValues(alpha: 0.5) : Colors.white12, width: sel ? 1.5 : 1),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(t['emoji'] as String, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 2),
                              Text(t['label'] as String, style: GoogleFonts.outfit(color: sel ? color : Colors.white38, fontSize: 9, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Tone Selection ──
                  Text('TONE', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: _tones.asMap().entries.map((e) {
                    final sel = e.key == _selectedTone;
                    return GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedTone = e.key); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: sel ? Colors.pinkAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                          border: Border.all(color: sel ? Colors.pinkAccent.withValues(alpha: 0.5) : Colors.white12),
                        ),
                        child: Text('${e.value['emoji']} ${e.value['label']}',
                          style: GoogleFonts.outfit(color: sel ? Colors.pinkAccent : Colors.white54, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 14),

                  // ── Input ──
                  Text('TOPIC OR PROMPT', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.15))),
                    child: TextField(
                      controller: _inputCtrl,
                      maxLines: 4,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      cursorColor: Colors.purpleAccent,
                      decoration: InputDecoration(border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
                        hintText: 'What should I write about?…', hintStyle: GoogleFonts.outfit(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Generate Button ──
                  GestureDetector(
                    onTap: _loading ? null : _generate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [Color(0xFF8B44FD), Color(0xFFFF4D8D)]),
                        boxShadow: [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.3), blurRadius: 16)],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(_loading ? 'Writing...' : 'Write for me ✨',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Result ──
                  if (_result.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.purpleAccent.withValues(alpha: 0.05),
                        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('📝 Result', style: GoogleFonts.outfit(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text('${_result.split(' ').length} words', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                        ]),
                        const SizedBox(height: 10),
                        Text(_result, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.7)),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerRight,
                      child: Text('+3 XP 💕', style: GoogleFonts.outfit(color: Colors.purpleAccent.withValues(alpha: 0.5), fontSize: 10))),
                  ],

                  // ── History ──
                  if (_history.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('RECENT WRITINGS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    ..._history.take(5).map((h) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                      child: Row(children: [
                        Text('📝', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(h['topic']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('${h['type']} • ${h['tone']}', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
                        ])),
                      ]),
                    )),
                  ],

                  const SizedBox(height: 30),
                ]),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}




