import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signup = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ctrl = ref.read(authControllerProvider.notifier);
    if (_signup) {
      await ctrl.signUp(_email.text, _password.text);
    } else {
      await ctrl.signIn(_email.text, _password.text);
    }
    if (ref.read(authControllerProvider).isAuthenticated && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_signup ? 'Ro\'yxatdan o\'tish' : 'Kirish')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text('SuperTutor AI',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('Bepul AI o\'qituvchi', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            if (!AppConfig.supabaseConfigured)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Supabase kalitlari .env\'da sozlanmagan. '
                  'Hozircha "Mehmon sifatida" davom etishingiz mumkin.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Parol',
                border: OutlineInputBorder(),
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: state.loading ? null : _submit,
              child: state.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_signup ? 'Ro\'yxatdan o\'tish' : 'Kirish'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _signup = !_signup),
              child: Text(_signup
                  ? 'Akkauntim bor — kirish'
                  : 'Akkaunt yoq — ro\'yxatdan o\'tish'),
            ),
            const Divider(height: 32),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Mehmon sifatida davom etish'),
            ),
          ],
        ),
      ),
    );
  }
}
