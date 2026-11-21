import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Download per-surah recordings only at a user's request, never as a bulk background job.
class SalahaldinRecitationCache {
  const SalahaldinRecitationCache({this.root, this.client});
  final Directory? root;
  final http.Client? client;

  static const maxBytes = 60 * 1024 * 1024;
  static final host = RegExp(r'^server[0-9]+\.mp3quran\.net$');
  static final fileName = RegExp(r'^[0-9]{3}\.mp3$');

  static Uri validateSource(String url) {
    final u = Uri.tryParse(url);
    if (u == null || u.scheme != 'https' || !host.hasMatch(u.host) ||
        u.userInfo.isNotEmpty || u.hasQuery || u.hasFragment ||
        (u.hasPort && u.port != 443) ||
        u.pathSegments.isEmpty || !fileName.hasMatch(u.pathSegments.last)) {
      throw const FormatException('Untrusted recitation URL');
    }
    return u;
  }

  Future<File> _path(Uri source) async {
    final base = root ?? await getApplicationSupportDirectory();
    final folder = base.uri.resolve('salahaldin/recitations/');
    final digest = sha256.convert(utf8.encode(source.toString()));
    return File(folder.resolve('$digest.mp3').toFilePath());
  }

  Future<File?> cached(String remote) async {
    final file = await _path(validateSource(remote));
    if (!await file.exists()) return null;
    final size = await file.length();
    return size >= 128 && size <= maxBytes ? file : null;
  }

  Future<Uri> playbackUri(String remote) async =>
      (await cached(remote))?.uri ?? validateSource(remote);

  Future<File> download(String remote) async {
    final source = validateSource(remote);
    final already = await cached(remote);
    if (already != null) return already;
    final output = await _path(source);
    await output.parent.create(recursive: true);
    final partial = File([output.path, 'part'].join('.'));
    final httpClient = client ?? http.Client();
    try {
      final req = http.Request('GET', source)..followRedirects = false;
      final resp = await httpClient.send(req).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        throw StateError((StringBuffer('Audio HTTP ')..write(resp.statusCode)).toString());
      }
      final size = int.tryParse(resp.headers['content-length'] ?? '');
      if (size != null && (size > maxBytes || size < 128)) {
        throw const FormatException('Audio size invalid');
      }
      final mime = resp.headers['content-type'] ?? '';
      if (mime.isNotEmpty && !mime.startsWith('audio/') &&
          !mime.startsWith('application/octet-stream')) {
        throw const FormatException('Not an audio response');
      }
      var count = 0;
      final sink = partial.openWrite();
      try {
        await for (final block in resp.stream.timeout(const Duration(seconds: 40))) {
          count += block.length;
          if (count > maxBytes) throw const FormatException('Audio too large');
          sink.add(block);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (count < 128) throw const FormatException('Truncated MP3');
      final b = await partial.openRead(0, 3).first;
      final id3 = b.length >= 3 && b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33;
      final frame = b.length >= 2 && b[0] == 0xff && (b[1] & 0xe0) == 0xe0;
      if (!id3 && !frame) throw const FormatException('Invalid MP3 header');
      return await partial.rename(output.path);
    } finally {
      if (client == null) httpClient.close();
      if (await partial.exists()) await partial.delete();
    }
  }

  Future<void> delete(String remote) async {
    final file = await _path(validateSource(remote));
    if (await file.exists()) await file.delete();
  }
}
