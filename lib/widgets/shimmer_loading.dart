import 'package:flutter/material.dart';

/// A premium shimmer loading effect widget.
/// Use instead of CircularProgressIndicator for a modern, polished feel.
///
/// ```dart
/// ShimmerLoading(
///   child: Column(children: [
///     ShimmerBox(height: 200),
///     SizedBox(height: 12),
///     ShimmerBox(height: 16, width: 200),
///   ]),
/// )
/// ```
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF1A1A2E),
    this.highlightColor = const Color(0xFF2A2A4E),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.baseColor,
            widget.highlightColor,
            widget.baseColor,
          ],
          stops: [
            (_animation.value - 0.3).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.3).clamp(0.0, 1.0),
          ],
          transform: GradientRotation(_animation.value * 0.5),
        ).createShader(bounds),
        child: child!,
      ),
      child: widget.child,
    );
  }
}

/// Individual shimmer placeholder box
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A complete card-shaped shimmer placeholder
class ShimmerCard extends StatelessWidget {
  final double height;
  
  const ShimmerCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(height: 14, width: 140),
            const SizedBox(height: 12),
            const ShimmerBox(height: 10),
            const SizedBox(height: 8),
            ShimmerBox(height: 10, width: MediaQuery.sizeOf(context).width * 0.6),
            const Spacer(),
            const Row(
              children: [
                ShimmerBox(height: 24, width: 24, borderRadius: 12),
                SizedBox(width: 8),
                ShimmerBox(height: 10, width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat message shimmer placeholder (for loading states)
class ShimmerChatBubble extends StatelessWidget {
  final bool isUser;
  
  const ShimmerChatBubble({super.key, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 12,
        right: isUser ? 12 : 60,
        bottom: 8,
      ),
      child: ShimmerLoading(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(height: 10),
              const SizedBox(height: 6),
              ShimmerBox(height: 10, width: isUser ? 120 : 180),
            ],
          ),
        ),
      ),
    );
  }
}
