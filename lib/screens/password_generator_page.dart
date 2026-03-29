import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});
  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> with SingleTickerProviderStateMixin {
  double _length = 16;
  bool _upper = true, _lower = true, _numbers = true, _symbols = true;
  String _password = '';
  List<Map<String, dynamic>> _history = [];
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _load(); _generate();
  }

  @override
  void dispose() { _glowCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try { _history = (jsonDecode(p.getString('password_gen_history') ?? '[]') as List).cast<Map<String, dynamic>>(); } catch (_) {}
    setState(() {});
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('password_gen_history', jsonEncode(_history.take(15).toList()));
  }

  void _generate() {
    String chars = '';
    if (_lower) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (_upper) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_numbers) chars += '0123456789';
    if (_symbols) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    if (chars.isEmpty) chars = 'abcdefghijklmnopqrstuvwxyz';

    final rng = Random.secure();
    final pw = List.generate(_length.round(), (_) => chars[rng.nextInt(chars.length)]).join();
    HapticFeedback.lightImpact();
    _glowCtrl.forward(from: 0);
    setState(() {
      _password = pw;
      _history.insert(0, {'pw': pw, 'time': DateTime.now().millisecondsSinceEpoch, 'length': _length.round()});
    });
    _save();
  }

  int get _strength {
    int score = 0;
    if (_password.length >= 12) score++;
    if (_password.length >= 20) score++;
    if (_upper && RegExp(r'[A-Z]').hasMatch(_password)) score++;
    if (_numbers && RegExp(r'[0-9]').hasMatch(_password)) score++;
    if (_symbols && RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(_password)) score++;
    return score.clamp(0, 4);
  }

  String get _strengthLabel => ['Weak', 'Fair', 'Good', 'Strong', 'Very Strong'][_strength];
  Color get _strengthColor => [Colors.redAccent, Colors.orangeAccent, Colors.amberAccent, Colors.greenAccent, Colors.cyanAccent][_strength];

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    _snack('📋 Copied to clipboard!', Colors.greenAccent);
  }

  String _timeAgo(int ms) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }

  void _snack(String msg, Color c) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w700)), backgroundColor: c, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PASSWORD GEN', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text('Secure password generator', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 11)),
          ])),
        ])),
        const SizedBox(height: 16),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: Column(children: [
          // Password display
          AnimatedBuilder(animation: _glowCtrl, builder: (_, __) => Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
              color: Colors.greenAccent.withValues(alpha: 0.05 + _glowCtrl.value * 0.05),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2 + _glowCtrl.value * 0.3), width: 2),
              boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: _glowCtrl.value * 0.1), blurRadius: 20)]),
            child: Column(children: [
              SelectableText(_password, style: GoogleFonts.firaCode(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(onTap: () => _copy(_password), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.greenAccent.withValues(alpha: 0.15), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.copy_rounded, color: Colors.greenAccent, size: 16), const SizedBox(width: 6), Text('Copy', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w700))]))),
                const SizedBox(width: 10),
                GestureDetector(onTap: _generate, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.cyanAccent.withValues(alpha: 0.15), border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.refresh_rounded, color: Colors.cyanAccent, size: 16), const SizedBox(width: 6), Text('Regenerate', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w700))]))),
              ]),
            ]),
          )),
          const SizedBox(height: 14),

          // Strength meter
          Container(width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _strengthColor.withValues(alpha: 0.06), border: Border.all(color: _strengthColor.withValues(alpha: 0.2))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Strength', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                Text(_strengthLabel, style: GoogleFonts.outfit(color: _strengthColor, fontSize: 12, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 8),
              Row(children: List.generate(5, (i) => Expanded(child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: i <= _strength ? _strengthColor : Colors.white.withValues(alpha: 0.08)))))),
            ]),
          ),
          const SizedBox(height: 14),

          // Length slider
          Container(width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.03), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('LENGTH', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                Text('${_length.round()} chars', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w800)),
              ]),
              SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: Colors.greenAccent, inactiveTrackColor: Colors.white.withValues(alpha: 0.08), thumbColor: Colors.greenAccent, overlayColor: Colors.greenAccent.withValues(alpha: 0.1)),
                child: Slider(value: _length, min: 4, max: 64, divisions: 60, onChanged: (v) { setState(() => _length = v); _generate(); })),
              const SizedBox(height: 8),
              // Toggles
              _toggleRow('ABC', 'Uppercase', _upper, (v) { setState(() => _upper = v); _generate(); }),
              _toggleRow('abc', 'Lowercase', _lower, (v) { setState(() => _lower = v); _generate(); }),
              _toggleRow('123', 'Numbers', _numbers, (v) { setState(() => _numbers = v); _generate(); }),
              _toggleRow('#!@', 'Symbols', _symbols, (v) { setState(() => _symbols = v); _generate(); }),
            ]),
          ),
          const SizedBox(height: 14),

          // History
          if (_history.isNotEmpty) ...[
            Align(alignment: Alignment.centerLeft, child: Text('RECENT PASSWORDS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1))),
            const SizedBox(height: 8),
            ..._history.take(10).map((h) => GestureDetector(onTap: () => _copy(h['pw'] as String),
              child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Expanded(child: Text(h['pw'] as String, style: GoogleFonts.firaCode(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text('${h['length']}ch • ${_timeAgo(h['time'] as int)}', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9)),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, color: Colors.white24, size: 14),
                ]),
              ),
            )),
          ],
        ]))),
      ])),
    );
  }

  Widget _toggleRow(String badge, String label, bool val, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: GestureDetector(onTap: () => onChanged(!val), child: Row(children: [
      Container(width: 32, height: 22, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: val ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04), border: Border.all(color: val ? Colors.greenAccent : Colors.white12)),
        child: Center(child: Text(badge, style: GoogleFonts.firaCode(color: val ? Colors.greenAccent : Colors.white24, fontSize: 8, fontWeight: FontWeight.w700)))),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.outfit(color: val ? Colors.white : Colors.white38, fontSize: 12)),
      const Spacer(),
      Icon(val ? Icons.toggle_on : Icons.toggle_off, color: val ? Colors.greenAccent : Colors.white24, size: 28),
    ])),
  );
}
