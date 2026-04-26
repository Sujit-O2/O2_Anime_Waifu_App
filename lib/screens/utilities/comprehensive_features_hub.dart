import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/widgets/premium_ui_kit.dart';
import 'package:anime_waifu/core/router/app_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// COMPREHENSIVE FEATURES HUB — All 100+ Features Accessible
/// ═══════════════════════════════════════════════════════════════════════════

class ComprehensiveFeaturesHub extends StatefulWidget {
  const ComprehensiveFeaturesHub({super.key});

  @override
  State<ComprehensiveFeaturesHub> createState() =>
      _ComprehensiveFeaturesHubState();
}

class _ComprehensiveFeaturesHubState extends State<ComprehensiveFeaturesHub> {
  String _searchQuery = '';
  int _selectedCategory = 0;

  final List<_FeatureCategory> _categories = [
    _FeatureCategory(
      name: 'All',
      icon: Icons.apps_rounded,
      color: Colors.purple,
    ),
    _FeatureCategory(
      name: 'AI Tools',
      icon: Icons.psychology_rounded,
      color: Colors.blue,
    ),
    _FeatureCategory(
      name: 'Games',
      icon: Icons.sports_esports_rounded,
      color: Colors.green,
    ),
    _FeatureCategory(
      name: 'Media',
      icon: Icons.video_library_rounded,
      color: Colors.red,
    ),
    _FeatureCategory(
      name: 'Rituals',
      icon: Icons.auto_awesome_rounded,
      color: Colors.amber,
    ),
    _FeatureCategory(
      name: 'Social',
      icon: Icons.people_rounded,
      color: Colors.pink,
    ),
    _FeatureCategory(
      name: 'Utilities',
      icon: Icons.build_rounded,
      color: Colors.cyan,
    ),
    _FeatureCategory(
      name: 'Wellness',
      icon: Icons.favorite_rounded,
      color: Colors.teal,
    ),
  ];

  final List<_Feature> _allFeatures = [
    // ── AI Tools ────────────────────────────────────────────────────────
    _Feature('AI Art Generator', Icons.palette_rounded, AppRouter.aiArtGenerator, 'AI Tools'),
    _Feature('AI Debug Panel', Icons.bug_report_rounded, AppRouter.aiDebugPanel, 'AI Tools'),
    _Feature('AI Image Journal', Icons.photo_library_rounded, AppRouter.aiImageJournal, 'AI Tools'),
    _Feature('AI Personality Modes', Icons.face_rounded, AppRouter.aiPersonalityModes, 'AI Tools'),
    _Feature('Dream Interpreter', Icons.nightlight_rounded, AppRouter.dreamInterpreter, 'AI Tools'),
    _Feature('Language Translator', Icons.translate_rounded, AppRouter.languageTranslator, 'AI Tools'),
    _Feature('Life Advice', Icons.lightbulb_rounded, AppRouter.lifeAdvice, 'AI Tools'),
    _Feature('Manga Translator', Icons.translate_rounded, AppRouter.mangaTranslator, 'AI Tools'),
    _Feature('Poem Generator', Icons.edit_rounded, AppRouter.poemGenerator, 'AI Tools'),
    _Feature('Recipe Recommender', Icons.restaurant_rounded, AppRouter.recipeRecommender, 'AI Tools'),
    _Feature('Relationship Advice', Icons.favorite_border_rounded, AppRouter.relationshipAdvice, 'AI Tools'),
    _Feature('Relationship Coach', Icons.psychology_rounded, AppRouter.relationshipCoach, 'AI Tools'),
    _Feature('Writing Helper', Icons.create_rounded, AppRouter.writingHelper, 'AI Tools'),
    _Feature('Code Reviewer', Icons.code_rounded, AppRouter.codeReviewer, 'AI Tools'),
    _Feature('Digital Clone', Icons.person_outline_rounded, AppRouter.digitalClone, 'AI Tools'),
    _Feature('Voice Emotion Detector', Icons.mic_rounded, AppRouter.voiceEmotionDetector, 'AI Tools'),

    // ── Games ───────────────────────────────────────────────────────────
    _Feature('AI Story Game', Icons.auto_stories_rounded, AppRouter.aiStoryGame, 'Games'),
    _Feature('Anime Quiz', Icons.quiz_rounded, AppRouter.animeQuiz, 'Games'),
    _Feature('Anime Wordle', Icons.grid_on_rounded, AppRouter.animeWordle, 'Games'),
    _Feature('Boss Battle', Icons.shield_rounded, AppRouter.bossBattle, 'Games'),
    _Feature('Daily Couple Challenge', Icons.favorite_rounded, AppRouter.dailyCoupleChallenge, 'Games'),
    _Feature('Draw Lots', Icons.casino_rounded, AppRouter.drawLots, 'Games'),
    _Feature('Gacha Collector', Icons.card_giftcard_rounded, AppRouter.gachaCollector, 'Games'),
    _Feature('Gacha', Icons.stars_rounded, AppRouter.gacha, 'Games'),
    _Feature('Global Quest Board', Icons.public_rounded, AppRouter.globalQuestBoard, 'Games'),
    _Feature('Love Quiz', Icons.favorite_rounded, AppRouter.loveQuiz, 'Games'),
    _Feature('Mini Games', Icons.games_rounded, AppRouter.miniGames, 'Games'),
    _Feature('Never Have I Ever', Icons.question_answer_rounded, AppRouter.neverHaveIEver, 'Games'),
    _Feature('Relationship Trivia', Icons.quiz_rounded, AppRouter.relationshipTrivia, 'Games'),
    _Feature('Rock Paper Scissors', Icons.back_hand_rounded, AppRouter.rockPaperScissors, 'Games'),
    _Feature('Roleplay Scenario', Icons.theater_comedy_rounded, AppRouter.roleplayScenario, 'Games'),
    _Feature('Spinner Wheel', Icons.album_rounded, AppRouter.spinnerWheel, 'Games'),
    _Feature('Story Adventure', Icons.explore_rounded, AppRouter.storyAdventure, 'Games'),
    _Feature('Story Mode', Icons.menu_book_rounded, AppRouter.storyMode, 'Games'),
    _Feature('Tic Tac Toe', Icons.grid_4x4_rounded, AppRouter.ticTacToe, 'Games'),
    _Feature('Truth or Dare', Icons.help_outline_rounded, AppRouter.truthOrDare, 'Games'),
    _Feature('Twenty Questions', Icons.question_mark_rounded, AppRouter.twentyQuestions, 'Games'),
    _Feature('Virtual Date', Icons.favorite_rounded, AppRouter.virtualDate, 'Games'),
    _Feature('Waifu Tier List', Icons.format_list_numbered_rounded, AppRouter.waifuTierList, 'Games'),
    _Feature('Word Association', Icons.text_fields_rounded, AppRouter.wordAssociation, 'Games'),
    _Feature('Word Puzzle', Icons.extension_rounded, AppRouter.wordPuzzle, 'Games'),
    _Feature('Would You Rather', Icons.compare_arrows_rounded, AppRouter.wouldYouRather, 'Games'),

    // ── Media ───────────────────────────────────────────────────────────
    _Feature('Anime Calendar', Icons.calendar_today_rounded, AppRouter.animeCalendar, 'Media'),
    _Feature('Anime Matchmaker', Icons.favorite_rounded, AppRouter.animeMatchmaker, 'Media'),
    _Feature('Anime OST', Icons.music_note_rounded, AppRouter.animeOst, 'Media'),
    _Feature('Anime Recommender', Icons.recommend_rounded, AppRouter.animeRecommender, 'Media'),
    _Feature('Anime Section', Icons.movie_rounded, AppRouter.animeSection, 'Media'),
    _Feature('Anime Watch Party', Icons.group_rounded, AppRouter.animeWatchParty, 'Media'),
    _Feature('Downloads', Icons.download_rounded, AppRouter.downloads, 'Media'),
    _Feature('Episode Alerts', Icons.notifications_active_rounded, AppRouter.episodeAlerts, 'Media'),
    _Feature('GIF Viewer', Icons.gif_rounded, AppRouter.gifViewer, 'Media'),
    _Feature('HiAnime', Icons.play_circle_rounded, AppRouter.hianime, 'Media'),
    _Feature('Manga Section', Icons.menu_book_rounded, AppRouter.mangaSection, 'Media'),
    _Feature('Music Player', Icons.music_note_rounded, AppRouter.musicPlayer, 'Media'),
    _Feature('Watch History', Icons.history_rounded, AppRouter.watchHistory, 'Media'),
    _Feature('Watchlist', Icons.bookmark_rounded, AppRouter.watchlist, 'Media'),
    _Feature('Web Streamers Hub', Icons.live_tv_rounded, AppRouter.webStreamersHub, 'Media'),

    // ── Rituals ─────────────────────────────────────────────────────────
    _Feature('Check-in Streak', Icons.local_fire_department_rounded, AppRouter.checkinStreak, 'Rituals'),
    _Feature('Daily Affirmations', Icons.self_improvement_rounded, AppRouter.dailyAffirmations, 'Rituals'),
    _Feature('Daily Challenge', Icons.emoji_events_rounded, AppRouter.dailyChallenge, 'Rituals'),
    _Feature('Daily Horoscope', Icons.star_rounded, AppRouter.dailyHoroscope, 'Rituals'),
    _Feature('Daily Love Letter', Icons.mail_rounded, AppRouter.dailyLoveLetter, 'Rituals'),
    _Feature('Daily Trivia', Icons.quiz_rounded, AppRouter.dailyTrivia, 'Rituals'),
    _Feature('Fortune Cookie', Icons.cookie_rounded, AppRouter.fortuneCookie, 'Rituals'),
    _Feature('Late Night Mode', Icons.nightlight_round, AppRouter.lateNightMode, 'Rituals'),
    _Feature('Morning Greeting', Icons.wb_sunny_rounded, AppRouter.morningGreetingCard, 'Rituals'),
    _Feature('Quote of Day', Icons.format_quote_rounded, AppRouter.quoteOfDay, 'Rituals'),
    _Feature('Zero Two Diary', Icons.book_rounded, AppRouter.zeroTwoDiary, 'Rituals'),

    // ── Social ──────────────────────────────────────────────────────────
    _Feature('Achievement Room', Icons.emoji_events_rounded, AppRouter.achievementRoom, 'Social'),
    _Feature('Achievements Gallery', Icons.photo_library_rounded, AppRouter.achievementsGallery, 'Social'),
    _Feature('Achievements', Icons.military_tech_rounded, AppRouter.achievements, 'Social'),
    _Feature('Friends', Icons.people_rounded, AppRouter.friends, 'Social'),
    _Feature('Gratitude Journal', Icons.favorite_rounded, AppRouter.gratitudeJournal, 'Social'),
    _Feature('Leaderboard', Icons.leaderboard_rounded, AppRouter.leaderboard, 'Social'),
    _Feature('Life Events', Icons.event_rounded, AppRouter.lifeEvents, 'Social'),
    _Feature('Memory Book', Icons.auto_stories_rounded, AppRouter.memoryBook, 'Social'),
    _Feature('Memory Stack', Icons.layers_rounded, AppRouter.memoryStack, 'Social'),
    _Feature('Memory Timeline', Icons.timeline_rounded, AppRouter.memoryTimeline, 'Social'),
    _Feature('Memory Vault', Icons.lock_rounded, AppRouter.memoryVault, 'Social'),
    _Feature('Memory Wall', Icons.photo_album_rounded, AppRouter.memoryWall, 'Social'),
    _Feature('Relationship Evolution', Icons.trending_up_rounded, AppRouter.relationshipEvolution, 'Social'),
    _Feature('Relationship Level Map', Icons.map_rounded, AppRouter.relationshipLevelMap, 'Social'),
    _Feature('Relationship Timeline', Icons.timeline_rounded, AppRouter.relationshipTimeline, 'Social'),

    // ── Utilities ───────────────────────────────────────────────────────
    _Feature('Advanced Settings', Icons.settings_rounded, AppRouter.advancedSettings, 'Utilities'),
    _Feature('Anniversary', Icons.cake_rounded, AppRouter.anniversary, 'Utilities'),
    _Feature('App Icon Picker', Icons.apps_rounded, AppRouter.appIconPicker, 'Utilities'),
    _Feature('AR Companion', Icons.view_in_ar_rounded, AppRouter.arCompanion, 'Utilities'),
    _Feature('AR Ruler', Icons.straighten_rounded, AppRouter.arRuler, 'Utilities'),
    _Feature('Auto Learning', Icons.school_rounded, AppRouter.autoLearning, 'Utilities'),
    _Feature('Auto Life Log', Icons.auto_awesome_rounded, AppRouter.autoLifeLog, 'Utilities'),
    _Feature('Background Insights', Icons.insights_rounded, AppRouter.backgroundInsights, 'Utilities'),
    _Feature('Bill Splitter', Icons.receipt_rounded, AppRouter.billSplitter, 'Utilities'),
    _Feature('Book Recommender', Icons.menu_book_rounded, AppRouter.bookRecommender, 'Utilities'),
    _Feature('Bucket List', Icons.list_rounded, AppRouter.bucketList, 'Utilities'),
    _Feature('Budget Tracker', Icons.account_balance_wallet_rounded, AppRouter.budgetTracker, 'Utilities'),
    _Feature('Chat Analytics', Icons.analytics_rounded, AppRouter.chatAnalytics, 'Utilities'),
    _Feature('Chat Share & Export', Icons.share_rounded, AppRouter.chatShareExport, 'Utilities'),
    _Feature('Chat Statistics', Icons.bar_chart_rounded, AppRouter.chatStatistics, 'Utilities'),
    _Feature('Clipboard Manager', Icons.content_paste_rounded, AppRouter.clipboardManager, 'Utilities'),
    _Feature('Cloud Sync', Icons.cloud_sync_rounded, AppRouter.cloudSync, 'Utilities'),
    _Feature('Commands', Icons.terminal_rounded, '/commands', 'Utilities'),
    _Feature('Countdown Timer', Icons.timer_rounded, AppRouter.countdownTimer, 'Utilities'),
    _Feature('Date Night Planner', Icons.event_rounded, AppRouter.dateNightPlanner, 'Utilities'),
    _Feature('Day Recap', Icons.today_rounded, AppRouter.dayRecap, 'Utilities'),
    _Feature('Dream Journal', Icons.nights_stay_rounded, AppRouter.dreamJournal, 'Utilities'),
    _Feature('Dream Mode', Icons.bedtime_rounded, AppRouter.dreamMode, 'Utilities'),
    _Feature('Emergency SOS', Icons.emergency_rounded, AppRouter.emergencySos, 'Utilities'),
    _Feature('Error Memory', Icons.error_outline_rounded, AppRouter.errorMemory, 'Utilities'),
    _Feature('File Intelligence', Icons.folder_rounded, AppRouter.fileIntelligence, 'Utilities'),
    _Feature('Future Simulator', Icons.fast_forward_rounded, AppRouter.futureSim, 'Utilities'),
    _Feature('Geofencing Settings', Icons.location_on_rounded, AppRouter.geofencingSettings, 'Utilities'),
    _Feature('Goal Tracker', Icons.flag_rounded, AppRouter.goalTracker, 'Utilities'),
    _Feature('Image Pack', Icons.collections_rounded, AppRouter.imagePack, 'Utilities'),
    _Feature('Kaomoji Picker', Icons.emoji_emotions_rounded, AppRouter.kaomojiPicker, 'Utilities'),
    _Feature('Knowledge Graph', Icons.account_tree_rounded, AppRouter.knowledgeGraph, 'Utilities'),
    _Feature('Life Simulator', Icons.psychology_rounded, AppRouter.lifeSim, 'Utilities'),
    _Feature('Love Letter', Icons.favorite_rounded, AppRouter.loveLetter, 'Utilities'),
    _Feature('MAL Sync', Icons.sync_rounded, AppRouter.malSync, 'Utilities'),
    _Feature('Movie Recommender', Icons.movie_rounded, AppRouter.movieRecommender, 'Utilities'),
    _Feature('Multiple Personas', Icons.people_outline_rounded, AppRouter.multiplePersonas, 'Utilities'),
    _Feature('Notes Pad', Icons.note_rounded, AppRouter.notesPad, 'Utilities'),
    _Feature('Notifications Settings', Icons.notifications_rounded, AppRouter.notificationsSettings, 'Utilities'),
    _Feature('Package Tracker', Icons.local_shipping_rounded, AppRouter.packageTracker, 'Utilities'),
    _Feature('Parking Spot Saver', Icons.local_parking_rounded, AppRouter.parkingSpotSaver, 'Utilities'),
    _Feature('Password Generator', Icons.vpn_key_rounded, AppRouter.passwordGenerator, 'Utilities'),
    _Feature('Personal Search', Icons.search_rounded, AppRouter.personalSearch, 'Utilities'),
    _Feature('Personality Settings', Icons.psychology_rounded, AppRouter.personalitySettings, 'Utilities'),
    _Feature('Pinned Messages', Icons.push_pin_rounded, AppRouter.pinnedMessages, 'Utilities'),
    _Feature('Plugin System', Icons.extension_rounded, AppRouter.pluginSystem, 'Utilities'),
    _Feature('Profile', Icons.person_rounded, AppRouter.profile, 'Utilities'),
    _Feature('Project Generator', Icons.create_new_folder_rounded, AppRouter.projectGenerator, 'Utilities'),
    _Feature('QR Scanner', Icons.qr_code_scanner_rounded, AppRouter.qrScanner, 'Utilities'),
    _Feature('Quests', Icons.assignment_rounded, AppRouter.quests, 'Utilities'),
    _Feature('Reward System', Icons.card_giftcard_rounded, AppRouter.rewardSystem, 'Utilities'),
    _Feature('Scheduled Messages', Icons.schedule_send_rounded, AppRouter.scheduledMessages, 'Utilities'),
    _Feature('Second Brain', Icons.psychology_rounded, AppRouter.secondBrain, 'Utilities'),
    _Feature('Secret Notes', Icons.lock_rounded, AppRouter.secretNotes, 'Utilities'),
    _Feature('Self Improvement', Icons.trending_up_rounded, AppRouter.selfImprovement, 'Utilities'),
    _Feature('Shared Bucket List', Icons.list_alt_rounded, AppRouter.sharedBucketList, 'Utilities'),
    _Feature('Smart Scanner', Icons.document_scanner_rounded, AppRouter.smartScanner, 'Utilities'),
    _Feature('Star Map', Icons.star_rounded, AppRouter.starMap, 'Utilities'),
    _Feature('Stats & Habits', Icons.bar_chart_rounded, AppRouter.statsHabits, 'Utilities'),
    _Feature('Sticker Sheet', Icons.emoji_emotions_rounded, AppRouter.animeStickerSheet, 'Utilities'),
    _Feature('Tarot Reading', Icons.auto_awesome_rounded, AppRouter.tarotReading, 'Utilities'),
    _Feature('Task Executor', Icons.task_rounded, AppRouter.taskExecutor, 'Utilities'),
    _Feature('Theme Accent', Icons.color_lens_rounded, AppRouter.themeAccent, 'Utilities'),
    _Feature('Theme Switcher', Icons.palette_rounded, AppRouter.themeSwitcher, 'Utilities'),
    _Feature('Thought Capture', Icons.lightbulb_rounded, AppRouter.thoughtCapture, 'Utilities'),
    _Feature('Time Machine', Icons.access_time_rounded, AppRouter.timeMachine, 'Utilities'),
    _Feature('Virtual Gift Shop', Icons.card_giftcard_rounded, AppRouter.virtualGiftShop, 'Utilities'),
    _Feature('Voice Call', Icons.phone_rounded, AppRouter.voiceCall, 'Utilities'),
    _Feature('Voice Notes', Icons.mic_rounded, AppRouter.voiceNotes, 'Utilities'),
    _Feature('Waifu Dev Mode', Icons.developer_mode_rounded, AppRouter.waifuDevMode, 'Utilities'),
    _Feature('Waifu XP Level', Icons.trending_up_rounded, AppRouter.waifuXpLevel, 'Utilities'),
    _Feature('Workflow Engine', Icons.account_tree_rounded, AppRouter.workflowEngine, 'Utilities'),
    _Feature('Year in Review', Icons.calendar_today_rounded, AppRouter.yearInReview, 'Utilities'),
    _Feature('Zero Two Calendar', Icons.event_rounded, AppRouter.zeroTwoCalendar, 'Utilities'),
    _Feature('Zero Two Facts', Icons.info_rounded, AppRouter.zeroTwoFacts, 'Utilities'),

    // ── Wellness ────────────────────────────────────────────────────────
    _Feature('Breathing Exercise', Icons.air_rounded, AppRouter.breathing, 'Wellness'),
    _Feature('Focus Mode', Icons.center_focus_strong_rounded, AppRouter.focusMode, 'Wellness'),
    _Feature('Habit Tracker', Icons.check_circle_rounded, AppRouter.habitTracker, 'Wellness'),
    _Feature('Medication Reminder', Icons.medication_rounded, AppRouter.medicationReminder, 'Wellness'),
    _Feature('Mood Tracker', Icons.mood_rounded, AppRouter.moodTracker, 'Wellness'),
    _Feature('Mood Tracking', Icons.sentiment_satisfied_rounded, AppRouter.moodTracking, 'Wellness'),
    _Feature('Pomodoro', Icons.timer_rounded, AppRouter.pomodoro, 'Wellness'),
    _Feature('Sleep Mode', Icons.bedtime_rounded, AppRouter.sleepMode, 'Wellness'),
    _Feature('Study Timer', Icons.school_rounded, AppRouter.studyTimer, 'Wellness'),
    _Feature('Wellness Reminders', Icons.notifications_active_rounded, AppRouter.wellnessReminders, 'Wellness'),
    _Feature('Workout Planner', Icons.fitness_center_rounded, AppRouter.workoutPlanner, 'Wellness'),
  ];

  List<_Feature> get _filteredFeatures {
    var features = _allFeatures;

    // Filter by category
    if (_selectedCategory > 0) {
      final categoryName = _categories[_selectedCategory].name;
      features = features.where((f) => f.category == categoryName).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      features = features
          .where((f) =>
              f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return features;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'All Features',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: PremiumTextField(
              hintText: 'Search features...',
              prefixIcon: Icons.search_rounded,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // ── Category Chips ──────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : tokens.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.name,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: tokens.panelMuted,
                    selectedColor: category.color,
                    onSelected: (_) => setState(() => _selectedCategory = index),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Feature Count ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredFeatures.length} features',
                style: GoogleFonts.outfit(
                  color: tokens.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Feature Grid ────────────────────────────────────────────────
          Expanded(
            child: _filteredFeatures.isEmpty
                ? PremiumEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No features found',
                    subtitle: 'Try a different search or category',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredFeatures.length,
                    itemBuilder: (context, index) {
                      final feature = _filteredFeatures[index];
                      return _buildFeatureCard(context, feature, theme, tokens);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    _Feature feature,
    ThemeData theme,
    AppDesignTokens tokens,
  ) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.pushNamed(context, feature.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.tertiary.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              feature.icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            feature.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCategory {
  final String name;
  final IconData icon;
  final Color color;

  _FeatureCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class _Feature {
  final String name;
  final IconData icon;
  final String route;
  final String category;

  _Feature(this.name, this.icon, this.route, this.category);
}
