import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/ai_content_service.dart';


class FortuneCookiePage extends StatefulWidget {
  const FortuneCookiePage({super.key});

  @override
  State<FortuneCookiePage> createState() => _FortuneCookiePageState();
}

class _FortuneCookiePageState extends State<FortuneCookiePage>
    with SingleTickerProviderStateMixin {
  List<String> _fortunes = <String>[];
  String? _fortune;
  bool _cracked = false;
  bool _loading = true;
  late AnimationController _crackCtrl;
  late Animation<double> _scaleAnim;
  final List<String> _history = <String>[];

  String get _commentaryMood {
    if (_history.length >= 5) {
      return 'achievement';
    }
    if (_fortune != null) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _crackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _crackCtrl, curve: Curves.elasticOut),
    );
    _loadFortunes();
  }

  @override
  void dispose() {
    _crackCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFortunes() async {
    try {
      final list = await AiContentService.getFortunes();
      if (mounted) {
        setState(() {
          _fortunes = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _crackCookie() {
    if (_fortunes.isEmpty) {
      return;
    }
    HapticFeedback.mediumImpact();
    final fortune =
        _fortunes[DateTime.now().millisecondsSinceEpoch % _fortunes.length];
    _crackCtrl.forward(from: 0);
    setState(() {
      _fortune = fortune;
      _cracked = true;
      if (_history.length > 9) {
        _history.removeAt(0);
      }
      _history.add(fortune);
    });
  }

  void _copyFortune() {
    final fortune = _fortune;
    if (fortune == null) {
      return;
    }
    Clipboard.setData(ClipboardData(text: fortune));
    showSuccessSnackbar(context, 'Fortune copied.');
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'FORTUNE COOKIE',
      subtitle: _fortune == null
          ? 'Crack the cookie for your next sign'
          : 'Tap again whenever you want a new fortune',
      onBack: () => Navigator.pop(context),
      actions: [
        if (_fortune != null)
          IconButton(
            onPressed: _copyFortune,
            icon: const Icon(
              Icons.copy_outlined,
              color: Colors.amberAccent,
            ),
          ),
      ],
      content: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
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
                                  'Fortune stream',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _fortune == null
                                      ? 'Your next message is still sealed'
                                      : 'A new fortune has been revealed',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _history.isEmpty
                                      ? 'Start cracking to build a tiny archive of fortunes and signs.'
                                      : 'You have opened ${_history.length} cookies this session and kept the recent messages below.',
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
                            progress: (_history.length.clamp(0, 10)) / 10,
                            foreground: Colors.amberAccent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cookie_outlined,
                                  color: Colors.amberAccent,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_history.length}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Opened',
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
                            title: 'Loaded',
                            value: '${_fortunes.length}',
                            icon: Icons.menu_book_rounded,
                            color: Colors.amberAccent,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'History',
                            value: '${_history.length}',
                            icon: Icons.history_rounded,
                            color: V2Theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Status',
                            value: _cracked ? 'Open' : 'Sealed',
                            icon: Icons.mark_chat_read_outlined,
                            color: V2Theme.secondaryColor,
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: 'Copy',
                            value: _fortune == null ? 'Locked' : 'Ready',
                            icon: Icons.copy_all_rounded,
                            color: Colors.lightGreenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _scaleAnim,
                            child: GestureDetector(
                              onTap: _crackCookie,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.amberAccent.withValues(alpha: 0.2),
                                      Colors.orange.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.amberAccent
                                        .withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amberAccent
                                          .withValues(alpha: 0.15),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _cracked ? '🥠' : '🍪',
                                    style: const TextStyle(fontSize: 64),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _cracked
                                ? 'Tap for another fortune'
                                : 'Tap the cookie',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_fortune != null)
                      GlassCard(
                        margin: EdgeInsets.zero,
                        child: Text(
                          '"$_fortune"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            height: 1.7,
                          ),
                        ),
                      ),
                    if (_history.length > 1) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Fortunes',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._history.reversed.skip(1).take(3).map(
                                  (fortune) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• $fortune',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                    if (_fortunes.isEmpty) ...[
                      const SizedBox(height: 16),
                      const EmptyState(
                        icon: Icons.cookie_outlined,
                        title: 'No fortunes loaded',
                        subtitle:
                            'The fortune feed is empty right now. Try opening this page again in a moment.',
                      ),
                    ],
              ],
            ),
    );
  }
}




