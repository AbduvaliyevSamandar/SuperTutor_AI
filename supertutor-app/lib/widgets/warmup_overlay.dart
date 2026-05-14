import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/theme.dart';

/// Tracks backend warmth (Render cold-start). If first /health call is slow,
/// we show an overlay so the user understands what's happening instead of
/// seeing scary 503 errors.
final backendWarmProvider = StateProvider<bool>((ref) => false);

class WarmupGate extends ConsumerStatefulWidget {
  final Widget child;
  const WarmupGate({super.key, required this.child});

  @override
  ConsumerState<WarmupGate> createState() => _WarmupGateState();
}

class _WarmupGateState extends ConsumerState<WarmupGate> {
  bool _showing = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ping());
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  Future<void> _ping() async {
    final dio = ref.read(dioProvider);
    // After ~3 s, show the overlay if still pending
    _slowTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !ref.read(backendWarmProvider)) {
        setState(() => _showing = true);
      }
    });
    try {
      await dio.get('/health', options: Options(
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 60),
      ));
      if (mounted) {
        ref.read(backendWarmProvider.notifier).state = true;
        setState(() => _showing = false);
      }
    } on DioException {
      if (mounted) {
        // Even on error, dismiss after a while — let the rest of the app show
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) setState(() => _showing = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showing)
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🦉 Server uyg\'onmoqda... ~30 soniya',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
