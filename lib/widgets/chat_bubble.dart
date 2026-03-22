import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:o2_waifu/models/chat_message.dart';
import 'package:o2_waifu/config/app_themes.dart';

/// Glassmorphism chat bubble with spring-dampened slide-in animation.
/// Max width 78% screen width for readability.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final AppThemeConfig themeConfig;

  const ChatBubble({
    super.key,
    required this.message,
    required this.themeConfig,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isInnerThought = message.isInnerThought;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.78),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isInnerThought
                      ? themeConfig.primaryColor.withValues(alpha: 0.1)
                      : isUser
                          ? themeConfig.chatBubbleUser.withValues(alpha: 0.7)
                          : themeConfig.chatBubbleAI.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: Border.all(
                    color: isInnerThought
                        ? themeConfig.primaryColor.withValues(alpha: 0.3)
                        : themeConfig.primaryColor.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isInnerThought)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'inner thought',
                          style: TextStyle(
                            color:
                                themeConfig.primaryColor.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: TextStyle(
                        color: themeConfig.textColor,
                        fontSize: isInnerThought ? 13 : 15,
                        fontStyle: isInnerThought
                            ? FontStyle.italic
                            : FontStyle.normal,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.mood != null) ...[
                          Text(
                            message.mood!,
                            style: TextStyle(
                              color: themeConfig.primaryColor
                                  .withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color:
                                themeConfig.textColor.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
