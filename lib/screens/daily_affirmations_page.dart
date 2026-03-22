import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_content_service.dart';
import '../widgets/waifu_background.dart';

class DailyAffirmationsPage extends StatefulWidget {
  const DailyAffirmationsPage({super.key});
  @override
  State<DailyAffirmationsPage> createState() => _DailyAffirmationsPageState();
}

class _DailyAffirmationsPageState extends State<DailyAffirmationsPage>
    with SingleTickerProviderStateMixin {
  List<String> _affirmations = [];
  int _idx = 0;
  bool _liked = false;
  bool _loading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await AiContentService.getAffirmations();
      if (mounted) {
        setState(() { _affirmations = list; _loading = false; });
        _fadeCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() {
    if (_affirmations.isEmpty) return;
    HapticFeedback.selectionClick();
    _fadeCtrl.reset();
    setState(() { _idx = (_idx + 1) % _affirmations.length; _liked = false; });
    _fadeCtrl.forward();
  }

  void _prev() {
    if (_affirmations.isEmpty) return;
    HapticFeedback.selectionClick();
    _fadeCtrl.reset();
    setState(() { _idx = (_idx - 1 + _affirmations.length) % _affirmations.length; _liked = false; });
    _fadeCtrl.forward();
  }

  void _toggleLike() {
    HapticFeedback.mediumImpact();
    setState(() => _liked = !_liked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.10,
        tint: const Color(0xFF0B0714),
        child: SafeArea(
          child: GestureDetector(
            onHorizontalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -200) { _next(); }
              else if ((d.primaryVelocity ?? 0) > 200) { _prev(); }
            },
            child: Column(children: [
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
                      Text('DAILY AFFIRMATIONS', style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      Text(_loading ? 'Zero Two is writing for you…' : 'Zero Two believes in you~ 💕',
                          style: GoogleFonts.outfit(
                              color: Colors.pinkAccent.withOpacity(0.6), fontSize: 10)),
                    ],
                  )),
                  if (!_loading)
                    GestureDetector(
                      onTap: _toggleLike,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _liked ? Colors.pinkAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _liked ? Colors.pinkAccent : Colors.white12),
                        ),
                        child: Icon(
                          _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _liked ? Colors.pinkAccent : Colors.white38,
                          size: 18,
                        ),
                      ),
                    ),
                ]),
              ),

              if (_loading)
                const Expanded(child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: Colors.pinkAccent),
                    SizedBox(height: 16),
                    Text('Generating affirmations with AI… 💕',
                        style: TextStyle(color: Colors.white54)),
                  ]),
                ))
              else if (_affirmations.isEmpty)
                const Expanded(child: Center(
                  child: Text('Could not load affirmations. Try again later.',
                      style: TextStyle(color: Colors.white54)),
                ))
              else ...[
                // Progress dots
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_affirmations.length.clamp(0, 20), (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: i == _idx ? 18 : 6, height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i == _idx ? Colors.pinkAccent : Colors.white.withOpacity(0.15),
                        ),
                      );
                    }),
                  ),
                ),

                // Affirmation card
                Expanded(child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.pinkAccent.withOpacity(0.1),
                          border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                        ),
                        child: Center(child: Text(
                          _liked ? '💕' : '💗',
                          style: const TextStyle(fontSize: 36),
                        )),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
                          boxShadow: [BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.06),
                            blurRadius: 24, spreadRadius: -4,
                          )],
                        ),
                        child: Text(
                          _affirmations[_idx],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 17, height: 1.7,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _navBtn(Icons.arrow_back_ios_rounded, _prev),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _affirmations[_idx]));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Affirmation copied~ 💕', style: GoogleFonts.outfit()),
                              backgroundColor: Colors.pinkAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ));
                          },
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.copy_outlined, color: Colors.pinkAccent, size: 16),
                              const SizedBox(width: 8),
                              Text('Copy', style: GoogleFonts.outfit(
                                  color: Colors.pinkAccent, fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _navBtn(Icons.arrow_forward_ios_rounded, _next),
                      ]),
                    ]),
                  ),
                )),

                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    '${_idx + 1} / ${_affirmations.length}',
                    style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white54, size: 18),
      ),
    );
  }
}
