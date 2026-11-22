import 'package:flutter_test/flutter_test.dart';
import 'package:salatime/service/quran/quran_recitation_cache.dart';

void main() {
  group('Quran recitation source validation', () {
    const source = 'https://server7.mp3quran.net/reciter/001.mp3';

    test('accepts official HTTPS audio and uses a deterministic cache key', () {
      expect(QuranRecitationCache.validateAudioSource(source).host,
          'server7.mp3quran.net');
      expect(QuranRecitationCache.audioFilename(source),
          QuranRecitationCache.audioFilename(source));
      expect(QuranRecitationCache.audioFilename(source), endsWith('.mp3'));
    });

    test('rejects untrusted or redirected endpoints', () {
      for (final url in [
        'http://server7.mp3quran.net/reciter/001.mp3',
        'https://mp3quran.net.evil.example/reciter/001.mp3',
        'https://server7.mp3quran.net/reciter/001.mp3?token=x',
        'https://server7.mp3quran.net:8080/reciter/001.mp3',
        'https://server7.mp3quran.net/reciter/001.mp3#fragment',
        'https://user@server7.mp3quran.net/reciter/001.mp3',
        'https://server7.mp3quran.net/reciter/001.txt',
        'https://example.org/001.mp3',
      ]) {
        expect(() => QuranRecitationCache.validateAudioSource(url),
            throwsArgumentError, reason: url);
      }
    });
  });
}
