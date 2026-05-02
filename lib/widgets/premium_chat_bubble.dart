import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/models/chat_message.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM CHAT BUBBLE — Optimized & Polished
/// ═══════════════════════════════════════════════════════════════════════════

class PremiumChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;
  final double fontSize;
  final VoidCallback? onLongPress;
  final VoidCallback? onReact;
  final bool isSelected;

  const PremiumChatBubble({
    super.key,
    required this.message,
    this.showTimestamp = false,
    this.fontSize = 14,
    this.onLongPress,
    this.onReact,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final isUser = message.role == 'user';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isUser ? 56 : 12,
        3,
        isUser ? 12 : 56,
        3,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [tokens.panelElevated, tokens.panel],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : isUser
                        ? null
                        : Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                            top: BorderSide(color: tokens.outline, width: 0.5),
                            right: BorderSide(color: tokens.outline, width: 0.5),
                            bottom: BorderSide(color: tokens.outline, width: 0.5),
                          ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFFFF4081).withValues(alpha: 0.35)
                        : theme.colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: isUser ? 16 : 10,
                    offset: const Offset(0, 4),
                    spreadRadius: isUser ? -2 : -3,
                  ),
                  if (!isUser)
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(-2, 0),
                      spreadRadius: 0,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.imageUrl != null ||
                              message.imagePath != null)
                            _buildImage(context),
                          if (message.content.isNotEmpty)
                            SelectableText(
                              message.content,
                              style: GoogleFonts.outfit(
                                color: isUser
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (message.reaction != null)
                      Container(
                        margin: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          bottom: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.2)
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.reaction!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: GoogleFonts.outfit(
                  color: tokens.textSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final imageUrl = message.imageUrl;
    final imagePath = message.imagePath;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(
        maxWidth: 280,
        maxHeight: 280,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Icon(Icons.error_outline, color: Colors.white54),
                ),
              )
            : imagePath != null
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Icon(Icons.error_outline,
                          color: Colors.white54),
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class PremiumTypingIndicator extends StatefulWidget {
  const PremiumTypingIndicator({super.key});

  @override
  State<PremiumTypingIndicator> createState() => _PremiumTypingIndicatorState();
}

class _PremiumTypingIndicatorState extends State<PremiumTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 60, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tokens.panelElevated,
              tokens.panel,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: tokens.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final value = (_controller.value - delay).clamp(0.0, 1.0);
                final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2);

                return Container(
                  margin: EdgeInsets.only(left: index > 0 ? 6 : 0),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        tokens.textMuted.withValues(alpha: 0.3 + opacity * 0.7),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class QuickReplyChips extends StatelessWidget {
  final List<String> replies;
  final Function(String) onReplyTap;

  const QuickReplyChips({
    super.key,
    required this.replies,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (replies.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: replies.map((reply) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onReplyTap(reply),
              borderRadius: BorderRadius.circular(20),
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  reply,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
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
}
