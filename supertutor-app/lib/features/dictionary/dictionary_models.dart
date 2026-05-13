class WordEntry {
  final String word;
  final String language;
  final String? partOfSpeech;
  final String translationUz;
  final String definition;
  final List<String> examples;
  final List<String> synonyms;

  const WordEntry({
    required this.word,
    required this.language,
    this.partOfSpeech,
    required this.translationUz,
    required this.definition,
    required this.examples,
    required this.synonyms,
  });

  factory WordEntry.fromJson(Map<String, dynamic> j) => WordEntry(
        word: j['word'] ?? '',
        language: j['language'] ?? 'en',
        partOfSpeech: j['part_of_speech'],
        translationUz: j['translation_uz'] ?? '',
        definition: j['definition'] ?? '',
        examples: List<String>.from(j['examples'] ?? const []),
        synonyms: List<String>.from(j['synonyms'] ?? const []),
      );
}

class SavedWord {
  final String word;
  final String language;
  final String translationUz;
  final String definition;
  final DateTime? savedAt;

  SavedWord({
    required this.word,
    required this.language,
    required this.translationUz,
    required this.definition,
    this.savedAt,
  });

  factory SavedWord.fromJson(Map<String, dynamic> j) => SavedWord(
        word: j['word'] ?? '',
        language: j['language'] ?? 'en',
        translationUz: j['translation_uz'] ?? '',
        definition: j['definition'] ?? '',
        savedAt: j['saved_at'] != null ? DateTime.tryParse(j['saved_at']) : null,
      );
}
