import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Licensed full-surah audio is stored only in the app's private local folder.
/// Multi-GB MP3 collections are intentionally not put into Git history.
class QuranRecitationCache {
  QuranRecitationCache({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const maxRecitationBytes = 80 * 1024 * 1024;

  static Uri validateAudioSource(String raw) {
    final url = Uri.tryParse(raw);
    if (url == null || url.scheme != 'https' ||
        !(url.host == 'mp3quran.net' || url.host.endsWith('.mp3quran.net')) ||
        url.userInfo.isNotEmpty || url.hasQuery || url.hasFragment ||
        !RegExp(r'/[0-9]{3}\.mp3$').hasMatch(url.path) ||
        url.pathSegments.contains('..')) {
      throw ArgumentError.value(raw, 'audioUrl', 'Untrusted recitation URL');
    }
    return url;
  }

  static String audioFilename(String raw) {
    final url = validateAudioSource(raw);
    return sha256.convert(utf8.encode(url.toString())).toString() + '.mp3';
  }

  Future<File> _file(String raw) async {
    final root = await getApplicationSupportDirectory();
    final folder = Directory(root.path + '/quran/recitations');
    return File(folder.path + '/' + audioFilename(raw));
  }

  Future<String?> cachedUrl(String raw) async {
    validateAudioSource(raw);
    final file = await _file(raw);
    if (!await file.exists()) return null;
    if (await file.length() < 1024) return null;
    return file.uri.toString();
  }

  /// Downloads a single recording with a size cap and atomically installs it.
  /// Never follows HTTP redirects to an untrusted third-party host.
  Future<String> download(String source) async {
    final uri = validateAudioSource(source);
    final output = await _file(source);
    if (await cachedUrl(source) case final String cached) return cached;

    await output.parent.create(recursive: true);
    final partial = File(output.path + '.partial');
    if (await partial.exists()) await partial.delete();

    IOSink? sink;
    try {
      final request = http.Request('GET', uri)..followRedirects = false;
      final response = await _client.send(request)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 ||
          (response.contentLength != null &&
           response.contentLength! > maxRecitationBytes)) {
        throw StateError('Recitation download refused');
      }
      sink = partial.openWrite();
      var bytes = 0;
      final signature = <int>[];
      await for (final chunk in response.stream.timeout(const Duration(seconds: 35))) {
        bytes += chunk.length;
        if (bytes > maxRecitationBytes) throw StateError('Recitation exceeds size limit');
        if (signature.length < 3) {
          signature.addAll(chunk.take(3 - signature.length));
        }
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      final validMp3 = signature.length >= 3 &&
          ((signature[0] == 0x49 && signature[1] == 0x44 &&
            signature[2] == 0x33) ||
           (signature[0] == 0xff && (signature[1] & 0xe0) == 0xe0));
      if (!validMp3 || bytes < 1024) {
        throw const FormatException('Downloaded file is not an MP3');
      }
      if (await output.exists()) await output.delete();
      return (await partial.rename(output.path)).uri.toString();
    } catch (_) {
      await sink?.close();
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }
}
