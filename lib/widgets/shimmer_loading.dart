import 'package:flutter/material.dart';

/// Shimmer loading skeleton — animated shimmering placeholders
/// shaped like grid tiles, replacing boring circular spinners.
class ShimmerLoading extends StatefulWidget {
  final int itemCount;
  final int crossAxisCount;
  const ShimmerLoading({super.key, this.itemCount = 12, this.crossAxisCount = 3});
  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = (_ctrl.value * 4) - 2; // Range: -2 to 2
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            childAspectRatio: 0.55,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: widget.itemCount,
          itemBuilder: (_, __) => _ShimmerTile(pos: v),
        );
      },
    );
  }
}

class _ShimmerTile extends StatelessWidget {
  final double pos;
  const _ShimmerTile({required this.pos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(pos - 1, 0), end: Alignment(pos + 1, 0),
              colors: [
                Colors.grey.shade900,
                Colors.grey.shade700.withValues(alpha: 0.4),
                Colors.grey.shade900,
              ],
            ),
          ),
        )),
        const SizedBox(height: 6),
        Container(height: 10, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey.shade900)),
        const SizedBox(height: 4),
        Container(height: 10, width: 60, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey.shade900)),
      ],
    );
  }
}


