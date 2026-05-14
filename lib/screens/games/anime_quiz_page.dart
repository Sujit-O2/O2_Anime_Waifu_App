import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/games_gamification/game_progress_db.dart';

import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/services/games_gamification/streak_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:anime_waifu/widgets/premium_animations.dart';

class AnimeQuizGamePage extends StatefulWidget {
  const AnimeQuizGamePage({super.key});

  @override
  State<AnimeQuizGamePage> createState() => _AnimeQuizGamePageState();
}

class _AnimeQuizGamePageState extends State<AnimeQuizGamePage>
    with SingleTickerProviderStateMixin {
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _totalQuestions = 0;
  int _level = 1;
  // Lives removed - each quiz is independent
  int _bestScore = 0;
  bool _loading = true;
  bool _answered = false;
  int? _selectedIndex;
  int _correctIndex = 0;
  String _coverUrl = '';
  List<String> _options = <String>[];
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _restoreStats();
    _loadQuestion();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreStats() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bestStreak = prefs.getInt('anime_quiz_best_streak_v2') ?? _bestStreak;
    });
    final rec = await GameProgressDB.instance.load('anime_quiz_v2');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
    });
  }

  Future<void> _saveStats() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('anime_quiz_best_streak_v2', _bestStreak);
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _answered = false;
      _selectedIndex = null;
    });

    try {
      final List<Map<String, dynamic>> animeList = <Map<String, dynamic>>[];
      for (int i = 0; i < 4; i++) {
        final http.Response resp = await http.get(
          Uri.parse('https://api.jikan.moe/v4/random/anime'),
          headers: <String, String>{'User-Agent': 'AnimeWaifuApp/3.0'},
        ).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final Map<String, dynamic> data =
              jsonDecode(resp.body)['data'] as Map<String, dynamic>;
          animeList.add(data);
        }
        if (i < 3) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
      }

      if (animeList.length < 4) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      final Random rng = Random();
      _correctIndex = rng.nextInt(4);
      final Map<String, dynamic> correct = animeList[_correctIndex];
      _coverUrl =
          correct['images']?['jpg']?['large_image_url']?.toString() ?? '';
      _options = animeList
          .map(
            (Map<String, dynamic> a) =>
                (a['title_english'] as String?) ??
                (a['title'] as String?) ??
                'Unknown',
          )
          .toList();

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onAnswer(int index) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedIndex = index;
      _totalQuestions++;
      if (index == _correctIndex) {
        HapticFeedback.heavyImpact();
        _score++;
        _streak++;
        _level++;
        if (_score > _bestScore) _bestScore = _score;
        if (_streak > _bestStreak) {
          _bestStreak = _streak;
        }
        StreakService.recordActivity();
        if (_streak >= 3 && mounted) {
          ConfettiBurst.show(context);
        }
      } else {
        HapticFeedback.vibrate();
        _streak = 0;
        _shakeCtrl.forward(from: 0);
      }
    });
    _saveStats();
    unawaited(GameProgressDB.instance.save('anime_quiz_v2', level: _level, bestScore: _bestScore, totalPlayed: _totalQuestions));

    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _loadQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: tokens.textSoft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.quiz_rounded, color: primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anime Quiz Challenge',
                      style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  Text('Guess the anime from its cover',
                      style: GoogleFonts.outfit(
                          color: tokens.textSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.15),
                  primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: primary, size: 16),
                const SizedBox(width: 6),
                Text('$_score/$_totalQuestions',
                    style: GoogleFonts.outfit(
                        color: primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tokens.panel.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: tokens.outline, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: primary, strokeWidth: 3),
                        const SizedBox(height: 16),
                        Text('Loading anime quiz...',
                            style: GoogleFonts.outfit(
                                color: tokens.textSoft,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )
              : _options.length < 4
                  ? Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: tokens.panel.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: tokens.outline, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.quiz_rounded,
                              color: tokens.textMuted, size: 48),
                          const SizedBox(height: 16),
                          Text('Quiz data unavailable',
                              style: GoogleFonts.outfit(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                              'The anime feed did not return enough options. Try again.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                  color: tokens.textSoft, fontSize: 14)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadQuestion,
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white),
                            label: const Text('Retry',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (_streak > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orangeAccent.withValues(alpha: 0.15),
                                    Colors.redAccent.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orangeAccent
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.orangeAccent,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text('STREAK: $_streak',
                                      style: GoogleFonts.outfit(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1)),
                                  if (_streak >= 3) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.emoji_events_rounded,
                                        color: Colors.amber, size: 18),
                                  ],
                                ],
                              ),
                            ),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _shakeCtrl,
                              builder: (_, child) {
                                final double offset =
                                    sin(_shakeCtrl.value * 4 * pi) * 10;
                                return Transform.translate(
                                  offset: Offset(offset, 0),
                                  child: child,
                                );
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: tokens.outline, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: _coverUrl.isNotEmpty
                                      ? AppCachedImage(
                                          url: _coverUrl,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: tokens.panel,
                                          child: Icon(
                                              Icons.image_not_supported_rounded,
                                              color: tokens.textMuted,
                                              size: 48),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary.withValues(alpha: 0.08),
                                  primary.withValues(alpha: 0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: primary.withValues(alpha: 0.2),
                                  width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.quiz_rounded,
                                    color: primary, size: 20),
                                const SizedBox(width: 12),
                                Text('Which anime is this?',
                                    style: GoogleFonts.outfit(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 4,
                              itemBuilder: (context, i) {
                                final bool isCorrect = i == _correctIndex;
                                final bool isSelected = i == _selectedIndex;

                                Color backgroundColor =
                                    tokens.panel.withValues(alpha: 0.8);
                                Color borderColor = tokens.outline;
                                Color textColor = theme.colorScheme.onSurface;
                                IconData? statusIcon;
                                Color? statusColor;

                                if (_answered) {
                                  if (isCorrect) {
                                    backgroundColor = Colors.greenAccent
                                        .withValues(alpha: 0.15);
                                    borderColor = Colors.greenAccent;
                                    statusIcon = Icons.check_circle_rounded;
                                    statusColor = Colors.greenAccent;
                                  } else if (isSelected) {
                                    backgroundColor = Colors.redAccent
                                        .withValues(alpha: 0.15);
                                    borderColor = Colors.redAccent;
                                    statusIcon = Icons.cancel_rounded;
                                    statusColor = Colors.redAccent;
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: _answered
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              _onAnswer(i);
                                            },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 400),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: borderColor, width: 2),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(_options[i],
                                                  style: GoogleFonts.outfit(
                                                    color: textColor,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  )),
                                            ),
                                            if (statusIcon != null) ...[
                                              const SizedBox(width: 12),
                                              Icon(statusIcon,
                                                  color: statusColor, size: 20),
                                            ] else if (!_answered) ...[
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: tokens.textSoft,
                                                      width: 1.5),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
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
