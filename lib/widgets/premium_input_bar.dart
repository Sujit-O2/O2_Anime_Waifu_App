// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM CHAT INPUT BAR — v10.0.2
/// Ultra-smooth input with:
/// • Morphing mic ↔ send button with spring animation
/// • Live voice waveform visualizer (16 bars)
/// • Smart reply suggestion chips with slide-in animation
/// • Emoji burst on send
/// • Haptic feedback on all interactions
/// • Adaptive height with smooth expand/collapse
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
  // Animations
  late AnimationController _sendMorphCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _chipCtrl;
  late AnimationController _sendBurstCtrl;

  late Animation<double> _sendMorph; // 0 = mic, 1 = send
  late Animation<double> _chipSlide;
  late Animation<double> _burstScale;

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
    _sendBurstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _sendMorph = CurvedAnimation(parent: _sendMorphCtrl, curve: Curves.easeInOut);
    _chipSlide = CurvedAnimation(parent: _chipCtrl, curve: Curves.easeOutBack);
    _burstScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _sendBurstCtrl, curve: Curves.easeOut));

    widget.controller.addListener(_onTextChanged);

    // Show chips if we have replies OR a surprise me callback
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
        for (int i = 0; i < _waveBars.length; i++) {
          _waveBars[i] = 0.2;
        }
      });
    }

    final hasReplies = widget.smartReplies.isNotEmpty || widget.onSurpriseMe != null;
    final hadReplies = old.smartReplies.isNotEmpty || old.onSurpriseMe != null;

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
    _sendBurstCtrl.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (!_hasText) return;
    HapticFeedback.mediumImpact();
    _sendBurstCtrl.forward(from: 0);
    widget.onSend();
  }

  void _handleMic() {
    HapticFeedback.heavyImpact();
    widget.onMicTap();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? const Color(0xFFFF0057);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Smart reply chips & Surprise Me
        if (_showChips) _buildChips(accent),
        // Main input row
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isDark
                ? theme.colorScheme.surface.withValues(alpha: 0.95)
                : theme.colorScheme.surface.withValues(alpha: 0.98),
            border: Border.all(
              color: widget.isListening
                  ? accent.withValues(alpha: 0.6)
                  : theme.colorScheme.outline.withValues(alpha: 0.25),
              width: widget.isListening ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: widget.isListening ? 0.15 : 0.06),
                blurRadius: 12,
                spreadRadius: -3,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 6),
              // Image Picker Button
              if (widget.onImagePick != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4, top: 8),
                  child: Stack(
                    children: [
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onImagePick!();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              widget.hasImage
                                  ? Icons.image
                                  : Icons.add_photo_alternate_outlined,
                              color: widget.hasImage
                                  ? accent
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      if (widget.hasImage)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            builder: (context, value, _) => Transform.scale(
                              scale: value,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: theme.colorScheme.surface,
                                      width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              // Waveform / text field
              Expanded(
                child: widget.isListening
                    ? _buildWaveform(accent)
                    : _buildTextField(theme),
              ),
              const SizedBox(width: 4),
              // Mic / Send button
              _buildActionButton(accent),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(ThemeData theme) {
    return ClipRect(
      child: TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: 5,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      style: GoogleFonts.outfit(
        fontSize: 15,
        height: 1.5,
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: widget.accentColor ?? theme.colorScheme.primary,
      cursorWidth: 2,
      cursorRadius: const Radius.circular(4),
      decoration: InputDecoration(
        hintText: widget.isThinking
            ? 'Zero Two is thinking...'
            : 'Message Zero Two...',
        hintStyle: GoogleFonts.outfit(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          fontSize: 14.5,
          fontStyle: widget.isThinking ? FontStyle.italic : FontStyle.normal,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
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
                  colors: [
                    accent,
                    accent.withValues(alpha: 0.4),
                  ],
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
      padding: const EdgeInsets.only(bottom: 6, right: 2),
      child: AnimatedBuilder(
        animation: Listenable.merge([_sendMorph, _burstScale]),
        builder: (_, __) {
          final isSend = _sendMorph.value > 0.5;
          return GestureDetector(
            onTap: isSend ? _handleSend : _handleMic,
            child: Transform.scale(
              scale: _sendBurstCtrl.isAnimating
                  ? _burstScale.value
                  : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isListening
                        ? [accent, accent.withValues(alpha: 0.7)]
                        : isSend
                            ? [accent, accent.withValues(alpha: 0.8)]
                            : [
                                accent.withValues(alpha: 0.15),
                                accent.withValues(alpha: 0.08)
                              ],
                  ),
                  boxShadow: (isSend || widget.isListening)
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: -2,
                          )
                        ]
                      : [],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: widget.isListening
                      ? const Icon(Icons.stop_rounded,
                          key: ValueKey('stop'),
                          color: Colors.white,
                          size: 22)
                      : isSend
                          ? const Icon(Icons.send_rounded,
                              key: ValueKey('send'),
                              color: Colors.white,
                              size: 20)
                          : Icon(Icons.mic_rounded,
                              key: const ValueKey('mic'),
                              color: accent,
                              size: 22),
                ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.05)],
                          ),
                          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Text(
                          reply,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
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

class _SurpriseChip extends StatefulWidget {
  final VoidCallback onPressed;
  const _SurpriseChip({required this.onPressed});

  @override
  State<_SurpriseChip> createState() => _SurpriseChipState();
}

class _SurpriseChipState extends State<_SurpriseChip> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 0.8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
        builder: (context, child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [p1, p2]),
            boxShadow: [
              BoxShadow(color: p1.withValues(alpha: _glow.value * 0.4), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
              SizedBox(width: 6),
              Text(
                'Surprise Me',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Thinking Indicator ───────────────────────────────────────────────────────
/// Animated "Zero Two is thinking..." with bouncing dots.
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
    for (final c in _ctrls) {
      c.dispose();
    }
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
