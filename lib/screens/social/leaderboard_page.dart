import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/widgets/best_records_display_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _xpBoard = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _affectionBoard = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _streakBoard = <Map<String, dynamic>>[];
  bool _loading = true;
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  int get _myXpRank => _xpBoard.indexWhere((item) => item['uid'] == _myUid) + 1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
    _publishMyScore();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _publishMyScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final aff = AffectionService.instance;
    try {
      await FirebaseFirestore.instance
          .collection('leaderboard')
          .doc(user.uid)
          .set(<String, dynamic>{
        'uid': user.uid,
        'name': user.displayName ?? user.email?.split('@').first ?? 'Darling',
        'photoUrl': user.photoURL ?? '',
        'xp': aff.points,
        'affection': aff.points,
        'streak': aff.streakDays,
        'level': aff.levelName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      if (kDebugMode) debugPrint('Leaderboard publish error: $error');
    }
  }

  Future<void> _load() async {
    try {
      final ref = FirebaseFirestore.instance.collection('leaderboard');
      final xp = await ref.orderBy('xp', descending: true).limit(50).get();
      final affection =
          await ref.orderBy('affection', descending: true).limit(50).get();
      final streak =
          await ref.orderBy('streak', descending: true).limit(50).get();
      if (!mounted) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _xpBoard = xp.docs.map((doc) => doc.data()).toList();
        _affectionBoard = affection.docs.map((doc) => doc.data()).toList();
        _streakBoard = streak.docs.map((doc) => doc.data()).toList();
        _loading = false;
      });
    } catch (error) {
      if (kDebugMode) debugPrint('Leaderboard load error: $error');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load leaderboard.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    await _publishMyScore();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'LEADERBOARD',
      subtitle: 'Compete with other Darlings',
      onBack: () => Navigator.pop(context),
      content: _loading
          ? const Center(
              child: CircularProgressIndicator(color: V2Theme.primaryColor),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
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
                                    'Competitive snapshot',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _myXpRank > 0
                                        ? 'You are #$_myXpRank on XP board'
                                        : 'Climb the first board',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Track top XP, affection, and streak players in one place and watch where your bond currently lands.',
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
                              progress: _xpBoard.isEmpty
                                  ? 0
                                  : 1 -
                                      ((_myXpRank <= 0
                                                  ? _xpBoard.length
                                                  : _myXpRank) /
                                              _xpBoard.length)
                                          .clamp(0, 1),
                              foreground: V2Theme.primaryColor,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: V2Theme.primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _myXpRank > 0 ? '#$_myXpRank' : '--',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'XP Rank',
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
                              title: 'XP Board',
                              value: '${_xpBoard.length}',
                              icon: Icons.star_rounded,
                              color: V2Theme.primaryColor,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Affection',
                              value: '${_affectionBoard.length}',
                              icon: Icons.favorite_rounded,
                              color: V2Theme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Streak',
                              value: '${_streakBoard.length}',
                              icon: Icons.local_fire_department_rounded,
                              color: Colors.orangeAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'My Rank',
                              value: _myXpRank > 0 ? '#$_myXpRank' : '--',
                              icon: Icons.person_pin_circle_rounded,
                              color: Colors.lightGreenAccent,
                            ),
                          ),
                        ],
                      ),
                      TabBar(
                        controller: _tabCtrl,
                        indicatorColor: V2Theme.primaryColor,
                        labelColor: V2Theme.primaryColor,
                        unselectedLabelColor: Colors.white38,
                        labelStyle: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        tabs: const [
                          Tab(text: 'XP'),
                          Tab(text: 'Affection'),
                          Tab(text: 'Streak'),
                          Tab(text: 'My Records'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildBoard(_xpBoard, 'xp', 'XP'),
                      _buildBoard(_affectionBoard, 'affection', 'Love'),
                      _buildBoard(_streakBoard, 'streak', 'Streak',
                          suffix: ' days'),
                      const BestRecordsDisplay(
                          compact: false, showHeader: false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBoard(List<Map<String, dynamic>> data, String key, String label,
      {String suffix = ''}) {
    if (data.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No $label data yet',
            subtitle:
                'Pull to refresh after scores are published and the board will fill in here.',
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: V2Theme.primaryColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: data.length,
        itemBuilder: (ctx, i) {
          final item = data[i];
          final isMe = item['uid'] == _myUid;
          final medals = ['🥇', '🥈', '🥉'];
          final rank = i < 3 ? medals[i] : '#${i + 1}';
          final name = (item['name'] as String?) ?? 'Darling';
          final value = item[key] ?? 0;
          return AnimatedEntry(
            index: i,
            child: GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              glow: isMe,
              child: Row(
                children: [
                  Text(
                    rank,
                    style: TextStyle(
                      fontSize: i < 3 ? 22 : 14,
                      color: i < 3 ? null : Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        V2Theme.primaryColor.withValues(alpha: 0.3),
                    backgroundImage:
                        (item['photoUrl'] as String?)?.isNotEmpty == true
                            ? NetworkImage(item['photoUrl'].toString())
                            : null,
                    child: (item['photoUrl'] as String?)?.isNotEmpty != true
                        ? Text(
                            name[0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMe ? '$name (you)' : name,
                          style: GoogleFonts.outfit(
                            color: isMe ? V2Theme.primaryColor : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          item['level'] as String? ?? '',
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$label $value$suffix',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
