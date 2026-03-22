import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../widgets/waifu_background.dart';

class SpinnerWheelPage extends StatefulWidget {
  const SpinnerWheelPage({super.key});
  @override
  State<SpinnerWheelPage> createState() => _SpinnerWheelPageState();
}

class _SpinnerWheelPageState extends State<SpinnerWheelPage>
    with SingleTickerProviderStateMixin {
  final List<String> _options = [
    'Zero Two 💕',
    'Hiro 🌹',
    'Ichigo ❄️',
    'Goro 💪',
    'Miku 🌊',
    'Zorome ⚡',
    'Kokoro 🌸',
    'Futoshi 🌟',
  ];
  final _textCtrl = TextEditingController();
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;
  String? _result;
  final _rng = Random();
  bool _spinning = false;
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _spinCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _spinCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        final segments = _options.length;
        final stopAngle = _spinAnim.value % (2 * pi);
        final idx =
            (segments - (stopAngle / (2 * pi / segments)).floor() % segments) %
                segments;
        setState(() {
          _result = _options[idx.clamp(0, _options.length - 1)];
          _spinning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _spin() {
    if (_spinning || _options.isEmpty) return;
    HapticFeedback.mediumImpact();
    final extra = 2 * pi * (3 + _rng.nextInt(5));
    final end = _currentAngle + extra;
    _spinAnim = Tween<double>(begin: _currentAngle, end: end)
        .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOut));
    _currentAngle = end;
    setState(() {
      _spinning = true;
      _result = null;
    });
    _spinCtrl.forward(from: 0);
  }

  void _addOption() {
    final t = _textCtrl.text.trim();
    if (t.isEmpty || _options.length >= 12) return;
    setState(() {
      _options.add(t);
    });
    _textCtrl.clear();
  }

  void _removeOption(int idx) {
    if (_options.length <= 2) return;
    setState(() => _options.removeAt(idx));
  }

  static const _segColors = [
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.amberAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.blueAccent,
    Colors.redAccent,
    Colors.tealAccent,
    Colors.yellowAccent,
    Colors.deepPurpleAccent,
    Colors.lightGreenAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF0A0714),
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
              Text('SPINNER WHEEL',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ]),
          ),

          // Wheel
          Expanded(
            child: AnimatedBuilder(
              animation: _spinCtrl,
              builder: (ctx, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(alignment: Alignment.center, children: [
                      Transform.rotate(
                        angle: _spinning
                            ? (_spinAnim.value)
                            : _currentAngle % (2 * pi),
                        child: CustomPaint(
                          size: const Size(260, 260),
                          painter: _WheelPainter(_options, _segColors),
                        ),
                      ),
                      // Center pin
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ]),
                  ),
                  // Pointer arrow
                  const Icon(Icons.arrow_drop_up_rounded,
                      color: Colors.white, size: 40),
                ]),
              ),
            ),
          ),

          // Result
          if (_result != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.pinkAccent.withOpacity(0.1),
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🎯', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Text(_result!,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),

          // Spin button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _spinning ? null : _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.pinkAccent.withOpacity(0.3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_spinning ? 'Spinning…' : 'SPIN!',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ),

          // Options list
          SizedBox(
            height: 130,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      style:
                          GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      cursorColor: Colors.pinkAccent,
                      decoration: InputDecoration(
                        hintText: 'Add option…',
                        hintStyle: GoogleFonts.outfit(
                            color: Colors.white30, fontSize: 12),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addOption,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.pinkAccent.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.pinkAccent, size: 20),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _options.length,
                  itemBuilder: (ctx, i) => GestureDetector(
                    onLongPress: () => _removeOption(i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color:
                            _segColors[i % _segColors.length].withOpacity(0.1),
                        border: Border.all(
                            color: _segColors[i % _segColors.length]
                                .withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_options[i],
                            style: GoogleFonts.outfit(
                                color: _segColors[i % _segColors.length],
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(Icons.close,
                            color: _segColors[i % _segColors.length]
                                .withOpacity(0.5),
                            size: 12),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ])),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> options;
  final List<Color> colors;
  _WheelPainter(this.options, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 4;
    final n = options.length;
    final sweep = 2 * pi / n;

    for (int i = 0; i < n; i++) {
      final start = i * sweep - pi / 2;
      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), start,
          sweep, true, paint);
      // Border
      final border = Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), start,
          sweep, true, border);

      // Text
      final angle = start + sweep / 2;
      final tx = cx + (r * 0.6) * cos(angle);
      final ty = cy + (r * 0.6) * sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: options[i],
          style:
              TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: 60);
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(angle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    // Outer ring
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => true;
}
