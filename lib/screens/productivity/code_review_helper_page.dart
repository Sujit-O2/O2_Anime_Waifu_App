import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/productivity/code_review_service.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class CodeReviewHelperPage extends StatefulWidget {
  const CodeReviewHelperPage({super.key});

  @override
  State<CodeReviewHelperPage> createState() => _CodeReviewHelperPageState();
}

class _CodeReviewHelperPageState extends State<CodeReviewHelperPage> {
  final _service = CodeReviewService.instance;
  final _codeCtrl = TextEditingController();
  final _langCtrl = TextEditingController();
  CodeReviewResult? _result;
  bool _analyzing = false;

  static const _bg = Color(0xFF0A0B14);
  static const _accent = Color(0xFFFF6D00);

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('code_review'));
    unawaited(_service.initialize());
    _langCtrl.text = 'dart';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _langCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _analyzing = true;
      _result = null;
    });
    final result = await _service.analyzeCode(
      code: _codeCtrl.text,
      language: _langCtrl.text.trim().isEmpty ? 'dart' : _langCtrl.text.trim(),
      context: 'Manual review',
    );
    if (mounted) setState(() {
      _result = result;
      _analyzing = false;
    });
  }

  Color _severityColor(IssueSeverity s) {
    switch (s) {
      case IssueSeverity.critical:
        return Colors.redAccent;
      case IssueSeverity.high:
        return Colors.orangeAccent;
      case IssueSeverity.medium:
        return Colors.amberAccent;
      case IssueSeverity.low:
        return Colors.greenAccent;
    }
  }

  String _severityEmoji(IssueSeverity s) {
    switch (s) {
      case IssueSeverity.critical:
        return '🚨';
      case IssueSeverity.high:
        return '⚠️';
      case IssueSeverity.medium:
        return '🔶';
      case IssueSeverity.low:
        return '💡';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('💻 Code Review',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
              onPressed: () => setState(() => _result = null),
              tooltip: 'Clear results',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                const Icon(Icons.code_rounded, color: _accent, size: 20),
                const SizedBox(width: 10),
                Text('Analyze Code',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ]),
              const SizedBox(height: 16),

              // Language chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['dart', 'python', 'javascript', 'typescript']
                    .map((lang) {
                  final sel = _langCtrl.text.toLowerCase() == lang;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _langCtrl.text = lang);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? _accent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel
                                ? _accent.withValues(alpha: 0.5)
                                : Colors.white12,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Text(lang.toUpperCase(),
                          style: GoogleFonts.outfit(
                              color: sel ? _accent : Colors.white54,
                              fontSize: 10,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Custom language field
              TextField(
                controller: _langCtrl,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Language (e.g. swift, go...)',
                  hintStyle: GoogleFonts.outfit(
                      color: Colors.white30, fontSize: 12),
                  prefixIcon: const Icon(Icons.translate_rounded,
                      color: Colors.white38, size: 18),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: _accent.withValues(alpha: 0.5))),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Code input
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _codeCtrl,
                  maxLines: 10,
                  style: GoogleFonts.sourceCodePro(
                      color: Colors.greenAccent.shade100,
                      fontSize: 13,
                      height: 1.5),
                  decoration: InputDecoration(
                    hintText: '// Paste your code here...',
                    hintStyle: GoogleFonts.sourceCodePro(
                        color: Colors.white24, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Analyze Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6D00), Color(0xFFBF360C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: _accent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _analyzing ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                        _analyzing ? 'ANALYZING...' : 'ANALYZE CODE',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 1.2)),
                  ),
                ),
              ),
            ]),
          ),

          // Results
          if (_result != null) ...[
            const SizedBox(height: 20),

            // Summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accent.withValues(alpha: 0.15),
                    _accent.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  const Icon(Icons.summarize_rounded,
                      color: _accent, size: 18),
                  const SizedBox(width: 10),
                  Text('Review Summary',
                      style: GoogleFonts.outfit(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
                const SizedBox(height: 14),
                // Metrics row
                Row(children: [
                  _metricChip(
                      'Lines',
                      '${_result!.review.linesOfCode}',
                      Colors.cyanAccent),
                  const SizedBox(width: 12),
                  _metricChip(
                      'Complexity',
                      _result!.review.complexity.toStringAsFixed(0),
                      Colors.purpleAccent),
                  const SizedBox(width: 12),
                  _metricChip(
                      'Score',
                      '${_result!.review.maintainability.toStringAsFixed(0)}/100',
                      Colors.greenAccent),
                ]),
                const SizedBox(height: 14),
                Text(_result!.summary,
                    style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5)),
              ]),
            ),
            const SizedBox(height: 16),

            // Recommendations
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.amberAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 10),
                  Text('Recommendations',
                      style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
                const SizedBox(height: 10),
                Text(_result!.recommendations,
                    style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5)),
              ]),
             ),

             // Issues list
            if (_result!.review.issues.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Issues Found (${_result!.review.issues.length})',
                  style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              ..._result!.review.issues.map((issue) {
                final color = _severityColor(issue.severity);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_severityEmoji(issue.severity),
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          if (issue.line > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('L${issue.line}',
                                  style: GoogleFonts.outfit(
                                      color: color, fontSize: 10)),
                            ),
                          if (issue.line > 0) const SizedBox(width: 6),
                          Expanded(
                            child: Text(issue.message,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text('💡 ${issue.suggestion}',
                            style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                                height: 1.4)),
                      ]),
                    ),
                  ]),
                );
              }),
            ],

            // Suggestions list
            if (_result!.review.suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                  'Suggestions (${_result!.review.suggestions.length})',
                  style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              ..._result!.review.suggestions.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(s.title,
                          style: GoogleFonts.outfit(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(s.description,
                          style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.4)),
                      if (s.example.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(s.example,
                              style: GoogleFonts.sourceCodePro(
                                  color: Colors.greenAccent.shade100,
                                  fontSize: 11)),
                        ),
                      ],
                    ]),
                  )),
            ],
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          Text(label,
              style: GoogleFonts.outfit(
                  color: Colors.white54, fontSize: 10)),
        ]),
      ),
    );
  }
}
