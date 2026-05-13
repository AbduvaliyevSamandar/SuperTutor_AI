import 'package:flutter/material.dart';
import '../core/theme.dart';

enum DuoButtonVariant { primary, secondary, danger, gold, neutral, outline }

class DuoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final DuoButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  const DuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DuoButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 52,
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _down = false;

  ({Color top, Color bottom, Color text}) get _colors {
    switch (widget.variant) {
      case DuoButtonVariant.primary:
        return (top: AppColors.primary, bottom: AppColors.primaryDark, text: Colors.white);
      case DuoButtonVariant.secondary:
        return (top: AppColors.secondary, bottom: AppColors.secondaryDark, text: Colors.white);
      case DuoButtonVariant.danger:
        return (top: AppColors.heart, bottom: AppColors.heartDark, text: Colors.white);
      case DuoButtonVariant.gold:
        return (top: AppColors.gold, bottom: AppColors.goldDark, text: AppColors.ink);
      case DuoButtonVariant.neutral:
        return (top: AppColors.surface, bottom: AppColors.border, text: AppColors.ink);
      case DuoButtonVariant.outline:
        return (top: Colors.white, bottom: AppColors.border, text: AppColors.ink);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final disabled = widget.onPressed == null || widget.loading;
    final pressed = _down && !disabled;
    final depth = pressed ? 0.0 : 4.0;

    final child = widget.loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: c.text, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  color: disabled ? c.text.withValues(alpha: 0.55) : c.text,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  fontSize: 15,
                ),
              ),
            ],
          );

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.expand ? double.infinity : null,
        height: widget.height + 4,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 4,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: disabled ? c.bottom.withValues(alpha: 0.45) : c.bottom,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: 0,
              bottom: depth == 0 ? 0 : 4,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: disabled ? c.top.withValues(alpha: 0.55) : c.top,
                  borderRadius: BorderRadius.circular(16),
                  border: widget.variant == DuoButtonVariant.outline
                      ? const Border.fromBorderSide(BorderSide(color: AppColors.border, width: 2))
                      : null,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
