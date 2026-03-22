import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../widgets/waifu_background.dart';

class DrawLotsPage extends StatefulWidget {
  const DrawLotsPage({super.key});
  @override
  State<DrawLotsPage> createState() => _DrawLotsPageState();
}

class _DrawLotsPageState extends State<DrawLotsPage>
    with SingleTickerProviderStateMixin {
  final List<String> _options = ['Option 1', 'Option 2', 'Option 3'];
  final _textCtrl = TextEditingController();
  String? _result;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  bool _drawing = false;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        final idx = _rng.nextInt(_options.length);
        setState(() {
          _result = _options[idx];
          _drawing = false;
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _draw() {
    if (_options.isEmpty || _drawing) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _drawing = true;
      _result = null;
    });
    _shakeCtrl.forward(from: 0);
  }

  void _addOption() {
    final t = _textCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _options.add(t));
    _textCtrl.clear();
  }

  void _removeOption(int idx) {
    if (_options.length <= 2) return;
    setState(() => _options.removeAt(idx));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.10,
        tint: const Color(0xFF0A080E),
        child: SafeArea(
            child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white60, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Text('DRAW LOTS',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ]),
          ),

          const Spacer(),

          // Sticks animation
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (ctx, _) {
              final angle =
                  _drawing ? sin(_shakeAnim.value * 4 * pi) * 0.1 : 0.0;
              return Transform.rotate(
                angle: angle,
                child: const Text('🫙', style: TextStyle(fontSize: 80)),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(_drawing ? 'Drawing…' : 'Shake the lot!',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),

          const SizedBox(height: 24),

          // Result
          if (_result != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.purpleAccent.withOpacity(0.08),
                  border:
                      Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                ),
                child: Column(children: [
                  Text('✨ Result',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 8),
                  Text(_result!,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                ]),
              ),
            ),

          const Spacer(),

          // Draw button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _drawing ? null : _draw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.purpleAccent.withOpacity(0.3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Draw a Lot!',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options editor
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  cursorColor: Colors.purpleAccent,
                  decoration: InputDecoration(
                    hintText: 'Add option…',
                    hintStyle:
                        GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _addOption(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addOption,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.purpleAccent, size: 20),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),

          // Chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _options.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onLongPress: () => _removeOption(i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.purpleAccent.withOpacity(0.1),
                    border:
                        Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                  ),
                  child: Text(_options[i],
                      style: GoogleFonts.outfit(
                          color: Colors.purpleAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ])),
      ),
    );
  }
}
