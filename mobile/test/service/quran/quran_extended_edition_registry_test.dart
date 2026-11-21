import 'package:flutter_test/flutter_test.dart';
import 'package:salatime/service/quran/quran_translation_repository.dart';

void main() {
  test('fourteen separately credited offline Quran editions are discoverable', () {
    expect(QuranTranslationRepository.supportedLanguages.length, 14);
    expect(QuranTranslationRepository.supportedLanguages,
        containsAll(['ar','bn','bs','de','en','es','fa','fr','id','ku','kmr','ms','tr','ur']));
    expect(QuranTranslationRepository.normalizeLanguage('bs-BA'), 'bs');
    expect(QuranTranslationRepository.normalizeLanguage('de-DE'), 'de');
    expect(QuranTranslationRepository.normalizeLanguage('ku-IQ'), 'ku');
    expect(QuranTranslationRepository.normalizeLanguage('kmr-IQ'), 'kmr');
  });
}
