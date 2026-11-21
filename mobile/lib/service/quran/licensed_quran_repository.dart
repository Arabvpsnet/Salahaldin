import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:salatime/service/reading/reading_progress_models.dart';

/// Licensed assets are bundled separately from the original QuranEnc editions.
/// All edition names, translator credits, and original text are preserved.
class LicensedQuranEdition {
  const LicensedQuranEdition(this.id, this.lang, this.title, this.credit,
      this.asset, {this.isTafsir = false});
  final String id;
  final String lang;
  final String title;
  final String credit;
  final String asset;
  final bool isTafsir;
}

class LicensedQuranRepository {
  LicensedQuranRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  static final instance = LicensedQuranRepository();
  static const editions = <LicensedQuranEdition>[
    LicensedQuranEdition('en.sahih', 'en', 'Saheeh International',
      'Umm Muhammad, Emily Assami & Amatullah Bantley · AlQuran.cloud',
      'assets/quran/licensed/translations/en.sahih.json'),
    LicensedQuranEdition('en.pickthall', 'en', 'Pickthall',
      'Marmaduke Pickthall · AlQuran.cloud',
      'assets/quran/licensed/translations/en.pickthall.json'),
    LicensedQuranEdition('en.yusufali', 'en', 'Yusuf Ali',
      'Abdullah Yusuf Ali · AlQuran.cloud',
      'assets/quran/licensed/translations/en.yusufali.json'),
    LicensedQuranEdition('fr.hamidullah', 'fr', 'Muhammad Hamidullah (français)',
      'Muhammad Hamidullah · AlQuran.cloud',
      'assets/quran/licensed/translations/fr.hamidullah.json'),
    LicensedQuranEdition('ur.jalandhry', 'ur', 'فتح محمد جالندھری',
      'Fateh Muhammad Jalandhry · AlQuran.cloud',
      'assets/quran/licensed/translations/ur.jalandhry.json'),
    LicensedQuranEdition('ar.muyassar', 'ar', 'التفسير الميسر',
      'مجمع الملك فهد لطباعة المصحف الشريف · quran-app',
      'assets/quran/licensed/tafsir/muyassar.json', isTafsir: true),
  ];

  final AssetBundle _bundle;
  final _loaded = <String, Map<int, List<String>>>{};
  final _pending = <String, Future<Map<int, List<String>>>>{};

  static LicensedQuranEdition edition(String id) =>
      editions.firstWhere((e) => e.id == id,
        orElse: () => throw ArgumentError.value(id, 'id', 'Unknown edition'));

  Future<List<String>> read(int surah, String id) async {
    if (surah < 1 || surah > 114) {
      throw RangeError.range(surah, 1, 114, 'surah');
    }
    final source = edition(id);
    if (_loaded.containsKey(id)) return _loaded[id]![surah]!;
    final pending = _pending[id] ??= _load(source);
    try {
      final data = await pending;
      _loaded.remove(id);
      _loaded[id] = data;
      while (_loaded.length > 2) _loaded.remove(_loaded.keys.first);
      return data[surah]!;
    } finally {
      _pending.remove(id);
    }
  }

  Future<Map<int, List<String>>> _load(LicensedQuranEdition source) async {
    final raw = await _bundle.loadString(source.asset, cache: false);
    if (raw.length > 6 * 1024 * 1024) {
      throw const FormatException('Quran asset too large');
    }
    return compute(parseLicensedQuranAsset, {
      'id': source.id,
      'kind': source.isTafsir ? 'tafsir' : 'translation',
      'raw': raw,
    });
  }
}

/// A pure isolate-friendly parser that verifies every ayah against the canonical index.
Map<int, List<String>> parseLicensedQuranAsset(Map<String, String> input) {
  final id = input['id'], kind = input['kind'], raw = input['raw'];
  if (id == null || raw == null || (kind != 'translation' && kind != 'tafsir')) {
    throw const FormatException('Missing edition identity');
  }
  final document = jsonDecode(raw);
  final result = <int, List<String>>{};
  var count = 0;
  if (kind == 'translation') {
    if (document is! Map || document['data'] is! Map ||
        (document['data'] as Map)['edition'] is! Map ||
        ((document['data'] as Map)['edition'] as Map)['identifier'] != id ||
        (document['data'] as Map)['surahs'] is! List) {
      throw const FormatException('Invalid translation edition metadata');
    }
    final chapters = (document['data'] as Map)['surahs'] as List;
    if (chapters.length != 114) throw const FormatException('Missing surahs');
    for (var s = 1; s <= 114; s++) {
      final chapter = chapters[s - 1];
      if (chapter is! Map || chapter['number'] != s || chapter['ayahs'] is! List) {
        throw FormatException('Invalid chapter $s');
      }
      final verses = chapter['ayahs'] as List;
      if (verses.length != QuranReadingKeys.verseCounts[s - 1]) {
        throw FormatException('Incomplete chapter $s');
      }
      final texts = <String>[];
      for (var a = 1; a <= verses.length; a++) {
        final row = verses[a - 1];
        if (row is! Map || row['numberInSurah'] != a ||
            row['text'] is! String || (row['text'] as String).trim().isEmpty) {
          throw FormatException('Invalid translation ayah $s:$a');
        }
        texts.add(row['text'] as String);
      }
      result[s] = List.unmodifiable(texts);
      count += texts.length;
    }
  } else {
    if (id != 'ar.muyassar' || document is! Map || document.length != 114) {
      throw const FormatException('Invalid tafsir edition');
    }
    for (var s = 1; s <= 114; s++) {
      final item = document['$s'];
      final verses = item is List ? item : item is Map ? item['ayahs'] : null;
      if (verses is! List || verses.length != QuranReadingKeys.verseCounts[s - 1]) {
        throw FormatException('Incomplete tafsir chapter $s');
      }
      final texts = <String>[];
      for (var a = 1; a <= verses.length; a++) {
        final row = verses[a - 1];
        if (row is! Map || row['ayah'] != a || row['text'] is! String ||
            (row['text'] as String).trim().isEmpty) {
          throw FormatException('Invalid tafsir ayah $s:$a');
        }
        texts.add(row['text'] as String);
      }
      result[s] = List.unmodifiable(texts);
      count += texts.length;
    }
  }
  if (result.length != 114 || count != 6236) {
    throw const FormatException('Incomplete Quran edition');
  }
  return Map.unmodifiable(result);
}
