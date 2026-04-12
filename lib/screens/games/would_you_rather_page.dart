import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/ai_content_service.dart';

class WouldYouRatherPage extends StatefulWidget {
  const WouldYouRatherPage({super.key});

  @override
  State<WouldYouRatherPage> createState() => _WouldYouRatherPageState();
}

class _WouldYouRatherPageState extends State<WouldYouRatherPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, String>> _questions = <Map<String, String>>[];
  bool _loading = true;
  int _idx = 0;
  int _votesA = 0;
  int _votesB = 0;
  bool _voted = false;
  int? _choice;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  String get _commentaryMood {
    if ((_votesA + _votesB) >= 6) {
      return 'achievement';
    }
    if (_voted) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );
    _load();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await AiContentService.getWouldYouRather();
      if (mounted) {
        setState(() {
          _questions = list;
          _loading = false;
        });
        _slideCtrl.forward();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() => _load();

  void _vote(int choice) {
    if (_voted) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _voted = true;
      _choice = choice;
      if (choice == 0) {
        _votesA++;
      } else {
        _votesB++;
      }
    });
  }

  void _next() {
    if (_questions.isEmpty) {
      return;
    }
    _slideCtrl.reset();
    setState(() {
      if (_idx < _questions.length - 1) {
        _idx++;
      } else {
        _idx = 0;
        _votesA = 0;
        _votesB = 0;
      }
      _voted = false;
      _choice = null;
    });
    _slideCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes = _votesA + _votesB;
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.10,
        tint: const Color(0xFF08100F),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: V2Theme.primaryColor),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: V2Theme.primaryColor,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      Row(
                        children: [
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
                              children: [
                                Text(
                                  'WOULD YOU RATHER',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  _questions.isEmpty
                                      ? 'No dilemmas available'
                                      : '${_idx + 1} / ${_questions.length} questions',
                                  style: GoogleFonts.outfit(
                                    color: V2Theme.secondaryColor
                                        .withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        margin: EdgeInsets.zero,
                        glow: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Decision board',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _voted
                                        ? 'Your vote is locked in'
                                        : 'Pick the side you would choose',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Keep voting through the deck and watch your session split drift between option A and option B.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ProgressRing(
                              progress: totalVotes.clamp(0, 10) / 10,
                              foreground: V2Theme.primaryColor,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.balance_rounded,
                                    color: V2Theme.primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$totalVotes',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Votes',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      WaifuCommentary(mood: _commentaryMood),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Option A',
                              value: '$_votesA',
                              icon: Icons.looks_one_rounded,
                              color: V2Theme.secondaryColor,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Option B',
                              value: '$_votesB',
                              icon: Icons.looks_two_rounded,
                              color: V2Theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Question',
                              value: _questions.isEmpty ? '--' : '${_idx + 1}',
                              icon: Icons.help_outline_rounded,
                              color: Colors.amberAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Deck',
                              value: '${_questions.length}',
                              icon: Icons.view_carousel_rounded,
                              color: Colors.lightGreenAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_questions.isEmpty)
                        const EmptyState(
                          icon: Icons.question_mark_rounded,
                          title: 'Could not load dilemmas',
                          subtitle:
                              'The question deck is empty right now. Try reopening this page later.',
                        )
                      else
                        SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            children: [
                              Text(
                                'Would you rather',
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildOption(
                                _questions[_idx]['optionA'] ?? 'Option A',
                                0,
                                V2Theme.secondaryColor,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Center(
                                  child: Text(
                                    'VS',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white38,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildOption(
                                _questions[_idx]['optionB'] ?? 'Option B',
                                1,
                                V2Theme.primaryColor,
                              ),
                              const SizedBox(height: 28),
                              if (_voted && totalVotes > 0) ...[
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${((_votesA / totalVotes) * 100).round()}%',
                                          style: GoogleFonts.outfit(
                                            color: V2Theme.secondaryColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Session split',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white24,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          '${((_votesB / totalVotes) * 100).round()}%',
                                          style: GoogleFonts.outfit(
                                            color: V2Theme.primaryColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _votesA / totalVotes,
                                        backgroundColor: V2Theme.primaryColor
                                            .withValues(alpha: 0.35),
                                        valueColor: AlwaysStoppedAnimation(
                                          V2Theme.secondaryColor
                                              .withValues(alpha: 0.8),
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _next,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: V2Theme.surfaceLight,
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: const BorderSide(
                                          color: Colors.white12),
                                    ),
                                  ),
                                  child: Text(
                                    _idx < _questions.length - 1
                                        ? 'Next Question'
                                        : 'Start Over',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOption(String text, int idx, Color color) {
    final selected = _voted && _choice == idx;
    final notSelected = _voted && _choice != idx;
    return GestureDetector(
      onTap: () => _vote(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? color.withValues(alpha: 0.12)
              : notSelected
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: selected
                ? color
                : notSelected
                    ? Colors.white12
                    : color.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: selected ? 0.2 : 0.08),
                border: Border.all(
                  color: color.withValues(alpha: selected ? 0.6 : 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  idx == 0 ? 'A' : 'B',
                  style: GoogleFonts.outfit(
                    color: selected ? color : color.withValues(alpha: 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  color: selected
                      ? Colors.white
                      : notSelected
                          ? Colors.white38
                          : Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




