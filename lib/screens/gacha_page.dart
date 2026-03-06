part of '../main.dart';

extension _GachaPageExtension on _ChatHomePageState {
  Widget _buildGachaPage() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'GACHA QUOTES',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Roll for a random Zero Two quote, Darling~ 🎲',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _GachaRoller(),
          ),
        ],
      ),
    );
  }
}

class _GachaRoller extends StatefulWidget {
  @override
  State<_GachaRoller> createState() => _GachaRollerState();
}

class _GachaRollerState extends State<_GachaRoller>
    with SingleTickerProviderStateMixin {
  String _quote = 'Tap the button to get a quote from me, Darling~ 💕';
  bool _rolling = false;
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _roll() async {
    if (_rolling) return;
    setState(() => _rolling = true);
    await _anim.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _quote = QuoteService.getRandomZeroTwoQuote());
    await _anim.reverse();
    setState(() => _rolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Quote card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.18),
                    Colors.pinkAccent.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primary.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  const Text('💕', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 16),
                  Text(
                    _quote,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Roll button
        GestureDetector(
          onTap: _roll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pinkAccent, primary],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_rolling ? '✨ Rolling...' : '🎲  ROLL',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Zero Two, ${QuoteService.zeroTwoQuotes.length} quotes total',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
      ],
    );
  }
}
