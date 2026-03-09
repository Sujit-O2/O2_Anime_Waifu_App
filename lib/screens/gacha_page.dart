part of '../main.dart';

extension _GachaPageExtension on _ChatHomePageState {
  Widget _buildGachaPage() {
    return const _GachaView();
  }
}

// ─── Gacha rarity tiers ───────────────────────────────────────────────────────
enum _GachaRarity { common, rare, epic, legendary }

_GachaRarity _rarityForIndex(int i, int total) {
  final pct = i / total;
  if (pct < 0.10) return _GachaRarity.legendary; // top 10%
  if (pct < 0.30) return _GachaRarity.epic;
  if (pct < 0.60) return _GachaRarity.rare;
  return _GachaRarity.common;
}

Color _rarityColor(_GachaRarity r) {
  switch (r) {
    case _GachaRarity.legendary:
      return const Color(0xFFFFD700); // gold
    case _GachaRarity.epic:
      return const Color(0xFFB24BF3); // purple
    case _GachaRarity.rare:
      return const Color(0xFF4B9EF3); // blue
    case _GachaRarity.common:
      return const Color(0xFF7FBF7F); // green
  }
}

String _rarityLabel(_GachaRarity r) {
  switch (r) {
    case _GachaRarity.legendary:
      return '✨ LEGENDARY';
    case _GachaRarity.epic:
      return '💜 EPIC';
    case _GachaRarity.rare:
      return '💙 RARE';
    case _GachaRarity.common:
      return '💚 COMMON';
  }
}

// ─── Main view ────────────────────────────────────────────────────────────────
class _GachaView extends StatefulWidget {
  const _GachaView();
  @override
  State<_GachaView> createState() => _GachaViewState();
}

class _GachaViewState extends State<_GachaView> with TickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _particleCtrl;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _glowAnim;

  String _quote = '';
  _GachaRarity _rarity = _GachaRarity.common;
  bool _rolling = false;
  bool _hasRolled = false;
  int _rollCount = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _glowAnim = Tween<double>(begin: 8, end: 24)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Future<void> _roll() async {
    if (_rolling) return;
    setState(() => _rolling = true);

    // Shake + rumble
    await _shakeCtrl.forward(from: 0);

    // Pick a random quote and determine rarity
    final quotes = QuoteService.zeroTwoQuotes;
    final quoteIndex =
        (DateTime.now().millisecondsSinceEpoch + _rollCount * 37) %
            quotes.length;
    final quote = quotes[quoteIndex];
    final rarity = _rarityForIndex(quoteIndex, quotes.length);

    await _particleCtrl.forward(from: 0);

    if (mounted) {
      setState(() {
        _quote = quote;
        _rarity = rarity;
        _rolling = false;
        _hasRolled = true;
        _rollCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(_rarity);

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              children: [
                Text('GACHA QUOTES',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3)),
                const SizedBox(height: 4),
                Text('Roll for a rare Zero Two quote, Darling~ 🎲',
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),

          // ── Rarity indicator bar ─────────────────────────────────────────────
          if (_hasRolled)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _GachaRarity.values.reversed.map((r) {
                  final active = r == _rarity;
                  final c = _rarityColor(r);
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: active ? 6 : 3,
                      decoration: BoxDecoration(
                        color: active ? c : c.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                    color: c.withValues(alpha: 0.6),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          if (_hasRolled) ...[
            const SizedBox(height: 6),
            Text(_rarityLabel(_rarity),
                style: GoogleFonts.outfit(
                    color: rarityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
          ],

          const SizedBox(height: 16),

          // ── Quote card ───────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: Listenable.merge([_shakeAnim, _glowAnim]),
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _hasRolled
                              ? [
                                  rarityColor.withValues(alpha: 0.18),
                                  rarityColor.withValues(alpha: 0.06),
                                  const Color(0xFF0D0D1A),
                                ]
                              : [
                                  Colors.pinkAccent.withValues(alpha: 0.10),
                                  Colors.deepPurple.withValues(alpha: 0.06),
                                  const Color(0xFF0D0D1A),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _hasRolled
                              ? rarityColor.withValues(alpha: 0.5)
                              : Colors.pinkAccent.withValues(alpha: 0.2),
                          width: _hasRolled ? 1.5 : 1.0,
                        ),
                        boxShadow: _hasRolled
                            ? [
                                BoxShadow(
                                  color: rarityColor.withValues(alpha: 0.25),
                                  blurRadius: _glowAnim.value,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: _hasRolled
                          ? _buildQuoteContent(rarityColor)
                          : _buildEmptyState(),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Roll count ───────────────────────────────────────────────────────
          if (_rollCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  '$_rollCount roll${_rollCount == 1 ? '' : 's'} · ${QuoteService.zeroTwoQuotes.length} quotes',
                  style:
                      GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
            ),

          // ── Roll button ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: GestureDetector(
              onTap: _roll,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _rolling
                      ? LinearGradient(
                          colors: [
                            Colors.white12,
                            Colors.white10,
                          ],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFF9B59B6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: _rolling
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.pinkAccent.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _rolling ? '✨  Rolling...' : '🎲  ROLL FOR QUOTE',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎲', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('Your quote awaits...',
              style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Tap ROLL to get a Zero Two quote!',
              style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuoteContent(Color color) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rarity star decoration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _rarity.index + 1 < 4 ? _rarity.index + 1 : 4,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.star_rounded, color: color, size: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Big quote character
          Text('❝',
              style: TextStyle(
                  fontSize: 40,
                  color: color.withValues(alpha: 0.6),
                  height: 0.5)),
          const SizedBox(height: 16),
          Text(
            _quote,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Text('❞',
              style: TextStyle(
                  fontSize: 40,
                  color: color.withValues(alpha: 0.6),
                  height: 0.5)),
          const SizedBox(height: 16),
          // Author badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text('— Zero Two 💕',
                style: GoogleFonts.outfit(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
