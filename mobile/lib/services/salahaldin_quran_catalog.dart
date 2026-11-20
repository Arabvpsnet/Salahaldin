import 'dart:convert';
import 'package:http/http.dart' as http;

/// Read-only catalog of attributed editions. Does not download or invent tafsir.
class SalahaldinEdition {
  const SalahaldinEdition({
    required this.id,
    required this.language,
    required this.kind,
    required this.sourceUrl,
    required this.availability,
  });

  final String id;
  final String language;
  final String kind;
  final Uri sourceUrl;
  final String availability;

  factory SalahaldinEdition.fromJson(Map<String, dynamic> data) =>
      SalahaldinEdition(
        id: data['id'] as String,
        language: data['lang'] as String,
        kind: data['kind'] as String,
        sourceUrl: Uri.parse(data['sourceUrl'] as String),
        availability: data['availability'] as String,
      );
}

/// An optional self-hosted catalog service. Reader UI integration is a separate task.
class SalahaldinQuranCatalog {
  const SalahaldinQuranCatalog(this.apiBase);

  final Uri apiBase;

  Future<List<SalahaldinEdition>> getEditions() async {
    final url = apiBase.resolve('api/salahaldin/v1/quran/editions');
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Quran edition catalog HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported Quran edition catalog');
    }
    final raw = decoded['editions'];
    if (raw is! List) throw const FormatException('Missing Quran edition list');
    return raw.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid edition entry');
      }
      return SalahaldinEdition.fromJson(entry);
    }).toList(growable: false);
  }
}
