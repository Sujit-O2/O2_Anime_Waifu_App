import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_content_service.dart';
import '../widgets/waifu_background.dart';

class NeverHaveIEverPage extends StatefulWidget {
  const NeverHaveIEverPage({super.key});
  @override
  State<NeverHaveIEverPage> createState() => _NeverHaveIEverPageState();
}

class _NeverHaveIEverPageState extends State<NeverHaveIEverPage>
    with SingleTickerProviderStateMixin {
  List<String> _prompts = [];
  bool _loading = true;
  int _idx = 0;
  bool _answered = false;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  int _haveCount = 0;
  int _haventCount = 0;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _load();
  }

  @override
  void dispose() { _slideCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final list = await AiContentService.getNeverHaveIEver();
      if (mounted) { setState(() { _prompts = list; _loading = false; }); _slideCtrl.forward(); }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _respond(bool have) {
    if (_answered) return;
    HapticFeedback.mediumImpact();
    setState(() { _answered = true; if (have) { _haveCount++; } else { _haventCount++; } });
  }

  void _next() {
    if (_prompts.isEmpty) return;
    _slideCtrl.reset();
    setState(() { _idx = (_idx + 1) % _prompts.length; _answered = false; });
    _slideCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.10, tint: const Color(0xFF0A0A14),
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
                Text('NEVER HAVE I EVER', style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                Text(_loading ? 'AI generating prompts…' : 'Card ${_idx + 1} of ${_prompts.length}',
                    style: GoogleFonts.outfit(color: Colors.deepOrangeAccent.withOpacity(0.6), fontSize: 10)),
              ])),
              if (!_loading && _prompts.isNotEmpty) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.deepOrangeAccent.withOpacity(0.1),
                  border: Border.all(color: Colors.deepOrangeAccent.withOpacity(0.3))),
                child: Text('$_haveCount / $_haventCount', style: GoogleFonts.outfit(
                    color: Colors.deepOrangeAccent, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),

          Expanded(child: _loading
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: Colors.deepOrangeAccent),
                  SizedBox(height: 16),
                  Text('Generating prompts with AI…', style: TextStyle(color: Colors.white54)),
                ]))
              : _prompts.isEmpty
                  ? Center(child: Text('Could not load prompts.', style: GoogleFonts.outfit(color: Colors.white54)))
                  : SlideTransition(position: _slideAnim, child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [
                                Colors.deepOrangeAccent.withOpacity(0.08),
                                Colors.pinkAccent.withOpacity(0.04)]),
                            border: Border.all(color: Colors.deepOrangeAccent.withOpacity(0.25)),
                            boxShadow: [BoxShadow(color: Colors.deepOrangeAccent.withOpacity(0.06), blurRadius: 24, spreadRadius: -4)]),
                          child: Column(children: [
                            const Text('🎭', style: TextStyle(fontSize: 42)),
                            const SizedBox(height: 20),
                            Text(_prompts[_idx], textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, height: 1.6, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        const SizedBox(height: 28),
                        if (!_answered) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _responseBtn('I have 😳', Colors.pinkAccent, () => _respond(true)),
                          const SizedBox(width: 16),
                          _responseBtn('I haven\'t 😇', Colors.cyanAccent, () => _respond(false)),
                        ]) else ...[
                          Text(_answered ? 'Tap to continue →' : '', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrangeAccent.withOpacity(0.15),
                              foregroundColor: Colors.deepOrangeAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.deepOrangeAccent.withOpacity(0.4))),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                            child: Text('Next Card →', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ],
                      ])))),
        ])),
      ),
    );
  }

  Widget _responseBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
    ),
  );
}
