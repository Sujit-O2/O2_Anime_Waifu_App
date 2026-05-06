import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/games_gamification/game_progress_db.dart';

class AnimeWordlePage extends StatefulWidget {
  const AnimeWordlePage({super.key});
  @override
  State<AnimeWordlePage> createState() => _AnimeWordlePageState();
}

class _AnimeWordlePageState extends State<AnimeWordlePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _guessCtrl = TextEditingController();
  final List<_WordleGuess> _guesses = <_WordleGuess>[];
  _AnimeTarget? _target;
  bool _loading = true, _won = false, _lost = false;
  List<_AnimeTarget> _suggestions = <_AnimeTarget>[];
  static const int _maxGuesses = 6;
  int _wins = 0;
  int _losses = 0;
  int _level = 1;
  int _lives = 3;
  int _bestScore = 0;
  int _bestSolveStreak = 0;
  int _currentSolveStreak = 0;

  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _restoreStats();
    _loadDailyAnime();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _guessCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreStats() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _wins = prefs.getInt('anime_wordle_wins_v2') ?? 0;
      _losses = prefs.getInt('anime_wordle_losses_v2') ?? 0;
    });
    final rec = await GameProgressDB.instance.load('anime_wordle');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
      _bestSolveStreak = prefs.getInt('anime_wordle_best_streak_v2') ?? 0;
      _currentSolveStreak =
          prefs.getInt('anime_wordle_current_streak_v2') ?? 0;
    });
  }

  Future<void> _saveStats() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('anime_wordle_wins_v2', _wins);
    await prefs.setInt('anime_wordle_losses_v2', _losses);
    await prefs.setInt('anime_wordle_best_streak_v2', _bestSolveStreak);
    await prefs.setInt('anime_wordle_current_streak_v2', _currentSolveStreak);
  }

  String get _commentaryMood {
    if (_won) {
      return 'achievement';
    }
    if (_currentSolveStreak >= 3) {
      return 'achievement';
    }
    if (_guesses.isEmpty) {
      return 'motivated';
    }
    return 'neutral';
  }

  Future<void> _loadDailyAnime() async {
    try {
      final DateTime today = DateTime.now();
      final int seed = today.year * 10000 + today.month * 100 + today.day;
      final Random rng = Random(seed);
      final http.Response resp = await http.get(Uri.parse(
          'https://api.jikan.moe/v4/top/anime?page=${rng.nextInt(5) + 1}&limit=25'));
      if (resp.statusCode == 200) {
        final List<dynamic> list =
            (jsonDecode(resp.body)['data'] as List<dynamic>?) ?? <dynamic>[];
        if (list.isNotEmpty) {
          final Map<String, dynamic> p =
              list[rng.nextInt(list.length)] as Map<String, dynamic>;
          _target = _AnimeTarget.fromJson(p);
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _searchSuggestions(String q) async {
    if (q.length < 2) {
      setState(() => _suggestions = <_AnimeTarget>[]);
      return;
    }
    try {
      final http.Response resp = await http.get(Uri.parse(
          'https://api.jikan.moe/v4/anime?q=${Uri.encodeComponent(q)}&limit=5'));
      if (resp.statusCode == 200) {
        final List<dynamic> list =
            (jsonDecode(resp.body)['data'] as List<dynamic>?) ?? <dynamic>[];
        if (!mounted) return;
        setState(() => _suggestions = list
            .map((dynamic a) => _AnimeTarget.fromJson(a as Map<String, dynamic>))
            .toList());
      }
    } catch (_) {}
  }

  void _submitGuess(_AnimeTarget guess) {
    if (_won || _lost || _target == null) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _guesses.add(_WordleGuess(guess: guess, target: _target!));
      _suggestions = <_AnimeTarget>[];
      _guessCtrl.clear();
      if (guess.title.toLowerCase() == _target!.title.toLowerCase()) {
        _won = true;
        _wins++;
        _level++;
        if (_wins > _bestScore) _bestScore = _wins;
        unawaited(GameProgressDB.instance.save('anime_wordle', level: _level, bestScore: _bestScore, totalPlayed: _wins + _losses));
        _currentSolveStreak++;
        if (_currentSolveStreak > _bestSolveStreak) {
          _bestSolveStreak = _currentSolveStreak;
        }
        HapticFeedback.heavyImpact();
      } else if (_guesses.length >= _maxGuesses) {
        _lost = true;
        _losses++;
        _lives--;
        if (_lives <= 0) _lives = 3;
        unawaited(GameProgressDB.instance.save('anime_wordle', level: _level, bestScore: _bestScore, totalPlayed: _wins + _losses));
        _currentSolveStreak = 0;
      }
    });
    _saveStats();
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
              // App Bar
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
                            'Anime Wordle',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Guess the mysterious anime using clues',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 12,
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
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                    : _target == null
                        ? Center(
                            child: EmptyState(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Daily puzzle unavailable',
                              subtitle:
                                  'The anime feed did not arrive this round. Try again.',
                              buttonText: 'Retry',
                              onButtonPressed: _loadDailyAnime,
                            ),
                          )
                        : SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: _ctrl, curve: Curves.easeOutCubic)),
                            child: FadeTransition(
                              opacity: _ctrl,
                              child: Column(
                                children: <Widget>[
                                  GlassCard(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.psychology_rounded,
                                          color: Colors.greenAccent,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Guess the anime! ${_maxGuesses - _guesses.length} tries left',
                                          style: GoogleFonts.outfit(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_won)
                                    _banner('🎉 Correct! "${_target!.title}"',
                                        Colors.green),
                                  if (_lost)
                                    _banner('😢 It was "${_target!.title}"',
                                        Colors.redAccent),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                            child: _statsCard('Wins', '$_wins')),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child:
                                                _statsCard('Losses', '$_losses')),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: _statsCard(
                                                'Best', '$_bestSolveStreak')),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 10, 12, 0),
                                    child: WaifuCommentary(
                                        mood: _commentaryMood),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: _guesses.length,
                                      itemBuilder:
                                          (BuildContext context, int i) =>
                                              _buildGuessRow(_guesses[i]),
                                    ),
                                  ),
                                  if (!_won && !_lost) ...<Widget>[
                                    if (_suggestions.isNotEmpty)
                                      Container(
                                        constraints:
                                            const BoxConstraints(maxHeight: 150),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: V2Theme.surfaceLight),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _suggestions.length,
                                          itemBuilder:
                                              (BuildContext context, int i) =>
                                                  ListTile(
                                            dense: true,
                                            title: Text(
                                              _suggestions[i].title,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${_suggestions[i].year} • ${_suggestions[i].type}',
                                              style: GoogleFonts.outfit(
                                                color: Colors.grey.shade500,
                                                fontSize: 11,
                                              ),
                                            ),
                                            onTap: () =>
                                                _submitGuess(_suggestions[i]),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 4, 12, 16),
                                      child: TextField(
                                        controller: _guessCtrl,
                                        style:
                                            const TextStyle(color: Colors.white),
                                        onChanged: _searchSuggestions,
                                        decoration: InputDecoration(
                                          hintText: 'Type anime name...',
                                          hintStyle: TextStyle(
                                              color: Colors.grey.shade600),
                                          filled: true,
                                          fillColor: Colors.white
                                              .withValues(alpha: 0.08),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Colors.greenAccent,
                                              width: 1.5,
                                            ),
                                          ),
                                          prefixIcon: const Icon(Icons.search,
                                              color: Colors.greenAccent),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner(String text, Color color) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget _statsCard(String label, String value) => GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );

  Widget _buildGuessRow(_WordleGuess g) => GlassCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              g.guess.title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                _clueChip('Year', '${g.guess.year}', g.yearMatch),
                _clueChip('Eps', '${g.guess.episodes}', g.episodeMatch),
                _clueChip('Type', g.guess.type, g.typeMatch),
                _clueChip('Studio', g.guess.studio, g.studioMatch),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: g.guess.genres.map((String genre) {
                final bool match = g.target.genres.contains(genre);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: match
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    genre,
                    style: GoogleFonts.outfit(
                      color: match ? Colors.green : Colors.redAccent,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _clueChip(String label, String value, _ClueMatch match) {
    final Color color = match == _ClueMatch.exact
        ? Colors.greenAccent
        : match == _ClueMatch.close
            ? Colors.amberAccent
            : Colors.redAccent;
    final String icon = match == _ClueMatch.exact
        ? '✅'
        : match == _ClueMatch.close
            ? '🔶'
            : '❌';
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.12),
        ),
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$icon $value',
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ClueMatch { exact, close, wrong }

class _WordleGuess {
  final _AnimeTarget guess, target;
  _WordleGuess({required this.guess, required this.target});
  _ClueMatch get yearMatch => guess.year == target.year
      ? _ClueMatch.exact
      : (guess.year - target.year).abs() <= 2
          ? _ClueMatch.close
          : _ClueMatch.wrong;
  _ClueMatch get episodeMatch => guess.episodes == target.episodes
      ? _ClueMatch.exact
      : (guess.episodes - target.episodes).abs() <= 5
          ? _ClueMatch.close
          : _ClueMatch.wrong;
  _ClueMatch get typeMatch =>
      guess.type == target.type ? _ClueMatch.exact : _ClueMatch.wrong;
  _ClueMatch get studioMatch =>
      guess.studio == target.studio ? _ClueMatch.exact : _ClueMatch.wrong;
}

class _AnimeTarget {
  final String title, type, studio;
  final int year, episodes;
  final double score;
  final List<String> genres;
  _AnimeTarget({
    required this.title,
    required this.year,
    required this.episodes,
    required this.score,
    required this.genres,
    required this.type,
    required this.studio,
  });
  factory _AnimeTarget.fromJson(Map<String, dynamic> j) => _AnimeTarget(
        title: j['title']?.toString() ?? '',
        year: j['year'] as int? ??
            (j['aired']?['prop']?['from']?['year'] as int?) ??
            0,
        episodes: j['episodes'] as int? ?? 0,
        score: (j['score'] as num?)?.toDouble() ?? 0.0,
        genres: (j['genres'] as List<dynamic>?)
                ?.map((dynamic g) => g['name']?.toString() ?? '')
                .toList() ??
            <String>[],
        type: j['type']?.toString() ?? 'TV',
        studio: (j['studios'] as List<dynamic>?)?.isNotEmpty == true
            ? j['studios'][0]['name']?.toString() ?? 'Unknown'
            : 'Unknown',
      );
}



