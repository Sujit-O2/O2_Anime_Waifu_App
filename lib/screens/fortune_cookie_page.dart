import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_content_service.dart';
import '../widgets/waifu_background.dart';

class FortuneCookiePage extends StatefulWidget {
  const FortuneCookiePage({super.key});
  @override
  State<FortuneCookiePage> createState() => _FortuneCookiePageState();
}

class _FortuneCookiePageState extends State<FortuneCookiePage>
    with SingleTickerProviderStateMixin {
  List<String> _fortunes = [];
  String? _fortune;
  bool _cracked = false;
  bool _loading = true;
  late AnimationController _crackCtrl;
  late Animation<double> _scaleAnim;
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _crackCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _crackCtrl, curve: Curves.elasticOut));
    _loadFortunes();
  }

  @override
  void dispose() {
    _crackCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFortunes() async {
    try {
      final list = await AiContentService.getFortunes();
      if (mounted) setState(() { _fortunes = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _crackCookie() {
    if (_fortunes.isEmpty) return;
    HapticFeedback.mediumImpact();
    final fortune = _fortunes[DateTime.now().millisecondsSinceEpoch % _fortunes.length];
    _crackCtrl.forward(from: 0);
    setState(() {
      _fortune = fortune;
      _cracked = true;
      if (_history.length > 9) _history.removeAt(0);
      _history.add(fortune);
    });
  }

  void _copyFortune() {
    if (_fortune == null) return;
    Clipboard.setData(ClipboardData(text: _fortune!));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Fortune copied~ 🥠', style: GoogleFonts.outfit()),
      backgroundColor: Colors.amberAccent.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.10,
        tint: const Color(0xFF0A0800),
        child: SafeArea(child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FORTUNE COOKIE', style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  Text(_loading ? 'Loading AI fortunes…' : 'Tap to crack a cookie~ 🥠',
                      style: GoogleFonts.outfit(color: Colors.amberAccent.withOpacity(0.6), fontSize: 10)),
                ],
              )),
              if (_fortune != null)
                GestureDetector(
                  onTap: _copyFortune,
                  child: const Icon(Icons.copy_outlined, color: Colors.amberAccent, size: 22),
                ),
            ]),
          ),
          const Spacer(),
          if (_loading)
            const CircularProgressIndicator(color: Colors.amberAccent)
          else
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: GestureDetector(
                  onTap: _crackCookie,
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Colors.amberAccent.withOpacity(0.2),
                        Colors.orange.withOpacity(0.05),
                      ]),
                      border: Border.all(color: Colors.amberAccent.withOpacity(0.4), width: 2),
                      boxShadow: [BoxShadow(
                        color: Colors.amberAccent.withOpacity(0.15),
                        blurRadius: 30, spreadRadius: 5,
                      )],
                    ),
                    child: Center(child: Text(
                      _cracked ? '🫙' : '🥠',
                      style: const TextStyle(fontSize: 64),
                      textAlign: TextAlign.center,
                    )),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _cracked ? 'Tap for another fortune~' : 'Tap the cookie!',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
              ),
            ])),
          const SizedBox(height: 32),
          if (_fortune != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.amberAccent.withOpacity(0.06),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.25)),
                ),
                child: Text(
                  '"$_fortune"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 15,
                      fontStyle: FontStyle.italic, height: 1.7),
                ),
              ),
            ),
          const Spacer(),
          if (_history.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Past fortunes 📜', style: GoogleFonts.outfit(
                      color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ..._history.reversed.skip(1).take(3).map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $f',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
                  )),
                ],
              ),
            ),
        ])),
      ),
    );
  }
}
