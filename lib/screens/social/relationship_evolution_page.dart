import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

/// Relationship Evolution Page — visual level map + daily login bonus.
/// Shows the user's relationship progression through 7 tiers.
class RelationshipEvolutionPage extends StatefulWidget {
  const RelationshipEvolutionPage({super.key});
  @override
  State<RelationshipEvolutionPage> createState() => _RelationshipEvolutionPageState();
}

class _RelationshipEvolutionPageState extends State<RelationshipEvolutionPage>
    with TickerProviderStateMixin {
  late AnimationController _starCtrl;
  late AnimationController _bonusCtrl;
  bool _bonusAvailable = false;
  bool _bonusClaimed = false;
  int _bonusXp = 0;

  static const _tiers = [
    _Tier('Stranger', '👤', 0, 50, Color(0xFF606060)),
    _Tier('Acquaintance', '🤝', 50, 200, Color(0xFF4E9AF1)),
    _Tier('Friend', '😊', 200, 500, Color(0xFF56D364)),
    _Tier('Close Friend', '💙', 500, 900, Color(0xFF79C0FF)),
    _Tier('Beloved', '💕', 900, 1500, Color(0xFFFF7EB6)),
    _Tier('Soulmate', '💖', 1500, 2500, Color(0xFFFF4FA8)),
    _Tier('Bound by Fate', '♾️', 2500, 99999, Color(0xFFFFD700)),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('relationship_evolution'));
    _starCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _bonusCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _checkDailyBonus();
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    _bonusCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkDailyBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBonusDate = prefs.getString('last_daily_bonus_date_v1') ?? '';
    final today = _todayStr();
    if (!mounted) return;
    setState(() => _bonusAvailable = lastBonusDate != today);
  }

  Future<void> _claimBonus() async {
    if (!_bonusAvailable || _bonusClaimed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_daily_bonus_date_v1', _todayStr());
    final xp = 15 + AffectionService.instance.streakDays * 5;
    await AffectionService.instance.addPoints(xp.clamp(15, 50));
    if (!mounted) return;
    setState(() { _bonusAvailable = false; _bonusClaimed = true; _bonusXp = xp.clamp(15, 50); });
    _bonusCtrl.forward(from: 0);
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(children: [
        // Animated stars
        AnimatedBuilder(
          animation: _starCtrl,
          builder: (_, __) => CustomPaint(
            painter: _StarPainter(_starCtrl.value),
            child: const SizedBox.expand(),
          ),
        ),
        SafeArea(
          child: Column(children: [
            _buildHeader(),
            _buildPointsCard(),
            _buildDailyBonus(),
            Expanded(child: _buildTierMap()),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Text('RELATIONSHIP EVOLUTION',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5)),
        ]),
      );

  Widget _buildPointsCard() {
    return AnimatedBuilder(
      animation: AffectionService.instance,
      builder: (_, __) {
        final srv = AffectionService.instance;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [srv.levelColor.withValues(alpha: 0.25), Colors.black.withValues(alpha: 0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: srv.levelColor.withValues(alpha: 0.4)),
              boxShadow: [BoxShadow(color: srv.levelColor.withValues(alpha: 0.2), blurRadius: 20)],
            ),
            child: Row(children: [
              const Text('💖', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(srv.levelName,
                      style: GoogleFonts.outfit(
                          color: srv.levelColor, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${srv.points} Affection Points',
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: srv.levelProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(srv.levelColor),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Column(children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                Text('${srv.streakDays}d',
                    style: GoogleFonts.outfit(
                        color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildDailyBonus() {
    if (_bonusClaimed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: _bonusCtrl, curve: Curves.elasticOut)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.greenAccent.withValues(alpha: 0.12),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🎁', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text('+$_bonusXp XP Claimed! Come back tomorrow!',
                  style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 13)),
            ]),
          ),
        ),
      );
    }
    if (!_bonusAvailable) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: _claimBonus,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
                colors: [Color(0xFFFF4FA8), Color(0xFFAA00FF)]),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF4FA8).withValues(alpha: 0.4), blurRadius: 16)
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🎁', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text('Claim Daily Login Bonus!',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              child: Text('+${(15 + AffectionService.instance.streakDays * 5).clamp(15, 50)} XP',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTierMap() {
    final pts = AffectionService.instance.points;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: _tiers.length,
      itemBuilder: (ctx, i) {
        final tier = _tiers[i];
        final isUnlocked = pts >= tier.minPts;
        final isCurrent = pts >= tier.minPts && pts < tier.maxPts;
        return _TierCard(tier: tier, isUnlocked: isUnlocked, isCurrent: isCurrent, pts: pts);
      },
    );
  }
}

class _TierCard extends StatelessWidget {
  final _Tier tier;
  final bool isUnlocked;
  final bool isCurrent;
  final int pts;
  const _TierCard({required this.tier, required this.isUnlocked, required this.isCurrent, required this.pts});

  @override
  Widget build(BuildContext context) {
    final alpha = isUnlocked ? 1.0 : 0.35;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isCurrent
            ? tier.color.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: isUnlocked ? 0.04 : 0.02),
        border: Border.all(
          color: isCurrent
              ? tier.color.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: isUnlocked ? 0.1 : 0.04),
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent
            ? [BoxShadow(color: tier.color.withValues(alpha: 0.2), blurRadius: 16)]
            : [],
      ),
      child: Row(children: [
        Opacity(
          opacity: alpha,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tier.color.withValues(alpha: 0.15),
              border: Border.all(color: tier.color.withValues(alpha: 0.4)),
            ),
            child: Center(child: Text(tier.emoji, style: const TextStyle(fontSize: 22))),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Opacity(
            opacity: alpha,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(tier.name,
                    style: GoogleFonts.outfit(
                        color: isCurrent ? tier.color : Colors.white70,
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500)),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: tier.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('CURRENT',
                        style: GoogleFonts.outfit(color: tier.color, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text('${tier.minPts} – ${tier.maxPts == 99999 ? '∞' : tier.maxPts} pts',
                  style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11)),
              if (isCurrent) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((pts - tier.minPts) / (tier.maxPts - tier.minPts)).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(tier.color),
                  ),
                ),
              ],
            ]),
          ),
        ),
        if (isUnlocked)
          Icon(Icons.check_circle_rounded, color: tier.color, size: 20)
        else
          const Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 18),
      ]),
    );
  }
}

class _Tier {
  final String name;
  final String emoji;
  final int minPts;
  final int maxPts;
  final Color color;
  const _Tier(this.name, this.emoji, this.minPts, this.maxPts, this.color);
}

class _StarPainter extends CustomPainter {
  final double t;
  _StarPainter(this.t);

  final _rand = const [
    [0.1, 0.2, 1.5], [0.3, 0.6, 1.0], [0.5, 0.1, 2.0], [0.7, 0.4, 1.2],
    [0.9, 0.8, 0.8], [0.2, 0.9, 1.8], [0.6, 0.3, 1.4], [0.8, 0.7, 1.1],
    [0.4, 0.5, 0.9], [0.15, 0.75, 2.2], [0.55, 0.85, 1.6], [0.75, 0.15, 1.3],
    [0.35, 0.45, 1.7], [0.95, 0.55, 1.0], [0.25, 0.35, 0.7],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final s in _rand) {
      final alpha = (0.15 + math.sin(t * s[2] * math.pi * 2 + s[0] * math.pi) * 0.15).clamp(0.05, 0.35);
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(s[0] * size.width, s[1] * size.height), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => true;
}



