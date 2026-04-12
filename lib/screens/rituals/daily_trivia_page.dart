import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/ai_personalization/ai_content_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class DailyTriviaPage extends StatefulWidget {
  const DailyTriviaPage({super.key});
  @override
  State<DailyTriviaPage> createState() => _DailyTriviaPageState();
}

class _DailyTriviaPageState extends State<DailyTriviaPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  int _idx = 0;
  int _score = 0;
  bool _answered = false;
  int? _selected;
  bool _finished = false;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await AiContentService.getTrivia();
      if (mounted) {
        setState(() { _questions = list; _loading = false; });
        _fadeCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _answer(int idx) {
    if (_answered || _questions.isEmpty) return;
    HapticFeedback.selectionClick();
    final q = _questions[_idx];
    final options = q['options'] as List;
    final rawAnswer = q['answer']?.toString() ?? '';
    // Answer can be index (int) or letter string ("A","B","C","D")
    int correct = 0;
    if (rawAnswer.length == 1 && rawAnswer.codeUnitAt(0) >= 65) {
      correct = rawAnswer.codeUnitAt(0) - 65;
    } else {
      correct = int.tryParse(rawAnswer) ?? 0;
    }
    // Also try matching option text if answer is the full string
    if (correct >= options.length) {
      correct = options.indexWhere((o) => o.toString().startsWith(rawAnswer));
      if (correct < 0) correct = 0;
    }
    setState(() {
      _selected = idx;
      _answered = true;
      if (idx == correct) _score++;
    });
    // Store correct index so _buildQuestion can use it
    _questions[_idx]['_correct_idx'] = correct;
  }

  void _next() {
    if (_idx < _questions.length - 1) {
      _fadeCtrl.reset();
      setState(() { _idx++; _answered = false; _selected = null; });
      _fadeCtrl.forward();
    } else {
      setState(() => _finished = true);
    }
  }

  void _reset() {
    _fadeCtrl.reset();
    setState(() { _idx = 0; _score = 0; _answered = false; _selected = null; _finished = false; });
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'DAILY TRIVIA',
      onBack: () => Navigator.pop(context),
      content: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedEntry(
            index: 1,
            child: WaifuCommentary(
              mood: _score >= 3 ? 'achievement' : 'neutral',
            ),
          ),
        ),
        AnimatedEntry(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Score',
                  value: '$_score',
                  icon: Icons.stars_rounded,
                  color: Colors.amberAccent,
                ),
              ),
              Expanded(
                child: StatCard(
                  title: 'Question',
                  value: _questions.isEmpty ? '0' : '${_idx + 1}',
                  icon: Icons.help_rounded,
                  color: V2Theme.secondaryColor,
                ),
              ),
            ],
          ),
        ),

        Expanded(child: _loading
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Colors.amberAccent),
                SizedBox(height: 16),
                Text('Generating trivia with AI...', style: TextStyle(color: Colors.white54)),
              ]))
            : _questions.isEmpty
                ? Center(child: Text('Could not load trivia. Try again.',
                    style: GoogleFonts.outfit(color: Colors.white54)))
                : _finished
                    ? _buildResult()
                    : FadeTransition(opacity: _fadeCtrl, child: _buildQuestion())),
      ]),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_idx];
    final rawOptions = q['options'] as List? ?? [];
    final options = rawOptions.map((e) => e.toString()).toList();
    final correct = (q['_correct_idx'] as int?) ?? 0;
    final explanation = q['explanation']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_idx + 1) / _questions.length,
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: const AlwaysStoppedAnimation(Colors.amberAccent),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          margin: EdgeInsets.zero,
          glow: true,
          child: Text(q['q']?.toString() ?? 'Question',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 16, height: 1.6, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        ...List.generate(options.length, (i) {
          Color borderColor = Colors.white12;
          Color bgColor = Colors.white.withValues(alpha: 0.03);
          Color textColor = Colors.white70;
          if (_answered) {
            if (i == correct) {
              borderColor = Colors.greenAccent;
              bgColor = Colors.greenAccent.withValues(alpha: 0.08);
              textColor = Colors.greenAccent;
            } else if (i == _selected) {
              borderColor = Colors.redAccent;
              bgColor = Colors.redAccent.withValues(alpha: 0.08);
              textColor = Colors.redAccent;
            }
          }
          return GestureDetector(
            onTap: () => _answer(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: bgColor,
                border: Border.all(color: borderColor),
              ),
              child: Row(children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor.withValues(alpha: 0.15),
                    border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Center(child: Text(String.fromCharCode(65 + i),
                      style: GoogleFonts.outfit(
                          color: textColor, fontSize: 11, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(options[i], style: GoogleFonts.outfit(
                    color: textColor, fontSize: 13, fontWeight: FontWeight.w600))),
                if (_answered && i == correct)
                  const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                if (_answered && i == _selected && i != correct)
                  const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
              ]),
            ),
          );
        }),
        if (_answered) ...[
          if (explanation.isNotEmpty)
            GlassCard(
              margin: EdgeInsets.zero,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(explanation,
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, height: 1.5))),
              ]),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent.withValues(alpha: 0.15),
                foregroundColor: Colors.amberAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.4))),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _idx < _questions.length - 1 ? 'Next Question →' : 'See Results ✨',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildResult() {
    final pct = _questions.isEmpty ? 0.0 : _score / _questions.length;
    final title = pct >= 0.9 ? 'Perfect Score, Darling!'
        : pct >= 0.7 ? 'Great Job!'
        : pct >= 0.5 ? 'Not Bad~'
        : 'Keep Learning!';
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          pct >= 0.9 ? Icons.emoji_events : pct >= 0.5 ? Icons.thumb_up : Icons.school,
          color: Colors.amberAccent,
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('$_score / ${_questions.length} correct',
            style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 16)),
        const SizedBox(height: 6),
        Text('${(pct * 100).round()}% accuracy',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _reset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent,
            foregroundColor: Colors.black87,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
          child: Text('Try Again', style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ]),
    ));
  }
}




