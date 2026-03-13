import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_content_service.dart';
import '../widgets/waifu_background.dart';

class WouldYouRatherPage extends StatefulWidget {
  const WouldYouRatherPage({super.key});
  @override
  State<WouldYouRatherPage> createState() => _WouldYouRatherPageState();
}

class _WouldYouRatherPageState extends State<WouldYouRatherPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, String>> _questions = [];
  bool _loading = true;
  int _idx = 0;
  int _votesA = 0;
  int _votesB = 0;
  bool _voted = false;
  int? _choice;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _load();
  }

  @override
  void dispose() { _slideCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final list = await AiContentService.getWouldYouRather();
      if (mounted) { setState(() { _questions = list; _loading = false; }); _slideCtrl.forward(); }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _vote(int choice) {
    if (_voted) return;
    HapticFeedback.mediumImpact();
    setState(() { _voted = true; _choice = choice;
      if (choice == 0) { _votesA++; } else { _votesB++; }
    });
  }

  void _next() {
    if (_idx < _questions.length - 1) {
      _slideCtrl.reset();
      setState(() { _idx++; _voted = false; _choice = null; });
      _slideCtrl.forward();
    } else {
      _slideCtrl.reset();
      setState(() { _idx = 0; _voted = false; _choice = null; _votesA = 0; _votesB = 0; });
      _slideCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.10, tint: const Color(0xFF08100F),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12)),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WOULD YOU RATHER', style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                Text(_loading ? 'AI generating dilemmas…'
                    : '${_idx + 1} / ${_questions.length} questions',
                    style: GoogleFonts.outfit(color: Colors.cyanAccent.withOpacity(0.6), fontSize: 10)),
              ])),
            ]),
          ),
          Expanded(child: _loading
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: Colors.cyanAccent),
                  SizedBox(height: 16),
                  Text('Generating dilemmas with AI…', style: TextStyle(color: Colors.white54)),
                ]))
              : _questions.isEmpty
                  ? Center(child: Text('Could not load questions.', style: GoogleFonts.outfit(color: Colors.white54)))
                  : SlideTransition(position: _slideAnim,
                      child: Padding(padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          const Spacer(),
                          Text('Would you rather…', style: GoogleFonts.outfit(
                              color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          _buildOption(_questions[_idx]['optionA'] ?? 'Option A', 0, Colors.cyanAccent),
                          const SizedBox(height: 16),
                          Container(width: 48, height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(color: Colors.white12)),
                            child: Center(child: Text('VS', style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900))),
                          ),
                          const SizedBox(height: 16),
                          _buildOption(_questions[_idx]['optionB'] ?? 'Option B', 1, Colors.pinkAccent),
                          const Spacer(),
                          if (_voted && (_votesA + _votesB) > 0) ...[
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('${((_votesA / (_votesA + _votesB)) * 100).round()}%',
                                      style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.w700)),
                                  Text('Your session results',
                                      style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
                                  Text('${((_votesB / (_votesA + _votesB)) * 100).round()}%',
                                      style: GoogleFonts.outfit(color: Colors.pinkAccent, fontWeight: FontWeight.w700)),
                                ]),
                                const SizedBox(height: 6),
                                ClipRRect(borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _votesA / (_votesA + _votesB),
                                    backgroundColor: Colors.pinkAccent.withOpacity(0.4),
                                    valueColor: AlwaysStoppedAnimation(Colors.cyanAccent.withOpacity(0.7)),
                                    minHeight: 6)),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _next,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.06),
                                  foregroundColor: Colors.white70,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: const BorderSide(color: Colors.white12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14)),
                                child: Text(_idx < _questions.length - 1 ? 'Next Question →' : 'Start Over 🔁',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ])))),
        ])),
      ),
    );
  }

  Widget _buildOption(String text, int idx, Color color) {
    final selected = _voted && _choice == idx;
    final notSelected = _voted && _choice != idx;
    return GestureDetector(
      onTap: () => _vote(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? color.withOpacity(0.12)
              : notSelected ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: selected ? color : notSelected ? Colors.white12 : color.withOpacity(0.3),
            width: selected ? 2 : 1)),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(selected ? 0.2 : 0.08),
              border: Border.all(color: color.withOpacity(selected ? 0.6 : 0.3))),
            child: Center(child: Text(idx == 0 ? 'A' : 'B',
                style: GoogleFonts.outfit(
                    color: selected ? color : color.withOpacity(0.6),
                    fontSize: 16, fontWeight: FontWeight.w900)))),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: GoogleFonts.outfit(
              color: selected ? Colors.white : notSelected ? Colors.white38 : Colors.white70,
              fontSize: 14, height: 1.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
        ]),
      ),
    );
  }
}
