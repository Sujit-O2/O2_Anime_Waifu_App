import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ENHANCED CHAT THEME — v2 Premium Bubbles & Micro-interactions
/// ═══════════════════════════════════════════════════════════════════════════

class EnhancedChatTheme {
  /// Premium Chat Bubble with Glassmorphism, Gradient & Entrance Animation
  static Widget premiumBubble({
    required BuildContext context,
    required String text,
    required bool isUser,
    bool showTimestamp = false,
    DateTime? timestamp,
    String? reaction,
    bool isSelected = false,
    VoidCallback? onLongPress,
  }) {
    return _AnimatedBubble(
      text: text,
      isUser: isUser,
      showTimestamp: showTimestamp,
      timestamp: timestamp,
      reaction: reaction,
      isSelected: isSelected,
      onLongPress: onLongPress,
    );
  }

  /// Quick Reply Chips with Staggered Entrance Animation
  static Widget quickReplyChips({
    required BuildContext context,
    required List<String> replies,
    required Function(String) onTap,
  }) {
    if (replies.isEmpty) return const SizedBox.shrink();

    return _QuickReplyChips(replies: replies, onTap: onTap);
  }

  /// Typing Indicator with Smooth Bounce Animation
  static Widget typingIndicator(BuildContext context) {
    return const _TypingIndicator();
  }

  static BorderRadius getBubbleRadius(bool isUser) {
    return BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(isUser ? 22 : 5),
      bottomRight: Radius.circular(isUser ? 5 : 22),
    );
  }

  static String formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (msgDate == today) {
      return 'Today ${_formatHour(timestamp)}';
    } else if (msgDate == yesterday) {
      return 'Yesterday ${_formatHour(timestamp)}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${_formatHour(timestamp)}';
    }
  }

  static String _formatHour(DateTime time) {
    final hour = time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour < 12 ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $ampm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final bool showTimestamp;
  final DateTime? timestamp;
  final String? reaction;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const _AnimatedBubble({
    required this.text,
    required this.isUser,
    this.showTimestamp = false,
    this.timestamp,
    this.reaction,
    this.isSelected = false,
    this.onLongPress,
  });

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.08 : -0.08, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          alignment: widget.isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onLongPress?.call();
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                widget.isUser ? 52 : 14,
                5,
                widget.isUser ? 14 : 52,
                5,
              ),
              child: Column(
                crossAxisAlignment: widget.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _BubbleContainer(
                    text: widget.text,
                    isUser: widget.isUser,
                    isSelected: widget.isSelected,
                    reaction: widget.reaction,
                    theme: theme,
                    tokens: tokens,
                  ),
                  if (widget.showTimestamp && widget.timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                      child: Text(
                        EnhancedChatTheme.formatTime(widget.timestamp!),
                        style: GoogleFonts.outfit(
                          color: tokens.textSoft.withValues(alpha: 0.55),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
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

class _BubbleContainer extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isSelected;
  final String? reaction;
  final ThemeData theme;
  final AppDesignTokens tokens;

  const _BubbleContainer({
    required this.text,
    required this.isUser,
    required this.isSelected,
    this.reaction,
    required this.theme,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final radius = EnhancedChatTheme.getBubbleRadius(isUser);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  Color.lerp(
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                    0.3,
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  tokens.panelElevated,
                  tokens.panel.withValues(alpha: 0.92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: radius,
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : Border.all(
                color: isUser
                    ? theme.colorScheme.primary.withValues(alpha: 0.0)
                    : tokens.outline.withValues(alpha: 0.5),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? theme.colorScheme.primary.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: isUser
              ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
              : ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    color: isUser
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                    height: 1.55,
                    letterSpacing: 0.15,
                  ),
                ),
                if (reaction != null && reaction!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _ReactionChip(
                      reaction: reaction!,
                      isUser: isUser,
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String reaction;
  final bool isUser;
  final ThemeData theme;

  const _ReactionChip({
    required this.reaction,
    required this.isUser,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.2)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser
              ? Colors.white.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        reaction,
        style: TextStyle(
          fontSize: 15,
          color: isUser ? Colors.white : theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Reply Chips
// ─────────────────────────────────────────────────────────────────────────────

class _QuickReplyChips extends StatefulWidget {
  final List<String> replies;
  final Function(String) onTap;

  const _QuickReplyChips({required this.replies, required this.onTap});

  @override
  State<_QuickReplyChips> createState() => _QuickReplyChipsState();
}

class _QuickReplyChipsState extends State<_QuickReplyChips>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(widget.replies.length, (i) {
          final delay = i * 0.12;
          final anim = CurvedAnimation(
            parent: _ctrl,
            curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
                curve: Curves.easeOutBack),
          );
          return ScaleTransition(
            scale: anim,
            child: FadeTransition(
              opacity: anim,
              child: _QuickReplyChip(
                text: widget.replies[i],
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onTap(widget.replies[i]);
                },
                theme: theme,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _QuickReplyChip extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final ThemeData theme;

  const _QuickReplyChip({
    required this.text,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_QuickReplyChip> createState() => _QuickReplyChipState();
}

class _QuickReplyChipState extends State<_QuickReplyChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: _pressed ? 0.2 : 0.1),
                theme.colorScheme.primary.withValues(alpha: _pressed ? 0.08 : 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.primary
                  .withValues(alpha: _pressed ? 0.5 : 0.3),
              width: 1.5,
            ),
            boxShadow: _pressed
                ? null
                : [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            widget.text,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 5, 60, 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tokens.panelElevated,
                tokens.panel.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(22),
            ),
            border: Border.all(
              color: tokens.outline.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BouncingDot(color: theme.colorScheme.primary, delay: 0),
              const SizedBox(width: 5),
              _BouncingDot(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  delay: 150),
              const SizedBox(width: 5),
              _BouncingDot(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  delay: 300),
              const SizedBox(width: 12),
              Text(
                'Zero Two is thinking...',
                style: GoogleFonts.outfit(
                  color: tokens.textMuted,
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BouncingDot extends StatefulWidget {
  final Color color;
  final int delay;

  const _BouncingDot({required this.color, required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bounceAnim = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _bounceAnim.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
