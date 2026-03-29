import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

// ── Games & Fun ──
import 'spinner_wheel_page.dart';
import 'never_have_i_ever_page.dart';
import 'draw_lots_page.dart';
import 'relationship_trivia_page.dart';
import 'would_you_rather_page.dart';
import 'boss_battle_page.dart';
import 'anime_wordle_page.dart';
import 'gacha_collector_page.dart';
import 'mini_games_page.dart';
import 'tic_tac_toe_page.dart';
import 'rock_paper_scissors_page.dart';
import 'word_association_page.dart';
import 'truth_or_dare_page.dart';
import 'love_quiz_page.dart';
import 'waifu_tier_list_page.dart';
import 'twenty_questions_page.dart';
import 'virtual_date_page.dart';
import 'story_mode_page.dart';
import 'roleplay_scenario_page.dart';

// ── Daily & AI ──
import 'zero_two_diary_page.dart';
import 'fortune_cookie_page.dart';
import 'daily_love_letter_page.dart';
import 'daily_affirmations_page.dart';
import 'quote_of_day_page.dart';
import 'daily_challenge_page.dart';
import 'daily_horoscope_page.dart';
import 'daily_trivia_page.dart';
import 'checkin_streak_page.dart';
import 'life_advice_page.dart';
import 'writing_helper_page.dart';
import 'relationship_advice_page.dart';
import 'relationship_coach_page.dart';
import 'dream_interpreter_page.dart';
import 'ai_art_generator_page.dart';
import 'manga_translator_page.dart';
import 'poem_generator_page.dart';
import 'language_translator_page.dart';
import 'recipe_recommender_page.dart';

// ── Recommendations ──
import 'anime_recommender_page.dart';
import 'book_recommender_page.dart';
import 'movie_recommender_page.dart';

// ── Tools & Productivity ──
import 'notes_pad_page.dart';
import 'dream_journal_page.dart';
import 'voice_notes_page.dart';
import 'goal_tracker_page.dart';
import 'habit_tracker_page.dart';
import 'budget_tracker_page.dart';
import 'pomodoro_page.dart';
import 'study_timer_page.dart';
import 'shared_bucket_list_page.dart';
import 'workout_planner_page.dart';
import 'breathing_page.dart';
import 'gratitude_journal_page.dart';
import 'countdown_timer_page.dart';

// ── Anime & Media ──
import 'manga_section_page.dart';
import 'web_streamers_hub_page.dart';
import 'anime_ost_page.dart';
import 'anime_calendar_page.dart';
import 'anime_watch_party_page.dart';
import 'anime_matchmaker_page.dart';
import 'watchlist_page.dart';
import 'watch_history_page.dart';
import 'downloads_page.dart';
import 'mal_sync_page.dart';
import 'episode_alerts_page.dart';

// ── Social & Cloud ──
import 'leaderboard_page.dart';
import 'cloud_sync_page.dart';
import 'friends_page.dart';
import 'global_quest_board_page.dart';
import 'pinned_messages_page.dart';
import 'scheduled_messages_page.dart';
import 'conversation_summary_page.dart';

// ── Stats & Insights ──
import 'chat_analytics_page.dart';
import 'relationship_level_map_page.dart';
import 'year_in_review_page.dart';
import 'achievements_gallery_page.dart';
import 'anniversary_page.dart';
import 'star_map_page.dart';
import 'relationship_evolution_page.dart';
import 'memory_timeline_page.dart';
import 'memory_wall_page.dart';
import 'memory_book_page.dart';

// ── Settings ──
import 'waifu_voice_call_screen.dart';

import 'zero_two_facts_page.dart';
import 'zero_two_calendar_page.dart';
import 'tarot_reading_page.dart';
import 'kaomoji_picker_page.dart';
import 'late_night_mode_page.dart';
import 'mood_tracker_page.dart';
import 'mood_tracking_page.dart';
import 'sleep_mode_page.dart';
import 'wellness_reminders_page.dart';
import 'daily_couple_challenge_page.dart';
import 'word_puzzle_page.dart';

// ── New Mega Features ──
import 'waifu_xp_level_page.dart';
import 'waifu_dev_mode_page.dart';
import 'life_sim_page.dart';
import 'plugin_system_page.dart';
import 'dream_mode_page.dart';
import 'ai_story_game_page.dart';
import 'user_analytics_dashboard_page.dart';
import 'chat_share_export_page.dart';
import 'ai_debug_panel_page.dart';
import 'second_brain_page.dart';
import 'reward_system_page.dart';
import 'focus_mode_page.dart';
import 'day_recap_page.dart';
import 'error_memory_page.dart';
import 'thought_capture_page.dart';
import 'self_improvement_page.dart';
import 'digital_clone_page.dart';
import 'future_sim_page.dart';
import 'auto_learning_page.dart';
import 'auto_life_log_page.dart';
import 'task_executor_page.dart';
import 'code_reviewer_page.dart';
import 'knowledge_graph_page.dart';
import 'time_machine_page.dart';
import 'workflow_engine_page.dart';
import 'personal_search_page.dart';
import 'project_generator_page.dart';
import 'ai_personality_modes_page.dart';
import 'background_insights_page.dart';
import 'memory_stack_page.dart';
import 'file_intelligence_page.dart';
import 'voice_emotion_detector_page.dart';

// ── Real-Life Tools ──
import 'parking_spot_saver_page.dart';
import 'smart_scanner_page.dart';
import 'medication_reminder_page.dart';
import 'package_tracker_page.dart';
import 'emergency_sos_page.dart';
import 'clipboard_manager_page.dart';
import 'bill_splitter_page.dart';
import 'ar_ruler_page.dart';
import 'password_generator_page.dart';
import 'qr_scanner_page.dart';

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
  final WidgetBuilder? builder;
  final VoidCallback? onTap;
  const _HubItem({
    required this.label,
    required this.icon,
    this.builder,
    this.onTap,
  });
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
  bool shouldRepaint(_SakuraPainter old) => old.t != t;
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
  final VoidCallback? onBack;
  final VoidCallback? onOpenCloudinary;
  const FeaturesHubPage({super.key, this.onBack, this.onOpenCloudinary});
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
        // ── 🎮 GAMES & FUN ──────────────────────────────────────
        _HubCategory(
          title: 'Games & Fun',
          emoji: '🎮',
          description: 'Play mini-games, earn XP, and have fun',
          color: Colors.pinkAccent,
          items: [
            _HubItem(label: 'Boss Battle', icon: Icons.security_rounded, builder: (_) => const BossBattlePage()),
            _HubItem(label: 'Anime Wordle', icon: Icons.grid_view_rounded, builder: (_) => const AnimeWordlePage()),
            _HubItem(label: 'Gacha Cards', icon: Icons.card_giftcard_rounded, builder: (_) => const GachaCollectorPage()),
            _HubItem(label: 'Mini Games', icon: Icons.sports_esports_rounded, builder: (_) => const GamesHubPage()),
            _HubItem(label: 'Tic-Tac-Toe', icon: Icons.grid_3x3_rounded, builder: (_) => const TicTacToePage()),
            _HubItem(label: 'Rock Paper', icon: Icons.back_hand_rounded, builder: (_) => const RockPaperScissorsPage()),
            _HubItem(label: 'Word Game', icon: Icons.text_fields_rounded, builder: (_) => const WordAssociationPage()),
            _HubItem(label: 'Spin Wheel', icon: Icons.casino_outlined, builder: (_) => const SpinnerWheelPage()),
            _HubItem(label: 'Never Have I Ever', icon: Icons.emoji_people_outlined, builder: (_) => const NeverHaveIEverPage()),
            _HubItem(label: 'Draw Lots', icon: Icons.grass_outlined, builder: (_) => const DrawLotsPage()),
            _HubItem(label: 'DITF Trivia', icon: Icons.quiz_outlined, builder: (_) => const RelationshipTriviaPage()),
            _HubItem(label: 'Would You Rather', icon: Icons.compare_arrows_outlined, builder: (_) => const WouldYouRatherPage()),
            _HubItem(label: 'Truth or Dare', icon: Icons.local_fire_department_outlined, builder: (_) => const TruthOrDarePage()),
            _HubItem(label: 'Love Quiz', icon: Icons.quiz_outlined, builder: (_) => const LoveQuizPage()),
            _HubItem(label: 'Waifu Tier List', icon: Icons.format_list_numbered_rounded, builder: (_) => const WaifuTierListPage()),
            _HubItem(label: '20 Questions', icon: Icons.help_rounded, builder: (_) => const TwentyQuestionsPage()),
            _HubItem(label: 'Virtual Date', icon: Icons.favorite_outline_rounded, builder: (_) => const VirtualDatePage()),
            _HubItem(label: 'Story Mode', icon: Icons.book_rounded, builder: (_) => const StoryModePage()),
            _HubItem(label: 'Roleplay', icon: Icons.theater_comedy_outlined, builder: (_) => const RoleplayScenarioPage()),
            _HubItem(label: 'Word Puzzle', icon: Icons.extension_rounded, builder: (_) => const WordPuzzlePage()),
            _HubItem(label: 'Couple Challenge', icon: Icons.favorite_rounded, builder: (_) => const DailyCoupleChallengePage()),
          ],
        ),

        // ── 💕 DAILY RITUALS ────────────────────────────────────
        _HubCategory(
          title: 'Daily Rituals',
          emoji: '💕',
          description: 'Daily actions, letters, and check-ins',
          color: const Color(0xFFFF4FA8),
          items: [
            _HubItem(label: 'ZT Diary', icon: Icons.book_outlined, builder: (_) => const ZeroTwoDiaryPage()),
            _HubItem(label: 'Love Letter', icon: Icons.mail_outline_rounded, builder: (_) => const DailyLoveLetterPage()),
            _HubItem(label: 'Affirmations', icon: Icons.self_improvement_outlined, builder: (_) => const DailyAffirmationsPage()),
            _HubItem(label: 'Quote of Day', icon: Icons.format_quote_outlined, builder: (_) => const QuoteOfDayPage()),
            _HubItem(label: 'Fortune Cookie', icon: Icons.cookie_outlined, builder: (_) => const FortuneCookiePage()),
            _HubItem(label: 'Check-in Streak', icon: Icons.local_fire_department_outlined, builder: (_) => const CheckinStreakPage()),
            _HubItem(label: 'Daily Challenge', icon: Icons.flag_rounded, builder: (_) => const DailyChallengePage()),
            _HubItem(label: 'Daily Horoscope', icon: Icons.auto_awesome_rounded, builder: (_) => const DailyHoroscopePage()),
            _HubItem(label: 'Daily Trivia', icon: Icons.lightbulb_outline, builder: (_) => const DailyTriviaPage()),
            _HubItem(label: 'Late Night Mode', icon: Icons.nights_stay_rounded, builder: (_) => const LateNightModePage()),
          ],
        ),

        // ── 🧠 AI TOOLS ────────────────────────────────────────
        _HubCategory(
          title: 'AI Tools',
          emoji: '🧠',
          description: 'AI-powered assistants and generators',
          color: Colors.cyanAccent,
          items: [
            _HubItem(label: 'AI Art Generator', icon: Icons.brush_rounded, builder: (_) => const AiArtGeneratorPage()),
            _HubItem(label: 'Manga Translator', icon: Icons.translate_rounded, builder: (_) => const MangaTranslatorPage()),
            _HubItem(label: 'Dream Interpreter', icon: Icons.bedtime_rounded, builder: (_) => const DreamInterpreterPage()),
            _HubItem(label: 'Life Advice', icon: Icons.lightbulb_outline, builder: (_) => const LifeAdvicePage()),
            _HubItem(label: 'Writing Helper', icon: Icons.edit_note_outlined, builder: (_) => const WritingHelperPage()),
            _HubItem(label: 'Relationship Advice', icon: Icons.favorite_border_outlined, builder: (_) => const RelationshipAdvicePage()),
            _HubItem(label: 'Relationship Coach', icon: Icons.psychology_rounded, builder: (_) => const RelationshipCoachPage()),
            _HubItem(label: 'Poem Generator', icon: Icons.edit_rounded, builder: (_) => const PoemGeneratorPage()),
            _HubItem(label: 'Translator', icon: Icons.translate_rounded, builder: (_) => const LanguageTranslatorPage()),
            _HubItem(label: 'Recipe Picks', icon: Icons.restaurant_rounded, builder: (_) => const RecipeRecommenderPage()),
          ],
        ),

        // ── 📚 RECOMMENDATIONS ──────────────────────────────────
        _HubCategory(
          title: 'Recommendations',
          emoji: '📚',
          description: 'Discover anime, books, and movies',
          color: Colors.deepPurpleAccent,
          items: [
            _HubItem(label: 'Anime Picks', icon: Icons.live_tv_outlined, builder: (_) => const AnimeRecommenderPage()),
            _HubItem(label: 'Book Picks', icon: Icons.menu_book_outlined, builder: (_) => const BookRecommenderPage()),
            _HubItem(label: 'Movie Picks', icon: Icons.movie_outlined, builder: (_) => const MovieRecommenderPage()),
          ],
        ),

        // ── 🛠️ PRODUCTIVITY ─────────────────────────────────────
        _HubCategory(
          title: 'Productivity',
          emoji: '🛠️',
          description: 'Journals, trackers, and planning tools',
          color: Colors.amberAccent,
          items: [
            _HubItem(label: 'Notes Pad', icon: Icons.note_alt_outlined, builder: (_) => const NotesPadPage()),
            _HubItem(label: 'Dream Journal', icon: Icons.nights_stay_outlined, builder: (_) => const DreamJournalPage()),
            _HubItem(label: 'Voice Notes', icon: Icons.mic_rounded, builder: (_) => const VoiceNotesPage()),
            _HubItem(label: 'Goal Tracker', icon: Icons.track_changes_outlined, builder: (_) => const GoalTrackerPage()),
            _HubItem(label: 'Habit Tracker', icon: Icons.check_circle_outline, builder: (_) => const HabitTrackerPage()),
            _HubItem(label: 'Budget Tracker', icon: Icons.account_balance_wallet_outlined, builder: (_) => const BudgetTrackerPage()),
            _HubItem(label: 'Pomodoro', icon: Icons.timer_outlined, builder: (_) => const PomodoroPage()),
            _HubItem(label: 'Study Timer', icon: Icons.school_rounded, builder: (_) => const StudyTimerPage()),
            _HubItem(label: 'Bucket List', icon: Icons.checklist_outlined, builder: (_) => const SharedBucketListPage()),
            _HubItem(label: 'Countdown Timer', icon: Icons.timer_rounded, builder: (_) => const CountdownTimerPage()),
          ],
        ),

        // ── 🧘 WELLNESS ─────────────────────────────────────────
        _HubCategory(
          title: 'Wellness',
          emoji: '🧘',
          description: 'Breathing, gratitude, and fitness',
          color: Colors.greenAccent,
          items: [
            _HubItem(label: 'Breathing', icon: Icons.air_outlined, builder: (_) => const BreathingExercisePage()),
            _HubItem(label: 'Gratitude Journal', icon: Icons.auto_awesome_outlined, builder: (_) => const GratitudeJournalPage()),
            _HubItem(label: 'Workout Planner', icon: Icons.fitness_center_outlined, builder: (_) => const WorkoutPlannerPage()),
            _HubItem(label: 'Mood Tracker', icon: Icons.mood_rounded, builder: (_) => const MoodTrackerPage()),
            _HubItem(label: 'Mood Tracking', icon: Icons.insights_rounded, builder: (_) => const MoodTrackingPage()),
            _HubItem(label: 'Sleep Mode', icon: Icons.bedtime_rounded, builder: (_) => const SleepModePage()),
            _HubItem(label: 'Wellness Reminders', icon: Icons.spa_rounded, builder: (_) => const WellnessRemindersPage()),
          ],
        ),

        // ── 📺 ANIME & MEDIA ────────────────────────────────────
        _HubCategory(
          title: 'Anime & Media',
          emoji: '📺',
          description: 'Browse, stream, and track anime',
          color: const Color(0xFFBB52FF),
          items: [
            _HubItem(label: 'Cloud Videos', icon: Icons.cloud_queue_rounded, onTap: widget.onOpenCloudinary),
            _HubItem(label: 'Manga Reader', icon: Icons.menu_book_rounded, builder: (_) => const MangaSectionPage()),
            _HubItem(label: 'Web Streamers', icon: Icons.travel_explore_rounded, builder: (_) => const WebStreamersHubPage()),
            _HubItem(label: 'Anime Quiz', icon: Icons.quiz_rounded, builder: (_) => const AnimeQuizPage()),
            _HubItem(label: 'Anime OST', icon: Icons.music_note_rounded, builder: (_) => const AnimeOstPage()),
            _HubItem(label: 'Anime Calendar', icon: Icons.calendar_month_rounded, builder: (_) => const AnimeCalendarPage()),
            _HubItem(label: 'Watch Party', icon: Icons.live_tv_rounded, builder: (_) => const AnimeWatchPartyPage()),
            _HubItem(label: 'Matchmaker', icon: Icons.favorite_rounded, builder: (_) => const AnimeMatchmakerPage()),
            _HubItem(label: 'Watchlist', icon: Icons.bookmark_outlined, builder: (_) => const WatchlistPage()),
            _HubItem(label: 'Watch History', icon: Icons.history_rounded, builder: (_) => const WatchHistoryPage()),
            _HubItem(label: 'Downloads', icon: Icons.download_rounded, builder: (_) => const DownloadsPage()),
            _HubItem(label: 'MAL Sync', icon: Icons.sync_rounded, builder: (_) => const MalSyncPage()),
            _HubItem(label: 'Episode Alerts', icon: Icons.notifications_active_rounded, builder: (_) => const EpisodeAlertsPage()),
          ],
        ),

        // ── 🌐 SOCIAL & CLOUD ───────────────────────────────────
        _HubCategory(
          title: 'Social & Cloud',
          emoji: '🌐',
          description: 'Community, sync, and multiplayer',
          color: Colors.orangeAccent,
          items: [
            _HubItem(label: 'Leaderboard', icon: Icons.leaderboard_outlined, builder: (_) => const LeaderboardPage()),
            _HubItem(label: 'Cloud Sync', icon: Icons.cloud_sync_outlined, builder: (_) => const CloudSyncPage()),
            _HubItem(label: 'Friends', icon: Icons.people_outline, builder: (_) => const FriendsPage()),
            _HubItem(label: 'Global Quests', icon: Icons.explore_outlined, builder: (_) => const GlobalQuestBoardPage()),
            _HubItem(label: 'Pinned Messages', icon: Icons.push_pin_outlined, builder: (_) => const PinnedMessagesPage()),
            _HubItem(label: 'Scheduled Msgs', icon: Icons.schedule_outlined, builder: (_) => const ScheduledMessagesPage()),
            _HubItem(label: 'Chat Summary', icon: Icons.summarize_rounded, builder: (_) => const ConversationSummaryPage()),
          ],
        ),

        // ── 📊 STATS & INSIGHTS ─────────────────────────────────
        _HubCategory(
          title: 'Stats & Insights',
          emoji: '📊',
          description: 'Track your relationship journey',
          color: Colors.tealAccent,
          items: [
            _HubItem(label: 'Chat Analytics', icon: Icons.bar_chart_outlined, builder: (_) => const ChatAnalyticsPage()),
            _HubItem(label: 'Level Map', icon: Icons.map_outlined, builder: (_) => const RelationshipLevelMapPage()),
            _HubItem(label: 'Year in Review', icon: Icons.calendar_month_outlined, builder: (_) => const YearInReviewPage()),
            _HubItem(label: 'Achievements', icon: Icons.emoji_events_outlined, builder: (_) => const AchievementsGalleryPage()),
            _HubItem(label: 'Star Map', icon: Icons.auto_awesome_outlined, builder: (_) => const StarMapPage()),
            _HubItem(label: 'Anniversary', icon: Icons.favorite_outlined, builder: (_) => const AnniversaryPage()),
            _HubItem(label: 'Evolution', icon: Icons.trending_up_rounded, builder: (_) => const RelationshipEvolutionPage()),
            _HubItem(label: 'Voice Call', icon: Icons.phone_rounded, builder: (_) => const WaifuVoiceCallScreen()),
            _HubItem(label: 'Memory Timeline', icon: Icons.timeline_rounded, builder: (_) => const MemoryTimelinePage()),
            _HubItem(label: 'Memory Wall', icon: Icons.photo_library_rounded, builder: (_) => const MemoryWallPage()),
            _HubItem(label: 'Memory Book', icon: Icons.auto_stories_rounded, builder: (_) => const MemoryBookPage()),
          ],
        ),

        // ── 🌸 EXTRAS ────────────────────────────────────────────
        _HubCategory(
          title: 'Extras',
          emoji: '🌸',
          description: 'Fun extras, Zero Two lore, and more',
          color: const Color(0xFFFF6B9D),
          items: [
            _HubItem(label: 'ZT Facts', icon: Icons.auto_awesome_rounded, builder: (_) => const ZeroTwoFactsPage()),
            _HubItem(label: 'ZT Calendar', icon: Icons.calendar_today_rounded, builder: (_) => const ZeroTwoCalendarPage()),
            _HubItem(label: 'Tarot Reading', icon: Icons.style_rounded, builder: (_) => const TarotReadingPage()),
            _HubItem(label: 'Kaomoji', icon: Icons.emoji_emotions_rounded, builder: (_) => const KaomojiPickerPage()),
          ],
        ),

        // ── 💻 DEV & CODE ─────────────────────────────────────────
        _HubCategory(
          title: 'Dev & Code',
          emoji: '💻',
          description: 'Code editor, debugging, and dev tools',
          color: Colors.cyanAccent,
          items: [
            _HubItem(label: 'Dev Mode', icon: Icons.code_rounded, builder: (_) => const WaifuDevModePage()),
            _HubItem(label: 'Error Memory', icon: Icons.bug_report_rounded, builder: (_) => const ErrorMemoryPage()),
            _HubItem(label: 'AI Debug Panel', icon: Icons.developer_mode_rounded, builder: (_) => const AiDebugPanelPage()),
            _HubItem(label: 'Plugin System', icon: Icons.extension_rounded, builder: (_) => const PluginSystemPage()),
          ],
        ),

        // ── ⚡ POWER TOOLS ─────────────────────────────────────────
        _HubCategory(
          title: 'Power Tools',
          emoji: '⚡',
          description: 'Productivity, focus, and life management',
          color: Colors.amberAccent,
          items: [
            _HubItem(label: 'Second Brain', icon: Icons.psychology_alt_rounded, builder: (_) => const SecondBrainPage()),
            _HubItem(label: 'Focus Mode', icon: Icons.center_focus_strong_rounded, builder: (_) => const FocusModePage()),
            _HubItem(label: 'Thought Capture', icon: Icons.lightbulb_rounded, builder: (_) => const ThoughtCapturePage()),
            _HubItem(label: 'Day Recap', icon: Icons.summarize_rounded, builder: (_) => const DayRecapPage()),
            _HubItem(label: 'Share & Export', icon: Icons.share_rounded, builder: (_) => const ChatShareExportPage()),
          ],
        ),

        // ── 🧠 BRAIN & GROWTH ─────────────────────────────────────
        _HubCategory(
          title: 'Brain & Growth',
          emoji: '🧠',
          description: 'XP, goals, rewards, and self-improvement',
          color: Colors.deepPurpleAccent,
          items: [
            _HubItem(label: 'XP & Level', icon: Icons.stars_rounded, builder: (_) => const WaifuXpLevelPage()),
            _HubItem(label: 'Rewards', icon: Icons.card_giftcard_rounded, builder: (_) => const RewardSystemPage()),
            _HubItem(label: 'Goal Tracker', icon: Icons.flag_rounded, builder: (_) => const GoalTrackerPage()),
            _HubItem(label: 'Self Growth', icon: Icons.trending_up_rounded, builder: (_) => const SelfImprovementPage()),
            _HubItem(label: 'AI Story Game', icon: Icons.auto_stories_rounded, builder: (_) => const AiStoryGamePage()),
            _HubItem(label: 'Dream Mode', icon: Icons.nights_stay_rounded, builder: (_) => const DreamModePage()),
            _HubItem(label: 'Life Sim', icon: Icons.favorite_rounded, builder: (_) => const LifeSimPage()),
            _HubItem(label: 'Analytics', icon: Icons.insights_rounded, builder: (_) => const UserAnalyticsDashboardPage()),
          ],
        ),

        // ── 🧬 AI EVOLUTION ──────────────────────────────────────────
        _HubCategory(
          title: 'AI Evolution',
          emoji: '🧬',
          description: 'Digital clone, auto-learning & future prediction',
          color: Colors.tealAccent,
          items: [
            _HubItem(label: 'Digital Clone', icon: Icons.person_pin_rounded, builder: (_) => const DigitalClonePage()),
            _HubItem(label: 'Future You', icon: Icons.rocket_launch_rounded, builder: (_) => const FutureSimPage()),
            _HubItem(label: 'Auto Learning', icon: Icons.auto_fix_high_rounded, builder: (_) => const AutoLearningPage()),
            _HubItem(label: 'Life Log', icon: Icons.timeline_rounded, builder: (_) => const AutoLifeLogPage()),
          ],
        ),

        // ── ⚡ SYSTEM & AUTOMATION ─────────────────────────────────────
        _HubCategory(
          title: 'System & Automation',
          emoji: '⚡',
          description: 'Task execution, workflows & project scaffolding',
          color: Colors.greenAccent,
          items: [
            _HubItem(label: 'Task Executor', icon: Icons.terminal_rounded, builder: (_) => const TaskExecutorPage()),
            _HubItem(label: 'Workflows', icon: Icons.account_tree_rounded, builder: (_) => const WorkflowEnginePage()),
            _HubItem(label: 'Project Gen', icon: Icons.create_new_folder_rounded, builder: (_) => const ProjectGeneratorPage()),
            _HubItem(label: 'File Intel', icon: Icons.folder_special_rounded, builder: (_) => const FileIntelligencePage()),
          ],
        ),

        // ── 🔍 INTELLIGENCE & SEARCH ──────────────────────────────────
        _HubCategory(
          title: 'Intelligence & Search',
          emoji: '🔍',
          description: 'Search everything, review code & AI insights',
          color: Colors.orangeAccent,
          items: [
            _HubItem(label: 'Personal Search', icon: Icons.search_rounded, builder: (_) => const PersonalSearchPage()),
            _HubItem(label: 'Code Reviewer', icon: Icons.rate_review_rounded, builder: (_) => const CodeReviewerPage()),
            _HubItem(label: 'AI Insights', icon: Icons.auto_awesome_rounded, builder: (_) => const BackgroundInsightsPage()),
            _HubItem(label: 'AI Modes', icon: Icons.psychology_rounded, builder: (_) => const AiPersonalityModesPage()),
            _HubItem(label: 'Emotion Detect', icon: Icons.mic_external_on_rounded, builder: (_) => const VoiceEmotionDetectorPage()),
          ],
        ),

        // ── 🧠 BRAIN ARCHITECTURE ─────────────────────────────────────
        _HubCategory(
          title: 'Brain Architecture',
          emoji: '🧠',
          description: 'Memory layers, knowledge graph & time travel',
          color: Colors.deepPurpleAccent,
          items: [
            _HubItem(label: 'Memory Stack', icon: Icons.layers_rounded, builder: (_) => const MemoryStackPage()),
            _HubItem(label: 'Knowledge Graph', icon: Icons.hub_rounded, builder: (_) => const KnowledgeGraphPage()),
            _HubItem(label: 'Time Machine', icon: Icons.history_rounded, builder: (_) => const TimeMachinePage()),
          ],
        ),

        // ── 🧰 REAL-LIFE TOOLS ──────────────────────────────────────
        _HubCategory(
          title: 'Real-Life Tools',
          emoji: '🧰',
          description: 'Practical everyday utilities',
          color: Colors.lightBlueAccent,
          items: [
            _HubItem(label: 'Parking Saver', icon: Icons.local_parking_rounded, builder: (_) => const ParkingSpotSaverPage()),
            _HubItem(label: 'Smart Scanner', icon: Icons.document_scanner_rounded, builder: (_) => const SmartScannerPage()),
            _HubItem(label: 'Health Reminders', icon: Icons.medication_rounded, builder: (_) => const MedicationReminderPage()),
            _HubItem(label: 'Package Tracker', icon: Icons.local_shipping_rounded, builder: (_) => const PackageTrackerPage()),
            _HubItem(label: 'Emergency SOS', icon: Icons.sos_rounded, builder: (_) => const EmergencySosPage()),
            _HubItem(label: 'Clipboard', icon: Icons.content_paste_rounded, builder: (_) => const ClipboardManagerPage()),
            _HubItem(label: 'Bill Splitter', icon: Icons.receipt_long_rounded, builder: (_) => const BillSplitterPage()),
            _HubItem(label: 'Ruler & Convert', icon: Icons.straighten_rounded, builder: (_) => const ArRulerPage()),
            _HubItem(label: 'Password Gen', icon: Icons.password_rounded, builder: (_) => const PasswordGeneratorPage()),
            _HubItem(label: 'QR Tools', icon: Icons.qr_code_scanner_rounded, builder: (_) => const QrScannerPage()),
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
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
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
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isOpen
                  ? Padding(
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
                              onTap: () {
                                if (item.onTap != null) {
                                  item.onTap!();
                                } else if (item.builder != null) {
                                  Navigator.push(context, MaterialPageRoute(builder: item.builder!));
                                }
                              },
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
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
