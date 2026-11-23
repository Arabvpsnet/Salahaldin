import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

typedef _Guide = Map<String, dynamic>;

final _guides = rootBundle
    .loadString('assets/faith/guide.json')
    .then(
      (source) => (jsonDecode(source) as Map<String, dynamic>)
          .cast<String, _Guide>(),
    );

const _rtl = {'ar', 'fa', 'ur', 'ckb', 'kmr'};
const _threeSurahs = [
  (112, 'الإخلاص', 'Al-Ikhlas'),
  (113, 'الفلق', 'Al-Falaq'),
  (114, 'الناس', 'An-Nas'),
];
const _recitations = [(1, 'الفاتحة', 'Al-Fatihah'), ..._threeSurahs];

String _language(BuildContext context, Map<String, _Guide> guides) {
  final code = Localizations.localeOf(context).languageCode;
  return guides.containsKey(code) ? code : 'en';
}

class FaithGuideEntries extends StatelessWidget {
  const FaithGuideEntries({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _guides,
      builder: (context, snapshot) {
        final guides = snapshot.data;
        if (guides == null) return const SizedBox.shrink();
        final guide = guides[_language(context, guides)]!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              for (final (key, icon, ruqyah) in [
                ('islam', Icons.menu_book_outlined, false),
                ('ruqyah', Icons.headphones_outlined, true),
              ])
                Card(
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text(guide[key] as String),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: RouteSettings(name: '/faith/$key'),
                        builder: (_) => _FaithGuideScreen(
                          guides: guides,
                          language: _language(context, guides),
                          ruqyah: ruqyah,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FaithGuideScreen extends StatefulWidget {
  const _FaithGuideScreen({
    required this.guides,
    required this.language,
    required this.ruqyah,
  });

  final Map<String, _Guide> guides;
  final String language;
  final bool ruqyah;

  @override
  State<_FaithGuideScreen> createState() => _FaithGuideScreenState();
}

class _FaithGuideScreenState extends State<_FaithGuideScreen> {
  static const _shahada =
      'أشهد أن لا إله إلا الله، وأشهد أن محمدًا رسول الله';
  static const _transliteration =
      'Ashhadu an lā ilāha illā Allāh, wa ashhadu anna Muḥammadan rasūlu Allāh.';

  late String _language = widget.language;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerSubscription;
  int? _track;
  bool _busy = false;
  bool _playing = false;
  bool _audioError = false;

  String _text(String key) => widget.guides[_language]![key] as String;

  Future<void> _play(int surah) async {
    final player = _player ??= AudioPlayer();
    _playerSubscription ??= player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _playing =
            state.playing &&
            state.processingState != ProcessingState.completed;
      });
    });
    setState(() {
      _busy = true;
      _audioError = false;
    });
    try {
      if (_track == surah && _playing) {
        await player.pause();
        return;
      }
      if (_track != surah) {
        await player.pause();
        if (!mounted) return;
        final chapter = surah.toString().padLeft(3, '0');
        await player.setUrl('https://server8.mp3quran.net/afs/$chapter.mp3');
        if (!mounted) return;
        setState(() => _track = surah);
      } else if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      if (!mounted) return;
      unawaited(player.play().catchError((Object error) {
        if (mounted) setState(() => _audioError = true);
      }));
    } catch (_) {
      if (mounted) {
        setState(() {
          _track = null;
          _audioError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    unawaited(_playerSubscription?.cancel());
    unawaited(_player?.dispose());
    super.dispose();
  }

  Widget _section(String key, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_text(key), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl.contains(_language)
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(_text(widget.ruqyah ? 'ruqyah' : 'islam'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 4,
                end: 4,
                bottom: 12,
              ),
              child: DropdownButton<String>(
                value: _language,
                isExpanded: true,
                items: [
                  for (final entry in widget.guides.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value['name'] as String),
                    ),
                ],
                onChanged: (code) {
                  if (code != null) setState(() => _language = code);
                },
              ),
            ),
            if (widget.ruqyah) ...[
              _section('ruqyah', [
                Text(_text('practice')),
                const SizedBox(height: 8),
                Text(
                  _language == 'ar'
                      ? 'مسلم 2200 • البخاري 5017، 5736'
                      : 'Muslim 2200 • Al-Bukhari 5017, 5736',
                ),
              ]),
              _section('signs', [Text(_text('care'))]),
              _section('audio', [
                Text(
                  _language == 'ar'
                      ? 'مشاري راشد العفاسي • MP3Quran'
                      : 'Mishary Rashid Alafasy • MP3Quran',
                ),
                for (final (number, arabic, latin) in _recitations)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_language == 'ar' ? arabic : '$latin · $arabic'),
                    leading: Icon(
                      _track == number && _playing
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    enabled: !_busy,
                    onTap: _busy ? null : () => _play(number),
                  ),
                if (_busy) const LinearProgressIndicator(),
                if (_audioError)
                  Semantics(liveRegion: true, child: Text(_text('audio_error'))),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () async {
                      try {
                        final source = Uri.https('www.mp3quran.net', '/eng/afs');
                        if (await launchUrl(source)) return;
                      } on PlatformException {
                        // Display the same retry message as the stream.
                      }
                      if (mounted) setState(() => _audioError = true);
                    },
                    child: const Text('MP3Quran ↗'),
                  ),
                ),
              ]),
            ] else ...[
              _section('shahada', [
                Text(_text('start')),
                const SizedBox(height: 12),
                Text(
                  _shahada,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(_transliteration, textDirection: TextDirection.ltr),
                const SizedBox(height: 8),
                Text(_text('meaning')),
              ]),
              _section('pillars', [
                for (final pillar in (widget.guides[_language]!['five'] as List))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $pillar'),
                  ),
                Text(_language == 'ar' ? 'البخاري 8' : 'Al-Bukhari 8'),
              ]),
              _section('importance', [Text(_text('why'))]),
            ],
          ],
        ),
      ),
    );
  }
}
