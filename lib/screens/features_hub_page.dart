import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'spinner_wheel_page.dart';
import 'never_have_i_ever_page.dart';
import 'draw_lots_page.dart';
import 'relationship_trivia_page.dart';
import 'would_you_rather_page.dart';
import 'zero_two_diary_page.dart';
import 'fortune_cookie_page.dart';
import 'roleplay_scenario_page.dart';
import 'life_advice_page.dart';
import 'writing_helper_page.dart';
import 'relationship_advice_page.dart';
import 'anime_recommender_page.dart';
import 'book_recommender_page.dart';
import 'movie_recommender_page.dart';
import 'quote_of_day_page.dart';
import 'notes_pad_page.dart';
import 'dream_journal_page.dart';
import 'leaderboard_page.dart';
import 'cloud_sync_page.dart';
import 'friends_page.dart';
import 'global_quest_board_page.dart';
import 'pinned_messages_page.dart';
import 'scheduled_messages_page.dart';
import 'checkin_streak_page.dart';
import 'chat_analytics_page.dart';
import 'relationship_level_map_page.dart';
import 'year_in_review_page.dart';
import 'achievements_gallery_page.dart';
import 'anniversary_page.dart';
import 'late_night_mode_page.dart';
import 'notifications_settings_page.dart';
import 'star_map_page.dart';

// ─── Hub category model ──────────────────────────────────────────────────────
class _HubCategory {
  final String title;
  final String emoji;
  final String description;
  final Color color;
  final List<_HubItem> items;
  const _HubCategory({
    required this.title,
    required this.emoji,
    required this.description,
    required this.color,
    required this.items,
  });
}

class _HubItem {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const _HubItem(
      {required this.label, required this.icon, required this.builder});
}

// ─── Sakura painter ──────────────────────────────────────────────────────────
class _SakuraPainter extends CustomPainter {
  final double t;
  final List<_Petal> petals;
  _SakuraPainter(this.t, this.petals);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      final x =
          (p.x * size.width + sin(t * p.speed + p.phase) * 18) % size.width;
      final y = (p.y * size.height + t * p.speed * 60) % size.height;
      final paint = Paint()..color = p.color.withValues(alpha: p.alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.speed + p.phase);
      _drawPetal(canvas, paint, p.size);
      canvas.restore();
    }
  }

  void _drawPetal(Canvas canvas, Paint paint, double sz) {
    final path = Path()
      ..moveTo(0, -sz)
      ..quadraticBezierTo(sz * 0.8, -sz * 0.5, 0, sz * 0.5)
      ..quadraticBezierTo(-sz * 0.8, -sz * 0.5, 0, -sz)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SakuraPainter old) => true;
}

class _Petal {
  final double x, y, size, speed, phase, alpha;
  final Color color;
  const _Petal({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.alpha,
    required this.color,
  });
}

// ─── Main Page ────────────────────────────────────────────────────────────────
class FeaturesHubPage extends StatefulWidget {
  const FeaturesHubPage({super.key});
  @override
  State<FeaturesHubPage> createState() => _FeaturesHubPageState();
}

class _FeaturesHubPageState extends State<FeaturesHubPage>
    with TickerProviderStateMixin {
  late AnimationController _sakuraCtrl;
  int? _expandedIdx;
  late List<_Petal> _petals;
  late List<_HubCategory> _categories;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _petals = List.generate(
        18,
        (_) => _Petal(
              x: rng.nextDouble(),
              y: rng.nextDouble(),
              size: 3 + rng.nextDouble() * 5,
              speed: 0.3 + rng.nextDouble() * 0.7,
              phase: rng.nextDouble() * pi * 2,
              alpha: 0.06 + rng.nextDouble() * 0.1,
              color: [
                const Color(0xFFFFB7D5),
                const Color(0xFFFFCCE3),
                Colors.white
              ][rng.nextInt(3)],
            ));

    _sakuraCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();

    _categories = _buildCategories();
  }

  @override
  void dispose() {
    _sakuraCtrl.dispose();
    super.dispose();
  }

  List<_HubCategory> _buildCategories() => [
        _HubCategory(
          title: 'Games',
          emoji: '🎮',
          description: 'Play mini-games and earn XP',
          color: Colors.pinkAccent,
          items: [
            _HubItem(
                label: 'Spin the Wheel',
                icon: Icons.casino_outlined,
                builder: (_) => const SpinnerWheelPage()),
            _HubItem(
                label: 'Never Have I Ever',
                icon: Icons.emoji_people_outlined,
                builder: (_) => const NeverHaveIEverPage()),
            _HubItem(
                label: 'Draw Lots',
                icon: Icons.grass_outlined,
                builder: (_) => const DrawLotsPage()),
            _HubItem(
                label: 'DITF Trivia',
                icon: Icons.quiz_outlined,
                builder: (_) => const RelationshipTriviaPage()),
            _HubItem(
                label: 'Would You Rather',
                icon: Icons.compare_arrows_outlined,
                builder: (_) => const WouldYouRatherPage()),
          ],
        ),
        _HubCategory(
          title: 'AI & Story',
          emoji: '🤖',
          description: 'Stories, roleplay, and AI interactions',
          color: Colors.deepPurpleAccent,
          items: [
            _HubItem(
                label: 'ZT\'s Diary',
                icon: Icons.book_outlined,
                builder: (_) => const ZeroTwoDiaryPage()),
            _HubItem(
                label: 'Fortune Cookie',
                icon: Icons.cookie_outlined,
                builder: (_) => const FortuneCookiePage()),
            _HubItem(
                label: 'Roleplay',
                icon: Icons.theater_comedy_outlined,
                builder: (_) => const RoleplayScenarioPage()),
            _HubItem(
                label: 'Life Advice',
                icon: Icons.lightbulb_outline,
                builder: (_) => const LifeAdvicePage()),
            _HubItem(
                label: 'Writing Helper',
                icon: Icons.edit_note_outlined,
                builder: (_) => const WritingHelperPage()),
            _HubItem(
                label: 'Relationship Advice',
                icon: Icons.favorite_border_outlined,
                builder: (_) => const RelationshipAdvicePage()),
          ],
        ),
        _HubCategory(
          title: 'Recommendations',
          emoji: '📚',
          description: 'Discover anime, books, and movies',
          color: Colors.cyanAccent,
          items: [
            _HubItem(
                label: 'Anime',
                icon: Icons.live_tv_outlined,
                builder: (_) => const AnimeRecommenderPage()),
            _HubItem(
                label: 'Books',
                icon: Icons.menu_book_outlined,
                builder: (_) => const BookRecommenderPage()),
            _HubItem(
                label: 'Movies',
                icon: Icons.movie_outlined,
                builder: (_) => const MovieRecommenderPage()),
            _HubItem(
                label: 'Quote of the Day',
                icon: Icons.format_quote_outlined,
                builder: (_) => const QuoteOfDayPage()),
          ],
        ),
        _HubCategory(
          title: 'Tools',
          emoji: '🛠️',
          description: 'Productivity and journaling apps',
          color: Colors.amberAccent,
          items: [
            _HubItem(
                label: 'Notes Pad',
                icon: Icons.note_alt_outlined,
                builder: (_) => const NotesPadPage()),
            _HubItem(
                label: 'Dream Journal',
                icon: Icons.nights_stay_outlined,
                builder: (_) => const DreamJournalPage()),
          ],
        ),
        _HubCategory(
          title: 'Firebase & Social',
          emoji: '🌐',
          description: 'Cloud, friends, and community features',
          color: Colors.greenAccent,
          items: [
            _HubItem(
                label: 'Leaderboard',
                icon: Icons.leaderboard_outlined,
                builder: (_) => const LeaderboardPage()),
            _HubItem(
                label: 'Cloud Sync',
                icon: Icons.cloud_sync_outlined,
                builder: (_) => const CloudSyncPage()),
            _HubItem(
                label: 'Friends',
                icon: Icons.people_outline,
                builder: (_) => const FriendsPage()),
            _HubItem(
                label: 'Global Quests',
                icon: Icons.explore_outlined,
                builder: (_) => const GlobalQuestBoardPage()),
            _HubItem(
                label: 'Pinned Messages',
                icon: Icons.push_pin_outlined,
                builder: (_) => const PinnedMessagesPage()),
            _HubItem(
                label: 'Scheduled Msgs',
                icon: Icons.schedule_outlined,
                builder: (_) => const ScheduledMessagesPage()),
            _HubItem(
                label: 'Check-in Streak',
                icon: Icons.local_fire_department_outlined,
                builder: (_) => const CheckinStreakPage()),
          ],
        ),
        _HubCategory(
          title: 'Stats & Insights',
          emoji: '📊',
          description: 'Track your relationship journey',
          color: Colors.orangeAccent,
          items: [
            _HubItem(
                label: 'Chat Analytics',
                icon: Icons.bar_chart_outlined,
                builder: (_) => const ChatAnalyticsPage()),
            _HubItem(
                label: 'Level Map',
                icon: Icons.map_outlined,
                builder: (_) => const RelationshipLevelMapPage()),
            _HubItem(
                label: 'Year in Review',
                icon: Icons.calendar_month_outlined,
                builder: (_) => const YearInReviewPage()),
            _HubItem(
                label: 'Achievements',
                icon: Icons.emoji_events_outlined,
                builder: (_) => const AchievementsGalleryPage()),
            _HubItem(
                label: 'Star Map',
                icon: Icons.auto_awesome_outlined,
                builder: (_) => const StarMapPage()),
            _HubItem(
                label: 'Anniversary',
                icon: Icons.favorite_outlined,
                builder: (_) => const AnniversaryPage()),
          ],
        ),
        _HubCategory(
          title: 'Settings',
          emoji: '⚙️',
          description: 'Customize your experience',
          color: Colors.blueAccent,
          items: [
            _HubItem(
                label: 'Night Mode',
                icon: Icons.nights_stay_outlined,
                builder: (_) => const LateNightModePage()),
            _HubItem(
                label: 'Notifications',
                icon: Icons.notifications_outlined,
                builder: (_) => const NotificationsSettingsPage()),
          ],
        ),
      ];

  void _toggle(int idx) =>
      setState(() => _expandedIdx = _expandedIdx == idx ? null : idx);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: Stack(
        children: [
          // Sakura background
          AnimatedBuilder(
            animation: _sakuraCtrl,
            builder: (_, __) => CustomPaint(
              painter: _SakuraPainter(_sakuraCtrl.value * 2 * pi, _petals),
              child: const SizedBox.expand(),
            ),
          ),

          // Top gradient fade
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF160B2E),
                    const Color(0xFF0A0A16).withValues(alpha: 0)
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ALL FEATURES',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 1.5)),
                        Text('Tap a category to explore',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 12)),
                      ]),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
                    ),
                    child: Text('🌸 Hub',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),

              const SizedBox(height: 12),

              // Category list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) => _buildCategoryCard(i),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(int idx) {
    final cat = _categories[idx];
    final isOpen = _expandedIdx == idx;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isOpen
            ? cat.color.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: isOpen
              ? cat.color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: isOpen
            ? [
                BoxShadow(
                    color: cat.color.withValues(alpha: 0.15), blurRadius: 20)
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _toggle(idx),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(children: [
                // Emoji glow box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cat.color.withValues(alpha: isOpen ? 0.2 : 0.1),
                    border: Border.all(color: cat.color.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                      child: Text(cat.emoji,
                          style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.title,
                            style: GoogleFonts.outfit(
                                color: isOpen ? cat.color : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(cat.description,
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 11)),
                      ]),
                ),
                // Count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: cat.color.withValues(alpha: 0.15),
                  ),
                  child: Text('${cat.items.length}',
                      style: GoogleFonts.outfit(
                          color: cat.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: isOpen ? cat.color : Colors.white38),
                ),
              ]),
            ),
          ),

          // Expandable items grid
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(children: [
                Divider(color: cat.color.withValues(alpha: 0.2), height: 1),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: cat.items.length,
                  itemBuilder: (ctx, j) {
                    final item = cat.items[j];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: item.builder)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: cat.color.withValues(alpha: 0.07),
                          border: Border.all(
                              color: cat.color.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, color: cat.color, size: 24),
                              const SizedBox(height: 6),
                              Text(item.label,
                                  style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                  maxLines: 2),
                            ]),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
