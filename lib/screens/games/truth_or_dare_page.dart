import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/ai_content_service.dart';

class TruthOrDarePage extends StatefulWidget {
  const TruthOrDarePage({super.key});

  @override
  State<TruthOrDarePage> createState() => _TruthOrDarePageState();
}

class _TruthOrDarePageState extends State<TruthOrDarePage>
    with SingleTickerProviderStateMixin {
  List<String> _truths = <String>[];
  List<String> _dares = <String>[];
  bool _loading = true;
  String? _card;
  bool _isTruth = true;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  final Random _rng = Random();
  int _truthPulls = 0;
  int _darePulls = 0;

  String get _commentaryMood {
    if ((_truthPulls + _darePulls) >= 6) {
      return 'achievement';
    }
    if (_card != null) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeOut),
    );
    _load();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await AiContentService.getTruthOrDare();
      if (mounted) {
        setState(() {
          _truths = data['truths'] ?? <String>[];
          _dares = data['dares'] ?? <String>[];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() => _load();

  void _draw(bool truth) {
    if (truth && _truths.isEmpty) {
      return;
    }
    if (!truth && _dares.isEmpty) {
      return;
    }
    HapticFeedback.mediumImpact();
    _flipCtrl.forward(from: 0);
    setState(() {
      _isTruth = truth;
      _card = truth
          ? _truths[_rng.nextInt(_truths.length)]
          : _dares[_rng.nextInt(_dares.length)];
      if (truth) {
        _truthPulls++;
      } else {
        _darePulls++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.10,
        tint: const Color(0xFF0B0A10),
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
                                  'TRUTH OR DARE',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  '${_truths.length} truths • ${_dares.length} dares ready',
                                  style: GoogleFonts.outfit(
                                    color: Colors.purpleAccent
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
                                    'Deck overview',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _card == null
                                        ? 'Pick a side to start'
                                        : (_isTruth
                                            ? 'Truth card live'
                                            : 'Dare card live'),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Jump between honest questions and bold dares, then keep cycling for a fresh card mix.',
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
                                  (_truthPulls + _darePulls).clamp(0, 10) / 10,
                              foreground: V2Theme.primaryColor,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.casino_rounded,
                                    color: V2Theme.primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_truthPulls + _darePulls}',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Draws',
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
                              title: 'Truth',
                              value: '$_truthPulls',
                              icon: Icons.psychology_alt_rounded,
                              color: V2Theme.secondaryColor,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Dare',
                              value: '$_darePulls',
                              icon: Icons.flash_on_rounded,
                              color: V2Theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Truth Deck',
                              value: '${_truths.length}',
                              icon: Icons.library_books_rounded,
                              color: Colors.amberAccent,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Dare Deck',
                              value: '${_dares.length}',
                              icon: Icons.auto_awesome_rounded,
                              color: Colors.lightGreenAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_card != null)
                        AnimatedBuilder(
                          animation: _flipAnim,
                          builder: (ctx, _) => Opacity(
                            opacity: _flipAnim.value,
                            child: GlassCard(
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.all(28),
                              glow: true,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: (_isTruth
                                              ? V2Theme.secondaryColor
                                              : V2Theme.primaryColor)
                                          .withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: (_isTruth
                                                ? V2Theme.secondaryColor
                                                : V2Theme.primaryColor)
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      _isTruth ? 'TRUTH' : 'DARE',
                                      style: GoogleFonts.outfit(
                                        color: _isTruth
                                            ? V2Theme.secondaryColor
                                            : V2Theme.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _card!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.7,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        const EmptyState(
                          icon: Icons.style_outlined,
                          title: 'Pick your first card',
                          subtitle:
                              'Choose truth for honesty or dare for chaos and the first prompt will appear here.',
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _choiceButton(
                              label: 'Truth',
                              icon: Icons.psychology_alt_rounded,
                              color: V2Theme.secondaryColor,
                              onTap: () => _draw(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _choiceButton(
                              label: 'Dare',
                              icon: Icons.flash_on_rounded,
                              color: V2Theme.primaryColor,
                              onTap: () => _draw(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _choiceButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




