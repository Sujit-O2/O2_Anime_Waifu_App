import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_content_service.dart';
import '../widgets/waifu_background.dart';

class ZeroTwoFactsPage extends StatefulWidget {
  const ZeroTwoFactsPage({super.key});
  @override
  State<ZeroTwoFactsPage> createState() => _ZeroTwoFactsPageState();
}

class _ZeroTwoFactsPageState extends State<ZeroTwoFactsPage>
    with TickerProviderStateMixin {
  List<String> _facts = [];
  int _currentIdx = 0;
  bool _loading = true;
  final Set<int> _favorites = {};
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _loadFacts();
  }

  @override
  void dispose() { _slideCtrl.dispose(); super.dispose(); }

  Future<void> _loadFacts() async {
    try {
      final facts = await AiContentService.getZeroTwoFacts();
      if (mounted) { setState(() { _facts = facts; _loading = false; }); _slideCtrl.forward(); }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() {
    if (_facts.isEmpty) return;
    HapticFeedback.selectionClick();
    _slideCtrl.reset();
    setState(() => _currentIdx = (_currentIdx + 1) % _facts.length);
    _slideCtrl.forward();
  }

  void _prev() {
    if (_facts.isEmpty) return;
    HapticFeedback.selectionClick();
    _slideCtrl.reset();
    setState(() => _currentIdx = (_currentIdx - 1 + _facts.length) % _facts.length);
    _slideCtrl.forward();
  }

  void _toggleFavorite() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_favorites.contains(_currentIdx)) { _favorites.remove(_currentIdx); }
      else { _favorites.add(_currentIdx); }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fact = _facts.isEmpty ? null : _facts[_currentIdx];
    final isFav = _favorites.contains(_currentIdx);
    final progress = _facts.isEmpty ? 0.0 : (_currentIdx + 1) / _facts.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.12, tint: const Color(0xFF090714),
        child: GestureDetector(
          onHorizontalDragEnd: (d) {
            if (d.primaryVelocity != null) {
              if (d.primaryVelocity! < -200) { _next(); }
              else if (d.primaryVelocity! > 200) { _prev(); }
            }
          },
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
                  Text('ZERO TWO LORE', style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  Text(_loading ? 'AI generating facts…' : _facts.isNotEmpty
                      ? 'Fact ${_currentIdx + 1} of ${_facts.length}'
                      : 'No facts available',
                      style: GoogleFonts.outfit(color: Colors.pinkAccent.withOpacity(0.6), fontSize: 10)),
                ])),
                if (!_loading) GestureDetector(
                  onTap: _toggleFavorite,
                  child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Colors.pinkAccent : Colors.white38, size: 24)),
              ]),
            ),
            if (_facts.isNotEmpty) Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress,
                    backgroundColor: Colors.white.withOpacity(0.07),
                    valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent), minHeight: 3)),
            ),
            Expanded(child: Stack(children: [
              Center(child: Text('02', style: GoogleFonts.outfit(
                  color: Colors.pinkAccent.withOpacity(0.04), fontSize: 250, fontWeight: FontWeight.w900))),
              _loading
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent),
                      SizedBox(height: 16),
                      Text('Generating lore with AI…', style: TextStyle(color: Colors.white54)),
                    ]))
                  : _facts.isEmpty
                      ? Center(child: Text('Could not load facts.', style: GoogleFonts.outfit(color: Colors.white54)))
                      : SlideTransition(position: _slideAnim,
                          child: Padding(padding: const EdgeInsets.all(24),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Container(padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: Colors.white.withOpacity(0.04),
                                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.25)),
                                  boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.08), blurRadius: 24, spreadRadius: -4)]),
                                child: Column(children: [
                                  const Text('🌸', style: TextStyle(fontSize: 36)),
                                  const SizedBox(height: 16),
                                  Text(fact!, textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, height: 1.7, fontWeight: FontWeight.w500)),
                                ]),
                              ),
                              const SizedBox(height: 24),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                _navBtn(Icons.arrow_back_ios_rounded, _prev),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () { HapticFeedback.lightImpact();
                                    Clipboard.setData(ClipboardData(text: fact));
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('Copied to clipboard~', style: GoogleFonts.outfit()),
                                      backgroundColor: Colors.pinkAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 2)));
                                  },
                                  child: Container(height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.pinkAccent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.pinkAccent.withOpacity(0.3))),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.copy_outlined, color: Colors.pinkAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Copy', style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.w700)),
                                    ])),
                                ),
                                const SizedBox(width: 20),
                                _navBtn(Icons.arrow_forward_ios_rounded, _next),
                              ]),
                              if (_favorites.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text('${_favorites.length} fact${_favorites.length > 1 ? 's' : ''} favorited 💖',
                                    style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
                              ],
                            ]))),
            ])),
          ])),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12)),
      child: Icon(icon, color: Colors.white54, size: 18)),
  );
}
