import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anime_waifu/core/providers/chat_provider.dart';
import 'package:anime_waifu/screens/ar_companion_page.dart';
import 'package:anime_waifu/screens/geofencing_settings_page.dart';
import 'package:anime_waifu/screens/memory_vault_page.dart';
import 'package:anime_waifu/services/manga_service.dart';
// about_page.dart is a part file — navigated via navIndex, not named routes
import 'package:anime_waifu/screens/achievement_room_page.dart';
import 'package:anime_waifu/screens/achievements_gallery_page.dart';
import 'package:anime_waifu/screens/achievements_screen.dart';
import 'package:anime_waifu/screens/advanced_settings_page.dart';
import 'package:anime_waifu/screens/ai_art_generator_page.dart';
// animated_splash_screen.dart requires args — use MaterialPageRoute
import 'package:anime_waifu/screens/anime_calendar_page.dart';
// anime_embed_player_page.dart requires constructor args — use MaterialPageRoute
import 'package:anime_waifu/screens/anime_matchmaker_page.dart';
import 'package:anime_waifu/screens/anime_ost_page.dart';
import 'package:anime_waifu/screens/anime_quiz_page.dart';
import 'package:anime_waifu/screens/anime_recommender_page.dart';
import 'package:anime_waifu/screens/anime_section_page.dart';
import 'package:anime_waifu/screens/anime_watch_party_page.dart';
import 'package:anime_waifu/screens/anime_wordle_page.dart';
import 'package:anime_waifu/screens/anniversary_page.dart';
import 'package:anime_waifu/screens/app_icon_picker_page.dart';
import 'package:anime_waifu/screens/book_recommender_page.dart';
import 'package:anime_waifu/screens/boss_battle_page.dart';
import 'package:anime_waifu/screens/breathing_page.dart';
import 'package:anime_waifu/screens/bucket_list_page.dart';
import 'package:anime_waifu/screens/budget_tracker_page.dart';
// character_database_page.dart requires args — use MaterialPageRoute
import 'package:anime_waifu/screens/chat_analytics_page.dart';
import 'package:anime_waifu/screens/chat_statistics_page.dart';
import 'package:anime_waifu/screens/checkin_streak_page.dart';
import 'package:anime_waifu/screens/cloud_sync_page.dart';
import 'package:anime_waifu/screens/commands_page.dart';
// conversation_summary_page.dart requires constructor args — use MaterialPageRoute
import 'package:anime_waifu/screens/countdown_timer_page.dart';
import 'package:anime_waifu/screens/daily_affirmations_page.dart';
import 'package:anime_waifu/screens/daily_challenge_page.dart';
import 'package:anime_waifu/screens/daily_couple_challenge_page.dart';
import 'package:anime_waifu/screens/daily_horoscope_page.dart';
import 'package:anime_waifu/screens/daily_love_letter_page.dart';
import 'package:anime_waifu/screens/daily_trivia_page.dart';
import 'package:anime_waifu/screens/data_vault_page.dart';
import 'package:anime_waifu/screens/date_night_planner_page.dart';
import 'package:anime_waifu/screens/downloads_page.dart';
import 'package:anime_waifu/screens/draw_lots_page.dart';
import 'package:anime_waifu/screens/dream_interpreter_page.dart';
import 'package:anime_waifu/screens/dream_journal_page.dart';
import 'package:anime_waifu/screens/episode_alerts_page.dart';
import 'package:anime_waifu/screens/features_hub_page.dart';
import 'package:anime_waifu/screens/fortune_cookie_page.dart';
import 'package:anime_waifu/screens/friends_page.dart';
import 'package:anime_waifu/screens/gacha_collector_page.dart';
import 'package:anime_waifu/screens/global_quest_board_page.dart';
import 'package:anime_waifu/screens/goal_tracker_page.dart';
import 'package:anime_waifu/screens/gratitude_journal_page.dart';
import 'package:anime_waifu/screens/habit_tracker_page.dart';
// hub_page.dart requires constructor args — use MaterialPageRoute
import 'package:anime_waifu/screens/image_pack_page.dart';
import 'package:anime_waifu/screens/kaomoji_picker_page.dart';
import 'package:anime_waifu/screens/language_translator_page.dart';
import 'package:anime_waifu/screens/late_night_mode_page.dart';
import 'package:anime_waifu/screens/leaderboard_page.dart';
import 'package:anime_waifu/screens/life_advice_page.dart';
import 'package:anime_waifu/screens/life_events_page.dart';
import 'package:anime_waifu/screens/login_screen.dart';
import 'package:anime_waifu/screens/love_letter_page.dart';
import 'package:anime_waifu/screens/love_quiz_page.dart';
import 'package:anime_waifu/screens/mal_sync_page.dart';
import 'package:anime_waifu/screens/manga_section_page.dart';
import 'package:anime_waifu/screens/manga_translator_page.dart';
import 'package:anime_waifu/screens/memory_book_page.dart';
import 'package:anime_waifu/screens/memory_timeline_page.dart';
import 'package:anime_waifu/screens/memory_wall_page.dart';
import 'package:anime_waifu/screens/mini_games_page.dart';
import 'package:anime_waifu/screens/mood_tracker_page.dart';
import 'package:anime_waifu/screens/mood_tracking_page.dart';
// morning_greeting_card.dart used to require args — now resolved via route map or static call
import 'package:anime_waifu/screens/morning_greeting_card.dart';
import 'package:anime_waifu/screens/movie_recommender_page.dart';
import 'package:anime_waifu/screens/multiple_personas_page.dart';
import 'package:anime_waifu/screens/music_player_page.dart';
import 'package:anime_waifu/screens/never_have_i_ever_page.dart';
import 'package:anime_waifu/screens/notes_pad_page.dart';
import 'package:anime_waifu/screens/notifications_settings_page.dart';
import 'package:anime_waifu/screens/personality_settings_page.dart';
import 'package:anime_waifu/screens/pinned_messages_page.dart';
import 'package:anime_waifu/screens/poem_generator_page.dart';
import 'package:anime_waifu/screens/pomodoro_page.dart';
import 'package:anime_waifu/screens/profile_screen.dart';
import 'package:anime_waifu/screens/quote_of_day_page.dart';
import 'package:anime_waifu/screens/recipe_recommender_page.dart';
import 'package:anime_waifu/screens/relationship_advice_page.dart';
import 'package:anime_waifu/screens/relationship_coach_page.dart';
import 'package:anime_waifu/screens/relationship_evolution_page.dart';
import 'package:anime_waifu/screens/relationship_level_map_page.dart';
import 'package:anime_waifu/screens/relationship_timeline_page.dart';
import 'package:anime_waifu/screens/relationship_trivia_page.dart';
import 'package:anime_waifu/screens/rock_paper_scissors_page.dart';
import 'package:anime_waifu/screens/roleplay_scenario_page.dart';
import 'package:anime_waifu/screens/scheduled_messages_page.dart';
import 'package:anime_waifu/screens/shared_bucket_list_page.dart';
import 'package:anime_waifu/screens/sleep_mode_page.dart';
import 'package:anime_waifu/screens/spinner_wheel_page.dart';
import 'package:anime_waifu/screens/star_map_page.dart';
import 'package:anime_waifu/screens/stats_habits_page.dart';
import 'package:anime_waifu/screens/story_adventure_page.dart';
import 'package:anime_waifu/screens/story_mode_page.dart';
import 'package:anime_waifu/screens/study_timer_page.dart';
import 'package:anime_waifu/screens/tarot_reading_page.dart';
import 'package:anime_waifu/screens/theme_accent_page.dart';
import 'package:anime_waifu/screens/theme_switcher_page.dart';
import 'package:anime_waifu/screens/tic_tac_toe_page.dart';
import 'package:anime_waifu/screens/truth_or_dare_page.dart';
import 'package:anime_waifu/screens/twenty_questions_page.dart';
import 'package:anime_waifu/screens/virtual_date_page.dart';
import 'package:anime_waifu/screens/virtual_gift_shop_page.dart';
import 'package:anime_waifu/screens/voice_notes_page.dart';
import 'package:anime_waifu/screens/waifu_tier_list_page.dart';
import 'package:anime_waifu/screens/waifu_voice_call_screen.dart';
import 'package:anime_waifu/screens/watch_history_page.dart';
import 'package:anime_waifu/screens/watchlist_page.dart';
import 'package:anime_waifu/screens/web_streamers_hub_page.dart';
import 'package:anime_waifu/screens/wellness_reminders_page.dart';
import 'package:anime_waifu/screens/word_association_page.dart';
import 'package:anime_waifu/screens/word_puzzle_page.dart';
import 'package:anime_waifu/screens/workout_planner_page.dart';
import 'package:anime_waifu/screens/would_you_rather_page.dart';
import 'package:anime_waifu/screens/writing_helper_page.dart';
import 'package:anime_waifu/screens/year_in_review_page.dart';
import 'package:anime_waifu/screens/zero_two_calendar_page.dart';
import 'package:anime_waifu/screens/zero_two_diary_page.dart';
import 'package:anime_waifu/screens/zero_two_facts_page.dart';
import 'package:anime_waifu/screens/ar_ruler_page.dart';
import 'package:anime_waifu/screens/bill_splitter_page.dart';
import 'package:anime_waifu/screens/clipboard_manager_page.dart';
import 'package:anime_waifu/screens/emergency_sos_page.dart';
import 'package:anime_waifu/screens/medication_reminder_page.dart';
import 'package:anime_waifu/screens/package_tracker_page.dart';
import 'package:anime_waifu/screens/parking_spot_saver_page.dart';
import 'package:anime_waifu/screens/password_generator_page.dart';
import 'package:anime_waifu/screens/qr_scanner_page.dart';
import 'package:anime_waifu/screens/smart_scanner_page.dart';
import 'package:anime_waifu/debug/wakeword_debug.dart';
import 'package:anime_waifu/screens/ai_debug_panel_page.dart';
import 'package:anime_waifu/screens/ai_personality_modes_page.dart';
import 'package:anime_waifu/screens/ai_story_game_page.dart';
import 'package:anime_waifu/screens/auto_learning_page.dart';
import 'package:anime_waifu/screens/auto_life_log_page.dart';
import 'package:anime_waifu/screens/background_insights_page.dart';
import 'package:anime_waifu/screens/chat_share_export_page.dart';
import 'package:anime_waifu/screens/code_reviewer_page.dart';
import 'package:anime_waifu/screens/day_recap_page.dart';
import 'package:anime_waifu/screens/digital_clone_page.dart';
import 'package:anime_waifu/screens/dream_mode_page.dart';
import 'package:anime_waifu/screens/error_memory_page.dart';
import 'package:anime_waifu/screens/file_intelligence_page.dart';
import 'package:anime_waifu/screens/focus_mode_page.dart';
import 'package:anime_waifu/screens/future_sim_page.dart';
import 'package:anime_waifu/screens/knowledge_graph_page.dart';
import 'package:anime_waifu/screens/life_sim_page.dart';
import 'package:anime_waifu/screens/memory_stack_page.dart';
import 'package:anime_waifu/screens/personal_search_page.dart';
import 'package:anime_waifu/screens/plugin_system_page.dart';
import 'package:anime_waifu/screens/project_generator_page.dart';
import 'package:anime_waifu/screens/quests_page.dart';
import 'package:anime_waifu/screens/reward_system_page.dart';
import 'package:anime_waifu/screens/second_brain_page.dart';
import 'package:anime_waifu/screens/secret_notes_page.dart';
import 'package:anime_waifu/screens/self_improvement_page.dart';
import 'package:anime_waifu/screens/task_executor_page.dart';
import 'package:anime_waifu/screens/thought_capture_page.dart';
import 'package:anime_waifu/screens/time_machine_page.dart';
import 'package:anime_waifu/screens/user_analytics_dashboard_page.dart';
import 'package:anime_waifu/screens/voice_emotion_detector_page.dart';
import 'package:anime_waifu/screens/waifu_dev_mode_page.dart';
import 'package:anime_waifu/screens/waifu_xp_level_page.dart';
import 'package:anime_waifu/screens/workflow_engine_page.dart';
import 'package:anime_waifu/screens/gacha_page.dart';
import 'package:anime_waifu/screens/hianime_webview_page.dart';
import 'package:anime_waifu/screens/manga_reader_page.dart';
import 'package:anime_waifu/models/manga_models.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppRouter
///
/// Centralized named-route registry. Replaces hundreds of inline
/// MaterialPageRoute constructors scattered through the drawer and screens
/// with clean Navigator.pushNamed() calls.
/// ─────────────────────────────────────────────────────────────────────────────
class AppRouter {
  AppRouter._();

  // ── Route Names ─────────────────────────────────────────────────────────
  static const String wakeDebug = '/wake-debug';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String achievements = '/achievements';
  static const String achievementRoom = '/achievement-room';
  static const String achievementsGallery = '/achievements-gallery';
  static const String advancedSettings = '/advanced-settings';
  static const String aiArtGenerator = '/ai-art-generator';
  static const String splash = '/splash';
  static const String animeCalendar = '/anime-calendar';
  static const String animeMatchmaker = '/anime-matchmaker';
  static const String animeOst = '/anime-ost';
  static const String animeQuiz = '/anime-quiz';
  static const String animeRecommender = '/anime-recommender';
  static const String animeSection = '/anime-section';
  static const String animeWatchParty = '/anime-watch-party';
  static const String animeWordle = '/anime-wordle';
  static const String anniversary = '/anniversary';
  static const String appIconPicker = '/app-icon-picker';
  static const String bookRecommender = '/book-recommender';
  static const String bossBattle = '/boss-battle';
  static const String breathing = '/breathing';
  static const String bucketList = '/bucket-list';
  static const String budgetTracker = '/budget-tracker';
  static const String characterDatabase = '/character-database';
  static const String chatAnalytics = '/chat-analytics';
  static const String chatStatistics = '/chat-statistics';
  static const String checkinStreak = '/checkin-streak';
  static const String cloudSync = '/cloud-sync';
  static const String commands = '/commands';
  static const String conversationSummary = '/conversation-summary';
  static const String countdownTimer = '/countdown-timer';
  static const String dailyAffirmations = '/daily-affirmations';
  static const String dailyChallenge = '/daily-challenge';
  static const String dailyCoupleChallenge = '/daily-couple-challenge';
  static const String dailyHoroscope = '/daily-horoscope';
  static const String dailyLoveLetter = '/daily-love-letter';
  static const String dailyTrivia = '/daily-trivia';
  static const String dataVault = '/data-vault';
  static const String dateNightPlanner = '/date-night-planner';
  static const String downloads = '/downloads';
  static const String drawLots = '/draw-lots';
  static const String dreamInterpreter = '/dream-interpreter';
  static const String dreamJournal = '/dream-journal';
  static const String episodeAlerts = '/episode-alerts';
  static const String featuresHub = '/features-hub';
  static const String fortuneCookie = '/fortune-cookie';
  static const String friends = '/friends';
  static const String gachaCollector = '/gacha-collector';
  static const String globalQuestBoard = '/global-quest-board';
  static const String goalTracker = '/goal-tracker';
  static const String gratitudeJournal = '/gratitude-journal';
  static const String habitTracker = '/habit-tracker';
  static const String hub = '/hub';
  static const String imagePack = '/image-pack';
  static const String kaomojiPicker = '/kaomoji-picker';
  static const String languageTranslator = '/language-translator';
  static const String lateNightMode = '/late-night-mode';
  static const String leaderboard = '/leaderboard';
  static const String lifeAdvice = '/life-advice';
  static const String lifeEvents = '/life-events';
  static const String loveLetter = '/love-letter';
  static const String loveQuiz = '/love-quiz';
  static const String malSync = '/mal-sync';
  static const String mangaSection = '/manga-section';
  static const String mangaTranslator = '/manga-translator';
  static const String memoryBook = '/memory-book';
  static const String memoryTimeline = '/memory-timeline';
  static const String memoryWall = '/memory-wall';
  static const String miniGames = '/mini-games';
  static const String moodTracker = '/mood-tracker';
  static const String moodTracking = '/mood-tracking';
  static const String morningGreetingCard = '/morning-greeting-card';
  static const String movieRecommender = '/movie-recommender';
  static const String multiplePersonas = '/multiple-personas';
  static const String musicPlayer = '/music-player';
  static const String neverHaveIEver = '/never-have-i-ever';
  static const String notesPad = '/notes-pad';
  static const String notificationsSettings = '/notifications-settings';
  static const String personalitySettings = '/personality-settings';
  static const String pinnedMessages = '/pinned-messages';
  static const String poemGenerator = '/poem-generator';
  static const String pomodoro = '/pomodoro';
  static const String quoteOfDay = '/quote-of-day';
  static const String recipeRecommender = '/recipe-recommender';
  static const String relationshipAdvice = '/relationship-advice';
  static const String relationshipCoach = '/relationship-coach';
  static const String relationshipEvolution = '/relationship-evolution';
  static const String relationshipLevelMap = '/relationship-level-map';
  static const String relationshipTimeline = '/relationship-timeline';
  static const String relationshipTrivia = '/relationship-trivia';
  static const String rockPaperScissors = '/rock-paper-scissors';
  static const String roleplayScenario = '/roleplay-scenario';
  static const String scheduledMessages = '/scheduled-messages';
  static const String sharedBucketList = '/shared-bucket-list';
  static const String sleepMode = '/sleep-mode';
  static const String spinnerWheel = '/spinner-wheel';
  static const String starMap = '/star-map';
  static const String statsHabits = '/stats-habits';
  static const String storyAdventure = '/story-adventure';
  static const String storyMode = '/story-mode';
  static const String studyTimer = '/study-timer';
  static const String tarotReading = '/tarot-reading';
  static const String themeAccent = '/theme-accent';
  static const String themeSwitcher = '/theme-switcher';
  static const String ticTacToe = '/tic-tac-toe';
  static const String truthOrDare = '/truth-or-dare';
  static const String twentyQuestions = '/twenty-questions';
  static const String virtualDate = '/virtual-date';
  static const String virtualGiftShop = '/virtual-gift-shop';
  static const String voiceCall = '/voice-call';
  static const String voiceNotes = '/voice-notes';
  static const String waifuTierList = '/waifu-tier-list';
  static const String watchHistory = '/watch-history';
  static const String watchlist = '/watchlist';
  static const String webStreamersHub = '/web-streamers-hub';
  static const String wellnessReminders = '/wellness-reminders';
  static const String wordAssociation = '/word-association';
  static const String wordPuzzle = '/word-puzzle';
  static const String workoutPlanner = '/workout-planner';
  static const String wouldYouRather = '/would-you-rather';
  static const String writingHelper = '/writing-helper';
  static const String yearInReview = '/year-in-review';
  static const String zeroTwoCalendar = '/zero-two-calendar';
  static const String zeroTwoDiary = '/zero-two-diary';
  static const String zeroTwoFacts = '/zero-two-facts';

  // ── Real-Life Utility Routes ──────────────────────────────────────────────
  static const String arRuler = '/ar-ruler';
  static const String billSplitter = '/bill-splitter';
  static const String clipboardManager = '/clipboard-manager';
  static const String emergencySos = '/emergency-sos';
  static const String medicationReminder = '/medication-reminder';
  static const String packageTracker = '/package-tracker';
  static const String parkingSpotSaver = '/parking-spot-saver';
  static const String passwordGenerator = '/password-generator';
  static const String qrScanner = '/qr-scanner';
  static const String smartScanner = '/smart-scanner';

  // ── Previously Missing Routes ────────────────────────────────────────────
  static const String aiDebugPanel = '/ai-debug-panel';
  static const String aiPersonalityModes = '/ai-personality-modes';
  static const String aiStoryGame = '/ai-story-game';
  static const String autoLearning = '/auto-learning';
  static const String autoLifeLog = '/auto-life-log';
  static const String backgroundInsights = '/background-insights';
  static const String chatShareExport = '/chat-share-export';
  static const String codeReviewer = '/code-reviewer';
  static const String dayRecap = '/day-recap';
  static const String digitalClone = '/digital-clone';
  static const String dreamMode = '/dream-mode';
  static const String errorMemory = '/error-memory';
  static const String fileIntelligence = '/file-intelligence';
  static const String focusMode = '/focus-mode';
  static const String futureSim = '/future-sim';
  static const String knowledgeGraph = '/knowledge-graph';
  static const String lifeSim = '/life-sim';
  static const String memoryStack = '/memory-stack';
  static const String personalSearch = '/personal-search';
  static const String pluginSystem = '/plugin-system';
  static const String projectGenerator = '/project-generator';
  static const String quests = '/quests';
  static const String rewardSystem = '/reward-system';
  static const String secondBrain = '/second-brain';
  static const String secretNotes = '/secret-notes';
  static const String selfImprovement = '/self-improvement';
  static const String taskExecutor = '/task-executor';
  static const String thoughtCapture = '/thought-capture';
  static const String timeMachine = '/time-machine';
  static const String userAnalyticsDashboard = '/user-analytics-dashboard';
  static const String voiceEmotionDetector = '/voice-emotion-detector';
  static const String waifuDevMode = '/waifu-dev-mode';
  static const String waifuXpLevel = '/waifu-xp-level';
  static const String workflowEngine = '/workflow-engine';
  static const String gacha = '/gacha';
  static const String arCompanion = '/ar-companion';
  static const String geofencingSettings = '/geofencing-settings';
  static const String memoryVault = '/memory-vault';
  static const String hianime = '/hianime';
  static const String mangaReader = '/manga-reader';

  // ── Route Map ───────────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
        wakeDebug: (_) => const WakewordDebugPage(),
        login: (_) => const LoginScreen(),
        profile: (_) => const ProfileScreen(),
        achievements: (_) => const AchievementsScreen(),
        achievementRoom: (_) => const AchievementRoomPage(),
        achievementsGallery: (_) => const AchievementsGalleryPage(),
        advancedSettings: (_) => const AdvancedSettingsPage(),
        aiArtGenerator: (_) => const AiArtGeneratorPage(),
        animeCalendar: (_) => const AnimeCalendarPage(),
        animeMatchmaker: (_) => const AnimeMatchmakerPage(),
        animeOst: (_) => const AnimeOstPage(),
        animeQuiz: (_) => const AnimeQuizGamePage(),
        animeRecommender: (_) => const AnimeRecommenderPage(),
        animeSection: (_) => const AnimeSectionPage(),
        animeWatchParty: (_) => const AnimeWatchPartyPage(),
        animeWordle: (_) => const AnimeWordlePage(),
        anniversary: (_) => const AnniversaryPage(),
        appIconPicker: (_) => const AppIconPickerPage(),
        bookRecommender: (_) => const BookRecommenderPage(),
        bossBattle: (_) => const BossBattlePage(),
        breathing: (_) => const BreathingExercisePage(),
        bucketList: (_) => const BucketListPage(),
        budgetTracker: (_) => const BudgetTrackerPage(),
        // characterDatabase requires args — use MaterialPageRoute directly
        chatAnalytics: (_) => const ChatAnalyticsPage(),
        chatStatistics: (context) => ChatStatisticsPage(
              messages: context.read<ChatProvider>().messages,
            ),
        checkinStreak: (_) => const CheckinStreakPage(),
        cloudSync: (_) => const CloudSyncPage(),
        commands: (_) => const CommandsPage(),
        // conversationSummary requires args — use MaterialPageRoute directly
        countdownTimer: (_) => const CountdownTimerPage(),
        dailyAffirmations: (_) => const DailyAffirmationsPage(),
        dailyChallenge: (_) => const DailyChallengePage(),
        dailyCoupleChallenge: (_) => const DailyCoupleChallengePage(),
        dailyHoroscope: (_) => const DailyHoroscopePage(),
        dailyLoveLetter: (_) => const DailyLoveLetterPage(),
        dailyTrivia: (_) => const DailyTriviaPage(),
        dataVault: (_) => const DataVaultPage(),
        dateNightPlanner: (_) => const DateNightPlannerPage(),
        downloads: (_) => const DownloadsPage(),
        drawLots: (_) => const DrawLotsPage(),
        dreamInterpreter: (_) => const DreamInterpreterPage(),
        dreamJournal: (_) => const DreamJournalPage(),
        episodeAlerts: (_) => const EpisodeAlertsPage(),
        featuresHub: (_) => const FeaturesHubPage(),
        fortuneCookie: (_) => const FortuneCookiePage(),
        friends: (_) => const FriendsPage(),
        gachaCollector: (_) => const GachaCollectorPage(),
        globalQuestBoard: (_) => const GlobalQuestBoardPage(),
        goalTracker: (_) => const GoalTrackerPage(),
        gratitudeJournal: (_) => const GratitudeJournalPage(),
        habitTracker: (_) => const HabitTrackerPage(),
        // hub requires args — use MaterialPageRoute directly
        imagePack: (_) => const ImagePackPage(),
        kaomojiPicker: (_) => const KaomojiPickerPage(),
        languageTranslator: (_) => const LanguageTranslatorPage(),
        lateNightMode: (_) => const LateNightModePage(),
        leaderboard: (_) => const LeaderboardPage(),
        lifeAdvice: (_) => const LifeAdvicePage(),
        lifeEvents: (_) => const LifeEventsPage(),
        loveLetter: (_) => const LoveLetterPage(),
        loveQuiz: (_) => const LoveQuizPage(),
        malSync: (_) => const MalSyncPage(),
        mangaSection: (_) => const MangaSectionPage(),
        mangaTranslator: (_) => const MangaTranslatorPage(),
        memoryBook: (_) => const MemoryBookPage(),
        memoryTimeline: (_) => const MemoryTimelinePage(),
        memoryWall: (_) => const MemoryWallPage(),
        miniGames: (_) => const GamesHubPage(),
        moodTracker: (_) => const MoodTrackerPage(),
        moodTracking: (_) => const MoodTrackingPage(),
        movieRecommender: (_) => const MovieRecommenderPage(),
        multiplePersonas: (_) => const MultiplePersonasPage(),
        musicPlayer: (_) => const MusicPlayerPage(),
        neverHaveIEver: (_) => const NeverHaveIEverPage(),
        notesPad: (_) => const NotesPadPage(),
        notificationsSettings: (_) => const NotificationsSettingsPage(),
        personalitySettings: (_) => const PersonalitySettingsPage(),
        pinnedMessages: (_) => const PinnedMessagesPage(),
        poemGenerator: (_) => const PoemGeneratorPage(),
        pomodoro: (_) => const PomodoroPage(),
        quoteOfDay: (_) => const QuoteOfDayPage(),
        recipeRecommender: (_) => const RecipeRecommenderPage(),
        relationshipAdvice: (_) => const RelationshipAdvicePage(),
        relationshipCoach: (_) => const RelationshipCoachPage(),
        relationshipEvolution: (_) => const RelationshipEvolutionPage(),
        relationshipLevelMap: (_) => const RelationshipLevelMapPage(),
        relationshipTimeline: (_) => const RelationshipTimelinePage(),
        relationshipTrivia: (_) => const RelationshipTriviaPage(),
        rockPaperScissors: (_) => const RockPaperScissorsPage(),
        roleplayScenario: (_) => const RoleplayScenarioPage(),
        scheduledMessages: (_) => const ScheduledMessagesPage(),
        sharedBucketList: (_) => const SharedBucketListPage(),
        sleepMode: (_) => const SleepModePage(),
        spinnerWheel: (_) => const SpinnerWheelPage(),
        starMap: (_) => const StarMapPage(),
        statsHabits: (_) => const StatsAndHabitsPage(),
        storyAdventure: (_) => const StoryAdventurePage(),
        storyMode: (_) => const StoryModePage(),
        studyTimer: (_) => const StudyTimerPage(),
        tarotReading: (_) => const TarotReadingPage(),
        themeAccent: (_) => const ThemeAccentPage(),
        themeSwitcher: (_) => const ThemeSwitcherPage(),
        ticTacToe: (_) => const TicTacToePage(),
        truthOrDare: (_) => const TruthOrDarePage(),
        twentyQuestions: (_) => const TwentyQuestionsPage(),
        virtualDate: (_) => const VirtualDatePage(),
        virtualGiftShop: (_) => const VirtualGiftShopPage(),
        voiceCall: (_) => const WaifuVoiceCallScreen(),
        voiceNotes: (_) => const VoiceNotesPage(),
        waifuTierList: (_) => const WaifuTierListPage(),
        watchHistory: (_) => const WatchHistoryPage(),
        watchlist: (_) => const WatchlistPage(),
        webStreamersHub: (_) => const WebStreamersHubPage(),
        wellnessReminders: (_) => const WellnessRemindersPage(),
        wordAssociation: (_) => const WordAssociationPage(),
        wordPuzzle: (_) => const WordPuzzlePage(),
        workoutPlanner: (_) => const WorkoutPlannerPage(),
        wouldYouRather: (_) => const WouldYouRatherPage(),
        writingHelper: (_) => const WritingHelperPage(),
        yearInReview: (_) => const YearInReviewPage(),
        zeroTwoCalendar: (_) => const ZeroTwoCalendarPage(),
        zeroTwoDiary: (_) => const ZeroTwoDiaryPage(),
        zeroTwoFacts: (_) => const ZeroTwoFactsPage(),

        // ── Real-Life Utility Routes ──────────────────────────────────────
        arRuler: (_) => const ArRulerPage(),
        billSplitter: (_) => const BillSplitterPage(),
        clipboardManager: (_) => const ClipboardManagerPage(),
        emergencySos: (_) => const EmergencySosPage(),
        medicationReminder: (_) => const MedicationReminderPage(),
        packageTracker: (_) => const PackageTrackerPage(),
        parkingSpotSaver: (_) => const ParkingSpotSaverPage(),
        passwordGenerator: (_) => const PasswordGeneratorPage(),
        qrScanner: (_) => const QrScannerPage(),
        smartScanner: (_) => const SmartScannerPage(),

        // ── Previously Missing Feature Routes ──────────────────────────────
        aiDebugPanel: (_) => const AiDebugPanelPage(),
        aiPersonalityModes: (_) => const AiPersonalityModesPage(),
        aiStoryGame: (_) => const AiStoryGamePage(),
        autoLearning: (_) => const AutoLearningPage(),
        autoLifeLog: (_) => const AutoLifeLogPage(),
        backgroundInsights: (_) => const BackgroundInsightsPage(),
        chatShareExport: (_) => const ChatShareExportPage(),
        codeReviewer: (_) => const CodeReviewerPage(),
        dayRecap: (_) => const DayRecapPage(),
        digitalClone: (_) => const DigitalClonePage(),
        dreamMode: (_) => const DreamModePage(),
        errorMemory: (_) => const ErrorMemoryPage(),
        fileIntelligence: (_) => const FileIntelligencePage(),
        focusMode: (_) => const FocusModePage(),
        futureSim: (_) => const FutureSimPage(),
        knowledgeGraph: (_) => const KnowledgeGraphPage(),
        lifeSim: (_) => const LifeSimPage(),
        memoryStack: (_) => const MemoryStackPage(),
        personalSearch: (_) => const PersonalSearchPage(),
        pluginSystem: (_) => const PluginSystemPage(),
        projectGenerator: (_) => const ProjectGeneratorPage(),
        quests: (_) => const QuestsPage(),
        rewardSystem: (_) => const RewardSystemPage(),
        secondBrain: (_) => const SecondBrainPage(),
        secretNotes: (_) => const SecretNotesPage(),
        selfImprovement: (_) => const SelfImprovementPage(),
        taskExecutor: (_) => const TaskExecutorPage(),
        thoughtCapture: (_) => const ThoughtCapturePage(),
        timeMachine: (_) => const TimeMachinePage(),
        userAnalyticsDashboard: (_) => const UserAnalyticsDashboardPage(),
        voiceEmotionDetector: (_) => const VoiceEmotionDetectorPage(),
        waifuDevMode: (_) => const WaifuDevModePage(),
        waifuXpLevel: (_) => const WaifuXpLevelPage(),
        workflowEngine: (_) => const WorkflowEnginePage(),
        gacha: (_) => const GachaPage(),
        arCompanion: (_) => const ArCompanionPage(),
        geofencingSettings: (_) => const GeofencingSettingsPage(),
        memoryVault: (_) => const MemoryVaultPage(),
        AppRouter.hianime: (_) => const HiAnimeWebviewPage(source: AnimeWebSource.hianime),
        AppRouter.mangaReader: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final chapter = args?['chapter'];
          if (chapter == null || chapter is! ChapterItem) {
            return const Scaffold(body: Center(child: Text('Invalid manga chapter')));
          }
          return MangaReaderPage(
            chapter: chapter,
            mangaTitle: args?['mangaTitle'] as String? ?? 'Manga',
          );
        },
        // New explicit routes for orphans
        AppRouter.morningGreetingCard: (_) => MorningGreetingCard(onDismiss: () {}),
      };
}
