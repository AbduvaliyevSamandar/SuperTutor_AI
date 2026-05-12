import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _Subject {
  final String id;
  final String title;
  final String emoji;
  final bool enabled;
  const _Subject(this.id, this.title, this.emoji, this.enabled);
}

const _subjects = <_Subject>[
  _Subject('english', 'Ingliz tili', '🇬🇧', true),
  _Subject('math', 'Matematika', '📐', true),
  _Subject('russian', 'Rus tili', '🇷🇺', false),
  _Subject('german', 'Nemis tili', '🇩🇪', false),
  _Subject('turkish', 'Turk tili', '🇹🇷', false),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperTutor AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.go('/dashboard'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qaysi fanni o\'rganamiz?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: _subjects.length,
                itemBuilder: (context, i) => _SubjectCard(s: _subjects[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final _Subject s;
  const _SubjectCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: s.enabled ? () => context.go('/chat/${s.id}') : null,
      child: Opacity(
        opacity: s.enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.emoji, style: const TextStyle(fontSize: 40)),
              Text(s.title,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                s.enabled ? 'Boshlash →' : 'Tez orada',
                style: TextStyle(color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
