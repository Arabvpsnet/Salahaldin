import 'package:flutter_test/flutter_test.dart';
import 'package:salatime/service/quran/quran_translation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('fourteen separately credited offline Quran editions are discoverable', () {
    expect(QuranTranslationRepository.supportedLanguages.length, 14);
    expect(QuranTranslationRepository.supportedEditions.length, 15);
    expect(QuranTranslationRepository.supportedLanguages,
        containsAll(['ar','bn','bs','de','en','es','fa','fr','id','ku','kmr','ms','tr','ur']));
    expect(QuranTranslationRepository.normalizeLanguage('bs-BA'), 'bs');
    expect(QuranTranslationRepository.normalizeLanguage('de-DE'), 'de');
    expect(QuranTranslationRepository.normalizeLanguage('ku-IQ'), 'ku');
    expect(QuranTranslationRepository.normalizeLanguage('kmr-IQ'), 'kmr');
    expect(QuranTranslationRepository.normalizeLanguage('ar_mokhtasar'), 'ar_mokhtasar');
  });
  test('two Arabic tafsirs remain separately selected with full attribution', () async {
    final repository = QuranTranslationRepository();
    final first = await repository.loadSurah(1, languageCode: 'ar');
    final second = await repository.loadSurah(1, languageCode: 'ar_mokhtasar');
    expect(first.translationSource!.editionKey, 'arabic_moyassar');
    expect(second.translationSource!.editionKey, 'arabic_mokhtasar');
    expect(first.translationSource!.isTafsir, isTrue);
    expect(second.translationSource!.isTafsir, isTrue);
    expect(second.data!.chapterInfo!
        .expand((page) => page.pageVerses!).length, 7);
    final sanahi = await repository.loadSurah(1, languageCode: 'kmr');
    expect(sanahi.translationSource!.editionKey, 'badini_sanahi');
    expect(sanahi.translationSource!.isRtl, isTrue);
  });

}
