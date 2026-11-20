import 'dart:convert';

import 'package:http/http.dart' as http;

/// Metadata only. No translation, tafsir or audio redistribution is granted.
class SalahaldinEdition {
  const SalahaldinEdition({
    required this.id,
    required this.language,
    required this.kind,
    required this.publisher,
    required this.sourceUrl,
    required this.availability,
  });

  final String id;
  final String language;
  final String kind;
  final String publisher;
  final Uri sourceUrl;
  final String availability;

  static const languages = <String>{
    'ar', 'tr', 'bs', 'da', 'de', 'en', 'arab-Latn', 'ckb', 'kmr'
  };

  factory SalahaldinEdition.fromJson(Map<String, dynamic> data) {
    final id = data['id'], lang = data['lang'], kind = data['kind'];
    final publisher = data['publisher'], source = data['sourceUrl'];
    final availability = data['availability'];
    if (id is! String || !RegExp(r'^[a-z0-9_-]{2,100}$').hasMatch(id) ||
        lang is! String || !languages.contains(lang) ||
        kind is! String ||
        !const {'tafsir', 'translation', 'translated-tafsir'}.contains(kind) ||
        publisher is! String || publisher.trim().isEmpty || publisher.length > 200 ||
        availability is! String || availability.trim().isEmpty || source is! String) {
      throw const FormatException('Invalid Quran edition metadata');
    }
    final url = Uri.tryParse(source);
    if (url == null || url.scheme != 'https' || url.host != 'quranenc.com' ||
        url.userInfo.isNotEmpty || url.hasFragment) {
      throw const FormatException('Untrusted Quran edition attribution URL');
    }
    return SalahaldinEdition(
      id: id, language: lang, kind: kind, publisher: publisher,
      sourceUrl: url, availability: availability,
    );
  }
}

/// Optional self-hosted metadata service; never fetches copyright-protected verse bodies.
class SalahaldinQuranCatalog {
  const SalahaldinQuranCatalog(this.apiBase, {this.client});

  final Uri apiBase;
  final http.Client? client;
  static const maxBytes = 1024 * 1024;

  Future<List<SalahaldinEdition>> getEditions() async {
    if (apiBase.scheme != 'https' &&
        !(apiBase.scheme == 'http' &&
          (apiBase.host == 'localhost' || apiBase.host == '127.0.0.1'))) {
      throw ArgumentError.value(apiBase, 'apiBase', 'HTTPS required');
    }
    if (apiBase.userInfo.isNotEmpty || apiBase.hasQuery || apiBase.hasFragment) {
      throw ArgumentError.value(apiBase, 'apiBase', 'Invalid API base');
    }
    final base = apiBase.path.endsWith('/')
        ? apiBase : apiBase.replace(path: apiBase.path + '/');
    final url = base.resolve('api/salahaldin/v1/quran/editions');
    final request = http.Request('GET', url)..followRedirects = false;
    final activeClient = client ?? http.Client();
    try {
      final response = await activeClient.send(request)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw StateError('Quran edition catalog HTTP ' + response.statusCode.toString());
      }
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(const Duration(seconds: 15))) {
        if (bytes.length + chunk.length > maxBytes) {
          throw const FormatException('Quran edition catalog exceeds 1 MB');
        }
        bytes.addAll(chunk);
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['schemaVersion'] != 1 || decoded['editions'] is! List) {
        throw const FormatException('Unsupported Quran edition catalog');
      }
      final editions = decoded['editions'] as List<dynamic>;
      if (editions.length > 200) {
        throw const FormatException('Unbounded Quran edition catalog');
      }
      final seen = <String>{};
      return editions.map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Invalid Quran edition entry');
        }
        final edition = SalahaldinEdition.fromJson(entry);
        if (!seen.add(edition.id)) {
          throw const FormatException('Duplicate Quran edition id');
        }
        return edition;
      }).toList(growable: false);
    } finally {
      if (client == null) activeClient.close();
    }
  }
}
