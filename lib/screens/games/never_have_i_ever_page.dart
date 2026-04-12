import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/ai_content_service.dart';

class NeverHaveIEverPage extends StatefulWidget {
  const NeverHaveIEverPage({super.key});

  @override
  State<NeverHaveIEverPage> createState() => _NeverHaveIEverPageState();
}

class _NeverHaveIEverPageState extends State<NeverHaveIEverPage>
    with SingleTickerProviderStateMixin {
  List<String> _prompts = <String>[];
  bool _loading = true;
  int _idx = 0;
  bool _answered = false;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  int _haveCount = 0;
  int _haventCount = 0;

  String get _commentaryMood {
    if ((_haveCount + _haventCount) >= 6) {
      return 'achievement';
    }
    if (_answered) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
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
      final list = await AiContentService.getNeverHaveIEver();
      if (mounted) {
        setState(() {
          _prompts = list;
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

  void _respond(bool have) {
    if (_answered) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _answered = true;
      if (have) {
        _haveCount++;
      } else {
        _haventCount++;
      }
    });
  }

  void _next() {
    if (_prompts.isEmpty) {
      return;
    }
    _slideCtrl.reset();
    setState(() {
      _idx = (_idx + 1) % _prompts.length;
      _answered = false;
    });
    _slideCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.10,
        tint: const Color(0xFF0A0A14),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepOrangeAccent,
                  ),
                )
              : ListView(
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
                                'NEVER HAVE I EVER',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                _prompts.isEmpty
                                    ? 'Prompt deck unavailable'
                                    : 'Card ${_idx + 1} of ${_prompts.length}',
                                style: GoogleFonts.outfit(
                                  color: Colors.deepOrangeAccent
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
                                  'Session pulse',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _answered
                                      ? 'Choice locked in for this card'
                                      : 'Pick your answer and keep going',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Track how many prompts land on "I have" versus "I haven\'t" as the deck rolls forward.',
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
                            progress:
                                (_haveCount + _haventCount).clamp(0, 10) / 10,
                            foreground: Colors.deepOrangeAccent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.forum_rounded,
                                  color: Colors.deepOrangeAccent,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_haveCount + _haventCount}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Answered',
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
                            title: 'I Have',
                            value: '$_haveCount',
                            icon: Icons.favorite_rounded,
                            color: V2Theme.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: "I Haven't",
                            value: '$_haventCount',
                            icon: Icons.do_not_disturb_alt_rounded,
                            color: V2Theme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Deck',
                            value: '${_prompts.length}',
                            icon: Icons.view_carousel_rounded,
                            color: Colors.amberAccent,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Card',
                            value: _prompts.isEmpty ? '--' : '${_idx + 1}',
                            icon: Icons.style_rounded,
                            color: Colors.lightGreenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_prompts.isEmpty)
                      const EmptyState(
                        icon: Icons.question_answer_outlined,
                        title: 'Could not load prompts',
                        subtitle:
                            'The prompt deck is empty right now. Try reopening this page later.',
                      )
                    else
                      SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          children: [
                            GlassCard(
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                children: [
                                  const Text(
                                    '🎲',
                                    style: TextStyle(fontSize: 42),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _prompts[_idx],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      height: 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (!_answered)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _responseBtn(
                                    'I have',
                                    V2Theme.primaryColor,
                                    () => _respond(true),
                                  ),
                                  const SizedBox(width: 16),
                                  _responseBtn(
                                    'I haven\'t',
                                    V2Theme.secondaryColor,
                                    () => _respond(false),
                                  ),
                                ],
                              )
                            else ...[
                              Text(
                                'Tap next when you are ready for another card.',
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _next,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.deepOrangeAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Next Card'),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _responseBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}




