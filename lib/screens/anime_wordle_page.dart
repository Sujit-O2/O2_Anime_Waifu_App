import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AnimeWordlePage extends StatefulWidget {
  const AnimeWordlePage({super.key});
  @override
  State<AnimeWordlePage> createState() => _AnimeWordlePageState();
}

class _AnimeWordlePageState extends State<AnimeWordlePage> {
  final _guessCtrl = TextEditingController();
  final List<_WordleGuess> _guesses = [];
  _AnimeTarget? _target;
  bool _loading = true, _won = false, _lost = false;
  List<_AnimeTarget> _suggestions = [];
  static const int _maxGuesses = 6;

  @override
  void initState() { super.initState(); _loadDailyAnime(); }

  @override
  void dispose() { _guessCtrl.dispose(); super.dispose(); }

  Future<void> _loadDailyAnime() async {
    try {
      final today = DateTime.now();
      final seed = today.year * 10000 + today.month * 100 + today.day;
      final rng = Random(seed);
      final resp = await http.get(Uri.parse(
        'https://api.jikan.moe/v4/top/anime?page=${rng.nextInt(5) + 1}&limit=25'));
      if (resp.statusCode == 200) {
        final list = (jsonDecode(resp.body)['data'] as List?) ?? [];
        if (list.isNotEmpty) {
          final p = list[rng.nextInt(list.length)];
          _target = _AnimeTarget.fromJson(p);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _searchSuggestions(String q) async {
    if (q.length < 2) { setState(() => _suggestions = []); return; }
    try {
      final resp = await http.get(Uri.parse(
        'https://api.jikan.moe/v4/anime?q=${Uri.encodeComponent(q)}&limit=5'));
      if (resp.statusCode == 200) {
        final list = (jsonDecode(resp.body)['data'] as List?) ?? [];
        setState(() => _suggestions = list.map((a) => _AnimeTarget.fromJson(a)).toList());
      }
    } catch (_) {}
  }

  void _submitGuess(_AnimeTarget guess) {
    if (_won || _lost || _target == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _guesses.add(_WordleGuess(guess: guess, target: _target!));
      _suggestions = []; _guessCtrl.clear();
      if (guess.title.toLowerCase() == _target!.title.toLowerCase()) {
        _won = true; HapticFeedback.heavyImpact();
      } else if (_guesses.length >= _maxGuesses) _lost = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('🧩 Anime Wordle', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(
          colors: [Colors.green.withValues(alpha: 0.4), Colors.black.withValues(alpha: 0.95)]))),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : _target == null
          ? Center(child: Text('Failed to load', style: TextStyle(color: Colors.grey.shade500)))
          : Column(children: [
              Container(
                margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2))),
                child: Text('Guess the anime! ${_maxGuesses - _guesses.length} tries left',
                  style: TextStyle(color: Colors.green.shade300, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              if (_won) _banner('🎉 Correct! "${_target!.title}"', Colors.green),
              if (_lost) _banner('😢 It was "${_target!.title}"', Colors.redAccent),
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(12), itemCount: _guesses.length,
                itemBuilder: (_, i) => _buildGuessRow(_guesses[i]))),
              if (!_won && !_lost) ...[
                if (_suggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF1A1A2E)),
                    child: ListView.builder(shrinkWrap: true, itemCount: _suggestions.length,
                      itemBuilder: (_, i) => ListTile(dense: true,
                        title: Text(_suggestions[i].title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: Text('${_suggestions[i].year} • ${_suggestions[i].type}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        onTap: () => _submitGuess(_suggestions[i]))),
                  ),
                Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  child: TextField(controller: _guessCtrl, style: const TextStyle(color: Colors.white),
                    onChanged: _searchSuggestions,
                    decoration: InputDecoration(hintText: 'Type anime name...',
                      hintStyle: TextStyle(color: Colors.grey.shade600), filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search, color: Colors.green)))),
              ],
            ]),
    );
  }

  Widget _banner(String text, Color color) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
      color: color.withValues(alpha: 0.15), border: Border.all(color: color)),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center));

  Widget _buildGuessRow(_WordleGuess g) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
      color: Colors.white.withValues(alpha: 0.04)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(g.guess.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 6),
      Row(children: [
        _clueChip('Year', '${g.guess.year}', g.yearMatch),
        _clueChip('Eps', '${g.guess.episodes}', g.episodeMatch),
        _clueChip('Type', g.guess.type, g.typeMatch),
        _clueChip('Studio', g.guess.studio, g.studioMatch),
      ]),
      const SizedBox(height: 4),
      Wrap(spacing: 4, children: g.guess.genres.map((genre) {
        final match = g.target.genres.contains(genre);
        return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
            color: match ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.15)),
          child: Text(genre, style: TextStyle(color: match ? Colors.green : Colors.redAccent, fontSize: 10)));
      }).toList()),
    ]));

  Widget _clueChip(String label, String value, _ClueMatch match) {
    final color = match == _ClueMatch.exact ? Colors.green : match == _ClueMatch.close ? Colors.amber : Colors.redAccent;
    final icon = match == _ClueMatch.exact ? '✅' : match == _ClueMatch.close ? '🔶' : '❌';
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withValues(alpha: 0.15)),
      child: Column(children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
        Text('$icon $value', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ])));
  }
}

enum _ClueMatch { exact, close, wrong }

class _WordleGuess {
  final _AnimeTarget guess, target;
  _WordleGuess({required this.guess, required this.target});
  _ClueMatch get yearMatch => guess.year == target.year ? _ClueMatch.exact
      : (guess.year - target.year).abs() <= 2 ? _ClueMatch.close : _ClueMatch.wrong;
  _ClueMatch get episodeMatch => guess.episodes == target.episodes ? _ClueMatch.exact
      : (guess.episodes - target.episodes).abs() <= 5 ? _ClueMatch.close : _ClueMatch.wrong;
  _ClueMatch get typeMatch => guess.type == target.type ? _ClueMatch.exact : _ClueMatch.wrong;
  _ClueMatch get studioMatch => guess.studio == target.studio ? _ClueMatch.exact : _ClueMatch.wrong;
}

class _AnimeTarget {
  final String title, type, studio;
  final int year, episodes;
  final double score;
  final List<String> genres;
  _AnimeTarget({required this.title, required this.year, required this.episodes,
    required this.score, required this.genres, required this.type, required this.studio});
  factory _AnimeTarget.fromJson(Map<String, dynamic> j) => _AnimeTarget(
    title: j['title'] ?? '', year: j['year'] ?? j['aired']?['prop']?['from']?['year'] ?? 0,
    episodes: j['episodes'] ?? 0, score: (j['score'] ?? 0).toDouble(),
    genres: (j['genres'] as List?)?.map((g) => g['name']?.toString() ?? '').toList() ?? [],
    type: j['type'] ?? 'TV',
    studio: (j['studios'] as List?)?.isNotEmpty == true ? j['studios'][0]['name'] : 'Unknown');
}
