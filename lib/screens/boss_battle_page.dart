import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Boss Battles — Anime trivia boss fights with HP bars and power-ups.
class BossBattlePage extends StatefulWidget {
  const BossBattlePage({super.key});
  @override
  State<BossBattlePage> createState() => _BossBattlePageState();
}

class _BossBattlePageState extends State<BossBattlePage> with TickerProviderStateMixin {
  int _bossHp = 100, _playerHp = 100;
  int _bossLevel = 1, _streak = 0, _score = 0;
  bool _loading = true, _gameOver = false, _bossDefeated = false;
  String? _currentQ;
  List<String> _options = [];
  String? _correctAnswer;
  String? _selectedAnswer;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  static const _bosses = [
    _Boss('👹 Goblin Slayer', 80, Color(0xFF4CAF50), 'Easy'),
    _Boss('🐉 Shenron', 120, Color(0xFFFFC107), 'Medium'),
    _Boss('😈 Sukuna', 160, Color(0xFFF44336), 'Hard'),
    _Boss('💀 Muzan', 200, Color(0xFF9C27B0), 'Nightmare'),
    _Boss('🌟 Goku Ultra', 250, Color(0xFFFF9800), 'God'),
  ];

  _Boss get _currentBoss => _bosses[min(_bossLevel - 1, _bosses.length - 1)];

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _startBoss();
  }

  @override
  void dispose() { _shakeCtrl.dispose(); super.dispose(); }

  Future<void> _startBoss() async {
    setState(() {
      _bossHp = _currentBoss.maxHp;
      _playerHp = 100;
      _bossDefeated = false;
      _gameOver = false;
    });
    await _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() { _loading = true; _selectedAnswer = null; });
    try {
      final resp = await http.get(Uri.parse('https://api.jikan.moe/v4/random/anime'));
      if (resp.statusCode == 200) {
        final anime = jsonDecode(resp.body)['data'];
        final title = anime['title']?.toString() ?? 'Unknown';
        final genres = (anime['genres'] as List?)?.map((g) => g['name'].toString()).toList() ?? [];
        
        int year = 0;
        if (anime['year'] != null) {
          year = int.tryParse(anime['year'].toString()) ?? 0;
        } else if (anime['aired']?['prop']?['from']?['year'] != null) {
          year = int.tryParse(anime['aired']['prop']['from']['year'].toString()) ?? 0;
        }

        int episodes = 0;
        if (anime['episodes'] != null) {
          episodes = int.tryParse(anime['episodes'].toString()) ?? 0;
        }

        final type = anime['type']?.toString() ?? 'TV';

        final rng = Random();
        final qType = rng.nextInt(4); // 4 possible question types now

        if (qType == 0 && genres.isNotEmpty) {
          _currentQ = 'What genre is "$title"?';
          _correctAnswer = genres[rng.nextInt(genres.length)];
          _options = _generateFakeOptions(_correctAnswer!, [
            'Action', 'Romance', 'Comedy', 'Horror', 'Sci-Fi', 'Fantasy', 'Mystery', 'Drama', 'Sports', 'Slice of Life'
          ]);
        } else if (qType == 1 && year > 0) {
          _currentQ = 'When did "$title" air?';
          _correctAnswer = '$year';
          _options = _generateNumericOptions(year, 3);
        } else if (qType == 2 && episodes > 0 && episodes < 2000) {
          // New episode count question to fix the unused variable
          _currentQ = 'How many episodes does "$title" have?';
          _correctAnswer = '$episodes';
          _options = _generateNumericOptions(episodes, episodes > 100 ? 50 : (episodes > 24 ? 12 : 3));
        } else {
          _currentQ = '"$title" is a ___?';
          _correctAnswer = type;
          _options = _generateFakeOptions(type, ['TV', 'Movie', 'OVA', 'ONA', 'Special']);
        }
      }
    } catch (_) {
      _currentQ = 'Error loading question';
      _options = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  List<String> _generateFakeOptions(String correct, List<String> pool) {
    final fakes = pool.where((o) => o != correct).toList()..shuffle();
    final opts = [correct, ...fakes.take(3)];
    opts.shuffle();
    return opts;
  }

  List<String> _generateNumericOptions(int correct, int spread) {
    final rng = Random();
    final opts = <String>{correct.toString()};
    while (opts.length < 4) {
      opts.add('${correct + rng.nextInt(spread * 2 + 1) - spread}');
    }
    return opts.toList()..shuffle();
  }

  void _answer(String ans) {
    if (_selectedAnswer != null) return;
    HapticFeedback.mediumImpact();
    setState(() => _selectedAnswer = ans);

    final correct = ans == _correctAnswer;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        if (correct) {
          final dmg = 20 + (_streak * 5);
          _bossHp = max(0, _bossHp - dmg);
          _streak++;
          _score += 10 * _streak;
          if (_bossHp <= 0) {
            _bossDefeated = true;
            HapticFeedback.heavyImpact();
          }
        } else {
          _playerHp = max(0, _playerHp - 25);
          _streak = 0;
          _shakeCtrl.forward(from: 0);
          if (_playerHp <= 0) {
            _gameOver = true;
            HapticFeedback.heavyImpact();
          }
        }
      });

      if (!_gameOver && !_bossDefeated) _loadQuestion();
    });
  }

  void _nextBoss() {
    setState(() => _bossLevel++);
    _startBoss();
  }

  @override
  Widget build(BuildContext context) {
    final boss = _currentBoss;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text('⚔️ Boss Battle Lv.$_bossLevel',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 16),
            child: Text('Score: $_score', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)))),
        ],
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(
          colors: [boss.color.withValues(alpha: 0.5), Colors.black.withValues(alpha: 0.95)]))),
      ),
      body: Column(children: [
        const SizedBox(height: 16),
        // Boss display
        Text(boss.emoji, style: const TextStyle(fontSize: 64)),
        Text(boss.name, style: TextStyle(color: boss.color, fontWeight: FontWeight.w900, fontSize: 20)),
        Text(boss.difficulty, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 12),
        // Boss HP bar
        Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
          child: _hpBar('BOSS', _bossHp, boss.maxHp, boss.color)),
        const SizedBox(height: 8),
        // Player HP bar
        AnimatedBuilder(animation: _shakeAnim, builder: (_, child) =>
          Transform.translate(offset: Offset(_shakeAnim.value * sin(_shakeCtrl.value * pi * 4), 0),
            child: child),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _hpBar('YOU', _playerHp, 100, Colors.cyan))),
        // Streak
        if (_streak > 0) Padding(padding: const EdgeInsets.only(top: 8),
          child: Text('🔥 Streak x$_streak (${20 + _streak * 5} dmg)',
            style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
        const Spacer(),
        // Game state
        if (_bossDefeated)
          _resultCard('🎉 Boss Defeated!', 'Score: $_score', Colors.green, 'Next Boss →', _nextBoss)
        else if (_gameOver)
          _resultCard('💀 Game Over', 'Score: $_score', Colors.red, 'Retry', _startBoss)
        else if (_loading)
          const Padding(padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Colors.amber))
        else ...[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(_currentQ ?? '', textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(height: 16),
          ...List.generate(_options.length, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: GestureDetector(
              onTap: () => _answer(_options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _selectedAnswer == null
                    ? Colors.white.withValues(alpha: 0.06)
                    : _options[i] == _correctAnswer
                      ? Colors.green.withValues(alpha: 0.3)
                      : _options[i] == _selectedAnswer
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: _selectedAnswer == null
                    ? Colors.white.withValues(alpha: 0.1)
                    : _options[i] == _correctAnswer ? Colors.green : Colors.transparent)),
                child: Text(_options[i], style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),
          )),
        ],
        const Spacer(),
      ]),
    );
  }

  Widget _hpBar(String label, int hp, int maxHp, Color color) {
    final pct = (hp / maxHp).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold)),
        Text('$hp/$maxHp', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(value: pct, minHeight: 10,
          backgroundColor: Colors.white.withValues(alpha: 0.08), color: color)),
    ]);
  }

  Widget _resultCard(String title, String sub, Color color, String btnLabel, VoidCallback onTap) =>
    Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.15), border: Border.all(color: color)),
      child: Column(children: [
        Text(title, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(sub, style: TextStyle(color: Colors.grey.shade400)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: color),
          child: Text(btnLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ]));
}

class _Boss {
  final String name, difficulty;
  final int maxHp;
  final Color color;
  const _Boss(this.name, this.maxHp, this.color, this.difficulty);
  String get emoji => name.split(' ')[0];
}
