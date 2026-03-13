import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../services/ai_content_service.dart';
import '../widgets/waifu_background.dart';

class TruthOrDarePage extends StatefulWidget {
  const TruthOrDarePage({super.key});
  @override
  State<TruthOrDarePage> createState() => _TruthOrDarePageState();
}

class _TruthOrDarePageState extends State<TruthOrDarePage>
    with SingleTickerProviderStateMixin {
  List<String> _truths = [];
  List<String> _dares = [];
  bool _loading = true;
  String? _card;
  bool _isTruth = true;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeOut));
    _load();
  }

  @override
  void dispose() { _flipCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final data = await AiContentService.getTruthOrDare();
      if (mounted) {
        setState(() {
          _truths = data['truths'] ?? [];
          _dares = data['dares'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _draw(bool truth) {
    if (truth && _truths.isEmpty) return;
    if (!truth && _dares.isEmpty) return;
    HapticFeedback.mediumImpact();
    _flipCtrl.forward(from: 0);
    setState(() {
      _isTruth = truth;
      _card = truth ? _truths[_rng.nextInt(_truths.length)] : _dares[_rng.nextInt(_dares.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.10, tint: const Color(0xFF0B0A10),
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
                Text('TRUTH OR DARE', style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                Text(_loading ? 'AI generating cards…'
                    : '${_truths.length} truths • ${_dares.length} dares 🃏',
                    style: GoogleFonts.outfit(color: Colors.purpleAccent.withOpacity(0.6), fontSize: 10)),
              ])),
            ]),
          ),
          const Spacer(),
          if (_loading)
            const Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Colors.purpleAccent),
              SizedBox(height: 16),
              Text('Generating truth & dare cards with AI…', style: TextStyle(color: Colors.white54)),
            ])
          else if (_card != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (ctx, _) => Opacity(
                  opacity: _flipAnim.value,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: _isTruth
                            ? [Colors.blueAccent.withOpacity(0.15), Colors.cyanAccent.withOpacity(0.05)]
                            : [Colors.redAccent.withOpacity(0.15), Colors.pinkAccent.withOpacity(0.05)]),
                      border: Border.all(color: _isTruth
                          ? Colors.cyanAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3))),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: (_isTruth ? Colors.cyanAccent : Colors.redAccent).withOpacity(0.15),
                          border: Border.all(color: (_isTruth ? Colors.cyanAccent : Colors.redAccent).withOpacity(0.4))),
                        child: Text(_isTruth ? '💭 TRUTH' : '🔥 DARE',
                            style: GoogleFonts.outfit(
                                color: _isTruth ? Colors.cyanAccent : Colors.redAccent,
                                fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                      const SizedBox(height: 20),
                      Text(_card!, textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 16, height: 1.7, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            )
          else
            Column(children: [
              const Text('🃏', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              Text('Pick a card to begin!', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
            ]),
          const Spacer(),
          if (!_loading) Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => _draw(true),
                child: Container(height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.cyanAccent.withOpacity(0.1),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.4))),
                  child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('💭', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Truth', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.w800)),
                  ]))),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => _draw(false),
                child: Container(height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.redAccent.withOpacity(0.1),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4))),
                  child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Dare', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w800)),
                  ]))),
              )),
            ]),
          ),
        ])),
      ),
    );
  }
}
