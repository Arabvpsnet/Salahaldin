import 'package:flutter_test/flutter_test.dart';
import 'package:salatime/helper/offline_quran_loader.dart';

void main() {
  test('exact normalized Quran search returns source verse without changing text', () {
    final verses = [
      {'id': 1, '_searchText': normalizeQuranSearch('بِسْمِ اللّهِ الرَّحْمَٰنِ')},
      {'id': 2, '_searchText': normalizeQuranSearch('الرَّحْمَنِ الرَّحِيمِ')},
    ];
    expect(searchQuranIndex(verses, 'بسم الله').single['id'], 1);
  });

  test('relaxes Arabic article only after exact matches are unavailable', () {
    final verses = [
      {'id': 1, '_searchText': normalizeQuranSearch('رب العالمين')},
      {'id': 2, '_searchText': normalizeQuranSearch('رحيم')},
      {'id': 3, '_searchText': normalizeQuranSearch('الرحمن')},
    ];
    // Definite-article prefix remains exact if it occurs.
    expect(searchQuranIndex(verses, 'الرحمن').single['id'], 3);
    // No exact match; use a conservative Arabic article fallback.
    expect(searchQuranIndex(verses, 'الرحيم').single['id'], 2);
  });

  test('limits broad match count and never matches empty queries', () {
    final verses = List.generate(600, (i) =>
      {'id': i, '_searchText': 'الله الرحمن الرحيم'});
    expect(searchQuranIndex(verses, 'الله'), hasLength(200));
    expect(searchQuranIndex(verses, 'الله', maxResults: 5), hasLength(5));
    expect(searchQuranIndex(verses, ''), isEmpty);
    expect(searchQuranIndex(verses, '  '), isEmpty);
    expect(searchQuranIndex(verses, 'الله', maxResults: 0), isEmpty);
  });
}
