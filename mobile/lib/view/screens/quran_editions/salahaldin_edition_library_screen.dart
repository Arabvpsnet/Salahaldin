import 'package:flutter/material.dart';
import 'package:salatime/data/model/response/sura_detile_model.dart';
import 'package:salatime/service/quran/quran_translation_repository.dart';
import 'package:salatime/view/screens/quran/widget/quran_translation_source_card.dart';
import 'package:salatime/view/screens/quran/widget/quran_translation_text.dart';

/// Edition selection is independent of the app interface language.
/// Every chapter is loaded from the verified bundled assets, without a request.
class SalahaldinEditionLibraryScreen extends StatefulWidget {
  const SalahaldinEditionLibraryScreen({super.key, this.initialSurah = 1});

  final int initialSurah;

  @override
  State<SalahaldinEditionLibraryScreen> createState() =>
      _SalahaldinEditionLibraryScreenState();
}

class _SalahaldinEditionLibraryScreenState
    extends State<SalahaldinEditionLibraryScreen> {
  static const languages = <String, String>{
    'ar': 'العربية — التفسير الميسر',
    'ar_mokhtasar': 'العربية — التفسير المختصر',
    'bn': 'বাংলা',
    'bs': 'Bosanski',
    'de': 'Deutsch',
    'en': 'English',
    'es': 'Español',
    'fa': 'فارسی',
    'fr': 'Français',
    'id': 'Bahasa Indonesia',
    'ku': 'کوردی — باموکی',
    'kmr': 'بادینی — سەناهی',
    'ms': 'Bahasa Melayu',
    'tr': 'Türkçe',
    'ur': 'اردو',
  };

  late int _surah;
  late Future<SuraDetaileModel> _reading;
  String _language = 'ar';
  bool _localeInitialized = false;
  double _fontSize = 19;

  @override
  void initState() {
    super.initState();
    _surah = widget.initialSurah.clamp(1, 114).toInt();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localeInitialized) return;
    _localeInitialized = true;
    final locale = Localizations.localeOf(context).languageCode;
    if (languages.containsKey(locale)) {
      _language = locale;
      _reload();
    }
  }

  void _reload() {
    _reading = QuranTranslationRepository.instance.loadSurah(
      _surah,
      languageCode: _language,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'مكتبة الترجمات والتفاسير' : 'Quran editions'),
        actions: [
          IconButton(
            tooltip: ar ? 'تصغير الخط' : 'Decrease font size',
            icon: const Icon(Icons.text_decrease),
            onPressed: _fontSize <= 14
                ? null : () => setState(() => _fontSize -= 2),
          ),
          IconButton(
            tooltip: ar ? 'تكبير الخط' : 'Increase font size',
            icon: const Icon(Icons.text_increase),
            onPressed: _fontSize >= 30
                ? null : () => setState(() => _fontSize += 2),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(ar
                  ? 'اختر اللغة والسورة — النصوص محفوظة دون إنترنت'
                  : 'Choose language and surah — complete offline editions'),
                DropdownButton<String>(
                  key: const ValueKey('edition-language'),
                  isExpanded: true,
                  value: _language,
                  items: [
                    for (final item in languages.entries)
                      DropdownMenuItem(
                        value: item.key,
                        child: Text(item.value),
                      ),
                  ],
                  onChanged: (code) {
                    if (code == null) return;
                    setState(() {
                      _language = code;
                      _reload();
                    });
                  },
                ),
                DropdownButton<int>(
                  key: const ValueKey('edition-surah'),
                  isExpanded: true,
                  value: _surah,
                  items: [
                    for (var i = 1; i <= 114; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text((ar ? 'السورة ' : 'Surah ') + i.toString()),
                      ),
                  ],
                  onChanged: (number) {
                    if (number == null) return;
                    setState(() {
                      _surah = number;
                      _reload();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<SuraDetaileModel>(
              future: _reading,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ar
                          ? 'تعذر تحميل إصدار القرآن؛ لم يتم استبدال النص بمصدر آخر'
                          : 'Edition unavailable; no substitute text was inserted'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => setState(_reload),
                          child: Text(ar ? 'أعد المحاولة' : 'Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final model = snapshot.requireData;
                final edition = model.translationSource;
                final verses = <PageVerses>[
                  for (final page in model.data?.chapterInfo ?? <ChapterInfo>[])
                    ...?page.pageVerses,
                ];
                if (edition == null || verses.isEmpty) {
                  return const Center(child: Text('Edition unavailable'));
                }
                return ListView.builder(
                  key: ValueKey('edition-$_language-$_surah'),
                  itemCount: verses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: QuranTranslationSourceCard(source: edition),
                      );
                    }
                    final verse = verses[index - 1];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  (ar ? 'الآية ' : 'Ayah ') +
                                    (verse.versesNumber ?? index).toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  verse.arabicName ?? '',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'AmiriQuran',
                                    fontSize: _fontSize + 6,
                                    height: 2,
                                  ),
                                ),
                                const Divider(height: 32),
                                QuranTranslationText(
                                  text: verse.translatedName ?? '',
                                  footnotes: verse.translationFootnotes,
                                  languageCode: edition.languageCode,
                                  fontSize: _fontSize,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
