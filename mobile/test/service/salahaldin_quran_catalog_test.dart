import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salatime/services/salahaldin_quran_catalog.dart';

void main() {
  final base = Uri.parse('https://mosque.example.test/');
  final edition = <String, dynamic>{
    'id': 'arabic_moyassar', 'lang': 'ar', 'kind': 'tafsir',
    'publisher': 'QuranEnc',
    'sourceUrl': 'https://quranenc.com/en/browse/arabic_moyassar',
    'availability': 'remote-source',
  };
  SalahaldinQuranCatalog service(Object body, {int status = 200}) =>
      SalahaldinQuranCatalog(base, client: MockClient((request) async =>
        http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json'})));

  test('validated Quran translations retain credits and HTTPS source', () async {
    final list = await service({'schemaVersion': 1, 'editions': [edition]}).getEditions();
    expect(list, hasLength(1));
    expect(list.single.publisher, 'QuranEnc');
    expect(list.single.sourceUrl.scheme, 'https');
  });
  test('rejects schema drift, incomplete entries and redirects', () async {
    await expectLater(service({'schemaVersion': 2, 'editions': []}).getEditions(),
      throwsFormatException);
    await expectLater(service({'schemaVersion': 1, 'editions': [{}]}).getEditions(),
      throwsFormatException);
    await expectLater(service({}, status: 302).getEditions(), throwsStateError);
  });
  test('rejects duplicates and attribution URL injection', () async {
    await expectLater(service({'schemaVersion': 1,
      'editions': [edition, edition]}).getEditions(), throwsFormatException);
    await expectLater(service({'schemaVersion': 1,
      'editions': [{...edition, 'sourceUrl': 'javascript:alert(1)'}]}).getEditions(),
      throwsFormatException);
  });
  test('requires TLS and rejects unbounded responses', () async {
    await expectLater(
      SalahaldinQuranCatalog(Uri.parse('http://external.example.test/')).getEditions(),
      throwsArgumentError);
    await expectLater(service({
      'schemaVersion': 1, 'editions': [], 'padding': 'x' * 1100000
    }).getEditions(), throwsFormatException);
  });
}
