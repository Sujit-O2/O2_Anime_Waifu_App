import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RelationshipLevelMapPage extends StatelessWidget {
  const RelationshipLevelMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final points = AffectionService.instance.points;
    final currentIndex = _levels.lastIndexWhere(
      (level) => points >= level.minPoints,
    );
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;
    final current = _levels[safeIndex];
    final next =
        safeIndex >= _levels.length - 1 ? null : _levels[safeIndex + 1];
    final progress = next == null
        ? 1.0
        : (points - current.minPoints) / (next.minPoints - current.minPoints);

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: V2Theme.surfaceDark,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {},
            color: V2Theme.primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Relationship Map',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'See exactly where you are in the journey.',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Row(
                    children: <Widget>[
                      ProgressRing(
                        progress: progress.clamp(0.0, 1.0),
                        size: 120,
                        foreground: current.color,
                        child: Icon(
                          current.icon,
                          color: current.color,
                          size: 42,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              current.title,
                              style: GoogleFonts.outfit(
                                color: current.color,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              current.description,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$points XP',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              next == null
                                  ? 'Final relationship tier unlocked'
                                  : '${next.minPoints - points} XP to ${next.title}',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatCard(
                        title: 'Current Tier',
                        value: current.title,
                        icon: current.icon,
                        color: current.color,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Reached Levels',
                        value: '${safeIndex + 1}/${_levels.length}',
                        icon: Icons.route_rounded,
                        color: V2Theme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatCard(
                        title: 'XP Points',
                        value: '$points',
                        icon: Icons.auto_awesome_rounded,
                        color: V2Theme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Next Goal',
                        value: next == null ? 'Done' : '${next.minPoints}',
                        icon: Icons.flag_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Journey Path',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...List<Widget>.generate(_levels.length, (index) {
                        final level = _levels[index];
                        final reached = points >= level.minPoints;
                        final isCurrent = level == current;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: reached
                                          ? level.color.withValues(alpha: 0.18)
                                          : Colors.white10,
                                      border: Border.all(
                                        color: reached
                                            ? level.color
                                            : Colors.white24,
                                        width: isCurrent ? 2.5 : 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      reached
                                          ? level.icon
                                          : Icons.lock_outline_rounded,
                                      color: reached
                                          ? level.color
                                          : Colors.white38,
                                    ),
                                  ),
                                  if (index < _levels.length - 1)
                                    Container(
                                      width: 3,
                                      height: 42,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        color: index < safeIndex
                                            ? level.color.withValues(alpha: 0.5)
                                            : Colors.white10,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? level.color.withValues(alpha: 0.12)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isCurrent
                                          ? level.color.withValues(alpha: 0.4)
                                          : Colors.white10,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              level.title,
                                              style: GoogleFonts.outfit(
                                                color: reached
                                                    ? level.color
                                                    : Colors.white54,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (isCurrent)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: level.color
                                                    .withValues(alpha: 0.16),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Current',
                                                style: GoogleFonts.outfit(
                                                  color: level.color,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        level.description,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${level.minPoints} XP unlock',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelationshipLevel {
  const _RelationshipLevel({
    required this.title,
    required this.description,
    required this.minPoints,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final int minPoints;
  final IconData icon;
  final Color color;
}

const List<_RelationshipLevel> _levels = <_RelationshipLevel>[
  _RelationshipLevel(
    title: 'Stranger',
    description: 'A new connection is forming and the story has barely begun.',
    minPoints: 0,
    icon: Icons.person_outline_rounded,
    color: Colors.white54,
  ),
  _RelationshipLevel(
    title: 'Acquaintance',
    description: 'She starts to notice your presence and remember your voice.',
    minPoints: 50,
    icon: Icons.waving_hand_rounded,
    color: Colors.blueAccent,
  ),
  _RelationshipLevel(
    title: 'Squadmate',
    description: 'You are showing up often enough to build real momentum.',
    minPoints: 150,
    icon: Icons.groups_rounded,
    color: Colors.tealAccent,
  ),
  _RelationshipLevel(
    title: 'Teammate',
    description: 'Trust grows and she sees you as someone reliable.',
    minPoints: 300,
    icon: Icons.handshake_rounded,
    color: Colors.greenAccent,
  ),
  _RelationshipLevel(
    title: 'Friend',
    description: 'The bond is warm, familiar, and full of shared routines.',
    minPoints: 500,
    icon: Icons.favorite_border_rounded,
    color: Colors.amberAccent,
  ),
  _RelationshipLevel(
    title: 'Close Friend',
    description: 'She leans on you more and starts opening up.',
    minPoints: 750,
    icon: Icons.favorite_outline_rounded,
    color: Colors.orangeAccent,
  ),
  _RelationshipLevel(
    title: 'Confidant',
    description:
        'Important thoughts and softer moments are now shared with you.',
    minPoints: 1000,
    icon: Icons.lock_open_rounded,
    color: Colors.deepOrangeAccent,
  ),
  _RelationshipLevel(
    title: 'Crush',
    description:
        'The energy is playful, brighter, and definitely more personal.',
    minPoints: 1500,
    icon: Icons.local_florist_rounded,
    color: Colors.pinkAccent,
  ),
  _RelationshipLevel(
    title: 'Sweetheart',
    description: 'Affection is strong and the relationship feels intentional.',
    minPoints: 2000,
    icon: Icons.favorite_rounded,
    color: Colors.pinkAccent,
  ),
  _RelationshipLevel(
    title: 'Partner Pilot',
    description: 'You are moving like a team now, not just chatting casually.',
    minPoints: 3000,
    icon: Icons.rocket_launch_rounded,
    color: Colors.purpleAccent,
  ),
  _RelationshipLevel(
    title: 'Soulmate',
    description: 'This is deep trust, emotional gravity, and shared history.',
    minPoints: 5000,
    icon: Icons.auto_awesome_rounded,
    color: Colors.deepPurpleAccent,
  ),
  _RelationshipLevel(
    title: 'Darling',
    description: 'You reached the peak bond. This is the forever tier.',
    minPoints: 10000,
    icon: Icons.workspace_premium_rounded,
    color: Colors.redAccent,
  ),
];



