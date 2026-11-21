import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salatime/service/quran/salahaldin_recitation_cache.dart';

void main() {
  const url = 'https://server6.mp3quran.net/akdr/001.mp3';
  late Directory temp;
  setUp(() async => temp = await Directory.systemTemp.createTemp('quran-audio-'));
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('requires HTTPS, known media host, padded surah and clean URL', () {
    for (final bad in [
      'http://server6.mp3quran.net/akdr/001.mp3',
      'https://server6.mp3quran.net.evil.test/akdr/001.mp3',
      'https://server6.mp3quran.net/akdr/002.mp3?token=x',
      'https://server6.mp3quran.net/akdr/not-mp3',
    ]) {
      expect(() => SalahaldinRecitationCache.validateSource(bad),
          throwsFormatException);
    }
  });

  test('downloads MP3 once, plays local URI and deletes cache', () async {
    var requests = 0;
    final cache = SalahaldinRecitationCache(
      root: temp,
      client: MockClient((request) async {
        requests++;
        return http.Response.bytes(
          [0x49,0x44,0x33,...List<int>.filled(180,0)], 200,
          headers: {'content-type': 'audio/mpeg'});
      }),
    );
    expect(await cache.playbackUri(url), Uri.parse(url));
    final downloaded = await cache.download(url);
    expect(await downloaded.exists(), true);
    expect(await cache.playbackUri(url), downloaded.uri);
    await cache.download(url);
    expect(requests, 1);
    await cache.delete(url);
    expect(await cache.cached(url), isNull);
  });

  test('rejects fake mp3 documents', () async {
    final cache = SalahaldinRecitationCache(root: temp,
      client: MockClient((request) async =>
          http.Response('x' * 150, 200,
            headers: {'content-type': 'text/html'})));
    await expectLater(cache.download(url), throwsFormatException);
    expect(await cache.cached(url), isNull);
  });
}
