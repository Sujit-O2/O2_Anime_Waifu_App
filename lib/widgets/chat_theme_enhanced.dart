import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ENHANCED CHAT THEME - Optimized Visual Design
/// ═══════════════════════════════════════════════════════════════════════════

class EnhancedChatTheme {
  /// Premium Chat Bubble with Glassmorphism & Gradient Effects
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
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isUser ? 50 : 16,
          6,
          isUser ? 16 : 50,
          6,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Animated Bubble Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.9),
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          tokens.panelElevated,
                          tokens.panel.withValues(alpha: 0.95),
                        ],
                      ),
                borderRadius: _getBubbleRadius(isUser),
                border: isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: isUser
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : tokens.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: _getBubbleRadius(isUser),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
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
                          fontWeight:
                              isUser ? FontWeight.w600 : FontWeight.w500,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (reaction != null && reaction.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              reaction,
                              style: TextStyle(
                                fontSize: 16,
                                color: isUser
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (showTimestamp && timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  _formatTime(timestamp),
                  style: GoogleFonts.outfit(
                    color: tokens.textSoft.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Quick Reply Chips with Enhanced Animation
  static Widget quickReplyChips({
    required BuildContext context,
    required List<String> replies,
    required Function(String) onTap,
  }) {
    if (replies.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: replies.map((reply) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onTap(reply),
              borderRadius: BorderRadius.circular(24),
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.primary.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  reply,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Typing Indicator with Smooth Animation
  static Widget typingIndicator(BuildContext context) {
    final tokens = context.appTokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 60, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tokens.panelElevated,
              tokens.panel,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(24),
          ),
          border: Border.all(color: tokens.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TypingDot(isActive: true),
            const SizedBox(width: 6),
            const _TypingDot(isActive: false, delay: 150),
            const SizedBox(width: 6),
            const _TypingDot(isActive: false, delay: 300),
            const SizedBox(width: 12),
            Text(
              'Zero Two is typing...',
              style: GoogleFonts.outfit(
                color: tokens.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BorderRadius _getBubbleRadius(bool isUser) {
    return BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: Radius.circular(isUser ? 24 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 24),
    );
  }

  static String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (msgDate == today) {
      return 'Today at ${_formatHour(timestamp)}';
    } else if (msgDate == yesterday) {
      return 'Yesterday at ${_formatHour(timestamp)}';
    } else {
      return '${timestamp.day}/${timestamp.month} at ${_formatHour(timestamp)}';
    }
  }

  static String _formatHour(DateTime time) {
    final hour = time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour < 12 ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $ampm';
  }
}

class _TypingDot extends StatefulWidget {
  final bool isActive;
  final int delay;

  const _TypingDot({required this.isActive, this.delay = 0});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tokens.textMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
