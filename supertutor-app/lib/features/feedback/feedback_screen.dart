import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _msg = TextEditingController();
  final _contact = TextEditingController();
  String _category = 'general';
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _msg.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_msg.text.trim().length < 5) {
      setState(() => _error = 'Iltimos, kamida 5 ta belgi yozing');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(dioProvider).post('/feedback', data: {
        'category': _category,
        'message': _msg.text.trim(),
        if (_contact.text.trim().isNotEmpty) 'contact': _contact.text.trim(),
      });
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = 'Yuborilmadi: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fikr / Xato yuborish')),
      body: _sent ? _buildSent() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Loyiha sifati uchun fikr-mulohazangiz juda muhim. Hech qanday matn jamoatchilikka ko\'rsatilmaydi.',
          style: TextStyle(
              color: AppColors.inkLight,
              fontWeight: FontWeight.w500,
              height: 1.45),
        ),
        const SizedBox(height: 20),
        const Text('Turi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('🐛 Xato'),
              selected: _category == 'bug',
              onSelected: (_) => setState(() => _category = 'bug'),
            ),
            ChoiceChip(
              label: const Text('💡 Taklif'),
              selected: _category == 'feature',
              onSelected: (_) => setState(() => _category = 'feature'),
            ),
            ChoiceChip(
              label: const Text('💬 Boshqa'),
              selected: _category == 'general',
              onSelected: (_) => setState(() => _category = 'general'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _msg,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Nimani yaxshilash kerak?',
            contentPadding: EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contact,
          decoration: const InputDecoration(
            hintText: 'Email yoki Telegram (ixtiyoriy)',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(
                  color: AppColors.heart,
                  fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 20),
        DuoButton(
          label: 'Yuborish',
          loading: _sending,
          onPressed: _sending ? null : _send,
        ),
      ],
    );
  }

  Widget _buildSent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🙏', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text('Rahmat!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Fikr-mulohazangiz qabul qilindi. Tezda ko\'rib chiqamiz.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkLight),
          ),
          const SizedBox(height: 24),
          DuoButton(label: 'Tugatish', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
