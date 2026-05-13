import 'package:flutter/material.dart';
import '../core/theme.dart';

class StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String? label;

  const StatChip({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              )),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(label!,
                style: const TextStyle(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                )),
          ],
        ],
      ),
    );
  }
}
