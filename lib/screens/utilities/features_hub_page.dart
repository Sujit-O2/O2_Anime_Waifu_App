import 'dart:math';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/core/providers/chat_provider.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/screens/admin/admin_hub_page.dart';
// ── Recommendations ──
import 'package:anime_waifu/screens/admin/admin_panel_page.dart';
import 'package:anime_waifu/screens/admin/discord_integration_panel_page.dart';
import 'package:anime_waifu/screens/admin/user_analytics_dashboard_page.dart';
import 'package:anime_waifu/screens/ai_tools/ai_art_generator_page.dart';
import 'package:anime_waifu/screens/ai_tools/ai_debug_panel_page.dart';
import 'package:anime_waifu/screens/ai_tools/ai_personality_modes_page.dart';
import 'package:anime_waifu/screens/ai_tools/dream_interpreter_page.dart';
import 'package:anime_waifu/screens/ai_tools/language_translator_page.dart';
import 'package:anime_waifu/screens/ai_tools/life_advice_page.dart';
import 'package:anime_waifu/screens/ai_tools/manga_translator_page.dart';
import 'package:anime_waifu/screens/ai_tools/poem_generator_page.dart';
import 'package:anime_waifu/screens/ai_tools/recipe_recommender_page.dart';
import 'package:anime_waifu/screens/ai_tools/relationship_advice_page.dart';
import 'package:anime_waifu/screens/ai_tools/relationship_coach_page.dart';
import 'package:anime_waifu/screens/ai_tools/writing_helper_page.dart';
import 'package:anime_waifu/screens/games/ai_story_game_page.dart';
import 'package:anime_waifu/screens/games/anime_quiz_page.dart';
import 'package:anime_waifu/screens/games/anime_wordle_page.dart';
import 'package:anime_waifu/screens/games/boss_battle_page.dart';
import 'package:anime_waifu/screens/games/daily_couple_challenge_page.dart';
import 'package:anime_waifu/screens/games/draw_lots_page.dart';
import 'package:anime_waifu/screens/games/gacha_collector_page.dart';
import 'package:anime_waifu/screens/games/global_quest_board_page.dart';
import 'package:anime_waifu/screens/games/love_quiz_page.dart';
import 'package:anime_waifu/screens/games/mini_games_page.dart';
import 'package:anime_waifu/screens/games/never_have_i_ever_page.dart';
import 'package:anime_waifu/screens/games/relationship_trivia_page.dart';
import 'package:anime_waifu/screens/games/rock_paper_scissors_page.dart';
import 'package:anime_waifu/screens/games/roleplay_scenario_page.dart';
// ── Games & Fun ──
import 'package:anime_waifu/screens/games/spinner_wheel_page.dart';
import 'package:anime_waifu/screens/games/story_mode_page.dart';
import 'package:anime_waifu/screens/games/tic_tac_toe_page.dart';
import 'package:anime_waifu/screens/games/truth_or_dare_page.dart';
import 'package:anime_waifu/screens/games/twenty_questions_page.dart';
import 'package:anime_waifu/screens/games/virtual_date_page.dart';
import 'package:anime_waifu/screens/games/waifu_tier_list_page.dart';
import 'package:anime_waifu/screens/games/word_association_page.dart';
import 'package:anime_waifu/screens/games/word_puzzle_page.dart';
import 'package:anime_waifu/screens/games/would_you_rather_page.dart';
import 'package:anime_waifu/screens/media/anime_calendar_page.dart';
//import 'package:anime_waifu/screens/games/anime_matchmaker_page.dart'; // File not found
import 'package:anime_waifu/screens/media/anime_matchmaker_page.dart';
import 'package:anime_waifu/screens/media/anime_ost_page.dart';
import 'package:anime_waifu/screens/media/anime_recommender_page.dart';
import 'package:anime_waifu/screens/media/anime_watch_party_page.dart';
import 'package:anime_waifu/screens/media/downloads_page.dart';
import 'package:anime_waifu/screens/media/episode_alerts_page.dart';
import 'package:anime_waifu/screens/media/hianime_webview_page.dart';
// ── Anime & Media ──
import 'package:anime_waifu/screens/media/manga_section_page.dart';
import 'package:anime_waifu/screens/media/watch_history_page.dart';
import 'package:anime_waifu/screens/media/watchlist_page.dart';
import 'package:anime_waifu/screens/media/web_streamers_hub_page.dart';
import 'package:anime_waifu/screens/utilities/music_player_page.dart';
import 'package:anime_waifu/screens/rituals/checkin_streak_page.dart';
import 'package:anime_waifu/screens/rituals/daily_affirmations_page.dart';
import 'package:anime_waifu/screens/rituals/daily_challenge_page.dart';
import 'package:anime_waifu/screens/rituals/daily_horoscope_page.dart';
import 'package:anime_waifu/screens/rituals/daily_love_letter_page.dart';
import 'package:anime_waifu/screens/rituals/daily_trivia_page.dart';
import 'package:anime_waifu/screens/rituals/fortune_cookie_page.dart';
import 'package:anime_waifu/screens/rituals/late_night_mode_page.dart';
import 'package:anime_waifu/screens/rituals/quote_of_day_page.dart';
// ── Daily & AI ──
import 'package:anime_waifu/screens/rituals/zero_two_diary_page.dart';
import 'package:anime_waifu/screens/social/achievements_gallery_page.dart';
import 'package:anime_waifu/screens/social/friends_page.dart';
import 'package:anime_waifu/screens/social/gratitude_journal_page.dart';
// ── Social & Cloud ──
import 'package:anime_waifu/screens/social/leaderboard_page.dart';
import 'package:anime_waifu/screens/social/memory_book_page.dart';
import 'package:anime_waifu/screens/social/memory_stack_page.dart';
import 'package:anime_waifu/screens/social/memory_timeline_page.dart';
import 'package:anime_waifu/screens/social/memory_vault_page.dart';
import 'package:anime_waifu/screens/social/memory_wall_page.dart';
import 'package:anime_waifu/screens/social/relationship_evolution_page.dart';
import 'package:anime_waifu/screens/social/relationship_level_map_page.dart';
import 'package:anime_waifu/screens/utilities/anniversary_page.dart';
// ── Orphan Integration ──
import 'package:anime_waifu/screens/utilities/ar_ruler_page.dart';
import 'package:anime_waifu/screens/utilities/auto_learning_page.dart';
import 'package:anime_waifu/screens/utilities/auto_life_log_page.dart';
import 'package:anime_waifu/screens/utilities/background_insights_page.dart';
import 'package:anime_waifu/screens/utilities/bill_splitter_page.dart';
import 'package:anime_waifu/screens/utilities/book_recommender_page.dart';
import 'package:anime_waifu/screens/utilities/budget_tracker_page.dart';
// ── Stats & Insights ──
import 'package:anime_waifu/screens/utilities/chat_analytics_page.dart';
import 'package:anime_waifu/screens/utilities/chat_share_export_page.dart';
import 'package:anime_waifu/screens/utilities/chat_statistics_page.dart';
import 'package:anime_waifu/screens/utilities/clipboard_manager_page.dart';
import 'package:anime_waifu/screens/utilities/cloud_sync_page.dart';
import 'package:anime_waifu/screens/utilities/code_reviewer_page.dart';
import 'package:anime_waifu/screens/utilities/conversation_summary_page.dart';
import 'package:anime_waifu/screens/utilities/countdown_timer_page.dart';
import 'package:anime_waifu/screens/utilities/day_recap_page.dart';
import 'package:anime_waifu/screens/utilities/digital_clone_page.dart';
import 'package:anime_waifu/screens/utilities/dream_journal_page.dart';
import 'package:anime_waifu/screens/utilities/dream_mode_page.dart';
import 'package:anime_waifu/screens/utilities/emergency_sos_page.dart';
import 'package:anime_waifu/screens/utilities/error_memory_page.dart';
import 'package:anime_waifu/screens/utilities/file_intelligence_page.dart';
import 'package:anime_waifu/screens/utilities/future_sim_page.dart';
import 'package:anime_waifu/screens/utilities/geofencing_settings_page.dart';
import 'package:anime_waifu/screens/utilities/goal_tracker_page.dart';
import 'package:anime_waifu/screens/utilities/kaomoji_picker_page.dart';
import 'package:anime_waifu/screens/utilities/knowledge_graph_page.dart';
import 'package:anime_waifu/screens/utilities/life_sim_page.dart';
import 'package:anime_waifu/screens/utilities/mal_sync_page.dart';
import 'package:anime_waifu/screens/utilities/movie_recommender_page.dart';
// ── Tools & Productivity ──
import 'package:anime_waifu/screens/utilities/notes_pad_page.dart';
import 'package:anime_waifu/screens/utilities/package_tracker_page.dart';
// ── Real-Life Tools ──
import 'package:anime_waifu/screens/utilities/parking_spot_saver_page.dart';
import 'package:anime_waifu/screens/utilities/password_generator_page.dart';
import 'package:anime_waifu/screens/utilities/personal_search_page.dart';
import 'package:anime_waifu/screens/utilities/pinned_messages_page.dart';
import 'package:anime_waifu/screens/utilities/plugin_system_page.dart';
import 'package:anime_waifu/screens/utilities/project_generator_page.dart';
import 'package:anime_waifu/screens/utilities/qr_scanner_page.dart';
import 'package:anime_waifu/screens/utilities/reward_system_page.dart';
import 'package:anime_waifu/screens/utilities/scheduled_messages_page.dart';
import 'package:anime_waifu/screens/utilities/second_brain_page.dart';
import 'package:anime_waifu/screens/utilities/secret_notes_page.dart';
import 'package:anime_waifu/screens/utilities/self_improvement_page.dart';
import 'package:anime_waifu/screens/utilities/shared_bucket_list_page.dart';
import 'package:anime_waifu/screens/utilities/smart_scanner_page.dart';
import 'package:anime_waifu/screens/utilities/star_map_page.dart';
import 'package:anime_waifu/screens/utilities/tarot_reading_page.dart';
import 'package:anime_waifu/screens/utilities/task_executor_page.dart';
import 'package:anime_waifu/screens/utilities/thought_capture_page.dart';
import 'package:anime_waifu/screens/utilities/time_machine_page.dart';
import 'package:anime_waifu/screens/utilities/voice_emotion_detector_page.dart';
import 'package:anime_waifu/screens/utilities/voice_notes_page.dart';
import 'package:anime_waifu/screens/utilities/waifu_dev_mode_page.dart';
// ── Settings ──
import 'package:anime_waifu/screens/utilities/waifu_voice_call_screen.dart';
// ── New Mega Features ──
import 'package:anime_waifu/screens/utilities/waifu_xp_level_page.dart';
import 'package:anime_waifu/screens/utilities/workflow_engine_page.dart';
import 'package:anime_waifu/screens/utilities/workout_planner_page.dart';
import 'package:anime_waifu/screens/utilities/year_in_review_page.dart';
import 'package:anime_waifu/screens/utilities/zero_two_calendar_page.dart';
import 'package:anime_waifu/screens/utilities/zero_two_facts_page.dart';
import 'package:anime_waifu/screens/wellness/../wellness/mood_tracking_page.dart';
import 'package:anime_waifu/screens/wellness/breathing_page.dart';
import 'package:anime_waifu/screens/wellness/focus_mode_page.dart';
import 'package:anime_waifu/screens/wellness/habit_tracker_page.dart';
import 'package:anime_waifu/screens/wellness/medication_reminder_page.dart';
import 'package:anime_waifu/screens/wellness/mood_tracker_page.dart';
import 'package:anime_waifu/screens/wellness/pomodoro_page.dart';
import 'package:anime_waifu/screens/wellness/sleep_mode_page.dart';
import 'package:anime_waifu/screens/wellness/study_timer_page.dart';
import 'package:anime_waifu/screens/wellness/wellness_reminders_page.dart';
// ── Media Gallery ──
import 'package:anime_waifu/screens/utilities/image_pack_page.dart';
import 'package:anime_waifu/screens/utilities/anime_sticker_sheet.dart';

// ── Social (Extended) ──
import 'package:anime_waifu/screens/social/gift_intelligence_page.dart';
import 'package:anime_waifu/screens/social/conflict_resolution_page.dart';
import 'package:anime_waifu/screens/social/long_distance_relationship_page.dart';
import 'package:anime_waifu/screens/social/social_event_planner_page.dart';

// ── Travel ──
import 'package:anime_waifu/screens/travel/travel_planner_page.dart';

// ── Productivity ──
import 'package:anime_waifu/screens/productivity/academic_research_page.dart';
import 'package:anime_waifu/screens/productivity/meeting_intelligence_page.dart';

// ── Financial ──
import 'package:anime_waifu/screens/financial/budget_coach_page.dart';
import 'package:anime_waifu/screens/financial/investment_companion_page.dart';

// ── Educational ──
import 'package:anime_waifu/screens/educational/language_learning_page.dart';
import 'package:anime_waifu/screens/educational/personalized_learning_page.dart';
import 'package:anime_waifu/screens/educational/skill_gap_analyzer_page.dart';
import 'package:anime_waifu/screens/educational/debate_critical_thinking_page.dart';

// ── Creative ──
import 'package:anime_waifu/screens/creative/art_direction_page.dart';
import 'package:anime_waifu/screens/creative/collaborative_storytelling_page.dart';
import 'package:anime_waifu/screens/creative/game_master_page.dart';
import 'package:anime_waifu/screens/creative/music_composition_page.dart';

// ── Wellness Advanced ──
import 'package:anime_waifu/screens/wellness_advanced/hydration_nutrition_page.dart';
import 'package:anime_waifu/screens/wellness_advanced/stress_detection_page.dart';
import 'package:anime_waifu/screens/wellness_advanced/meditation_guide_page.dart';
import 'package:anime_waifu/screens/wellness_advanced/sleep_tracking_page.dart';

// ── Memory & AI ──
import 'package:anime_waifu/screens/memory_ai/voice_clone_training_page.dart';
import 'package:anime_waifu/screens/memory_ai/enhanced_dream_journal_page.dart';
import 'package:anime_waifu/screens/memory_ai/relationship_heatmap_page.dart';
import 'package:anime_waifu/screens/memory_ai/smart_photo_memory_page.dart';
import 'package:anime_waifu/screens/memory_ai/conversation_bookmarks_page.dart';
import 'package:anime_waifu/screens/memory_ai/emotion_memory_timeline_page.dart';

// ── AI Advanced ──
import 'package:anime_waifu/screens/ai_advanced/personality_evolution_page.dart';
import 'package:anime_waifu/screens/ai_advanced/semantic_memory_page.dart';
import 'package:anime_waifu/screens/ai_advanced/conversation_mode_page.dart';
import 'package:anime_waifu/screens/ai_advanced/emotional_memory_page.dart';
import 'package:anime_waifu/screens/ai_advanced/smart_reply_page.dart';
import 'package:anime_waifu/screens/ai_advanced/enhanced_memory_page.dart';
import 'package:anime_waifu/screens/ai_advanced/ai_copilot_page.dart';
import 'package:anime_waifu/screens/ai_advanced/alter_ego_page.dart';
import 'package:anime_waifu/screens/ai_advanced/voice_emotion_page.dart';
import 'package:anime_waifu/screens/ai_advanced/ai_content_page.dart';
import 'package:anime_waifu/screens/ai_advanced/emotional_ai_page.dart';
import 'package:anime_waifu/screens/ai_advanced/emotional_recovery_page.dart';
import 'package:anime_waifu/screens/ai_advanced/self_reflection_page.dart';

// ── Social Advanced ──
import 'package:anime_waifu/screens/social_advanced/contacts_lookup_page.dart';
import 'package:anime_waifu/screens/social_advanced/social_features_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _hubQueryKey = 'features_hub_query_v2';

  late AnimationController _sakuraCtrl;
  int? _expandedIdx;
  late List<_Petal> _petals;
  late List<_HubCategory> _categories;
  String _query = '';
  late TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
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
    _restoreHubPrefs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
            _HubItem(
                label: 'Boss Battle',
                icon: Icons.security_rounded,
                builder: (_) => const BossBattlePage()),
            _HubItem(
                label: 'Anime Wordle',
                icon: Icons.grid_view_rounded,
                builder: (_) => const AnimeWordlePage()),
            _HubItem(
                label: 'Gacha Cards',
                icon: Icons.card_giftcard_rounded,
                builder: (_) => const GachaCollectorPage()),
            _HubItem(
                label: 'Mini Games',
                icon: Icons.sports_esports_rounded,
                builder: (_) => const GamesHubPage()),
            _HubItem(
                label: 'Tic-Tac-Toe',
                icon: Icons.grid_3x3_rounded,
                builder: (_) => const TicTacToePage()),
            _HubItem(
                label: 'Rock Paper',
                icon: Icons.back_hand_rounded,
                builder: (_) => const RockPaperScissorsPage()),
            _HubItem(
                label: 'Word Game',
                icon: Icons.text_fields_rounded,
                builder: (_) => const WordAssociationPage()),
            _HubItem(
                label: 'Spin Wheel',
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
            _HubItem(
                label: 'Truth or Dare',
                icon: Icons.local_fire_department_outlined,
                builder: (_) => const TruthOrDarePage()),
            _HubItem(
                label: 'Love Quiz',
                icon: Icons.quiz_outlined,
                builder: (_) => const LoveQuizPage()),
            _HubItem(
                label: 'Waifu Tier List',
                icon: Icons.format_list_numbered_rounded,
                builder: (_) => const WaifuTierListPage()),
            _HubItem(
                label: '20 Questions',
                icon: Icons.help_rounded,
                builder: (_) => const TwentyQuestionsPage()),
            _HubItem(
                label: 'Virtual Date',
                icon: Icons.favorite_outline_rounded,
                builder: (_) => const VirtualDatePage()),
            _HubItem(
                label: 'Story Mode',
                icon: Icons.book_rounded,
                builder: (_) => const StoryModePage()),
            _HubItem(
                label: 'Roleplay',
                icon: Icons.theater_comedy_outlined,
                builder: (_) => const RoleplayScenarioPage()),
            _HubItem(
                label: 'Word Puzzle',
                icon: Icons.extension_rounded,
                builder: (_) => const WordPuzzlePage()),
            _HubItem(
                label: 'Couple Challenge',
                icon: Icons.favorite_rounded,
                builder: (_) => const DailyCoupleChallengePage()),
          ],
        ),

        // ── 💕 DAILY RITUALS ────────────────────────────────────
        _HubCategory(
          title: 'Daily Rituals',
          emoji: '💕',
          description: 'Daily actions, letters, and check-ins',
          color: const Color(0xFFFF4FA8),
          items: [
            _HubItem(
                label: 'ZT Diary',
                icon: Icons.book_outlined,
                builder: (_) => const ZeroTwoDiaryPage()),
            _HubItem(
                label: 'Love Letter',
                icon: Icons.mail_outline_rounded,
                builder: (_) => const DailyLoveLetterPage()),
            _HubItem(
                label: 'Affirmations',
                icon: Icons.self_improvement_outlined,
                builder: (_) => const DailyAffirmationsPage()),
            _HubItem(
                label: 'Quote of Day',
                icon: Icons.format_quote_outlined,
                builder: (_) => const QuoteOfDayPage()),
            _HubItem(
                label: 'Fortune Cookie',
                icon: Icons.cookie_outlined,
                builder: (_) => const FortuneCookiePage()),
            _HubItem(
                label: 'Check-in Streak',
                icon: Icons.local_fire_department_outlined,
                builder: (_) => const CheckinStreakPage()),
            _HubItem(
                label: 'Daily Challenge',
                icon: Icons.flag_rounded,
                builder: (_) => const DailyChallengePage()),
            _HubItem(
                label: 'Daily Horoscope',
                icon: Icons.auto_awesome_rounded,
                builder: (_) => const DailyHoroscopePage()),
            _HubItem(
                label: 'Daily Trivia',
                icon: Icons.lightbulb_outline,
                builder: (_) => const DailyTriviaPage()),
            _HubItem(
                label: 'Late Night Mode',
                icon: Icons.nights_stay_rounded,
                builder: (_) => const LateNightModePage()),
          ],
        ),

        // ── 🧠 AI TOOLS ────────────────────────────────────────
        _HubCategory(
          title: 'AI Tools',
          emoji: '🧠',
          description: 'AI-powered assistants and generators',
          color: Colors.cyanAccent,
          items: [
            _HubItem(
                label: 'AI Art Generator',
                icon: Icons.brush_rounded,
                builder: (_) => const AiArtGeneratorPage()),
            _HubItem(
                label: 'Manga Translator',
                icon: Icons.translate_rounded,
                builder: (_) => const MangaTranslatorPage()),
            _HubItem(
                label: 'Dream Interpreter',
                icon: Icons.bedtime_rounded,
                builder: (_) => const DreamInterpreterPage()),
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
            _HubItem(
                label: 'Relationship Coach',
                icon: Icons.psychology_rounded,
                builder: (_) => const RelationshipCoachPage()),
            _HubItem(
                label: 'Poem Generator',
                icon: Icons.edit_rounded,
                builder: (_) => const PoemGeneratorPage()),
            _HubItem(
                label: 'Translator',
                icon: Icons.translate_rounded,
                builder: (_) => const LanguageTranslatorPage()),
            _HubItem(
                label: 'Recipe Picks',
                icon: Icons.restaurant_rounded,
                builder: (_) => const RecipeRecommenderPage()),
          ],
        ),

        // ── 📚 RECOMMENDATIONS ──────────────────────────────────
        _HubCategory(
          title: 'Recommendations',
          emoji: '📚',
          description: 'Discover anime, books, and movies',
          color: Colors.deepPurpleAccent,
          items: [
            _HubItem(
                label: 'Anime Picks',
                icon: Icons.live_tv_outlined,
                builder: (_) => const AnimeRecommenderPage()),
            _HubItem(
                label: 'Book Picks',
                icon: Icons.menu_book_outlined,
                builder: (_) => const BookRecommenderPage()),
            _HubItem(
                label: 'Movie Picks',
                icon: Icons.movie_outlined,
                builder: (_) => const MovieRecommenderPage()),
          ],
        ),

        // ── 🛠️ PRODUCTIVITY ─────────────────────────────────────
        _HubCategory(
          title: 'Productivity',
          emoji: '🛠️',
          description: 'Journals, trackers, and planning tools',
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
            _HubItem(
                label: 'Voice Notes',
                icon: Icons.mic_rounded,
                builder: (_) => const VoiceNotesPage()),
            _HubItem(
                label: 'Goal Tracker',
                icon: Icons.track_changes_outlined,
                builder: (_) => const GoalTrackerPage()),
            _HubItem(
                label: 'Habit Tracker',
                icon: Icons.check_circle_outline,
                builder: (_) => const HabitTrackerPage()),
            _HubItem(
                label: 'Budget Tracker',
                icon: Icons.account_balance_wallet_outlined,
                builder: (_) => const BudgetTrackerPage()),
            _HubItem(
                label: 'Pomodoro',
                icon: Icons.timer_outlined,
                builder: (_) => const PomodoroPage()),
            _HubItem(
                label: 'Study Timer',
                icon: Icons.school_rounded,
                builder: (_) => const StudyTimerPage()),
            _HubItem(
                label: 'Bucket List',
                icon: Icons.checklist_outlined,
                builder: (_) => const SharedBucketListPage()),
            _HubItem(
                label: 'Countdown Timer',
                icon: Icons.timer_rounded,
                builder: (_) => const CountdownTimerPage()),
          ],
        ),

        // ── 🧘 WELLNESS ─────────────────────────────────────────
        _HubCategory(
          title: 'Wellness',
          emoji: '🧘',
          description: 'Breathing, gratitude, and fitness',
          color: Colors.greenAccent,
          items: [
            _HubItem(
                label: 'Breathing',
                icon: Icons.air_outlined,
                builder: (_) => const BreathingExercisePage()),
            _HubItem(
                label: 'Gratitude Journal',
                icon: Icons.auto_awesome_outlined,
                builder: (_) => const GratitudeJournalPage()),
            _HubItem(
                label: 'Workout Planner',
                icon: Icons.fitness_center_outlined,
                builder: (_) => const WorkoutPlannerPage()),
            _HubItem(
                label: 'Mood Tracker',
                icon: Icons.mood_rounded,
                builder: (_) => const MoodTrackerPage()),
            _HubItem(
                label: 'Mood Tracking',
                icon: Icons.insights_rounded,
                builder: (_) => const MoodTrackingPage()),
            _HubItem(
                label: 'Sleep Mode',
                icon: Icons.bedtime_rounded,
                builder: (_) => const SleepModePage()),
            _HubItem(
                label: 'Wellness Reminders',
                icon: Icons.spa_rounded,
                builder: (_) => const WellnessRemindersPage()),
          ],
        ),

        // ── 📺 ANIME & MEDIA ────────────────────────────────────
        _HubCategory(
          title: 'Anime & Media',
          emoji: '📺',
          description: 'Browse, stream, and track anime',
          color: const Color(0xFFBB52FF),
          items: [
            _HubItem(
                label: 'Cloud Videos',
                icon: Icons.cloud_queue_rounded,
                onTap: widget.onOpenCloudinary),
            _HubItem(
                label: 'Manga Reader',
                icon: Icons.menu_book_rounded,
                builder: (_) => const MangaSectionPage()),
            _HubItem(
                label: 'Web Streamers',
                icon: Icons.travel_explore_rounded,
                builder: (_) => const WebStreamersHubPage()),
            _HubItem(
                label: 'Anime Quiz',
                icon: Icons.quiz_rounded,
                builder: (_) => const AnimeQuizGamePage()),
            _HubItem(
                label: 'Anime OST',
                icon: Icons.music_note_rounded,
                builder: (_) => const AnimeOstPage()),
            _HubItem(
                label: 'Music Player',
                icon: Icons.play_circle_rounded,
                builder: (_) => const MusicPlayerPage()),
            _HubItem(
                label: 'Anime Calendar',
                icon: Icons.calendar_month_rounded,
                builder: (_) => const AnimeCalendarPage()),
            _HubItem(
                label: 'Watch Party',
                icon: Icons.live_tv_rounded,
                builder: (_) => const AnimeWatchPartyPage()),
            _HubItem(
                label: 'Matchmaker',
                icon: Icons.favorite_rounded,
                builder: (_) => const AnimeMatchmakerPage()),
            _HubItem(
                label: 'HiAnime Portal',
                icon: Icons.movie_filter_rounded,
                builder: (_) =>
                    const HiAnimeWebviewPage(source: AnimeWebSource.hianime)),
            _HubItem(
                label: 'Watchlist',
                icon: Icons.bookmark_outlined,
                builder: (_) => const WatchlistPage()),
            _HubItem(
                label: 'Watch History',
                icon: Icons.history_rounded,
                builder: (_) => const WatchHistoryPage()),
            _HubItem(
                label: 'Downloads',
                icon: Icons.download_rounded,
                builder: (_) => const DownloadsPage()),
            _HubItem(
                label: 'MAL Sync',
                icon: Icons.sync_rounded,
                builder: (_) => const MalSyncPage()),
            _HubItem(
                label: 'Episode Alerts',
                icon: Icons.notifications_active_rounded,
                builder: (_) => const EpisodeAlertsPage()),
          ],
        ),

        // ── 🌐 SOCIAL & CLOUD ───────────────────────────────────
        _HubCategory(
          title: 'Social & Cloud',
          emoji: '🌐',
          description: 'Community, sync, and multiplayer',
          color: Colors.orangeAccent,
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
                label: 'Chat Summary',
                icon: Icons.summarize_rounded,
                builder: (_) => const ConversationSummaryPage()),
          ],
        ),

        // ── 📊 STATS & INSIGHTS ─────────────────────────────────
        _HubCategory(
          title: 'Stats & Insights',
          emoji: '📊',
          description: 'Track your relationship journey',
          color: Colors.tealAccent,
          items: [
            _HubItem(
                label: 'Chat Analytics',
                icon: Icons.bar_chart_outlined,
                builder: (_) => const ChatAnalyticsPage()),
            _HubItem(
                label: 'Chat Statistics',
                icon: Icons.query_stats_rounded,
                builder: (context) => ChatStatisticsPage(
                    messages: context.read<ChatProvider>().messages)),
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
            _HubItem(
                label: 'Evolution',
                icon: Icons.trending_up_rounded,
                builder: (_) => const RelationshipEvolutionPage()),
            _HubItem(
                label: 'Voice Call',
                icon: Icons.phone_rounded,
                builder: (_) => const WaifuVoiceCallScreen()),
            _HubItem(
                label: 'Memory Timeline',
                icon: Icons.timeline_rounded,
                builder: (_) => const MemoryTimelinePage()),
            _HubItem(
                label: 'Memory Wall',
                icon: Icons.photo_library_rounded,
                builder: (_) => const MemoryWallPage()),
            _HubItem(
                label: 'Memory Book',
                icon: Icons.auto_stories_rounded,
                builder: (_) => const MemoryBookPage()),
          ],
        ),

        // ── 🌸 EXTRAS ────────────────────────────────────────────
        _HubCategory(
          title: 'Extras',
          emoji: '🌸',
          description: 'Fun extras, Zero Two lore, and more',
          color: const Color(0xFFFF6B9D),
          items: [
            _HubItem(
                label: 'ZT Facts',
                icon: Icons.auto_awesome_rounded,
                builder: (_) => const ZeroTwoFactsPage()),
            _HubItem(
                label: 'ZT Calendar',
                icon: Icons.calendar_today_rounded,
                builder: (_) => const ZeroTwoCalendarPage()),
            _HubItem(
                label: 'Tarot Reading',
                icon: Icons.style_rounded,
                builder: (_) => const TarotReadingPage()),
            _HubItem(
                label: 'Kaomoji',
                icon: Icons.emoji_emotions_rounded,
                builder: (_) => const KaomojiPickerPage()),
          ],
        ),

        // ── 💻 DEV & CODE ─────────────────────────────────────────
        _HubCategory(
          title: 'Dev & Code',
          emoji: '💻',
          description: 'Code editor, debugging, and dev tools',
          color: Colors.cyanAccent,
          items: [
            _HubItem(
                label: 'Dev Mode',
                icon: Icons.code_rounded,
                builder: (_) => const WaifuDevModePage()),
            // 🔐 Firebase Cleanup Panel hidden - accessible only via About page easter egg (6-7 clicks)
            _HubItem(
                label: 'Error Memory',
                icon: Icons.bug_report_rounded,
                builder: (_) => const ErrorMemoryPage()),
            _HubItem(
                label: 'AI Debug Panel',
                icon: Icons.developer_mode_rounded,
                builder: (_) => const AiDebugPanelPage()),
            _HubItem(
                label: 'Plugin System',
                icon: Icons.extension_rounded,
                builder: (_) => const PluginSystemPage()),
          ],
        ),

        // ── ⚡ POWER TOOLS ─────────────────────────────────────────
        _HubCategory(
          title: 'Power Tools',
          emoji: '⚡',
          description: 'Productivity, focus, and life management',
          color: Colors.amberAccent,
          items: [
            _HubItem(
                label: 'Second Brain',
                icon: Icons.psychology_alt_rounded,
                builder: (_) => const SecondBrainPage()),
            _HubItem(
                label: 'Focus Mode',
                icon: Icons.center_focus_strong_rounded,
                builder: (_) => const FocusModePage()),
            _HubItem(
                label: 'Thought Capture',
                icon: Icons.lightbulb_rounded,
                builder: (_) => const ThoughtCapturePage()),
            _HubItem(
                label: 'Day Recap',
                icon: Icons.summarize_rounded,
                builder: (_) => const DayRecapPage()),
            _HubItem(
                label: 'Share & Export',
                icon: Icons.share_rounded,
                builder: (_) => const ChatShareExportPage()),
          ],
        ),

        // ── 🧠 BRAIN & GROWTH ─────────────────────────────────────
        _HubCategory(
          title: 'Brain & Growth',
          emoji: '🧠',
          description: 'XP, goals, rewards, and self-improvement',
          color: Colors.deepPurpleAccent,
          items: [
            _HubItem(
                label: 'XP & Level',
                icon: Icons.stars_rounded,
                builder: (_) => const WaifuXpLevelPage()),
            _HubItem(
                label: 'Rewards',
                icon: Icons.card_giftcard_rounded,
                builder: (_) => const RewardSystemPage()),
            _HubItem(
                label: 'Goal Tracker',
                icon: Icons.flag_rounded,
                builder: (_) => const GoalTrackerPage()),
            _HubItem(
                label: 'Self Growth',
                icon: Icons.trending_up_rounded,
                builder: (_) => const SelfImprovementPage()),
            _HubItem(
                label: 'AI Story Game',
                icon: Icons.auto_stories_rounded,
                builder: (_) => const AiStoryGamePage()),
            _HubItem(
                label: 'Dream Mode',
                icon: Icons.nights_stay_rounded,
                builder: (_) => const DreamModePage()),
            _HubItem(
                label: 'Life Sim',
                icon: Icons.favorite_rounded,
                builder: (_) => const LifeSimPage()),
            _HubItem(
                label: 'Analytics',
                icon: Icons.insights_rounded,
                builder: (_) => const UserAnalyticsDashboardPage()),
          ],
        ),

        // ── 🧬 AI EVOLUTION ──────────────────────────────────────────
        _HubCategory(
          title: 'AI Evolution',
          emoji: '🧬',
          description: 'Digital clone, auto-learning & future prediction',
          color: Colors.tealAccent,
          items: [
            _HubItem(
                label: 'Digital Clone',
                icon: Icons.person_pin_rounded,
                builder: (_) => const DigitalClonePage()),
            _HubItem(
                label: 'Future You',
                icon: Icons.rocket_launch_rounded,
                builder: (_) => const FutureSimPage()),
            _HubItem(
                label: 'Auto Learning',
                icon: Icons.auto_fix_high_rounded,
                builder: (_) => const AutoLearningPage()),
            _HubItem(
                label: 'Life Log',
                icon: Icons.timeline_rounded,
                builder: (_) => const AutoLifeLogPage()),
          ],
        ),

        // ── ⚡ SYSTEM & AUTOMATION ─────────────────────────────────────
        _HubCategory(
          title: 'System & Automation',
          emoji: '⚡',
          description: 'Task execution, workflows & project scaffolding',
          color: Colors.greenAccent,
          items: [
            _HubItem(
                label: 'Task Executor',
                icon: Icons.terminal_rounded,
                builder: (_) => const TaskExecutorPage()),
            _HubItem(
                label: 'Workflows',
                icon: Icons.account_tree_rounded,
                builder: (_) => const WorkflowEnginePage()),
            _HubItem(
                label: 'Project Gen',
                icon: Icons.create_new_folder_rounded,
                builder: (_) => const ProjectGeneratorPage()),
            _HubItem(
                label: 'File Intel',
                icon: Icons.folder_special_rounded,
                builder: (_) => const FileIntelligencePage()),
          ],
        ),

        // ── 🔍 INTELLIGENCE & SEARCH ──────────────────────────────────
        _HubCategory(
          title: 'Intelligence & Search',
          emoji: '🔍',
          description: 'Search everything, review code & AI insights',
          color: Colors.orangeAccent,
          items: [
            _HubItem(
                label: 'Personal Search',
                icon: Icons.search_rounded,
                builder: (_) => const PersonalSearchPage()),
            _HubItem(
                label: 'Code Reviewer',
                icon: Icons.rate_review_rounded,
                builder: (_) => const CodeReviewerPage()),
            _HubItem(
                label: 'AI Insights',
                icon: Icons.auto_awesome_rounded,
                builder: (_) => const BackgroundInsightsPage()),
            _HubItem(
                label: 'AI Modes',
                icon: Icons.psychology_rounded,
                builder: (_) => const AiPersonalityModesPage()),
            _HubItem(
                label: 'Emotion Detect',
                icon: Icons.mic_external_on_rounded,
                builder: (_) => const VoiceEmotionDetectorPage()),
          ],
        ),

        // ── 🧠 BRAIN ARCHITECTURE ─────────────────────────────────────
        _HubCategory(
          title: 'Brain Architecture',
          emoji: '🧠',
          description: 'Memory layers, knowledge graph & time travel',
          color: Colors.deepPurpleAccent,
          items: [
            _HubItem(
                label: 'Memory Stack',
                icon: Icons.layers_rounded,
                builder: (_) => const MemoryStackPage()),
            _HubItem(
                label: 'Knowledge Graph',
                icon: Icons.hub_rounded,
                builder: (_) => const KnowledgeGraphPage()),
            _HubItem(
                label: 'Time Machine',
                icon: Icons.history_rounded,
                builder: (_) => const TimeMachinePage()),
            _HubItem(
                label: 'Memory Vault',
                icon: Icons.lock_clock_rounded,
                builder: (_) => const MemoryVaultPage()),
            _HubItem(
                label: 'Secret Notes',
                icon: Icons.enhanced_encryption_rounded,
                builder: (_) => const SecretNotesPage()),
          ],
        ),

        // ── 🧰 REAL-LIFE TOOLS ──────────────────────────────────────
        _HubCategory(
          title: 'Real-Life Tools',
          emoji: '🧰',
          description: 'Practical everyday utilities',
          color: Colors.lightBlueAccent,
          items: [
            _HubItem(
                label: 'Parking Saver',
                icon: Icons.local_parking_rounded,
                builder: (_) => const ParkingSpotSaverPage()),
            _HubItem(
                label: 'Smart Scanner',
                icon: Icons.document_scanner_rounded,
                builder: (_) => const SmartScannerPage()),
            _HubItem(
                label: 'Health Reminders',
                icon: Icons.medication_rounded,
                builder: (_) => const MedicationReminderPage()),
            _HubItem(
                label: 'Package Tracker',
                icon: Icons.local_shipping_rounded,
                builder: (_) => const PackageTrackerPage()),
            _HubItem(
                label: 'Emergency SOS',
                icon: Icons.sos_rounded,
                builder: (_) => const EmergencySosPage()),
            _HubItem(
                label: 'Clipboard',
                icon: Icons.content_paste_rounded,
                builder: (_) => const ClipboardManagerPage()),
            _HubItem(
                label: 'Bill Splitter',
                icon: Icons.receipt_long_rounded,
                builder: (_) => const BillSplitterPage()),
            _HubItem(
                label: 'Ruler & Convert',
                icon: Icons.straighten_rounded,
                builder: (_) => const ArRulerPage()),
            _HubItem(
                label: 'Password Gen',
                icon: Icons.password_rounded,
                builder: (_) => const PasswordGeneratorPage()),
            _HubItem(
                label: 'QR Tools',
                icon: Icons.qr_code_scanner_rounded,
                builder: (_) => const QrScannerPage()),
            _HubItem(
                label: 'Geofence Zones',
                icon: Icons.my_location_rounded,
                builder: (_) => const GeofencingSettingsPage()),
          ],
        ),

        // ── 🖼️ MEDIA GALLERY ─────────────────────────────────────────────
        _HubCategory(
          title: 'Media Gallery',
          emoji: '🖼️',
          description: 'GIFs, images, wallpapers, and sticker collections',
          color: Colors.deepPurpleAccent,
          items: [
            _HubItem(
                label: 'Sticker Pack',
                icon: Icons.auto_awesome_rounded,
                builder: (_) => const AnimeStickerSheet()),
            _HubItem(
                label: 'Image Packs',
                icon: Icons.photo_library_rounded,
                builder: (_) => const ImagePackPage()),
            _HubItem(
                label: 'Wallpapers',
                icon: Icons.wallpaper_rounded,
                builder: (_) => const ImagePackPage()),
            _HubItem(
                label: 'Sticker Gallery',
                icon: Icons.emoji_emotions_rounded,
                builder: (_) => const AnimeStickerSheet()),
          ],
        ),

        // ── 🌍 SOCIAL & TRAVEL ──────────────────────────────────────────
        _HubCategory(
          title: 'Social & Travel',
          emoji: '🌍',
          description:
              'Relationship tools, event planning, and travel companions',
          color: Colors.orangeAccent,
          items: [
            _HubItem(
                label: 'Gift Intelligence',
                icon: Icons.card_giftcard_rounded,
                builder: (_) => const GiftIntelligencePage()),
            _HubItem(
                label: 'Conflict Resolution',
                icon: Icons.handshake_rounded,
                builder: (_) => const ConflictResolutionPage()),
            _HubItem(
                label: 'Long Distance Love',
                icon: Icons.favorite_rounded,
                builder: (_) => const LongDistanceRelationshipPage()),
            _HubItem(
                label: 'Event Planner',
                icon: Icons.event_rounded,
                builder: (_) => const SocialEventPlannerPage()),
            _HubItem(
                label: 'Travel Planner',
                icon: Icons.flight_rounded,
                builder: (_) => const TravelPlannerPage()),
          ],
        ),

        // ── 💼 PRODUCTIVITY ──────────────────────────────────────────────
        _HubCategory(
          title: 'Productivity',
          emoji: '💼',
          description:
              'Academic research, meeting intelligence, and smart tracking',
          color: Colors.cyan.shade700,
          items: [
            _HubItem(
                label: 'Academic Research',
                icon: Icons.school_rounded,
                builder: (_) => const AcademicResearchPage()),
            _HubItem(
                label: 'Meeting Intelligence',
                icon: Icons.groups_rounded,
                builder: (_) => const MeetingIntelligencePage()),
            _HubItem(
                label: 'Smart Habit Tracker',
                icon: Icons.track_changes_rounded,
                builder: (_) => const HabitTrackerPage()),
            _HubItem(
                label: 'Goal Tracker',
                icon: Icons.flag_rounded,
                builder: (_) => const GoalTrackerPage()),
          ],
        ),

        // ── 💰 FINANCIAL ─────────────────────────────────────────────────
        _HubCategory(
          title: 'Financial',
          emoji: '💰',
          description: 'Budget coaching and investment guidance',
          color: Colors.green.shade700,
          items: [
            _HubItem(
                label: 'Budget Coach',
                icon: Icons.account_balance_wallet_rounded,
                builder: (_) => const BudgetCoachPage()),
            _HubItem(
                label: 'Investment Companion',
                icon: Icons.trending_up_rounded,
                builder: (_) => const InvestmentCompanionPage()),
          ],
        ),

        // ── 🎓 EDUCATIONAL ───────────────────────────────────────────────
        _HubCategory(
          title: 'Educational',
          emoji: '🎓',
          description:
              'Language learning, personalized education, and skill development',
          color: Colors.indigo.shade700,
          items: [
            _HubItem(
                label: 'Language Learning',
                icon: Icons.language_rounded,
                builder: (_) => const LanguageLearningPage()),
            _HubItem(
                label: 'Personalized Learning',
                icon: Icons.psychology_rounded,
                builder: (_) => const PersonalizedLearningPage()),
            _HubItem(
                label: 'Skill Gap Analyzer',
                icon: Icons.analytics_rounded,
                builder: (_) => const SkillGapAnalyzerPage()),
            _HubItem(
                label: 'Debate & Critical Thinking',
                icon: Icons.forum_rounded,
                builder: (_) => const DebateCriticalThinkingPage()),
          ],
        ),

        // ── 🎨 CREATIVE ──────────────────────────────────────────────────
        _HubCategory(
          title: 'Creative',
          emoji: '🎨',
          description:
              'Art direction, storytelling, game mastering, and music composition',
          color: Colors.pink.shade700,
          items: [
            _HubItem(
                label: 'Art Direction',
                icon: Icons.brush_rounded,
                builder: (_) => const ArtDirectionPage()),
            _HubItem(
                label: 'Collaborative Storytelling',
                icon: Icons.auto_stories_rounded,
                builder: (_) => const CollaborativeStorytellingPage()),
            _HubItem(
                label: 'Game Master',
                icon: Icons.casino_rounded,
                builder: (_) => const GameMasterPage()),
            _HubItem(
                label: 'Music Composition',
                icon: Icons.music_note_rounded,
                builder: (_) => const MusicCompositionPage()),
          ],
        ),

        // ── 💪 WELLNESS+ ─────────────────────────────────────────────────
        _HubCategory(
          title: 'Wellness+',
          emoji: '💪',
          description: 'Advanced wellness tools beyond basic meditation',
          color: Colors.lightBlue.shade700,
          items: [
            _HubItem(
                label: 'Hydration & Nutrition',
                icon: Icons.local_drink_rounded,
                builder: (_) => const HydrationNutritionPage()),
            _HubItem(
                label: 'Stress Detection',
                icon: Icons.warning_rounded,
                builder: (_) => const StressDetectionPage()),
            _HubItem(
                label: 'Guided Meditation',
                icon: Icons.self_improvement_rounded,
                builder: (_) => const MeditationGuidePage()),
            _HubItem(
                label: 'Sleep Tracking',
                icon: Icons.bedtime_rounded,
                builder: (_) => const SleepTrackingPage()),
          ],
        ),

        // ── 🧠 MEMORY & AI ───────────────────────────────────────────────
        _HubCategory(
          title: 'Memory & AI',
          emoji: '🧠',
          description: 'Enhanced memory features and AI-powered intelligence',
          color: Colors.deepPurple.shade700,
          items: [
            _HubItem(
                label: 'Voice Clone Training',
                icon: Icons.record_voice_over_rounded,
                builder: (_) => const VoiceCloneTrainingPage()),
            _HubItem(
                label: 'Dream Journal',
                icon: Icons.nightlight_round,
                builder: (_) => const EnhancedDreamJournalPage()),
            _HubItem(
                label: 'Relationship Heatmap',
                icon: Icons.thermostat_rounded,
                builder: (_) => const RelationshipHeatmapPage()),
            _HubItem(
                label: 'Smart Photo Memory',
                icon: Icons.photo_camera_rounded,
                builder: (_) => const SmartPhotoMemoryPage()),
            _HubItem(
                label: 'Conversation Bookmarks',
                icon: Icons.bookmark_rounded,
                builder: (_) => const ConversationBookmarksPage()),
            _HubItem(
                label: 'Emotion Timeline',
                icon: Icons.timeline_rounded,
                builder: (_) => const EmotionMemoryTimelinePage()),
          ],
        ),

        // ── 🤖 AI ADVANCED ───────────────────────────────────────────────
        _HubCategory(
          title: 'AI Advanced',
          emoji: '🤖',
          description:
              'Cutting-edge AI features for personality, memory, and intelligence',
          color: Colors.purple.shade700,
          items: [
            _HubItem(
                label: 'Personality Evolution',
                icon: Icons.trending_up_rounded,
                builder: (_) => const PersonalityEvolutionPage()),
            _HubItem(
                label: 'Semantic Memory',
                icon: Icons.memory_rounded,
                builder: (_) => const SemanticMemoryPage()),
            _HubItem(
                label: 'Conversation Modes',
                icon: Icons.chat_rounded,
                builder: (_) => const ConversationModePage()),
            _HubItem(
                label: 'Emotional Memory',
                icon: Icons.favorite_rounded,
                builder: (_) => const EmotionalMemoryPage()),
            _HubItem(
                label: 'Smart Reply',
                icon: Icons.smart_button_rounded,
                builder: (_) => const SmartReplyPage()),
            _HubItem(
                label: 'Enhanced Memory',
                icon: Icons.enhance_photo_translate_rounded,
                builder: (_) => const EnhancedMemoryPage()),
            _HubItem(
                label: 'AI Copilot',
                icon: Icons.assistant_rounded,
                builder: (_) => const AiCopilotPage()),
            _HubItem(
                label: 'Alter Ego Personas',
                icon: Icons.person_rounded,
                builder: (_) => const AlterEgoPage()),
            _HubItem(
                label: 'Voice Emotion',
                icon: Icons.mic_rounded,
                builder: (_) => const VoiceEmotionPage()),
            _HubItem(
                label: 'AI Content Generator',
                icon: Icons.create_rounded,
                builder: (_) => const AiContentPage()),
            _HubItem(
                label: 'Emotional AI',
                icon: Icons.psychology_rounded,
                builder: (_) => const EmotionalAiPage()),
            _HubItem(
                label: 'Emotional Recovery',
                icon: Icons.healing_rounded,
                builder: (_) => const EmotionalRecoveryPage()),
            _HubItem(
                label: 'Self Reflection',
                icon: Icons.self_improvement_rounded,
                builder: (_) => const SelfReflectionPage()),
          ],
        ),

        // ── 👥 SOCIAL ADVANCED ───────────────────────────────────────────
        _HubCategory(
          title: 'Social Advanced',
          emoji: '👥',
          description: 'Advanced social features and community tools',
          color: Colors.green.shade700,
          items: [
            _HubItem(
                label: 'Contacts Lookup',
                icon: Icons.contacts_rounded,
                builder: (_) => const ContactsLookupPage()),
            _HubItem(
                label: 'Social Features',
                icon: Icons.groups_rounded,
                builder: (_) => const SocialFeaturesPage()),
          ],
        ),

        // ── ⚙️ ADMIN HUB (YOUR CONTROL CENTER) ────────────────────────────────
        _HubCategory(
          title: 'Admin Control',
          emoji: '⚙️',
          description: 'Your exclusive admin dashboard & control center',
          color: Colors.deepOrangeAccent,
          items: [
            _HubItem(
                label: 'Admin Hub (All Tools)',
                icon: Icons.admin_panel_settings_rounded,
                builder: (_) => const AdminHubPage()),
          ],
        ),

        // ── 🚀 ENTERPRISE SERVICES ────────────────────────────────────
        _HubCategory(
          title: 'Enterprise Services',
          emoji: '🚀',
          description: 'Admin tools, webhooks, and advanced features',
          color: Colors.purpleAccent,
          items: [
            _HubItem(
                label: 'Admin Dashboard',
                icon: Icons.admin_panel_settings_rounded,
                builder: (_) => const AdminPanelPage()),
            _HubItem(
                label: 'Discord Webhooks',
                icon: Icons.webhook_rounded,
                builder: (_) => const DiscordIntegrationPanelPage()),
            _HubItem(
                label: 'Achievement System',
                icon: Icons.emoji_events_rounded,
                builder: (_) => const AchievementsGalleryPage()),
          ],
        ),
      ];

  void _toggle(int idx) =>
      setState(() => _expandedIdx = _expandedIdx == idx ? null : idx);

  Future<void> _restoreHubPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _query = prefs.getString(_hubQueryKey) ?? '');
  }

  Future<void> _saveHubPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hubQueryKey, _query);
  }

  List<_HubCategory> get _visibleCategories {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _categories;
    }

    return _categories
        .map((category) {
          final filteredItems = category.items.where((item) {
            return item.label.toLowerCase().contains(query) ||
                category.title.toLowerCase().contains(query) ||
                category.description.toLowerCase().contains(query);
          }).toList();
          if (filteredItems.isEmpty &&
              !category.title.toLowerCase().contains(query) &&
              !category.description.toLowerCase().contains(query)) {
            return null;
          }
          return _HubCategory(
            title: category.title,
            emoji: category.emoji,
            description: category.description,
            color: category.color,
            items: filteredItems.isEmpty ? category.items : filteredItems,
          );
        })
        .whereType<_HubCategory>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _visibleCategories;
    final totalItems = _categories.fold<int>(
        0, (sum, category) => sum + category.items.length);
    final visibleItems = visibleCategories.fold<int>(
      0,
      (sum, category) => sum + category.items.length,
    );
    final commentaryMood = visibleItems >= 40
        ? 'achievement'
        : visibleItems >= 12
            ? 'motivated'
            : 'neutral';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.3),
                    Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0)
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(children: [
              // Premium Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            size: 20),
                        onPressed: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FEATURES HUB',
                                  style: GoogleFonts.outfit(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      letterSpacing: 1.5)),
                              const SizedBox(height: 4),
                              Text('Explore all Zero Two features',
                                  style: GoogleFonts.outfit(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.8),
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.diamond_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('$visibleItems',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // ═══ IMPROVED SEARCH BAR ═══
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.06),
                          ],
                        ),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.search_rounded,
                              color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                        Expanded(
                          child: TextField(
                            textDirection: TextDirection.ltr,
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16, fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search features...',
                              hintStyle: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            onChanged: (value) {
                              _query = value;
                              _saveHubPrefs();
                              setState(() {});
                            },
                            controller: _searchCtrl,
                          ),
                        ),
                        if (_query.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              _query = '';
                              _saveHubPrefs();
                              setState(() {});
                            },
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.tune_rounded,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25), size: 20),
                          ),
                      ]),
                    ),
                  ],
                ),
              ),

              // Scrollable overview + category list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  addRepaintBoundaries: true,
                  cacheExtent: 800,
                  itemCount: 2 + (visibleCategories.isEmpty ? 1 : visibleCategories.length),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildHubOverview(
                        commentaryMood: commentaryMood,
                        totalItems: totalItems,
                        visibleItems: visibleItems,
                      );
                    }
                    if (index == 1) return const SizedBox(height: 12);
                    if (visibleCategories.isEmpty) {
                      return const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching features',
                        subtitle:
                            'Try a broader search and the matching feature groups will appear here.',
                      );
                    }
                    return _buildCategoryCard(visibleCategories[index - 2], index - 2);
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHubOverview({
    required String commentaryMood,
    required int totalItems,
    required int visibleItems,
  }) {
    return Column(
      children: [
        WaifuCommentary(mood: commentaryMood),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Categories',
                  value: '${_categories.length}',
                  icon: Icons.dashboard_customize_rounded,
                  color: V2Theme.primaryColor,
                ),
              ),
              Expanded(
                child: StatCard(
                  title: 'Features',
                  value: '$totalItems',
                  icon: Icons.grid_view_rounded,
                  color: V2Theme.secondaryColor,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Visible',
                  value: '$visibleItems',
                  icon: Icons.visibility_rounded,
                  color: Colors.orangeAccent,
                ),
              ),
              Expanded(
                child: StatCard(
                  title: 'Open Section',
                  value: _expandedIdx == null ? 'None' : '${_expandedIdx! + 1}',
                  icon: Icons.unfold_more_rounded,
                  color: Colors.lightGreenAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(_HubCategory cat, int idx) {
    final isOpen = _expandedIdx == idx;
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isOpen
              ? [
                  cat.color.withValues(alpha: 0.12),
                  cat.color.withValues(alpha: 0.06),
                ]
              : [
                  tokens.panel.withValues(alpha: 0.8),
                  tokens.panel.withValues(alpha: 0.6),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isOpen ? cat.color.withValues(alpha: 0.4) : tokens.outline,
          width: isOpen ? 2 : 1,
        ),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: cat.color.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: cat.color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: -1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium Header
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.lightImpact();
                _toggle(idx);
              },
              splashColor: cat.color.withValues(alpha: 0.1),
              highlightColor: cat.color.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  // Premium emoji container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          cat.color.withValues(alpha: isOpen ? 0.25 : 0.15),
                          cat.color.withValues(alpha: isOpen ? 0.15 : 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: cat.color.withValues(alpha: isOpen ? 0.5 : 0.3),
                        width: 2,
                      ),
                      boxShadow: isOpen
                          ? [
                              BoxShadow(
                                color: cat.color.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child:
                          Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Content section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.title,
                            style: GoogleFonts.outfit(
                                color: isOpen
                                    ? cat.color
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(cat.description,
                            style: GoogleFonts.outfit(
                                color: tokens.textSoft,
                                fontSize: 13,
                                height: 1.3)),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Count badge with premium design
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          cat.color.withValues(alpha: 0.2),
                          cat.color.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                        color: cat.color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text('${cat.items.length}',
                        style: GoogleFonts.outfit(
                            color: cat.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),

                  const SizedBox(width: 12),

                  // Animated chevron
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isOpen ? cat.color : tokens.textMuted,
                      size: 24,
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // Premium expandable items grid
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isOpen
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: tokens.panelMuted.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: tokens.outline,
                          width: 1,
                        ),
                      ),
                      child: Column(children: [
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                cat.color.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: cat.items.length,
                          itemBuilder: (ctx, j) {
                            final item = cat.items[j];
                            return _buildFeatureItem(item, cat.color);
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

  Widget _buildFeatureItem(_HubItem item, Color categoryColor) {
    return Semantics(
      button: true,
      label: item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          if (item.onTap != null) {
            item.onTap!();
          } else if (item.builder != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: item.builder!),
            );
          }
        },
        splashColor: categoryColor.withValues(alpha: 0.1),
        highlightColor: categoryColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                categoryColor.withValues(alpha: 0.08),
                categoryColor.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
