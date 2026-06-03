import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Lightweight shimmer placeholder — no external package, single AnimationController.
class Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

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
        final t = _c.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: SizedBox(
            width: widget.width,
            height: widget.height ?? 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + 2 * t, 0),
                  end: Alignment(1 + 2 * t, 0),
                  colors: const [
                    AppColors.border,
                    AppColors.surface,
                    AppColors.border,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shortcut for a stack of skeleton lines (e.g. list row placeholder).
class SkeletonList extends StatelessWidget {
  final int rows;
  final double rowHeight;
  final double spacing;
  const SkeletonList({
    super.key,
    this.rows = 4,
    this.rowHeight = 56,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        rows,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i == rows - 1 ? 0 : spacing),
          child: Skeleton(height: rowHeight, radius: 14),
        ),
      ),
    );
  }
}
