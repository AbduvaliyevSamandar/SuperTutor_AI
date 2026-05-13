import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
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
  bool _obscure = true;

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mascot
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🦉', style: TextStyle(fontSize: 64)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _signup ? 'Akkaunt yarating' : 'Xush kelibsiz!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Bepul AI o\'qituvchi bilan o\'rganishni boshlang',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.inkLight, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              if (!AppConfig.supabaseConfigured)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.goldDark),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mehmon rejimida ham xizmat ishlaydi.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscure,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Parol',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.heart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.heart, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: const TextStyle(
                              color: AppColors.heartDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              DuoButton(
                label: _signup ? 'Ro\'yxatdan o\'tish' : 'Kirish',
                loading: state.loading,
                onPressed: state.loading ? null : _submit,
              ),
              const SizedBox(height: 10),
              DuoButton(
                label: _signup ? 'Akkauntim bor' : 'Akkaunt yaratish',
                variant: DuoButtonVariant.outline,
                onPressed: () => setState(() => _signup = !_signup),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.border, thickness: 1.5)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('YOKI',
                        style: TextStyle(
                            color: AppColors.inkLighter,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: AppColors.border, thickness: 1.5)),
                ],
              ),
              const SizedBox(height: 18),
              DuoButton(
                label: 'Mehmon sifatida davom etish',
                variant: DuoButtonVariant.neutral,
                icon: Icons.person_outline,
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
