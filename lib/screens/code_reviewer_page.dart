import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI Code Reviewer — Paste code, get instant review with issues, improvements & optimizations.
class CodeReviewerPage extends StatefulWidget {
  const CodeReviewerPage({super.key});
  @override
  State<CodeReviewerPage> createState() => _CodeReviewerPageState();
}

class _CodeReviewerPageState extends State<CodeReviewerPage> {
  final _ctrl = TextEditingController();
  bool _reviewing = false;
  Map<String, dynamic>? _review;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('code_reviewer_history');
    if (d != null) setState(() => _history = (jsonDecode(d) as List).cast<Map<String, dynamic>>());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('code_reviewer_history', jsonEncode(_history.take(20).toList()));
  }

  void _reviewCode() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _reviewing = true);
    await Future.delayed(const Duration(seconds: 2));

    // Simulate AI code review
    final issues = <Map<String, dynamic>>[];
    if (code.contains('var ')) issues.add({'severity': 'warning', 'msg': 'Use specific types instead of "var" for better readability', 'icon': '⚠️'});
    if (code.contains('print(') || code.contains('console.log')) issues.add({'severity': 'info', 'msg': 'Remove debug print/log statements before production', 'icon': 'ℹ️'});
    if (!code.contains('try') && !code.contains('catch')) issues.add({'severity': 'warning', 'msg': 'No error handling detected — add try/catch blocks', 'icon': '⚠️'});
    if (code.length > 200) issues.add({'severity': 'info', 'msg': 'Consider splitting into smaller functions (${code.length} chars)', 'icon': '📏'});
    if (code.contains('TODO') || code.contains('FIXME')) issues.add({'severity': 'warning', 'msg': 'Unresolved TODO/FIXME comments found', 'icon': '📝'});
    if (code.contains('null') || code.contains('!.')) issues.add({'severity': 'error', 'msg': 'Potential null safety issue — avoid force unwrapping', 'icon': '🔴'});
    if (issues.isEmpty) issues.add({'severity': 'success', 'msg': 'Code looks clean! No major issues found', 'icon': '✅'});

    final score = issues.where((i) => i['severity'] == 'error').isEmpty
        ? issues.where((i) => i['severity'] == 'warning').isEmpty ? 95 : 75
        : 50;

    final suggestions = [
      'Add meaningful comments for complex logic',
      'Consider extracting magic numbers into constants',
      'Ensure consistent naming conventions',
      'Add unit tests for critical functions',
    ];

    setState(() {
      _reviewing = false;
      _review = {
        'code': code.substring(0, code.length.clamp(0, 100)),
        'issues': issues,
        'score': score,
        'suggestions': suggestions.take(3).toList(),
        'time': DateTime.now().toIso8601String(),
      };
      _history.insert(0, _review!);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('CODE REVIEWER', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(children: [
        // Code input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.code_rounded, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 6),
              Text('PASTE CODE', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              maxLines: 8,
              style: GoogleFonts.firaCode(color: Colors.white70, fontSize: 12),
              cursorColor: Colors.cyanAccent,
              decoration: InputDecoration(
                hintText: 'Paste your code here for review...\n\nExample:\nfunction add(a, b) {\n  return a + b;\n}',
                hintStyle: GoogleFonts.firaCode(color: Colors.white12, fontSize: 11),
                border: InputBorder.none,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // Review button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _reviewing ? null : _reviewCode,
            icon: _reviewing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.rate_review_rounded, size: 18),
            label: Text(_reviewing ? 'ANALYZING...' : '🔍 REVIEW CODE', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
              foregroundColor: Colors.cyanAccent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Review results
        if (_review != null) ...[
          // Score
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                (_review!['score'] >= 80 ? Colors.greenAccent : _review!['score'] >= 60 ? Colors.amberAccent : Colors.redAccent).withValues(alpha: 0.08),
                Colors.transparent,
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (_review!['score'] >= 80 ? Colors.greenAccent : _review!['score'] >= 60 ? Colors.amberAccent : Colors.redAccent).withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Text('${_review!['score']}', style: GoogleFonts.outfit(
                color: _review!['score'] >= 80 ? Colors.greenAccent : _review!['score'] >= 60 ? Colors.amberAccent : Colors.redAccent,
                fontSize: 36, fontWeight: FontWeight.w900,
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CODE QUALITY SCORE', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                Text(
                  _review!['score'] >= 80 ? 'Great code! Minor polish needed.' : _review!['score'] >= 60 ? 'Decent but has warnings.' : 'Needs significant improvement.',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 10),

          // Issues
          ...(_review!['issues'] as List).map((issue) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (issue['severity'] == 'error' ? Colors.redAccent : issue['severity'] == 'warning' ? Colors.amberAccent : Colors.cyanAccent).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (issue['severity'] == 'error' ? Colors.redAccent : issue['severity'] == 'warning' ? Colors.amberAccent : Colors.cyanAccent).withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Text(issue['icon'], style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(issue['msg'], style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))),
            ]),
          )),

          const SizedBox(height: 10),
          // Suggestions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.deepPurpleAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.15))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💡 SUGGESTIONS', style: GoogleFonts.outfit(color: Colors.deepPurpleAccent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 6),
              ...(_review!['suggestions'] as List).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $s', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
              )),
            ]),
          ),
        ],
      ])),
    );
  }
}
