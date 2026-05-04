// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM CHAT INPUT BAR — v10.0.2
/// Glassmorphism design with frosted blur, neon glow border, morphing button
/// ═══════════════════════════════════════════════════════════════════════════

class PremiumChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;
  final VoidCallback onMicTap;
  final VoidCallback? onImagePick;
  final VoidCallback? onSurpriseMe;
  final VoidCallback? onAssistantOverlay;
  final bool hasImage;
  final bool isListening;
  final bool isThinking;
  final List<String> smartReplies;
  final Function(String)? onSmartReply;
  final Color? accentColor;

  const PremiumChatInputBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onSend,
    required this.onMicTap,
    this.onImagePick,
    this.onSurpriseMe,
    this.onAssistantOverlay,
    this.hasImage = false,
    this.isListening = false,
    this.isThinking = false,
    this.smartReplies = const [],
    this.onSmartReply,
    this.accentColor,
  });

  @override
  State<PremiumChatInputBar> createState() => _PremiumChatInputBarState();
}

class _PremiumChatInputBarState extends State<PremiumChatInputBar>
    with TickerProviderStateMixin {
  late AnimationController _sendMorphCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _chipCtrl;
  late AnimationController _glowCtrl;

  late Animation<double> _sendMorph;
  late Animation<double> _chipSlide;
  late Animation<double> _glowAnim;

  bool _hasText = false;
  bool _showChips = false;
  final List<double> _waveBars = List.generate(16, (_) => 0.2);
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    _sendMorphCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100))
      ..addListener(_updateWave);
    _chipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _sendMorph =
        CurvedAnimation(parent: _sendMorphCtrl, curve: Curves.easeInOut);
    _chipSlide =
        CurvedAnimation(parent: _chipCtrl, curve: Curves.easeOutBack);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    widget.controller.addListener(_onTextChanged);

    if (widget.smartReplies.isNotEmpty || widget.onSurpriseMe != null) {
      _showChips = true;
      _chipCtrl.forward();
    }
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendMorphCtrl.forward();
        HapticFeedback.selectionClick();
      } else {
        _sendMorphCtrl.reverse();
      }
    }
  }

  void _updateWave() {
    if (!widget.isListening) return;
    setState(() {
      for (int i = 0; i < _waveBars.length; i++) {
        _waveBars[i] = 0.1 + _random.nextDouble() * 0.9;
      }
    });
  }

  @override
  void didUpdateWidget(PremiumChatInputBar old) {
    super.didUpdateWidget(old);

    if (widget.isListening && !old.isListening) {
      _waveCtrl.repeat();
    } else if (!widget.isListening && old.isListening) {
      _waveCtrl.stop();
      setState(() {
        for (int i = 0; i < _waveBars.length; i++) _waveBars[i] = 0.2;
      });
    }

    final hasReplies =
        widget.smartReplies.isNotEmpty || widget.onSurpriseMe != null;
    final hadReplies =
        old.smartReplies.isNotEmpty || old.onSurpriseMe != null;

    if (hasReplies && !hadReplies) {
      _showChips = true;
      _chipCtrl.forward(from: 0);
    } else if (!hasReplies && hadReplies) {
      _chipCtrl.reverse().then((_) => setState(() => _showChips = false));
    } else if (widget.smartReplies != old.smartReplies && hasReplies) {
      _chipCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _sendMorphCtrl.dispose();
    _waveCtrl.dispose();
    _chipCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (!_hasText) return;
    HapticFeedback.mediumImpact();
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? const Color(0xFFFF0057);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showChips) _buildChips(accent),
          _buildGlassBar(accent),
        ],
      ),
    );
  }

  Widget _buildGlassBar(Color accent) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        final glowOpacity =
            widget.isListening ? _glowAnim.value : (_hasText ? 0.45 : 0.2);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: glowOpacity * 0.5),
                blurRadius: 20,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: const Color(0xFF6C00FF).withValues(alpha: glowOpacity * 0.3),
                blurRadius: 30,
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: widget.isListening
                        ? accent.withValues(alpha: 0.8)
                        : accent.withValues(alpha: glowOpacity * 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 4),
                    if (widget.onImagePick != null) _buildImageButton(accent),
                    Expanded(
                      child: widget.isListening
                          ? _buildWaveform(accent)
                          : _buildTextField(),
                    ),
                    _buildActionButton(accent),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageButton(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onImagePick!();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.hasImage
                ? accent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: widget.hasImage
                  ? accent.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Icon(
            widget.hasImage
                ? Icons.image_rounded
                : Icons.add_photo_alternate_outlined,
            color: widget.hasImage
                ? accent
                : Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: 5,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      style: GoogleFonts.outfit(
        fontSize: 15,
        height: 1.5,
        color: Colors.white.withValues(alpha: 0.92),
        fontWeight: FontWeight.w400,
      ),
      cursorColor: widget.accentColor ?? const Color(0xFFFF0057),
      cursorWidth: 2,
      cursorRadius: const Radius.circular(4),
      decoration: InputDecoration(
        hintText: widget.isThinking
            ? 'Zero Two is thinking...'
            : 'Message Zero Two...',
        hintStyle: GoogleFonts.outfit(
          color: Colors.white.withValues(alpha: 0.28),
          fontSize: 14.5,
          fontStyle:
              widget.isThinking ? FontStyle.italic : FontStyle.normal,
          fontWeight: FontWeight.w300,
        ),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildWaveform(Color accent) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_waveBars.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 3,
              height: 4 + _waveBars[i] * 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [accent, accent.withValues(alpha: 0.3)],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActionButton(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: AnimatedBuilder(
        animation: _sendMorph,
        builder: (_, __) {
          final isSend = _sendMorph.value > 0.5;
          return GestureDetector(
            onTap: isSend ? _handleSend : () {
              HapticFeedback.heavyImpact();
              widget.onMicTap();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isListening
                      ? [accent, const Color(0xFF6C00FF)]
                      : isSend
                          ? [accent, const Color(0xFFFF6B9D)]
                          : [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.06),
                            ],
                ),
                border: Border.all(
                  color: (isSend || widget.isListening)
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: (isSend || widget.isListening)
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: -2,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: widget.isListening
                    ? const Icon(Icons.stop_rounded,
                        key: ValueKey('stop'),
                        color: Colors.white,
                        size: 20)
                    : isSend
                        ? const Icon(Icons.send_rounded,
                            key: ValueKey('send'),
                            color: Colors.white,
                            size: 18)
                        : Icon(Icons.mic_rounded,
                            key: const ValueKey('mic'),
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChips(Color accent) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_chipSlide),
      child: FadeTransition(
        opacity: _chipSlide,
        child: SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            children: [
              if (widget.onSurpriseMe != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SurpriseChip(onPressed: widget.onSurpriseMe!),
                ),
              ...widget.smartReplies.map((reply) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSmartReply?.call(reply);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: accent.withValues(alpha: 0.12),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.35),
                                  width: 1),
                            ),
                            child: Text(
                              reply,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Surprise Chip ────────────────────────────────────────────────────────────
class _SurpriseChip extends StatefulWidget {
  final VoidCallback onPressed;
  const _SurpriseChip({required this.onPressed});

  @override
  State<_SurpriseChip> createState() => _SurpriseChipState();
}

class _SurpriseChipState extends State<_SurpriseChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 0.8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const p1 = Color(0xFFBB52FF);
    const p2 = Color(0xFFFF4FA8);
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [p1, p2]),
                boxShadow: [
                  BoxShadow(
                    color: p1.withValues(alpha: _glow.value * 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'Surprise Me',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Thinking Indicator ───────────────────────────────────────────────────────
class ThinkingIndicator extends StatefulWidget {
  final Color color;
  final String label;

  const ThinkingIndicator({
    super.key,
    this.color = const Color(0xFFFF0057),
    this.label = 'Zero Two is thinking',
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 600))
        ..repeat(reverse: true);
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) ctrl.forward();
      });
      _ctrls.add(ctrl);
      _anims.add(Tween<double>(begin: 0, end: -6).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeInOut)));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: widget.color.withValues(alpha: 0.7),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
