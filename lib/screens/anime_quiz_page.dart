import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/app_cached_image.dart';

import 'package:http/http.dart' as http;
import '../widgets/premium_animations.dart';
import '../services/streak_service.dart';

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
  List<String> _options = [];
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _loadQuestion();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() { _loading = true; _answered = false; _selectedIndex = null; });

    try {
      // Fetch 4 random anime for options
      final animeList = <Map<String, dynamic>>[];
      for (int i = 0; i < 4; i++) {
        final resp = await http.get(
          Uri.parse('https://api.jikan.moe/v4/random/anime'),
          headers: {'User-Agent': 'AnimeWaifuApp/3.0'},
        ).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body)['data'] as Map<String, dynamic>;
          animeList.add(data);
        }
        // Jikan rate limit: small delay
        if (i < 3) await Future.delayed(const Duration(milliseconds: 350));
      }

      if (animeList.length < 4) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final rng = Random();
      _correctIndex = rng.nextInt(4);
      final correct = animeList[_correctIndex];
      _coverUrl = correct['images']?['jpg']?['large_image_url'] ?? '';
      _options = animeList.map((a) =>
        (a['title_english'] as String?) ?? (a['title'] as String?) ?? 'Unknown'
      ).toList();

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onAnswer(int index) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedIndex = index;
      _totalQuestions++;
      if (index == _correctIndex) {
        _score++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
        StreakService.recordActivity(); // Record quiz activity for daily streak
        // Confetti on 3+ streak
        if (_streak >= 3 && mounted) {
          ConfettiBurst.show(context);
        }
      } else {
        _streak = 0;
        _shakeCtrl.forward(from: 0);
      }
    });

    // Auto-advance after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _loadQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🎮 Anime Quiz',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.amber.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
        actions: [
          // Score display
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text('$_score/$_totalQuestions',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
          ),
        ],
      ),
      body: _loading
        ? Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 16),
              Text('Loading quiz...', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ))
        : _options.length < 4
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
                const SizedBox(height: 12),
                Text('Failed to load quiz data',
                  style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadQuestion,
                  child: const Text('Retry')),
              ],
            ))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Streak bar
                  if (_streak > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.orange.withValues(alpha: 0.3),
                          Colors.red.withValues(alpha: 0.3),
                        ]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text('Streak: $_streak',
                            style: const TextStyle(color: Colors.orange,
                                fontWeight: FontWeight.bold, fontSize: 14)),
                          if (_bestStreak > 0) ...[
                            const SizedBox(width: 12),
                            Text('Best: $_bestStreak',
                              style: TextStyle(color: Colors.orange.shade300,
                                  fontSize: 12)),
                          ],
                        ],
                      ),
                    ),

                  // Cover image
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _coverUrl.isNotEmpty
                        ? AppCachedImage(url: _coverUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade900),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Question
                  Text('Which anime is this?',
                    style: TextStyle(color: Colors.grey.shade300,
                        fontSize: 18, fontWeight: FontWeight.w700)),

                  const SizedBox(height: 12),

                  // Options
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: List.generate(4, (i) {
                        final isCorrect = i == _correctIndex;
                        final isSelected = i == _selectedIndex;
                        Color bgColor = Colors.white.withValues(alpha: 0.06);
                        Color borderColor = Colors.transparent;
                        Color textColor = Colors.white;

                        if (_answered) {
                          if (isCorrect) {
                            bgColor = Colors.green.withValues(alpha: 0.2);
                            borderColor = Colors.green;
                          } else if (isSelected) {
                            bgColor = Colors.red.withValues(alpha: 0.2);
                            borderColor = Colors.red;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => _onAnswer(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor, width: 2),
                              ),
                              child: Text(_options[i],
                                style: TextStyle(color: textColor, fontSize: 14,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
