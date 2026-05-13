class WordEntry {
  final String word;
  final String source;
  final String target;
  final String? partOfSpeech;
  final String translation;
  final String definition;
  final List<String> examples;
  final List<String> exampleTranslations;
  final List<String> synonyms;

  const WordEntry({
    required this.word,
    required this.source,
    required this.target,
    this.partOfSpeech,
    required this.translation,
    required this.definition,
    required this.examples,
    required this.exampleTranslations,
    required this.synonyms,
  });

  factory WordEntry.fromJson(Map<String, dynamic> j) => WordEntry(
        word: j['word'] ?? '',
        source: j['source'] ?? 'en',
        target: j['target'] ?? 'uz',
        partOfSpeech: j['part_of_speech'],
        translation: j['translation'] ?? '',
        definition: j['definition'] ?? '',
        examples: List<String>.from(j['examples'] ?? const []),
        exampleTranslations:
            List<String>.from(j['example_translations'] ?? const []),
        synonyms: List<String>.from(j['synonyms'] ?? const []),
      );
}

class SavedWord {
  final String word;
  final String language;
  final String translation;
  final String definition;
  final DateTime? savedAt;

  SavedWord({
    required this.word,
    required this.language,
    required this.translation,
    required this.definition,
    this.savedAt,
  });

  factory SavedWord.fromJson(Map<String, dynamic> j) => SavedWord(
        word: j['word'] ?? '',
        language: j['language'] ?? 'en',
        translation: j['translation_uz'] ?? '',
        definition: j['definition'] ?? '',
        savedAt:
            j['saved_at'] != null ? DateTime.tryParse(j['saved_at']) : null,
      );
}
