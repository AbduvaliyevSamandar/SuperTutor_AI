import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Tiny shimmer-style loading placeholder. No external dependency.
class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  const ShimmerBox({
    super.key,
    this.height = 18,
    this.width,
    this.radius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_c.value);
        final color = Color.lerp(
            AppColors.border, AppColors.surface, t)!;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

class StatsSkeleton extends StatelessWidget {
  const StatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(height: 80, radius: 14),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: ShimmerBox(height: 72, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 72, radius: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: ShimmerBox(height: 72, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 72, radius: 12)),
            ],
          ),
          const SizedBox(height: 18),
          const ShimmerBox(height: 24, width: 160),
          const SizedBox(height: 10),
          const ShimmerBox(height: 60, radius: 14),
          const SizedBox(height: 8),
          const ShimmerBox(height: 60, radius: 14),
        ],
      ),
    );
  }
}
