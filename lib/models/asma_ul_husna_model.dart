class AsmaUlHusnaName {
  final int id;
  final String arabic;
  final String transliteration;
  final Map<String, String> translations;

  AsmaUlHusnaName({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translations,
  });

  String getTranslation(String languageCode) {
    return translations[languageCode] ?? translations['en'] ?? '';
  }
}

