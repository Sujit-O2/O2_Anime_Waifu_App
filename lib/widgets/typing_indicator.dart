import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 💬 Typing Indicator Widget
/// 
/// Shows "Zero Two is thinking..." with animated dots for natural conversation flow.
/// Includes mood-aware variations and smooth animations.
class TypingIndicator extends StatefulWidget {
  final String? customText;
  final Color? color;
  final double size;
  final bool showAvatar;
  final String? avatarUrl;

  const TypingIndicator({
    super.key,
    this.customText,
    this.color,
    this.size = 12.0,
    this.showAvatar = true,
    this.avatarUrl,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    // Staggered animations for each dot
    _dot1 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 50,
      ),
    ]).animate(_controller);

    _dot2 = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 16.67,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 33.33,
      ),
    ]).animate(_controller);

    _dot3 = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 33.33,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 16.67,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = widget.color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.showAvatar) ...[
            _buildAvatar(theme),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.customText != null) ...[
                    Flexible(
                      child: Text(
                        widget.customText!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, _dot1.value),
                            child: _buildDot(dotColor),
                          ),
                          const SizedBox(width: 4),
                          Transform.translate(
                            offset: Offset(0, _dot2.value),
                            child: _buildDot(dotColor),
                          ),
                          const SizedBox(width: 4),
                          Transform.translate(
                            offset: Offset(0, _dot3.value),
                            child: _buildDot(dotColor),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: widget.avatarUrl != null
            ? Image.asset(
                widget.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(theme),
              )
            : _buildDefaultAvatar(theme),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        size: 20,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}

/// Compact typing indicator for inline use
class CompactTypingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const CompactTypingIndicator({
    super.key,
    this.color,
    this.size = 8.0,
  });

  @override
  State<CompactTypingIndicator> createState() => _CompactTypingIndicatorState();
}

class _CompactTypingIndicatorState extends State<CompactTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final opacity = (math.sin((_controller.value * 2 * math.pi) - delay) + 1) / 2;
            
            return Padding(
              padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
              child: Opacity(
                opacity: 0.3 + (opacity * 0.7),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Mood-aware typing indicator with contextual messages
class MoodAwareTypingIndicator extends StatelessWidget {
  final String mood;
  final bool showAvatar;
  final String? avatarUrl;

  const MoodAwareTypingIndicator({
    super.key,
    required this.mood,
    this.showAvatar = true,
    this.avatarUrl,
  });

  String _getTypingText(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
        return 'Thinking of something fun~';
      case 'sad':
      case 'melancholy':
        return 'Choosing my words carefully...';
      case 'loving':
      case 'affectionate':
        return 'Thinking about you, darling~';
      case 'playful':
      case 'teasing':
        return 'Hmm, what should I say...';
      case 'serious':
      case 'focused':
        return 'Processing your request...';
      case 'sleepy':
      case 'tired':
        return 'Thinking... *yawn*';
      default:
        return 'Zero Two is thinking...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TypingIndicator(
      customText: _getTypingText(mood),
      showAvatar: showAvatar,
      avatarUrl: avatarUrl,
    );
  }
}
