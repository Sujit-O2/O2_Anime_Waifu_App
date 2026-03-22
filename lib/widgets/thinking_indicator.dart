import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Glass shimmer "Thinking..." indicator with high-gloss linear shimmer.
class ThinkingIndicator extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;

  const ThinkingIndicator({
    super.key,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlightColor.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Shimmer.fromColors(
            baseColor: baseColor.withValues(alpha: 0.5),
            highlightColor: highlightColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: highlightColor),
                const SizedBox(width: 8),
                Text(
                  'Zero Two is thinking...',
                  style: TextStyle(
                    color: highlightColor,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
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
