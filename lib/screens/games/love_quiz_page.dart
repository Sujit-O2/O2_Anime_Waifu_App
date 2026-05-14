import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/ai_personalization/ai_content_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/games_gamification/game_progress_db.dart';

class LoveQuizPage extends StatefulWidget {
  const LoveQuizPage({super.key});
  @override
  State<LoveQuizPage> createState() => _LoveQuizPageState();
}

class _LoveQuizPageState extends State<LoveQuizPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  int _currentQ = 0;
  int _score = 0;
  int _level = 1;
  // Lives removed - each quiz is independent
  int _bestScore = 0;
  bool _answered = false;
  int? _selectedOption;
  bool _finished = false;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _loadDB();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _load();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final list = await AiContentService.getLoveQuiz();
      if (mounted) { setState(() { _questions = list; _loading = false; }); _fadeCtrl.forward(); }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDB() async {
    final rec = await GameProgressDB.instance.load('love_quiz');
    if (!mounted) return;
    setState(() {
      _level = (rec['level'] as int?) ?? 1;
      _bestScore = (rec['bestScore'] as int?) ?? 0;
    });
  }

  void _answer(int idx) {
    if (_answered || _questions.isEmpty) return;
    HapticFeedback.selectionClick();
    final q = _questions[_currentQ];
    final options = q['options'] as List? ?? [];
    final rawAnswer = q['answer']?.toString() ?? '0';
    int correct = 0;
    if (rawAnswer.length == 1 && rawAnswer.codeUnitAt(0) >= 65) {
      correct = rawAnswer.codeUnitAt(0) - 65;
    } else {
      correct = int.tryParse(rawAnswer) ?? 0;
    }
    if (correct >= options.length) correct = 0;
    setState(() { _selectedOption = idx; _answered = true; if (idx == correct) { _score++; _level++; if (_score > _bestScore) _bestScore = _score; unawaited(GameProgressDB.instance.save('love_quiz', level: _level, bestScore: _bestScore, totalPlayed: _score)); } });
    _questions[_currentQ]['_correct_idx'] = correct;
  }

  void _next() {
    if (_currentQ < _questions.length - 1) {
      _fadeCtrl.reset();
      setState(() { _currentQ++; _answered = false; _selectedOption = null; });
      _fadeCtrl.forward();
    } else {
      setState(() => _finished = true);
    }
  }

  void _reset() {
    _fadeCtrl.reset();
    setState(() { _currentQ = 0; _score = 0; _answered = false; _selectedOption = null; _finished = false; });
    _fadeCtrl.forward();
  }

  String get _resultTitle {
    if (_questions.isEmpty) return '';
    final pct = _score / _questions.length;
    if (pct >= 0.9) return 'Perfect Darling! ??';
    if (pct >= 0.7) return 'Great Match! ??';
    if (pct >= 0.5) return 'Getting There~ ?';
    return 'Keep Trying, Darling! ??';
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'LOVE QUIZ',
      subtitle: 'Test your bond with Zero Two',
      onBack: () => Navigator.pop(context),
      actions: [
        if (!_loading && !_finished && _questions.isNotEmpty) Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3))),
          child: Text('${_currentQ + 1}/${_questions.length}',
              style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
      content: _loading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Colors.pinkAccent),
              SizedBox(height: 16),
              Text('Generating love quiz with AI…', style: TextStyle(color: Colors.white54)),
            ]))
          : _questions.isEmpty
              ? Center(child: Text('Could not load quiz.', style: GoogleFonts.outfit(color: Colors.white54)))
              : _finished ? _buildResult()
              : FadeTransition(opacity: _fadeCtrl, child: _buildQuestion()),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentQ];
    final options = (q['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final correct = (q['_correct_idx'] as int?) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentQ + 1) / _questions.length,
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent), minHeight: 3)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2))),
          child: Text(q['q']?.toString() ?? 'Question', style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 17, height: 1.6, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        ...List.generate(options.length, (i) {
          Color borderColor = Colors.white12;
          Color bgColor = Colors.white.withValues(alpha: 0.03);
          Color textColor = Colors.white70;
          if (_answered) {
            if (i == correct) { borderColor = Colors.greenAccent; bgColor = Colors.greenAccent.withValues(alpha: 0.08); textColor = Colors.greenAccent; }
            else if (i == _selectedOption) { borderColor = Colors.redAccent; bgColor = Colors.redAccent.withValues(alpha: 0.08); textColor = Colors.redAccent; }
          }
          return GestureDetector(
            onTap: () => _answer(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: bgColor, border: Border.all(color: borderColor)),
              child: Row(children: [
                Container(width: 28, height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: borderColor.withValues(alpha: 0.15),
                    border: Border.all(color: borderColor.withValues(alpha: 0.5))),
                  child: Center(child: Text(String.fromCharCode(65 + i),
                      style: GoogleFonts.outfit(color: textColor, fontSize: 12, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 14),
                Expanded(child: Text(options[i], style: GoogleFonts.outfit(
                    color: textColor, fontSize: 14, fontWeight: FontWeight.w600))),
                if (_answered && i == correct)
                  const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                if (_answered && i == _selectedOption && i != correct)
                  const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
              ]),
            ),
          );
        }),
        if (_answered) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2),
                foregroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.4))),
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(_currentQ < _questions.length - 1 ? 'Next Question ?' : 'See Results ??',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
            )),
        ),
      ]),
    );
  }

  Widget _buildResult() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_score >= _questions.length * 0.7 ? '??' : '??', style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 20),
        Text(_resultTitle, style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('$_score / ${_questions.length} correct',
            style: GoogleFonts.outfit(color: Colors.pinkAccent, fontSize: 16)),
        const SizedBox(height: 8),
        Text('You got $_score hearts from Zero Two~ ??',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _reset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
          child: Text('Try Again', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ]),
    ));
  }
}




