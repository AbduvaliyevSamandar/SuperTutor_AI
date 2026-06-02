import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/error_messages.dart';
import '../../core/theme.dart';

class ChatSession {
  final String id;
  final String subject;
  final DateTime startedAt;
  final int messagesCount;
  final int durationSeconds;
  ChatSession({
    required this.id,
    required this.subject,
    required this.startedAt,
    required this.messagesCount,
    required this.durationSeconds,
  });

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        id: j['id'] as String,
        subject: (j['subject'] ?? '') as String,
        startedAt: DateTime.tryParse(j['started_at'] ?? '')?.toLocal() ??
            DateTime.now(),
        messagesCount: (j['messages_count'] ?? 0) as int,
        durationSeconds: (j['duration_seconds'] ?? 0) as int,
      );
}

class StoredMessage {
  final String role;
  final String content;
  final DateTime createdAt;
  StoredMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });
  factory StoredMessage.fromJson(Map<String, dynamic> j) => StoredMessage(
        role: j['role'] as String,
        content: j['content'] as String,
        createdAt: DateTime.tryParse(j['created_at'] ?? '')?.toLocal() ??
            DateTime.now(),
      );
}

final _sessionListProvider =
    FutureProvider.autoDispose<List<ChatSession>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/sessions');
  final items = (r.data['items'] as List<dynamic>?) ?? [];
  return items
      .map((e) => ChatSession.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

class ChatHistoryScreen extends ConsumerWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_sessionListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Suhbatlar tarixi')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(_sessionListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyView();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_sessionListProvider);
              await ref.read(_sessionListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _SessionTile(session: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ChatSession session;
  const _SessionTile({required this.session});

  String get _emoji => switch (session.subject) {
        'math' => '📐',
        'english' => '🇬🇧',
        'russian' => '🇷🇺',
        'german' => '🇩🇪',
        'turkish' => '🇹🇷',
        _ => '🎓',
      };

  String get _title => switch (session.subject) {
        'math' => 'Matematika',
        'english' => 'Ingliz tili',
        'russian' => 'Rus tili',
        'german' => 'Nemis tili',
        'turkish' => 'Turk tili',
        _ => session.subject,
      };

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Bugun ${_hm(d)}';
    if (diff.inDays == 1) return 'Kecha ${_hm(d)}';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    return '${m} daq';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(session.startedAt)} · ${session.messagesCount} xabar · ${_formatDuration(session.durationSeconds)}',
                      style: const TextStyle(
                          color: AppColors.inkLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkLighter),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Hozircha suhbatlar yo\'q',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Birinchi suhbatingizni boshlang —\nbu yerda saqlanib qoladi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.inkLight, fontWeight: FontWeight.w600),
            ),
          ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.inkLight, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }
}

class SessionDetailScreen extends ConsumerStatefulWidget {
  final ChatSession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  List<StoredMessage>? _messages;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.get('/sessions/${widget.session.id}/messages');
      final items = (r.data['items'] as List<dynamic>?) ?? [];
      setState(() {
        _messages = items
            .map((e) =>
                StoredMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suhbat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Yangi suhbat boshlash',
            onPressed: () => context.go('/chat/${widget.session.subject}'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                })
              : _messages == null || _messages!.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bu sessiyada xabarlar topilmadi.',
                          style: TextStyle(
                              color: AppColors.inkLight,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages!.length,
                      itemBuilder: (_, i) =>
                          _StoredBubble(message: _messages![i]),
                    ),
    );
  }
}

class _StoredBubble extends StatelessWidget {
  final StoredMessage message;
  const _StoredBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🦉', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border, width: 1.5),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      shrinkWrap: true,
                      softLineBreak: true,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
