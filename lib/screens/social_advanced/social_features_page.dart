import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialFeaturesPage extends StatefulWidget {
  const SocialFeaturesPage({super.key});

  @override
  State<SocialFeaturesPage> createState() => _SocialFeaturesPageState();
}

class _SocialFeaturesPageState extends State<SocialFeaturesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  static const double _socialScore = 742;
  static const double _maxScore = 1000;

  final List<_Friend> _friends = const [
    _Friend('Sakura M.', 'Anime & Manga', 94, Colors.pink),
    _Friend('Hiro T.', 'Gaming & Tech', 87, Colors.blue),
    _Friend('Yuki A.', 'Music & Art', 81, Colors.purple),
    _Friend('Ren K.', 'Fitness & Health', 76, Colors.green),
    _Friend('Mia S.', 'Travel & Food', 71, Colors.orange),
  ];

  final List<_Activity> _feed = const [
    _Activity(Icons.star, 'Earned "Social Butterfly" badge', '2m ago',
        Colors.amber),
    _Activity(Icons.people, 'Connected with 3 new friends', '1h ago',
        Colors.blue),
    _Activity(Icons.emoji_events, 'Reached Level 8 Social Score', '3h ago',
        Colors.purple),
    _Activity(Icons.chat_bubble, 'Completed 50 conversations', '1d ago',
        Colors.teal),
    _Activity(Icons.favorite, 'Received 12 reactions today', '1d ago',
        Colors.pink),
  ];

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);
    _ringCtrl.forward();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Social Features',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1565C0), cs.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreCard(
                      score: _socialScore,
                      max: _maxScore,
                      anim: _ringAnim,
                      cs: cs),
                  const SizedBox(height: 16),
                  _StatsRow(cs: cs),
                  const SizedBox(height: 20),
                  Text('Friend Suggestions',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ..._friends.map((f) => _FriendCard(friend: f, cs: cs)),
                  const SizedBox(height: 20),
                  Text('Activity Feed',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ..._feed.map((a) => _ActivityTile(activity: a, cs: cs)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score Card with animated ring ─────────────────────────────────────────
class _ScoreCard extends StatelessWidget {
  const _ScoreCard(
      {required this.score,
      required this.max,
      required this.anim,
      required this.cs});
  final double score;
  final double max;
  final Animation<double> anim;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: anim,
              builder: (_, __) => SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: (score / max) * anim.value,
                    color: cs.primary,
                    bg: cs.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(score * anim.value).round()}',
                          style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: cs.primary),
                        ),
                        Text('pts',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Social Score',
                      style: GoogleFonts.outfit(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Level 8 — Social Butterfly',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: cs.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('${(max - score).round()} pts to Level 9',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: score / max,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(
      {required this.progress, required this.color, required this.bg});
  final double progress;
  final Color color;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    paint.color = bg;
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Stats Row ──────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Friends', '24', Icons.people_outline),
      ('Reactions', '156', Icons.favorite_outline),
      ('Streak', '12d', Icons.local_fire_department_outlined),
      ('Badges', '8', Icons.emoji_events_outlined),
    ];
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    child: Column(
                      children: [
                        Icon(s.$3, color: cs.primary, size: 22),
                        const SizedBox(height: 4),
                        Text(s.$2,
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(s.$1,
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Friend Card ────────────────────────────────────────────────────────────
class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend, required this.cs});
  final _Friend friend;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: friend.color.withAlpha(40),
          child: Text(
            friend.name[0],
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: friend.color),
          ),
        ),
        title: Text(friend.name,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        subtitle: Text(friend.interests,
            style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${friend.compatibility}%',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green)),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {},
              style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text('Add', style: GoogleFonts.outfit(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity Tile ──────────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.cs});
  final _Activity activity;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: activity.color.withAlpha(30),
          child: Icon(activity.icon, color: activity.color, size: 20),
        ),
        title: Text(activity.text,
            style: GoogleFonts.outfit(fontSize: 13)),
        trailing: Text(activity.time,
            style: GoogleFonts.outfit(
                fontSize: 11, color: cs.onSurfaceVariant)),
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────────────────
class _Friend {
  const _Friend(this.name, this.interests, this.compatibility, this.color);
  final String name;
  final String interests;
  final int compatibility;
  final Color color;
}

class _Activity {
  const _Activity(this.icon, this.text, this.time, this.color);
  final IconData icon;
  final String text;
  final String time;
  final Color color;
}
