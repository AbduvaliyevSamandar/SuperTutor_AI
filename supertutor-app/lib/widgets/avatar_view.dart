import 'package:flutter/material.dart';

/// Placeholder avatar. Replace with a Lottie animation file later:
///   Lottie.asset('assets/avatar_talking.json', repeat: speaking)
class AvatarView extends StatelessWidget {
  final bool speaking;
  const AvatarView({super.key, required this.speaking});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      width: double.infinity,
      color: scheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: AnimatedScale(
        scale: speaking ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 220),
        child: CircleAvatar(
          radius: 56,
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            speaking ? Icons.graphic_eq : Icons.face_outlined,
            size: 56,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
