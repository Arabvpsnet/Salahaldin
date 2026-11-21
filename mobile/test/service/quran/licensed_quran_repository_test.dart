import 'package:flutter_test/flutter_test.dart';
import 'package:salatime/service/quran/licensed_quran_repository.dart';
import 'package:salatime/service/quran/quran_recitation_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all six transferred Quran editions are complete and readable offline',
      () async {
    final repository = LicensedQuranRepository();
    expect(LicensedQuranRepository.editions.length, 6);
    for (final edition in LicensedQuranRepository.editions) {
      final first = await repository.read(1, edition.id);
      final finalSurah = await repository.read(114, edition.id);
      expect(first, hasLength(7), reason: edition.id);
      expect(finalSurah, hasLength(6), reason: edition.id);
      if (edition.isTafsir) {
        // Upstream stores chapter-2 keys in lexical order (1,10,100...).
        // Read by canonical ayah identity without changing the source.
        expect(await repository.read(2, edition.id), hasLength(286));
      }
      expect(first.every((text) => text.trim().isNotEmpty), isTrue);
      expect(finalSurah.every((text) => text.trim().isNotEmpty), isTrue);
      expect(edition.credit, isNotEmpty);
      expect(edition.title, isNotEmpty);
    }
  });

  test('refuses invalid Quran identities instead of substituting other editions',
      () async {
    final repository = LicensedQuranRepository();
    expect(
      () => repository.read(115, 'en.sahih'),
      throwsRangeError,
    );
    expect(
      () => repository.read(1, 'unknown'),
      throwsArgumentError,
    );
    expect(
      () => parseLicensedQuranAsset({
        'id': 'en.sahih',
        'kind': 'translation',
        'raw': '{}',
      }),
      throwsFormatException,
    );
    expect(
      () => parseLicensedQuranAsset({
        'id': 'ar.muyassar',
        'kind': 'tafsir',
        'raw': '{"1": []}',
      }),
      throwsFormatException,
    );
  });

  test('offline MP3 source only accepts trusted HTTPS MP3Quran hosts', () {
    final accepted = QuranRecitationCache.validateAudioSource(
      'https://server7.mp3quran.net/s_gmd/001.mp3',
    );
    expect(accepted.host, 'server7.mp3quran.net');
    expect(
      QuranRecitationCache.audioFilename(accepted.toString()),
      matches(RegExp(r'^[0-9a-f]{64}\.mp3$')),
    );
    for (final uri in [
      'http://server7.mp3quran.net/s_gmd/001.mp3',
      'https://mp3quran.net.evil.example/s_gmd/001.mp3',
      'https://server7.mp3quran.net/s_gmd/001.mp3?token=abc',
      'https://user:pass@server7.mp3quran.net/s_gmd/001.mp3',
      'https://server7.mp3quran.net/s_gmd/../../etc/passwd',
      'https://example.com/001.mp3',
    ]) {
      expect(
        () => QuranRecitationCache.validateAudioSource(uri),
        throwsArgumentError,
        reason: uri,
      );
    }
  });
}
