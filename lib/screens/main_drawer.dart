// ignore_for_file: use_build_context_synchronously
part of '../main.dart';

extension _MainDrawerExtension on _ChatHomePageState {
  Widget _buildNavDrawer(AppThemeMode mode) {
    final theme = AppThemes.getTheme(mode);
    final primary = theme.primaryColor;
    final gradient = AppThemes.getGradient(mode);
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 700;

    final mainItems = [
      {'label': 'Chat', 'icon': Icons.chat_bubble_outline, 'nav': 0},
      {'label': 'Notifications', 'icon': Icons.notifications_outlined, 'nav': 1},
      {'label': 'Videos', 'icon': Icons.videocam_outlined, 'nav': 2},
    ];

    Widget navItem(Map<String, dynamic> item) {
      final navIdx = item['nav'] as int;
      final selected = _navIndex == navIdx;

      if (navIdx == 99) {
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: isSmall ? 10 : 13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.transparent),
            child: Row(children: [
              Icon(item['icon'] as IconData, color: Colors.white54, size: isSmall ? 18 : 20),
              const SizedBox(width: 13),
              Text(item['label'] as String, style: GoogleFonts.outfit(color: Colors.white70, fontSize: isSmall ? 13 : 14)),
              const Spacer(),
              Icon(Icons.open_in_new_rounded, color: Colors.white12, size: 12),
            ]),
          ),
        );
      }
      if (navIdx == 98) {
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: isSmall ? 10 : 13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.transparent),
            child: Row(children: [
              Icon(item['icon'] as IconData, color: Colors.white54, size: isSmall ? 18 : 20),
              const SizedBox(width: 13),
              Text(item['label'] as String, style: GoogleFonts.outfit(color: Colors.white70, fontSize: isSmall ? 13 : 14)),
              const Spacer(),
              Icon(Icons.open_in_new_rounded, color: Colors.white12, size: 12),
            ]),
          ),
        );
      }

      return InkWell(
        onTap: () {
          updateState(() => _navIndex = navIdx);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: isSmall ? 10 : 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? primary.withValues(alpha: 0.18) : Colors.transparent,
            border: Border.all(color: selected ? primary.withValues(alpha: 0.45) : Colors.transparent),
          ),
          child: Row(children: [
            Icon(item['icon'] as IconData, color: selected ? primary : Colors.white54, size: isSmall ? 18 : 20),
            const SizedBox(width: 13),
            Expanded(
              child: Text(item['label'] as String,
                  style: GoogleFonts.outfit(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: isSmall ? 13 : 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
            ),
            if (navIdx == 1 && _notifHistory.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(10)),
                child: Text('${_notifHistory.length}',
                    style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w700)),
              ),
            if (selected) Icon(Icons.chevron_right_rounded, size: 16, color: primary.withValues(alpha: 0.55)),
          ]),
        ),
      );
    }

    Widget sectionHeader(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
          child: Row(children: [
            Text(title,
                style: GoogleFonts.outfit(
                    color: Colors.white24, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08), thickness: 1)),
          ]),
        );

    Widget quickItem(String label, IconData icon, Color color, VoidCallback onTap, {String? badge}) {
      return InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: isSmall ? 7 : 9),
          child: Row(children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 13),
            Expanded(child: Text(label, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13))),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(badge, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, color: Colors.white12, size: 12),
          ]),
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradient.first.withValues(alpha: 0.97), gradient.last.withValues(alpha: 0.97)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              top: 175,
              child: Opacity(
                opacity: 0.32,
                child: Image.asset('assets/gif/sidebar_bg.gif',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.06), Colors.black.withValues(alpha: 0.32)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: _buildDrawerTopBanner(primary),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, isSmall ? 10 : 14, 18, 8),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.2),
                          border: Border.all(color: primary.withValues(alpha: 0.55), width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image(
                            image: _imageProviderFor(assetPath: _appIconImageAsset, customPath: _effectiveAppIconCustomPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.auto_awesome, color: primary, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('ZERO TWO',
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                        Text('CORE 002 · S-002',
                            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, letterSpacing: 1.8)),
                      ]),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent,
                          boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 6)],
                        ),
                      ),
                    ]),
                  ),
                  AnimatedBuilder(
                    animation: AffectionService.instance,
                    builder: (context, child) {
                      final srv = AffectionService.instance;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(srv.levelName,
                                    style: GoogleFonts.outfit(
                                        color: srv.levelColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('${srv.points} pts',
                                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: srv.levelProgress,
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(srv.levelColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                  _buildDrawerAutoListenTile(primary),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SYSTEM METRICS',
                              style: GoogleFonts.outfit(
                                  color: primary.withValues(alpha: 0.8), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          Row(children: [
                            Icon(Icons.memory_outlined, color: Colors.white54, size: 14),
                            const SizedBox(width: 8),
                            Text('Context Nodes:', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                            const Spacer(),
                            Text('${_messages.length}',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.monitor_heart_outlined, color: Colors.white54, size: 14),
                            const SizedBox(width: 8),
                            Text('Core Status:', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                            const Spacer(),
                            Text('Stable',
                                style: GoogleFonts.outfit(
                                    color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.hub_outlined, color: Colors.white54, size: 14),
                            const SizedBox(width: 8),
                            Text('Model Override:', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                            const Spacer(),
                            Expanded(
                              child: Text(
                                  _devModelOverride.isNotEmpty ? _devModelOverride : 'Default',
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      children: [
                        sectionHeader('CORE'),
                        ...mainItems.map((e) => navItem(Map<String, dynamic>.from(e))),
                        sectionHeader('FEATURE HUBS'),

                        // ── 1. WAIFU HUB ─────────────────────────────────────
                        quickItem('Waifu Hub', Icons.auto_awesome_rounded, Colors.pinkAccent, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => HubPage(
                            hubTitle: 'Waifu Hub',
                            hubEmoji: '🌸',
                            hubColor: Colors.pinkAccent,
                            groups: [
                              HubGroup(title: 'Daily Waifu', emoji: '💌', accent: Colors.pinkAccent, features: [
                                HubFeature(label: 'ZT Diary', icon: Icons.book_outlined, color: Colors.pinkAccent, badge: 'Daily', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZeroTwoDiaryPage()))),
                                HubFeature(label: 'Fortune Cookie', icon: Icons.cookie_outlined, color: Colors.amberAccent, badge: '🥠', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FortuneCookiePage()))),
                                HubFeature(label: 'Daily Love Letter', icon: Icons.mail_outline_rounded, color: Colors.pinkAccent, badge: 'Daily', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyLoveLetterPage()))),
                                HubFeature(label: 'Affirmations', icon: Icons.self_improvement_outlined, color: Colors.purpleAccent, badge: 'Daily', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyAffirmationsPage()))),
                                HubFeature(label: 'Quote of Day', icon: Icons.format_quote_outlined, color: Colors.cyanAccent, badge: 'Daily', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteOfDayPage()))),
                              ]),
                              HubGroup(title: 'Stories & Roleplay', emoji: '🎭', accent: Colors.deepPurpleAccent, features: [
                                HubFeature(label: 'Pinned Messages', icon: Icons.push_pin_outlined, color: Colors.deepPurpleAccent, badge: 'Saved', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PinnedMessagesPage()))),
                                HubFeature(label: 'Calendar', icon: Icons.calendar_month_outlined, color: Colors.pinkAccent, badge: 'Events', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZeroTwoCalendarPage()))),
                                HubFeature(label: 'Sleep Mode', icon: Icons.bedtime_outlined, color: Colors.indigoAccent, badge: 'DND', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepModePage()))),
                                HubFeature(label: 'Chat Stats', icon: Icons.insights_rounded, color: Colors.cyanAccent, badge: 'Analytics', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatStatisticsPage(messages: [..._pastMessages, ..._messages])))),
                                HubFeature(label: 'Mood Tracker', icon: Icons.mood_rounded, color: Colors.yellowAccent, badge: 'Daily', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodTrackingPage()))),
                                HubFeature(label: 'Daily Challenge', icon: Icons.emoji_events_outlined, color: Colors.orangeAccent, badge: 'Mission', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyChallengePage()))),
                                HubFeature(label: 'Tarot Reading', icon: Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent, badge: '3 Cards', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TarotReadingPage()))),
                                HubFeature(label: 'Achievements', icon: Icons.emoji_events_rounded, color: Colors.amberAccent, badge: '🏆20', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementRoomPage()))),
                                HubFeature(label: 'Theme', icon: Icons.palette_rounded, color: Colors.purpleAccent, badge: '5 Styles', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSwitcherPage()))),
                                HubFeature(label: 'Love Letters', icon: Icons.mail_rounded, color: Colors.pinkAccent, badge: 'Weekly', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoveLetterPage()))),
                                HubFeature(label: 'Rock Paper Scissors', icon: Icons.sports_esports_rounded, color: Colors.greenAccent, badge: 'Mini Game', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RockPaperScissorsPage()))),
                                HubFeature(label: 'Memory Wall', icon: Icons.photo_album_rounded, color: Colors.cyanAccent, badge: 'Gallery', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryWallPage()))),
                                HubFeature(label: 'Roleplay Scenarios', icon: Icons.theater_comedy_outlined, color: Colors.deepPurpleAccent, badge: '6 Scenes', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleplayScenarioPage()))),
                                HubFeature(label: 'Story RPG', icon: Icons.book_outlined, color: Colors.purpleAccent, badge: '6 Worlds', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryAdventurePage()))),
                                HubFeature(label: 'Virtual Date', icon: Icons.favorite_outline_rounded, color: Colors.redAccent, badge: '5 Scenes', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VirtualDatePage()))),
                                HubFeature(label: 'Our Story', icon: Icons.timeline_outlined, color: Colors.pinkAccent, badge: 'Timeline', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RelationshipTimelinePage()))),
                                HubFeature(label: 'Memory Book', icon: Icons.photo_album_outlined, color: Colors.cyanAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryBookPage()))),
                              ]),
                              HubGroup(title: 'AI Companions', emoji: '🤖', accent: Colors.cyanAccent, features: [
                                HubFeature(label: 'Anime Picks', icon: Icons.movie_filter_outlined, color: Colors.deepPurpleAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnimeRecommenderPage()))),
                                HubFeature(label: 'Book Picks', icon: Icons.menu_book_outlined, color: Colors.amberAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookRecommenderPage()))),
                                HubFeature(label: 'Poem Generator', icon: Icons.auto_fix_high_outlined, color: Colors.deepPurpleAccent, badge: '5 Styles', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoemGeneratorPage()))),
                                HubFeature(label: 'Date Planner', icon: Icons.restaurant_menu_outlined, color: Colors.redAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DateNightPlannerPage()))),
                                HubFeature(label: 'Life Advice', icon: Icons.psychology_outlined, color: Colors.cyanAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LifeAdvicePage()))),
                              ]),
                              HubGroup(title: 'Lore & Knowledge', emoji: '📚', accent: Colors.orangeAccent, features: [
                                HubFeature(label: 'ZeroTwo Facts', icon: Icons.info_outline_rounded, color: Colors.pinkAccent, badge: '20', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZeroTwoFactsPage()))),
                                HubFeature(label: 'DITF Trivia', icon: Icons.quiz_outlined, color: Colors.cyanAccent, badge: '10 Qs', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RelationshipTriviaPage()))),
                                HubFeature(label: 'Daily Trivia', icon: Icons.quiz_outlined, color: Colors.amberAccent, badge: '10 Qs', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTriviaPage()))),
                                HubFeature(label: 'Horoscope', icon: Icons.auto_awesome_outlined, color: Colors.purpleAccent, badge: '12 Signs', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyHoroscopePage()))),
                                HubFeature(label: 'Kaomoji', icon: Icons.emoji_emotions_outlined, color: Colors.yellowAccent, badge: '100+', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KaomojiPickerPage()))),
                              ]),
                              HubGroup(title: 'New Features', emoji: '🆕', accent: Colors.pinkAccent, features: [
                                HubFeature(label: 'Dream Interpreter', icon: Icons.bedtime_rounded, color: Colors.deepPurpleAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DreamInterpreterPage()))),
                                HubFeature(label: 'Story Mode', icon: Icons.book_rounded, color: Colors.purpleAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryModePage()))),
                                HubFeature(label: 'Relationship Coach', icon: Icons.psychology_rounded, color: Colors.pinkAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RelationshipCoachPage()))),
                                HubFeature(label: 'Tic-Tac-Toe', icon: Icons.grid_3x3_rounded, color: Colors.cyanAccent, badge: 'Game', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicTacToePage()))),
                                HubFeature(label: 'Word Association', icon: Icons.text_fields_rounded, color: Colors.tealAccent, badge: 'Game', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WordAssociationPage()))),
                                HubFeature(label: '20 Questions', icon: Icons.help_rounded, color: Colors.amberAccent, badge: 'Game', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TwentyQuestionsPage()))),
                                HubFeature(label: 'Study Timer', icon: Icons.timer_rounded, color: Colors.greenAccent, badge: 'Pomodoro', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyTimerPage()))),
                                HubFeature(label: 'Voice Notes', icon: Icons.note_rounded, color: Colors.orangeAccent, badge: 'Notes', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceNotesPage()))),
                                HubFeature(label: 'Bucket List', icon: Icons.checklist_rounded, color: Colors.redAccent, badge: 'Dreams', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SharedBucketListPage()))),
                                HubFeature(label: 'Daily Challenge', icon: Icons.favorite_rounded, color: Colors.pinkAccent, badge: 'Daily', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyCoupleChallengePage()))),
                              ]),
                            ],
                          )));
                        }, badge: '5 Groups'),

                        // ── ARCADE ───────────────────────────────────────────
                        quickItem(' Arcade Games', Icons.sports_esports_rounded, Colors.greenAccent, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesHubPage()));
                        }, badge: '8 Games'),

                        // ── 2. GAMES & FUN HUB ───────────────────────────────
                        quickItem('🎮  Games & Fun', Icons.sports_esports_outlined, Colors.greenAccent, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => HubPage(
                            hubTitle: 'Games & Fun',
                            hubEmoji: '🎮',
                            hubColor: Colors.greenAccent,
                            groups: [
                              HubGroup(title: 'Card Games', emoji: '🃏', accent: Colors.deepOrangeAccent, features: [
                                HubFeature(label: 'Draw Lots', icon: Icons.casino_outlined, color: Colors.greenAccent, badge: '20 Dares', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DrawLotsPage()))),
                                HubFeature(label: 'Truth or Dare', icon: Icons.local_fire_department_outlined, color: Colors.orangeAccent, badge: 'Game', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TruthOrDarePage()))),
                                HubFeature(label: 'Never Have I Ever', icon: Icons.casino_outlined, color: Colors.deepOrangeAccent, badge: '20 cards', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NeverHaveIEverPage()))),
                                HubFeature(label: 'Would You Rather', icon: Icons.help_outline_rounded, color: Colors.lightBlueAccent, badge: 'Game', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WouldYouRatherPage()))),
                                HubFeature(label: 'Love Quiz', icon: Icons.quiz_outlined, color: Colors.purpleAccent, badge: '8 Qs', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoveQuizPage()))),
                              ]),
                              HubGroup(title: 'Interactive Fun', emoji: '🎡', accent: Colors.amberAccent, features: [
                                HubFeature(label: 'Spin Wheel', icon: Icons.radio_button_checked_outlined, color: Colors.amberAccent, badge: 'Decide!', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpinnerWheelPage()))),
                                HubFeature(label: 'Virtual Gift Shop', icon: Icons.card_giftcard_outlined, color: Colors.amberAccent, badge: '12 Gifts', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VirtualGiftShopPage()))),
                                HubFeature(label: 'Commands', icon: Icons.terminal_rounded, color: Colors.pinkAccent, badge: '40+', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommandsPage()))),
                                HubFeature(label: 'Personas', icon: Icons.face_6_outlined, color: Colors.orangeAccent, badge: '8', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiplePersonasPage()))),
                                HubFeature(label: 'Word Puzzle', icon: Icons.extension_outlined, color: Colors.greenAccent, badge: 'Anime', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WordPuzzlePage()))),
                              ]),
                              HubGroup(title: 'Anime & Media', emoji: '🎬', accent: Colors.blueAccent, features: [
                                HubFeature(label: 'Anime Picks', icon: Icons.movie_filter_outlined, color: Colors.deepPurpleAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnimeRecommenderPage()))),
                                HubFeature(label: 'Watch & Anime', icon: Icons.movie_outlined, color: Colors.blueAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MovieRecommenderPage()))),
                                HubFeature(label: 'Music Player', icon: Icons.music_note_rounded, color: Colors.purpleAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPlayerPage()))),
                                HubFeature(label: 'Kaomoji', icon: Icons.emoji_emotions_outlined, color: Colors.yellowAccent, badge: '100+', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KaomojiPickerPage()))),
                              ]),
                            ],
                          )));
                        }, badge: '3 Groups'),

                        // ── 3. TOOLS & LIFE HUB ──────────────────────────────
                        quickItem(' Tools & Life', Icons.build_circle_outlined, Colors.tealAccent, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => HubPage(
                            hubTitle: 'Tools & Life',
                            hubEmoji: '🛠️',
                            hubColor: Colors.tealAccent,
                            groups: [
                              HubGroup(title: 'Productivity', emoji: '⚡', accent: Colors.lightGreenAccent, features: [
                                HubFeature(label: 'Goal Tracker', icon: Icons.track_changes_outlined, color: Colors.lightGreenAccent, badge: '+15 XP', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalTrackerPage()))),
                                HubFeature(label: 'Pomodoro', icon: Icons.timer_outlined, color: Colors.pinkAccent, badge: '25 min', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PomodoroPage()))),
                                HubFeature(label: 'Habit Tracker', icon: Icons.check_circle_outline, color: Colors.greenAccent, badge: 'Streaks', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitTrackerPage()))),
                                HubFeature(label: 'Budget Tracker', icon: Icons.account_balance_wallet_outlined, color: Colors.greenAccent, badge: 'Rs', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetTrackerPage()))),
                                HubFeature(label: 'Countdown', icon: Icons.hourglass_bottom_outlined, color: Colors.orangeAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CountdownTimerPage()))),
                              ]),
                              HubGroup(title: 'Wellness', emoji: '🌿', accent: Colors.tealAccent, features: [
                                HubFeature(label: 'Breathing', icon: Icons.air_outlined, color: Colors.cyanAccent, badge: '4-7-8', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreathingExercisePage()))),
                                HubFeature(label: 'Gratitude Journal', icon: Icons.auto_awesome_outlined, color: Colors.greenAccent, badge: 'Journal', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GratitudeJournalPage()))),
                                HubFeature(label: 'Wellness Reminders', icon: Icons.health_and_safety_outlined, color: Colors.tealAccent, badge: 'Reminders', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessRemindersPage()))),
                                HubFeature(label: 'Workout Planner', icon: Icons.fitness_center_outlined, color: Colors.redAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutPlannerPage()))),
                                HubFeature(label: 'Life Advice', icon: Icons.psychology_outlined, color: Colors.cyanAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LifeAdvicePage()))),
                              ]),
                              HubGroup(title: 'Journal & Notes', emoji: '📓', accent: Colors.purpleAccent, features: [
                                HubFeature(label: 'Notes Pad', icon: Icons.note_alt_outlined, color: Colors.tealAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesPadPage()))),
                                HubFeature(label: 'Dream Journal', icon: Icons.nights_stay_outlined, color: Colors.deepPurpleAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DreamJournalPage()))),
                                HubFeature(label: 'Bucket List', icon: Icons.checklist_outlined, color: Colors.lightGreenAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BucketListPage()))),
                                HubFeature(label: 'Writing Helper', icon: Icons.edit_note_outlined, color: Colors.purpleAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WritingHelperPage()))),
                                HubFeature(label: 'Chat Summary', icon: Icons.summarize_outlined, color: Colors.tealAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationSummaryPage()))),
                              ]),
                              HubGroup(title: 'Romance Toolkit', emoji: '💑', accent: Colors.pinkAccent, features: [
                                HubFeature(label: 'Love Advice', icon: Icons.favorite_border_outlined, color: Colors.pinkAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RelationshipAdvicePage()))),
                                HubFeature(label: 'Date Night Planner', icon: Icons.restaurant_menu_outlined, color: Colors.redAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DateNightPlannerPage()))),
                                HubFeature(label: 'Recipe AI', icon: Icons.restaurant_outlined, color: Colors.orangeAccent, badge: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeRecommenderPage()))),
                                HubFeature(label: 'Translator', icon: Icons.translate_outlined, color: Colors.pinkAccent, badge: '10 langs', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageTranslatorPage()))),
                                HubFeature(label: 'Anniversary', icon: Icons.favorite_border_rounded, color: Colors.pinkAccent, badge: 'Dates', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnniversaryPage()))),
                              ]),
                            ],
                          )));
                        }, badge: '5 Groups'),

                        // ── 4. SOCIAL & CLOUD HUB ────────────────────────────
                        quickItem(' Social & Cloud', Icons.people_outline_rounded, Colors.orangeAccent, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => HubPage(
                            hubTitle: 'Social & Cloud',
                            hubEmoji: '🔥',
                            hubColor: Colors.orangeAccent,
                            groups: [
                              HubGroup(title: 'Community', emoji: '🌍', accent: Colors.lightBlueAccent, features: [
                                HubFeature(label: 'Leaderboard', icon: Icons.leaderboard_outlined, color: Colors.amberAccent, badge: 'Global', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardPage()))),
                                HubFeature(label: 'Friends', icon: Icons.people_outline_rounded, color: Colors.lightBlueAccent, badge: 'Connect', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsPage()))),
                                HubFeature(label: 'Global Quests', icon: Icons.public_outlined, color: Colors.greenAccent, badge: 'Live', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalQuestBoardPage()))),
                                HubFeature(label: 'Cloud Sync', icon: Icons.cloud_sync_outlined, color: Colors.cyanAccent, badge: 'Sync', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CloudSyncPage()))),
                              ]),
                              HubGroup(title: 'Progress & Rewards', emoji: '🏆', accent: Colors.amberAccent, features: [
                                HubFeature(label: 'Achievements', icon: Icons.emoji_events_outlined, color: Colors.amberAccent, badge: 'Earn', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsGalleryPage()))),
                                HubFeature(label: 'Daily Check-in', icon: Icons.local_fire_department_outlined, color: Colors.orangeAccent, badge: 'Streak', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckinStreakPage()))),
                                HubFeature(label: 'Level Map', icon: Icons.map_outlined, color: Colors.purpleAccent, badge: '12 Lvls', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RelationshipLevelMapPage()))),
                                HubFeature(label: 'Year in Review', icon: Icons.calendar_today_outlined, color: Colors.orangeAccent, badge: '2025', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YearInReviewPage()))),
                              ]),
                              HubGroup(title: 'Messages & Alerts', emoji: '📬', accent: Colors.tealAccent, features: [
                                HubFeature(label: 'Scheduled Messages', icon: Icons.schedule_outlined, color: Colors.tealAccent, badge: 'Timed', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledMessagesPage()))),
                                HubFeature(label: 'Pinned Messages', icon: Icons.push_pin_outlined, color: Colors.deepPurpleAccent, badge: 'Saved', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PinnedMessagesPage()))),
                                HubFeature(label: 'Chat Analytics', icon: Icons.bar_chart_outlined, color: Colors.tealAccent, badge: 'Stats', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatAnalyticsPage()))),
                                HubFeature(label: 'Notifications Setup', icon: Icons.notifications_active_outlined, color: Colors.pinkAccent, badge: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsPage()))),
                              ]),
                            ],
                          )));
                        }, badge: '3 Groups'),

                        // ── 5. SETTINGS HUB ──────────────────────────────────
                        quickItem(' Settings & More', Icons.settings_outlined, Colors.white54, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => HubPage(
                            hubTitle: 'Settings & More',
                            hubEmoji: '⚙️',
                            hubColor: Colors.blueGrey,
                            groups: [
                              HubGroup(title: 'App Settings', emoji: '🎨', accent: Colors.purpleAccent, features: [
                                HubFeature(label: 'Settings', icon: Icons.settings_outlined, color: Colors.white70, onTap: () { updateState(() => _navIndex = 3); }),
                                HubFeature(label: 'Themes', icon: Icons.palette_outlined, color: Colors.pinkAccent, onTap: () { updateState(() => _navIndex = 4); }),
                                HubFeature(label: 'Notifications', icon: Icons.notifications_outlined, color: Colors.orangeAccent, onTap: () { updateState(() => _navIndex = 1); }),
                                HubFeature(label: 'Late Night Mode', icon: Icons.nights_stay_outlined, color: Colors.indigoAccent, badge: 'Cozy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LateNightModePage()))),
                              ]),
                              HubGroup(title: 'Profile & Stats', emoji: '👤', accent: Colors.blueAccent, features: [
                                HubFeature(label: 'My Profile', icon: Icons.person_outline, color: Colors.blueAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                                HubFeature(label: 'Achievements', icon: Icons.emoji_events_outlined, color: Colors.amberAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen()))),
                                HubFeature(label: 'About', icon: Icons.info_outline, color: Colors.white54, onTap: () { updateState(() => _navIndex = 7); }),
                                HubFeature(label: 'All Features List', icon: Icons.auto_awesome_rounded, color: Colors.amberAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeaturesPage()))),
                              ]),
                              HubGroup(title: 'Developer Tools', emoji: '🔧', accent: Colors.orangeAccent, features: [
                                HubFeature(label: 'Dev Config', icon: Icons.terminal, color: Colors.greenAccent, onTap: () { updateState(() => _navIndex = 5); }),
                                HubFeature(label: 'Debug Panel', icon: Icons.bug_report_outlined, color: Colors.orangeAccent, onTap: () { updateState(() => _navIndex = 6); }),
                              ]),
                            ],
                          )));
                        }, badge: '3 Groups'),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // ── Mini Music Player in Drawer ───────────────────────────
                  _buildDrawerMusicTile(primary),

                  Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(children: [
                      Text('S-002 · Zero Two',
                          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10, letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text('Dev by Sujit-O2',
                          style: GoogleFonts.outfit(color: Colors.white12, fontSize: 9, letterSpacing: 1)),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTopBanner(Color primary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 125,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/gif/sidebar_top.gif',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primary.withValues(alpha: 0.4), Colors.black54])))),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.04), Colors.black.withValues(alpha: 0.65)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primary.withValues(alpha: 0.5)),
                    ),
                    child: Text('NEURAL LINK ACTIVE',
                        style: GoogleFonts.outfit(
                            color: primary, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                  ),
                  const SizedBox(height: 5),
                  Text('S-002',
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  Text('AI Companion System',
                      style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerAutoListenTile(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (_isAutoListening ? primary : Colors.white12).withValues(alpha: 0.18),
          ),
          child: Icon(
            _isAutoListening ? Icons.mic_rounded : Icons.mic_off_rounded,
            color: _isAutoListening ? primary : Colors.white38,
            size: 15,
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Auto Listen',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(_isAutoListening ? 'Microphone active' : 'Tap to enable',
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
        ]),
        const Spacer(),
        Switch(
          value: _isAutoListening,
          onChanged: (_) => _toggleAutoListen(),
          activeColor: primary,
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white12,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }

  Widget _buildDrawerMusicTile(Color primary) {
    final svc = MusicPlayerService.instance;
    return ValueListenableBuilder<SongModel?>(
      valueListenable: svc.currentSong,
      builder: (context, song, _) {
        if (song == null) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: svc.isPlaying,
          builder: (context, playing, _) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary.withValues(alpha: 0.18), Colors.black.withValues(alpha: 0.4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withValues(alpha: 0.35)),
                  boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.10), blurRadius: 12)],
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.22)),
                    child: Icon(playing ? Icons.equalizer_rounded : Icons.music_note_rounded, color: primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPlayerPage()));
                      },
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(playing ? '♪ Now Playing' : '⏸ Paused',
                            style: GoogleFonts.outfit(
                                color: playing ? primary.withValues(alpha: 0.85) : Colors.white38, fontSize: 10)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => svc.skipPrevious(),
                    child: Icon(Icons.skip_previous_rounded, color: Colors.white54, size: 22),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => svc.playPause(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.25)),
                      child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: primary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => svc.skipNext(),
                    child: Icon(Icons.skip_next_rounded, color: Colors.white54, size: 22),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
