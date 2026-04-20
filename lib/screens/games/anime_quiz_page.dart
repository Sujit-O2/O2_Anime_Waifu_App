import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/games_gamification/streak_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:anime_waifu/widgets/premium_animations.dart';

/// Anime Quiz Game — Guess the anime from its cover image!
/// Uses Jikan API random anime endpoint for quiz data.
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
    if (!mounted) {
      return;
    }
    setState(() {
      _bestStreak =
          prefs.getInt('anime_quiz_best_streak_v2') ?? _bestStreak;
    });
  }

  Future<void> _saveStats() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('anime_quiz_best_streak_v2', _bestStreak);
  }

  String get _commentaryMood {
    if (_streak >= 3) {
      return 'achievement';
    }
    if (_totalQuestions == 0) {
      return 'motivated';
    }
    return 'neutral';
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _answered = false;
      _selectedIndex = null;
    });

    try {
      // Fetch 4 random anime for options
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
        // Jikan rate limit: small delay
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
    if (_answered) {
      return;
    }
    setState(() {
      _answered = true;
      _selectedIndex = index;
      _totalQuestions++;
      if (index == _correctIndex) {
        HapticFeedback.heavyImpact();
        _score++;
        _streak++;
        if (_streak > _bestStreak) {
          _bestStreak = _streak;
        }
        StreakService.recordActivity(); // Record quiz activity for daily streak
        // Confetti on 3+ streak
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

    // Auto-advance after 1.5s
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _loadQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: V2Theme.surfaceDark,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: <Widget>[
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
                        children: <Widget>[
                          Text(
                            'Anime Quiz',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Guess the anime from its cover.',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: V2Theme.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: V2Theme.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.star_rounded,
                            color: V2Theme.accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_score/$_totalQuestions',
                            style: GoogleFonts.outfit(
                              color: V2Theme.accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CircularProgressIndicator(
                              color: V2Theme.accentColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading quiz...',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      )
                    : _options.length < 4
                        ? EmptyState(
                            title: 'Quiz data unavailable',
                            subtitle:
                                'The anime feed did not return enough options. Try again.',
                            icon: Icons.quiz_rounded,
                            buttonText: 'Retry',
                            onButtonPressed: _loadQuestion,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: <Widget>[
                                // Streak bar
                                if (_streak > 0)
                                  AnimatedEntry(
                                    index: 0,
                                    child: GlassCard(
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          const Text(
                                            '🔥',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Streak: $_streak',
                                            style: GoogleFonts.outfit(
                                              color: Colors.orangeAccent,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (_bestStreak > 0) ...<Widget>[
                                            const SizedBox(width: 16),
                                            Text(
                                              'Best: $_bestStreak',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white54,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),

                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: AnimatedEntry(
                                    index: 1,
                                    child: WaifuCommentary(
                                      mood: _commentaryMood,
                                    ),
                                  ),
                                ),

                                // Cover image
                                Expanded(
                                  flex: 3,
                                  child: AnimatedEntry(
                                    index: 2,
                                    child: AnimatedBuilder(
                                      animation: _shakeCtrl,
                                      builder: (BuildContext context,
                                          Widget? child) {
                                        final double offset = sin(
                                                _shakeCtrl.value * 4 * pi) *
                                            10;
                                        return Transform.translate(
                                          offset: Offset(offset, 0),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.1),
                                            width: 2,
                                          ),
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 16,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          child: _coverUrl.isNotEmpty
                                              ? AppCachedImage(
                                                  url: _coverUrl,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: V2Theme.surfaceLight,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Text(
                                  'Which anime is this?',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Options
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: List<Widget>.generate(4, (int i) {
                                      final bool isCorrect = i == _correctIndex;
                                      final bool isSelected =
                                          i == _selectedIndex;
                                      Color baseColor =
                                          Colors.white.withValues(alpha: 0.05);
                                      Color borderColor = Colors.white
                                          .withValues(alpha: 0.05);

                                      if (_answered) {
                                        if (isCorrect) {
                                          baseColor = Colors.greenAccent
                                              .withValues(alpha: 0.2);
                                          borderColor = Colors.greenAccent;
                                        } else if (isSelected) {
                                          baseColor = Colors.redAccent
                                              .withValues(alpha: 0.2);
                                          borderColor = Colors.redAccent;
                                        }
                                      }

                                      return AnimatedEntry(
                                        index: i + 3,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: GestureDetector(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              _onAnswer(i);
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 14,
                                              ),
                                              decoration: BoxDecoration(
                                                color: baseColor,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: borderColor,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Text(
                                                _options[i],
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
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




