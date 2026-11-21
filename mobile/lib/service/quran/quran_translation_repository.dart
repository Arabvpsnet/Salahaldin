import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:salatime/data/model/response/quran_translation_source.dart';
import 'package:salatime/data/model/response/sura_detile_model.dart';
import 'package:salatime/service/reading/reading_progress_models.dart';

export 'package:salatime/data/model/response/quran_translation_source.dart';

class QuranTranslationVerse {
  const QuranTranslationVerse({
    required this.translation,
    required this.footnotes,
  });
  final String translation;
  final String footnotes;
}

/// Published translations are read by chapter, without a runtime network call.
/// A missing or corrupt edition is an error, never an English substitution.
class QuranTranslationRepository {
  QuranTranslationRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static final instance = QuranTranslationRepository();
  static const supportedLanguages = {
    'ar',
    'bn',
    'bs',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'id',
    'ku',
    'kmr',
    'ms',
    'tr',
    'ur',
  };
  static const supportedEditions = {...supportedLanguages, 'ar_mokhtasar'};
  static const _base = 'assets/quran/translations';
  final AssetBundle _bundle;
  Future<Map<String, QuranTranslationSource>>? _manifest;
  final _chapters = <String, Map<int, QuranTranslationVerse>>{};
  final _loading = <String, Future<Map<int, QuranTranslationVerse>>>{};
  final _badiniHashes = <int, String>{};
  final _mokhtasarHashes = <int, String>{};

  static String normalizeLanguage(String code) {
    final requested = code.toLowerCase();
    if (requested == 'ar_mokhtasar') return requested;
    var language = requested.split(RegExp('[-_]')).first;
    if (language == 'sp') language = 'es';
    if (!supportedLanguages.contains(language)) {
      throw ArgumentError.value(
        code,
        'languageCode',
        'Unsupported Quran language',
      );
    }
    return language;
  }

  Future<QuranTranslationSource> source(String languageCode) async {
    final language = normalizeLanguage(languageCode);
    final sources = await (_manifest ??= _loadManifest().catchError((
      Object error,
    ) {
      _manifest = null;
      throw error;
    }));
    final result = sources[language];
    if (result == null) {
      throw FormatException('Missing published edition: $language');
    }
    return result;
  }

  Future<Map<String, QuranTranslationSource>> _loadManifest() async {
    final raw = await _bundle.loadString('$_base/manifest.json', cache: false);
    final document = jsonDecode(raw);
    if (document is! Map ||
        document['schemaVersion'] != 1 ||
        document['sources'] is! Map) {
      throw const FormatException('Invalid published translation manifest');
    }
    final result = <String, QuranTranslationSource>{};
    for (final entry in (document['sources'] as Map).entries) {
      final source = QuranTranslationSource.fromJson(
        Map<String, dynamic>.from(entry.value),
      );
      if (entry.key != source.languageCode ||
          !supportedLanguages.contains(entry.key)) {
        throw const FormatException('Translation manifest language mismatch');
      }
      final uri = Uri.tryParse(source.sourceUrl);
      if (uri == null || uri.scheme != 'https' || uri.host != 'quranenc.com') {
        throw const FormatException('Invalid published source URL');
      }
      result[entry.key as String] = source;
    }
    // Badini is a separate, independently attributed edition. Its source is
    // pinned to an immutable Git commit; don't conflate it with Kurdish Bamoki.
    final badiniRaw = await _bundle.loadString(
      'assets/quran/badini/manifest.json', cache: false);
    final badini = jsonDecode(badiniRaw);
    if (badini is! Map || badini['schemaVersion'] != 1 ||
        badini['editionKey'] != 'badini_sanahi' ||
        badini['verseCount'] != 6236 ||
        badini['source'] is! Map || badini['surahSha256'] is! Map ||
        (badini['surahSha256'] as Map).length != 114) {
      throw const FormatException('Invalid independent Badini edition');
    }
    final sanahi = QuranTranslationSource.fromJson(
      Map<String, dynamic>.from(badini['source'] as Map));
    const pinnedBadini =
      'https://github.com/0xdolan/kurdish_quran/blob/'
      'd0752aaa22f197261a58cad75724bac9cffd868d/'
      'txt/translation_sanahi.txt';
    if (sanahi.languageCode != 'kmr' ||
        sanahi.editionKey != 'badini_sanahi' ||
        sanahi.sourceUrl != pinnedBadini ||
        sanahi.version != 'd0752aaa22f1') {
      throw const FormatException('Badini attribution mismatch');
    }
    final badiniHashMap = badini['surahSha256'] as Map;
    _badiniHashes.clear();
    for (var surah = 1; surah <= 114; surah++) {
      final hash = badiniHashMap[surah.toString()];
      if (hash is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
        throw const FormatException('Missing Badini chapter hash');
      }
      _badiniHashes[surah] = hash;
    }
    result['kmr'] = sanahi;

    // Al-Mukhtasar is a second Arabic tafsir; the existing Al-Muyassar remains
    // the Arabic default. It has its own version and chapter fingerprints.
    final mokhtasarRaw = await _bundle.loadString(
      'assets/quran/tafsir/arabic_mokhtasar/manifest.json', cache: false);
    final mokhtasarManifest = jsonDecode(mokhtasarRaw);
    if (mokhtasarManifest is! Map ||
        mokhtasarManifest['schemaVersion'] != 1 ||
        mokhtasarManifest['editionKey'] != 'arabic_mokhtasar' ||
        mokhtasarManifest['verseCount'] != 6236 ||
        mokhtasarManifest['source'] is! Map ||
        mokhtasarManifest['surahSha256'] is! Map ||
        (mokhtasarManifest['surahSha256'] as Map).length != 114) {
      throw const FormatException('Invalid Al-Mukhtasar tafsir manifest');
    }
    final mokhtasar = QuranTranslationSource.fromJson(
      Map<String, dynamic>.from(mokhtasarManifest['source'] as Map));
    if (mokhtasar.languageCode != 'ar' ||
        mokhtasar.editionKey != 'arabic_mokhtasar' ||
        !mokhtasar.isTafsir ||
        mokhtasar.sourceUrl !=
            'https://quranenc.com/en/browse/arabic_mokhtasar') {
      throw const FormatException('Invalid Al-Mukhtasar publisher metadata');
    }
    _mokhtasarHashes.clear();
    final mokhtasarMap = mokhtasarManifest['surahSha256'] as Map;
    for (var surah = 1; surah <= 114; surah++) {
      final hash = mokhtasarMap[surah.toString()];
      if (hash is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
        throw const FormatException('Missing Al-Mukhtasar chapter hash');
      }
      _mokhtasarHashes[surah] = hash;
    }
    result['ar_mokhtasar'] = mokhtasar;

    if (result.length != supportedEditions.length) {
      throw const FormatException('Incomplete published Quran edition catalogue');
    }
    return Map.unmodifiable(result);
  }

  Future<QuranTranslationVerse> verse(
    int surah,
    int verse, {
    required String languageCode,
  }) async {
    if (!QuranReadingKeys.valid(surah, verse)) {
      throw ArgumentError('Invalid canonical Quran verse');
    }
    return (await _chapter(surah, await source(languageCode)))[verse]!;
  }

  Future<Map<int, QuranTranslationVerse>> _chapter(
    int surah,
    QuranTranslationSource source,
  ) {
    final key = '${source.editionKey}:$surah';
    final cached = _chapters.remove(key);
    if (cached != null) {
      _chapters[key] = cached;
      return Future.value(cached);
    }
    return _loading[key] ??= _readChapter(surah, source)
        .then((chapter) {
          _chapters[key] = chapter;
          while (_chapters.length > 8) {
            _chapters.remove(_chapters.keys.first);
          }
          return chapter;
        })
        .whenComplete(() {
          _loading.remove(key);
        });
  }

  Future<Map<int, QuranTranslationVerse>> _readChapter(
    int surah,
    QuranTranslationSource source,
  ) async {
    final chapterPath = source.editionKey == 'arabic_mokhtasar'
        ? 'assets/quran/tafsir/arabic_mokhtasar/' + surah.toString() + '.json'
        : source.languageCode == 'kmr'
            ? 'assets/quran/badini/' + surah.toString() + '.json'
            : 'assets/quran/translations/' + source.languageCode +
                '/' + surah.toString() + '.json';
    final raw = await _bundle.loadString(chapterPath, cache: false);
    if (source.languageCode == 'kmr' &&
        sha256.convert(utf8.encode(raw)).toString() != _badiniHashes[surah]) {
      throw const FormatException('Badini chapter hash mismatch');
    }
    if (source.editionKey == 'arabic_mokhtasar' &&
        sha256.convert(utf8.encode(raw)).toString() != _mokhtasarHashes[surah]) {
      throw const FormatException('Al-Mukhtasar chapter hash mismatch');
    }
    return compute(_parseChapter, {
      'raw': raw,
      'source': source.toJson(),
      'surah': surah,
      'verseCount': QuranReadingKeys.verseCounts[surah - 1],
    });
  }

  Future<SuraDetaileModel> loadSurah(
    int surah, {
    required String languageCode,
  }) async {
    if (!QuranReadingKeys.valid(surah, 1)) {
      throw ArgumentError.value(surah, 'surah', 'Invalid Quran surah');
    }
    final edition = await source(languageCode);
    final translations = await _chapter(surah, edition);
    final raw = await _bundle.loadString(
      'assets/quran/en/s00$surah.json',
      cache: false,
    );
    final model = await compute(_parseCanonicalSurah, raw);
    final chapter = model.data?.chapter;
    if (chapter?.id != surah) {
      throw const FormatException('Canonical surah identity mismatch');
    }
    final seen = <int>{};
    for (final page in model.data?.chapterInfo ?? <ChapterInfo>[]) {
      for (final verse in page.pageVerses ?? <PageVerses>[]) {
        final number = verse.versesNumber;
        if (verse.chapterId != surah || number == null || !seen.add(number)) {
          throw const FormatException('Invalid canonical verse identity');
        }
        final official = translations[number];
        if (official == null) {
          throw const FormatException('Missing published verse');
        }
        verse.translatedName = official.translation;
        verse.translationFootnotes = official.footnotes;
      }
    }
    if (seen.length != translations.length) {
      throw const FormatException('Incomplete canonical surah');
    }
    model.translationSource = edition;
    return model;
  }
}

SuraDetaileModel _parseCanonicalSurah(String raw) {
  final decoded = jsonDecode(raw);
  return SuraDetaileModel.fromJson(
    Map<String, dynamic>.from(decoded is List ? decoded.first : decoded),
  );
}

Map<int, QuranTranslationVerse> _parseChapter(Map<String, dynamic> input) {
  final document = jsonDecode(input['raw'] as String);
  final source = input['source'] as Map;
  if (document is! Map ||
      document['schemaVersion'] != 1 ||
      document['languageCode'] != source['languageCode'] ||
      document['editionKey'] != source['editionKey'] ||
      document['version'] != source['version'] ||
      document['surah'] != input['surah'] ||
      document['verses'] is! Map) {
    throw const FormatException('Published chapter does not match its edition');
  }
  final rows = document['verses'] as Map;
  final count = input['verseCount'] as int;
  if (rows.length != count) {
    throw const FormatException('Incomplete published chapter');
  }
  final result = <int, QuranTranslationVerse>{};
  for (var number = 1; number <= count; number++) {
    final row = rows['$number'];
    if (row is! Map ||
        row['translation'] is! String ||
        (row['translation'] as String).trim().isEmpty ||
        row['footnotes'] is! String) {
      throw const FormatException('Invalid published verse text or notes');
    }
    result[number] = QuranTranslationVerse(
      translation: row['translation'],
      footnotes: row['footnotes'],
    );
  }
  return Map.unmodifiable(result);
}
).hasMatch(hash)) {
        throw const FormatException('Missing Badini SHA256 fingerprint');
      }
      _badiniHashes[surah] = hash;
    }
    result['kmr'] = sanahi;
    if (result.length != supportedLanguages.length) {
      throw const FormatException('Incomplete published translation manifest');
    }
    return Map.unmodifiable(result);
  }

  Future<QuranTranslationVerse> verse(
    int surah,
    int verse, {
    required String languageCode,
  }) async {
    if (!QuranReadingKeys.valid(surah, verse)) {
      throw ArgumentError('Invalid canonical Quran verse');
    }
    return (await _chapter(surah, await source(languageCode)))[verse]!;
  }

  Future<Map<int, QuranTranslationVerse>> _chapter(
    int surah,
    QuranTranslationSource source,
  ) {
    final key = '${source.languageCode}:$surah';
    final cached = _chapters.remove(key);
    if (cached != null) {
      _chapters[key] = cached;
      return Future.value(cached);
    }
    return _loading[key] ??= _readChapter(surah, source)
        .then((chapter) {
          _chapters[key] = chapter;
          while (_chapters.length > 8) {
            _chapters.remove(_chapters.keys.first);
          }
          return chapter;
        })
        .whenComplete(() {
          _loading.remove(key);
        });
  }

  Future<Map<int, QuranTranslationVerse>> _readChapter(
    int surah,
    QuranTranslationSource source,
  ) async {
    final raw = await _bundle.loadString(
      '$_base/${source.languageCode}/$surah.json',
      cache: false,
    );
    return compute(_parseChapter, {
      'raw': raw,
      'source': source.toJson(),
      'surah': surah,
      'verseCount': QuranReadingKeys.verseCounts[surah - 1],
    });
  }

  Future<SuraDetaileModel> loadSurah(
    int surah, {
    required String languageCode,
  }) async {
    if (!QuranReadingKeys.valid(surah, 1)) {
      throw ArgumentError.value(surah, 'surah', 'Invalid Quran surah');
    }
    final edition = await source(languageCode);
    final translations = await _chapter(surah, edition);
    final raw = await _bundle.loadString(
      'assets/quran/en/s00$surah.json',
      cache: false,
    );
    final model = await compute(_parseCanonicalSurah, raw);
    final chapter = model.data?.chapter;
    if (chapter?.id != surah) {
      throw const FormatException('Canonical surah identity mismatch');
    }
    final seen = <int>{};
    for (final page in model.data?.chapterInfo ?? <ChapterInfo>[]) {
      for (final verse in page.pageVerses ?? <PageVerses>[]) {
        final number = verse.versesNumber;
        if (verse.chapterId != surah || number == null || !seen.add(number)) {
          throw const FormatException('Invalid canonical verse identity');
        }
        final official = translations[number];
        if (official == null) {
          throw const FormatException('Missing published verse');
        }
        verse.translatedName = official.translation;
        verse.translationFootnotes = official.footnotes;
      }
    }
    if (seen.length != translations.length) {
      throw const FormatException('Incomplete canonical surah');
    }
    model.translationSource = edition;
    return model;
  }
}

SuraDetaileModel _parseCanonicalSurah(String raw) {
  final decoded = jsonDecode(raw);
  return SuraDetaileModel.fromJson(
    Map<String, dynamic>.from(decoded is List ? decoded.first : decoded),
  );
}

Map<int, QuranTranslationVerse> _parseChapter(Map<String, dynamic> input) {
  final document = jsonDecode(input['raw'] as String);
  final source = input['source'] as Map;
  if (document is! Map ||
      document['schemaVersion'] != 1 ||
      document['languageCode'] != source['languageCode'] ||
      document['editionKey'] != source['editionKey'] ||
      document['version'] != source['version'] ||
      document['surah'] != input['surah'] ||
      document['verses'] is! Map) {
    throw const FormatException('Published chapter does not match its edition');
  }
  final rows = document['verses'] as Map;
  final count = input['verseCount'] as int;
  if (rows.length != count) {
    throw const FormatException('Incomplete published chapter');
  }
  final result = <int, QuranTranslationVerse>{};
  for (var number = 1; number <= count; number++) {
    final row = rows['$number'];
    if (row is! Map ||
        row['translation'] is! String ||
        (row['translation'] as String).trim().isEmpty ||
        row['footnotes'] is! String) {
      throw const FormatException('Invalid published verse text or notes');
    }
    result[number] = QuranTranslationVerse(
      translation: row['translation'],
      footnotes: row['footnotes'],
    );
  }
  return Map.unmodifiable(result);
}
