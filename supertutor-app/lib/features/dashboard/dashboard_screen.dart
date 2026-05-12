import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistika')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _StatCard(title: 'Umumiy o\'qish vaqti', value: '0 min'),
          _StatCard(title: 'Sessiyalar', value: '0'),
          _StatCard(title: 'Streak (kun)', value: '0 🔥'),
          _StatCard(title: 'Ingliz tili darajasi', value: 'A1'),
          _StatCard(title: 'Matematika to\'g\'ri javoblar', value: '0%'),
          SizedBox(height: 20),
          Text(
            'Statistika tez orada Supabase backend bilan ulanadi.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title),
        trailing: Text(value,
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
