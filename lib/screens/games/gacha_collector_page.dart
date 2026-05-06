import 'dart:async' show unawaited;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

/// Gacha Waifu Collector — Daily card pulls with rarity tiers + animations.
class GachaCollectorPage extends StatefulWidget {
  const GachaCollectorPage({super.key});
  @override
  State<GachaCollectorPage> createState() => _GachaCollectorPageState();
}

class _GachaCollectorPageState extends State<GachaCollectorPage>
    with TickerProviderStateMixin {
  final Random _rng = Random();
  late AnimationController _spinCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _spinAnim;
  bool _pulling = false;
  _WaifuCard? _lastPull;
  final List<_WaifuCard> _collection = [];

  static const List<_WaifuCard> _pool = [
    // SSR (3% chance)
    _WaifuCard('Zero Two', '02', _Rarity.ssr, '💗', Color(0xFFE91E63),
        'Darling in the FRANXX'),
    _WaifuCard('Rem', 'レム', _Rarity.ssr, '💙', Color(0xFF2196F3), 'Re:Zero'),
    _WaifuCard('Miku', '初音', _Rarity.ssr, '🩵', Color(0xFF00BCD4), 'Vocaloid'),
    // SR (12% chance)
    _WaifuCard(
        'Makima', '鎖', _Rarity.sr, '🔴', Color(0xFFD32F2F), 'Chainsaw Man'),
    _WaifuCard(
        'Yor Forger', '殺', _Rarity.sr, '🖤', Color(0xFF424242), 'Spy x Family'),
    _WaifuCard(
        'Nezuko', '禰', _Rarity.sr, '🌸', Color(0xFFFF9800), 'Demon Slayer'),
    _WaifuCard('Mai Sakurajima', '桜', _Rarity.sr, '💜', Color(0xFF9C27B0),
        'Bunny Girl Senpai'),
    _WaifuCard(
        'Power', '力', _Rarity.sr, '🧡', Color(0xFFFF5722), 'Chainsaw Man'),
    // R (35% chance)
    _WaifuCard('Hinata', '日', _Rarity.r, '🤍', Color(0xFF7986CB), 'Naruto'),
    _WaifuCard(
        'Mikasa', '巨', _Rarity.r, '⚔️', Color(0xFF455A64), 'Attack on Titan'),
    _WaifuCard('Asuna', '剣', _Rarity.r, '🧡', Color(0xFFFF7043), 'SAO'),
    _WaifuCard('Nami', '海', _Rarity.r, '🍊', Color(0xFFFFA726), 'One Piece'),
    _WaifuCard('Erza', '鎧', _Rarity.r, '❤️', Color(0xFFC62828), 'Fairy Tail'),
    // N (50% chance)
    _WaifuCard('Sakura', '桜', _Rarity.n, '🌸', Color(0xFFF48FB1), 'Naruto'),
    _WaifuCard('Ochako', '∞', _Rarity.n, '🤎', Color(0xFF8D6E63), 'MHA'),
    _WaifuCard('Tohru', '竜', _Rarity.n, '💛', Color(0xFFFDD835), 'Dragon Maid'),
    _WaifuCard('Emilia', '氷', _Rarity.n, '🤍', Color(0xFFE0E0E0), 'Re:Zero'),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('gacha_collector'));
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _spinAnim = CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOutExpo);
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  _WaifuCard _rollCard() {
    final roll = _rng.nextDouble() * 100;
    List<_WaifuCard> pool;
    if (roll < 3) {
      pool = _pool.where((c) => c.rarity == _Rarity.ssr).toList();
    } else if (roll < 15) {
      pool = _pool.where((c) => c.rarity == _Rarity.sr).toList();
    } else if (roll < 50) {
      pool = _pool.where((c) => c.rarity == _Rarity.r).toList();
    } else {
      pool = _pool.where((c) => c.rarity == _Rarity.n).toList();
    }
    return pool[_rng.nextInt(pool.length)];
  }

  Future<void> _pull() async {
    if (_pulling) return;
    setState(() {
      _pulling = true;
      _lastPull = null;
    });
    HapticFeedback.heavyImpact();

    _spinCtrl.reset();
    _spinCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1800));

    final card = _rollCard();
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    setState(() {
      _lastPull = card;
      _collection.insert(0, card);
      _pulling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'GACHA COLLECTION',
      subtitle: 'Unlock Rare Waifu Cards',
      onBack: () => Navigator.pop(context),
      actions: [
        Center(
            child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text('${_collection.length} cards',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        )),
      ],
      content: Column(
        children: [
          const SizedBox(height: 20),
          // Pull Area
          Expanded(
            flex: 3,
            child: Center(
              child: _pulling
                  ? AnimatedBuilder(
                      animation: _spinAnim,
                      builder: (_, __) => Transform.rotate(
                        angle: _spinAnim.value * 6 * pi,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [
                              Colors.amber,
                              Colors.deepPurple,
                              Colors.pinkAccent
                            ]),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5)
                            ],
                          ),
                          child: const Center(
                              child: Text('✨', style: TextStyle(fontSize: 40))),
                        ),
                      ),
                    )
                  : _lastPull != null
                      ? _buildRevealCard(_lastPull!)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎴', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 12),
                            Text('Tap to pull!',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
            ),
          ),

          // Pull Button
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
            child: GestureDetector(
              onTap: _pull,
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                        colors: [Colors.amber.shade700, Colors.deepPurple]),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.amber
                              .withValues(alpha: 0.2 + _glowCtrl.value * 0.3),
                          blurRadius: 20,
                          spreadRadius: -4)
                    ],
                  ),
                  child: const Center(
                      child: Text('✨ PULL ✨',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3))),
                ),
              ),
            ),
          ),

          // Rates info
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('SSR 3% • SR 12% • R 35% • N 50%',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
          ),

          // Collection
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('📦 Collection',
                        style: TextStyle(
                            color: Colors.grey.shade300,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
                Expanded(
                  child: _collection.isEmpty
                      ? Center(
                          child: Text('No cards yet',
                              style: TextStyle(color: Colors.grey.shade700)))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8),
                          itemCount: _collection.length,
                          itemBuilder: (_, i) => _buildMiniCard(_collection[i]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealCard(_WaifuCard card) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (_, val, child) => Transform.scale(scale: val, child: child),
      child: Container(
        width: 180,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
              colors: [card.color, card.color.withValues(alpha: 0.4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          border: Border.all(color: card.rarity.borderColor, width: 3),
          boxShadow: [
            BoxShadow(
                color: card.color.withValues(alpha: 0.5),
                blurRadius: 25,
                spreadRadius: -5)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 36)),
            Text(card.kanji,
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w100,
                    color: Colors.white.withValues(alpha: 0.3))),
            const SizedBox(height: 8),
            Text(card.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            Text(card.anime,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: card.rarity.borderColor.withValues(alpha: 0.3),
                  border: Border.all(color: card.rarity.borderColor)),
              child: Text(card.rarity.label,
                  style: TextStyle(
                      color: card.rarity.borderColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard(_WaifuCard card) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(colors: [
          card.color.withValues(alpha: 0.3),
          card.color.withValues(alpha: 0.1)
        ]),
        border: Border.all(
            color: card.rarity.borderColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(card.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(card.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          Text(card.rarity.label,
              style: TextStyle(
                  color: card.rarity.borderColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

enum _Rarity {
  ssr('SSR', Color(0xFFFFD700)),
  sr('SR', Color(0xFFE040FB)),
  r('R', Color(0xFF42A5F5)),
  n('N', Color(0xFF78909C));

  final String label;
  final Color borderColor;
  const _Rarity(this.label, this.borderColor);
}

class _WaifuCard {
  final String name;
  final String kanji;
  final _Rarity rarity;
  final String emoji;
  final Color color;
  final String anime;
  const _WaifuCard(
      this.name, this.kanji, this.rarity, this.emoji, this.color, this.anime);
}



