import 'dart:math' as math;
import 'package:flutter/material.dart';

class AvatarView extends StatefulWidget {
  final bool speaking;
  const AvatarView({super.key, required this.speaking});

  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView>
    with TickerProviderStateMixin {
  late final AnimationController _mouth;
  late final AnimationController _blink;
  late final AnimationController _idle;

  @override
  void initState() {
    super.initState();
    _mouth = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scheduleBlink();
  }

  void _scheduleBlink() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2200 + math.Random().nextInt(2200)));
      if (!mounted) return;
      await _blink.forward(from: 0);
      await _blink.reverse();
    }
  }

  @override
  void didUpdateWidget(covariant AvatarView old) {
    super.didUpdateWidget(old);
    if (widget.speaking && !_mouth.isAnimating) {
      _mouth.repeat(reverse: true);
    } else if (!widget.speaking && _mouth.isAnimating) {
      _mouth.stop();
      _mouth.value = 0;
    }
  }

  @override
  void dispose() {
    _mouth.dispose();
    _blink.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.4),
            scheme.surfaceContainerLow,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: Listenable.merge([_mouth, _blink, _idle]),
        builder: (context, _) {
          final bob = math.sin(_idle.value * 2 * math.pi) * 3;
          return Transform.translate(
            offset: Offset(0, bob),
            child: CustomPaint(
              size: const Size(140, 160),
              painter: _FacePainter(
                skin: const Color(0xFFFFD9B0),
                hair: const Color(0xFF3A2A20),
                mouthColor: const Color(0xFFC34F4F),
                eyeColor: const Color(0xFF2B2B2B),
                accent: scheme.primary,
                mouthOpen: _mouth.value,
                blink: _blink.value,
                speaking: widget.speaking,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final Color skin;
  final Color hair;
  final Color mouthColor;
  final Color eyeColor;
  final Color accent;
  final double mouthOpen;
  final double blink;
  final bool speaking;

  _FacePainter({
    required this.skin,
    required this.hair,
    required this.mouthColor,
    required this.eyeColor,
    required this.accent,
    required this.mouthOpen,
    required this.blink,
    required this.speaking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Shoulders / shirt
    final shirt = Paint()..color = accent;
    final shirtPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 26)
      ..quadraticBezierTo(
          cx, size.height - 60, size.width, size.height - 26)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(shirtPath, shirt);

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 50), width: 28, height: 22),
        const Radius.circular(8),
      ),
      Paint()..color = skin,
    );

    // Head (oval)
    final headRect = Rect.fromCenter(
        center: Offset(cx, cy), width: 110, height: 130);
    canvas.drawOval(headRect, Paint()..color = skin);

    // Hair (top)
    final hairPath = Path()
      ..moveTo(cx - 56, cy - 18)
      ..quadraticBezierTo(cx - 60, cy - 70, cx, cy - 78)
      ..quadraticBezierTo(cx + 60, cy - 70, cx + 56, cy - 18)
      ..quadraticBezierTo(cx + 40, cy - 50, cx, cy - 52)
      ..quadraticBezierTo(cx - 40, cy - 50, cx - 56, cy - 18)
      ..close();
    canvas.drawPath(hairPath, Paint()..color = hair);

    // Eyes
    final eyeY = cy - 6;
    final eyeHeight = 8 * (1 - blink);
    final eyePaint = Paint()..color = eyeColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 20, eyeY), width: 10, height: eyeHeight),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 20, eyeY), width: 10, height: eyeHeight),
      eyePaint,
    );

    // Eyebrows
    final brow = Paint()
      ..color = hair
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx - 28, cy - 22), Offset(cx - 12, cy - 24), brow);
    canvas.drawLine(
        Offset(cx + 12, cy - 24), Offset(cx + 28, cy - 22), brow);

    // Cheek blush
    final blush = Paint()
      ..color = const Color(0x33E07A7A);
    canvas.drawCircle(Offset(cx - 30, cy + 14), 7, blush);
    canvas.drawCircle(Offset(cx + 30, cy + 14), 7, blush);

    // Nose
    final nose = Paint()
      ..color = skin.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy + 2), Offset(cx, cy + 14), nose);

    // Mouth (animated)
    final mouthW = 26.0;
    final mouthH = 4 + mouthOpen * 14;
    final mouthRect = Rect.fromCenter(
        center: Offset(cx, cy + 28), width: mouthW, height: mouthH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mouthRect, const Radius.circular(8)),
      Paint()..color = mouthColor,
    );

    // Speaking glow indicator
    if (speaking) {
      final glow = Paint()
        ..color = accent.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawOval(headRect.inflate(4), glow);
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) =>
      old.mouthOpen != mouthOpen ||
      old.blink != blink ||
      old.speaking != speaking;
}
