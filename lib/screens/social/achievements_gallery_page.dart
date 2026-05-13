import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/games_gamification/achievements_service.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementsGalleryPage extends StatefulWidget {
  const AchievementsGalleryPage({super.key});

  @override
  State<AchievementsGalleryPage> createState() =>
      _AchievementsGalleryPageState();
}

class _AchievementsGalleryPageState extends State<AchievementsGalleryPage> {
  String _filter = 'All';
  final List<String> _filters = <String>['All', 'Unlocked', 'Locked'];

  @override
  void initState() {
    super.initState();
    _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    try {
      final unlocked = AchievementsService.instance.unlocked;
      await FirebaseFirestore.instance
          .collection('achievements')
          .doc(user.uid)
          .set({
        'unlocked': unlocked,
        'total': AchievementsService.all.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _refresh() async {
    await AchievementsService.instance.load();
    await _syncToCloud();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final aff = AffectionService.instance;
    const all = AchievementsService.all;
    final unlocked = AchievementsService.instance.unlocked;
    final unlockedCount = unlocked.length;
    final totalCount = all.length;
    final pct =
        totalCount == 0 ? 0 : (unlockedCount / totalCount * 100).round();

    final filtered = all.where((achievement) {
      if (_filter == 'Unlocked') {
        return unlocked.contains(achievement.id);
      }
      if (_filter == 'Locked') {
        return !unlocked.contains(achievement.id);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: const Color(0xFF0B0A14),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACHIEVEMENTS',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.4,
                            ),
                          ),
                          Text(
                            'Badges, milestones, and bond progress',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: V2Theme.primaryColor,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      GlassCard(
                        margin: EdgeInsets.zero,
                        glow: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Badge progress',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$unlockedCount / $totalCount unlocked',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$pct% complete with ${aff.points} bond points collected across the app.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ProgressRing(
                              progress: totalCount == 0
                                  ? 0
                                  : unlockedCount / totalCount,
                              foreground: V2Theme.primaryColor,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    color: V2Theme.primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$pct%',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Complete',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Unlocked',
                              value: '$unlockedCount',
                              icon: Icons.lock_open_rounded,
                              color: V2Theme.primaryColor,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Locked',
                              value: '${totalCount - unlockedCount}',
                              icon: Icons.lock_outline_rounded,
                              color: V2Theme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Filter',
                              value: _filter,
                              icon: Icons.tune_rounded,
                              color: Colors.amberAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Bond XP',
                              value: '${aff.points}',
                              icon: Icons.favorite_rounded,
                              color: Colors.lightGreenAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final selected = filter == _filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: selected,
                                onSelected: (_) {
                                  if (!mounted) return;
                                  setState(() => _filter = filter);
                                },
                                labelStyle: GoogleFonts.outfit(
                                  color:
                                      selected ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                                selectedColor: V2Theme.primaryColor
                                    .withValues(alpha: 0.26),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.06),
                                side: BorderSide(
                                  color: selected
                                      ? V2Theme.primaryColor
                                      : Colors.white12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        EmptyState(
                          icon: Icons.workspace_premium_outlined,
                          title: 'No achievements in this view',
                          subtitle:
                              'Try a different filter or keep exploring the app to unlock new badges.',
                          buttonText: 'Show All',
                          onButtonPressed: () =>
                              setState(() => _filter = 'All'),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final achievement = filtered[index];
                            final isUnlocked =
                                unlocked.contains(achievement.id);
                            return AnimatedEntry(
                              index: index,
                              child: _AchievementCard(
                                achievement: achievement,
                                unlocked: isUnlocked,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
  });

  final AchievementDef achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final accent = unlocked ? V2Theme.primaryColor : Colors.white24;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      glow: unlocked,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 38,
                  color: unlocked ? Colors.white : const Color(0x44FFFFFF),
                ),
              ),
              if (unlocked)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.black,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            style: GoogleFonts.outfit(
              color: unlocked ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            achievement.description,
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: 11,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              unlocked ? 'Unlocked' : 'In Progress',
              style: GoogleFonts.outfit(
                color: unlocked ? accent : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
