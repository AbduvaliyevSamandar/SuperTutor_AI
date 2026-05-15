import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Lottie-style multi-layer mascot animation built on the existing icon_fg.png.
/// Features: floating bob + breathing scale + gentle rotation + sparkle ring.
class AnimatedMascotPro extends StatefulWidget {
  final double size;
  final bool celebrating;
  const AnimatedMascotPro({super.key, this.size = 120, this.celebrating = false});

  @override
  State<AnimatedMascotPro> createState() => _AnimatedMascotProState();
}

class _AnimatedMascotProState extends State<AnimatedMascotPro>
    with TickerProviderStateMixin {
  late final AnimationController _bob;
  late final AnimationController _breathe;
  late final AnimationController _spark;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
    _spark = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedMascotPro old) {
    super.didUpdateWidget(old);
    if (widget.celebrating && !_spark.isAnimating) {
      _spark.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _breathe.dispose();
    _spark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.6,
      height: widget.size * 1.4,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bob, _breathe, _spark]),
        builder: (_, _) {
          final bob = Curves.easeInOut.transform(_bob.value);
          final breathe = Curves.easeInOut.transform(_breathe.value);
          final rot = math.sin(_bob.value * math.pi * 2) * 0.04;
          final scale = 1.0 + breathe * 0.04;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Soft halo
              Container(
                width: widget.size * 1.5,
                height: widget.size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18 + bob * 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Sparkles around
              CustomPaint(
                size: Size(widget.size * 1.5, widget.size * 1.5),
                painter: _SparklePainter(
                  progress: _spark.value,
                  color: AppColors.gold,
                  intensity: widget.celebrating ? 1.0 : 0.5,
                ),
              ),
              // Mascot image
              Transform.translate(
                offset: Offset(0, -bob * 8),
                child: Transform.rotate(
                  angle: rot,
                  child: Transform.scale(
                    scale: scale,
                    child: Image.asset(
                      'assets/icon/icon_fg.png',
                      width: widget.size,
                      height: widget.size,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double intensity;

  _SparklePainter({
    required this.progress,
    required this.color,
    required this.intensity,
  });

  static const _count = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.45;
    final paint = Paint();
    for (int i = 0; i < _count; i++) {
      final phase = (progress + i / _count) % 1.0;
      final angle = phase * math.pi * 2 - math.pi / 2;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * radius;
      final t = (math.sin(phase * math.pi)).clamp(0.0, 1.0);
      final sz = 3 + t * 6 * intensity;
      paint.color = color.withValues(alpha: t * 0.8);
      _drawStar(canvas, Offset(x, y), sz, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double size, Paint p) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final r = (i.isEven) ? size : size * 0.4;
      final x = c.dx + math.cos(a) * r;
      final y = c.dy + math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) =>
      old.progress != progress || old.intensity != intensity;
}
