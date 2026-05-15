import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../../widgets/sound_effects.dart';
import '../auth/auth_controller.dart';
import '../currency/currency_controller.dart';

class CameraDictionaryScreen extends ConsumerStatefulWidget {
  const CameraDictionaryScreen({super.key});

  @override
  ConsumerState<CameraDictionaryScreen> createState() =>
      _CameraDictionaryScreenState();
}

class _CameraDictionaryScreenState
    extends ConsumerState<CameraDictionaryScreen> {
  final _picker = ImagePicker();
  List<int>? _imageBytes;
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;
  String _target = 'en';

  Future<void> _pickAndIdentify(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _loading = true;
      _result = null;
      _error = null;
    });
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
        'target': _target,
      });
      final r =
          await ref.read(dioProvider).post('/identify/object', data: form);
      final data = Map<String, dynamic>.from(r.data);
      setState(() => _result = data);
      SoundEffects.correct();
      if (ref.read(authControllerProvider).isAuthenticated) {
        await ref
            .read(currencyControllerProvider.notifier)
            .awardXp(3, reason: 'camera_dict');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera lug\'at'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Maqsad til',
            initialValue: _target,
            icon: Text(
              {'en': '🇬🇧', 'ru': '🇷🇺', 'de': '🇩🇪', 'tr': '🇹🇷'}[_target] ?? '🇬🇧',
              style: const TextStyle(fontSize: 22),
            ),
            onSelected: (v) => setState(() => _target = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'en', child: Text('🇬🇧  English')),
              PopupMenuItem(value: 'ru', child: Text('🇷🇺  Russian')),
              PopupMenuItem(value: 'de', child: Text('🇩🇪  German')),
              PopupMenuItem(value: 'tr', child: Text('🇹🇷  Turkish')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(
                        Uint8List.fromList(_imageBytes!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📷', style: TextStyle(fontSize: 56)),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Biror narsani suratga oling — AI uning nomini va tarjimasini bersin',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.inkLight,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const CircularProgressIndicator()
            else if (_result != null)
              _ResultCard(result: _result!)
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.heart)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: DuoButton(
                    label: 'Kamera',
                    variant: DuoButtonVariant.secondary,
                    icon: Icons.camera_alt_outlined,
                    onPressed: () => _pickAndIdentify(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DuoButton(
                    label: 'Galereya',
                    variant: DuoButtonVariant.outline,
                    icon: Icons.photo_library_outlined,
                    onPressed: () => _pickAndIdentify(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(result['word'] ?? '',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800)),
              ),
              const Text('+3 XP',
                  style: TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.w800)),
            ],
          ),
          if ((result['translation_uz'] ?? '').toString().isNotEmpty)
            Text(result['translation_uz'],
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          if ((result['example'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"${result['example']}"',
                style: const TextStyle(
                    color: AppColors.inkLight,
                    fontStyle: FontStyle.italic,
                    height: 1.3)),
          ],
        ],
      ),
    );
  }
}

