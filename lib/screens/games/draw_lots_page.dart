import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class DrawLotsPage extends StatefulWidget {
  const DrawLotsPage({super.key});

  @override
  State<DrawLotsPage> createState() => _DrawLotsPageState();
}

class _DrawLotsPageState extends State<DrawLotsPage>
    with SingleTickerProviderStateMixin {
  final List<String> _options = <String>['Option 1', 'Option 2', 'Option 3'];
  final TextEditingController _textCtrl = TextEditingController();
  final Random _rng = Random();

  String? _result;
  bool _drawing = false;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  String get _commentaryMood {
    if (_result != null) {
      return 'achievement';
    }
    if (_options.length >= 4) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );
    _shakeCtrl.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        final int idx = _rng.nextInt(_options.length);
        setState(() {
          _result = _options[idx];
          _drawing = false;
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _draw() {
    if (_options.isEmpty || _drawing) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _drawing = true;
      _result = null;
    });
    _shakeCtrl.forward(from: 0);
  }

  void _addOption() {
    final String text = _textCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _options.add(text));
    _textCtrl.clear();
  }

  void _removeOption(int index) {
    if (_options.length <= 2) {
      return;
    }
    final String removed = _options[index];
    setState(() => _options.removeAt(index));
    showUndoSnackbar(
      context,
      'Option removed.',
      () => setState(() => _options.insert(index, removed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: ListView(
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
                  child: Text(
                    'DRAW LOTS',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
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
                          'Decision helper',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _result ?? 'Ready to draw',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add choices below and let the draw decide the winner.',
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
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) {
                      final double angle = _drawing
                          ? sin(_shakeAnim.value * 4 * pi) * 0.1
                          : 0;
                      return Transform.rotate(angle: angle, child: child);
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: V2Theme.primaryColor.withValues(alpha: 0.18),
                      ),
                      child: const Icon(
                        Icons.shuffle_rounded,
                        color: V2Theme.primaryColor,
                        size: 30,
                      ),
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
                    title: 'Choices',
                    value: '${_options.length}',
                    icon: Icons.list_alt_rounded,
                    color: V2Theme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Status',
                    value: _drawing ? 'Drawing' : 'Ready',
                    icon: Icons.flash_on_rounded,
                    color: V2Theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _drawing ? null : _draw,
              style: FilledButton.styleFrom(
                backgroundColor: V2Theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(_drawing ? 'Drawing' : 'Draw a Lot'),
            ),
            const SizedBox(height: 14),
            GlassCard(
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      style: GoogleFonts.outfit(color: Colors.white),
                      cursorColor: V2Theme.primaryColor,
                      decoration: InputDecoration(
                        hintText: 'Add option',
                        hintStyle: GoogleFonts.outfit(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _addOption(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addOption,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          V2Theme.secondaryColor.withValues(alpha: 0.2),
                      foregroundColor: V2Theme.secondaryColor,
                    ),
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_options.isEmpty)
              const EmptyState(
                icon: Icons.playlist_add_rounded,
                title: 'No options yet',
                subtitle: 'Add at least two options to start drawing.',
              )
            else
              ..._options.asMap().entries.map(
                (entry) => SwipeToDismissItem(
                  onDismissed: () => _removeOption(entry.key),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      entry.value,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



