import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/duo_button.dart';
import '../auth/auth_controller.dart';
import 'dictionary_models.dart';
import 'dictionary_repository.dart';

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final _input = TextEditingController();
  String _lang = 'en';
  WordEntry? _result;
  bool _loading = false;
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final w = _input.text.trim();
    if (w.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _saved = false;
    });
    try {
      final r = await ref
          .read(dictionaryRepositoryProvider)
          .lookup(w, language: _lang);
      setState(() => _result = r);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveWord() async {
    if (_result == null) return;
    if (!ref.read(authControllerProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saqlash uchun kiring')),
      );
      return;
    }
    try {
      await ref.read(dictionaryRepositoryProvider).save(_result!);
      setState(() => _saved = true);
      ref.invalidate(savedWordsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${_result!.word}" saqlandi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saqlash xatosi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lug\'at'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    onSubmitted: (_) => _search(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'So\'z qidiring...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _LangDropdown(
                        value: _lang,
                        onChanged: (v) => setState(() => _lang = v),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _search)
              : _result != null
                  ? _ResultView(
                      entry: _result!,
                      saved: _saved,
                      onSave: _saveWord,
                    )
                  : const _SavedListView(),
    );
  }
}

class _LangDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _LangDropdown({required this.value, required this.onChanged});

  static const _opts = {
    'en': '🇬🇧',
    'ru': '🇷🇺',
    'de': '🇩🇪',
    'tr': '🇹🇷',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        items: _opts.entries
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: const TextStyle(fontSize: 18)),
                ))
            .toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final WordEntry entry;
  final bool saved;
  final VoidCallback onSave;
  const _ResultView({
    required this.entry,
    required this.saved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.word,
                      style: Theme.of(context).textTheme.headlineMedium),
                  if (entry.partOfSpeech != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.partOfSpeech!,
                        style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.gold),
              tooltip: 'Saqlash',
              onPressed: saved ? null : onSave,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🇺🇿', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.translationUz,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Ta\'rif'),
        Text(entry.definition,
            style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
                fontSize: 15,
                height: 1.4)),
        if (entry.examples.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionLabel('Misollar'),
          ...entry.examples.map((ex) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(color: AppColors.inkLight)),
                    Expanded(
                      child: Text(
                        ex,
                        style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              )),
        ],
        if (entry.synonyms.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionLabel('Sinonimlar'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.synonyms
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Text(s,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.inkLight,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.heart),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          DuoButton(
            label: 'Qaytadan urinish',
            variant: DuoButtonVariant.outline,
            onPressed: onRetry,
            expand: false,
          ),
        ],
      ),
    );
  }
}

class _SavedListView extends ConsumerWidget {
  const _SavedListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔍', style: TextStyle(fontSize: 56)),
              SizedBox(height: 12),
              Text(
                'So\'z qidiring va o\'rganishni boshlang.\nSaqlash uchun kiring.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkLight),
              ),
            ],
          ),
        ),
      );
    }
    final async = ref.watch(savedWordsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Xato: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Hali so\'z saqlanmagan.\nQidirib boshlang.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkLight),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final w = items[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(w.word,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(w.translationUz),
                trailing: _LanguageFlag(language: w.language),
              ),
            );
          },
        );
      },
    );
  }
}

class _LanguageFlag extends StatelessWidget {
  final String language;
  const _LanguageFlag({required this.language});

  @override
  Widget build(BuildContext context) {
    final flag = switch (language) {
      'en' => '🇬🇧',
      'ru' => '🇷🇺',
      'de' => '🇩🇪',
      'tr' => '🇹🇷',
      _ => '🌐',
    };
    return Text(flag, style: const TextStyle(fontSize: 22));
  }
}
