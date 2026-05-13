import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'dictionary_models.dart';

class DictionaryRepository {
  final Dio _dio;
  DictionaryRepository(this._dio);

  Future<WordEntry> lookup(
    String word, {
    String source = 'en',
    String target = 'uz',
  }) async {
    final r = await _dio.get(
      '/dictionary/lookup',
      queryParameters: {
        'word': word,
        'source': source,
        'target': target,
      },
    );
    return WordEntry.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<void> save(WordEntry e) async {
    await _dio.post('/dictionary/save', data: {
      'word': e.word,
      'source': e.source,
      'target': e.target,
      'translation': e.translation,
      'definition': e.definition,
    });
  }

  Future<List<SavedWord>> savedWords() async {
    final r = await _dio.get('/dictionary/saved');
    final items = (r.data['items'] as List?) ?? const [];
    return items
        .map((j) => SavedWord.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }
}

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  return DictionaryRepository(ref.watch(dioProvider));
});

final savedWordsProvider = FutureProvider<List<SavedWord>>((ref) async {
  return ref.watch(dictionaryRepositoryProvider).savedWords();
});
