import 'package:flutter/material.dart';
import 'package:salatime/service/quran/licensed_quran_repository.dart';

/// Separate edition picker; does not replace the app's existing QuranEnc reader.
class LicensedQuranReaderTab extends StatefulWidget {
  const LicensedQuranReaderTab({super.key, required this.surahNumber});
  final int surahNumber;

  static String title(BuildContext context) =>
      switch (Localizations.localeOf(context).languageCode) {
        'da' => 'Tafsir og oversættelser',
        'en' => 'Tafsir & translations',
        'fr' => 'Tafsir et traductions',
        'tr' => 'Tefsir ve mealler',
        _ => 'التفسير والترجمات',
      };

  @override
  State<LicensedQuranReaderTab> createState() => _LicensedQuranReaderTabState();
}

class _LicensedQuranReaderTabState extends State<LicensedQuranReaderTab> {
  final repository = LicensedQuranRepository.instance;
  String _edition = 'ar.muyassar';
  Future<List<String>>? _verses;
  bool _selectedFromLanguage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedFromLanguage) return;
    _selectedFromLanguage = true;
    final lang = Localizations.localeOf(context).languageCode;
    final id = switch (lang) {
      'en' => 'en.sahih',
      'fr' => 'fr.hamidullah',
      'ur' => 'ur.jalandhry',
      _ => 'ar.muyassar',
    };
    if (_edition != id) {
      _edition = id;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant LicensedQuranReaderTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) _load();
  }

  void _load() {
    _verses = repository.read(widget.surahNumber, _edition);
  }

  String _label(String ar, String en, String da, String tr) =>
      switch (Localizations.localeOf(context).languageCode) {
        'da' => da,
        'tr' => tr,
        'en' || 'fr' => en,
        _ => ar,
      };

  @override
  Widget build(BuildContext context) {
    final source = LicensedQuranRepository.edition(_edition);
    final isRtl = source.lang == 'ar' || source.lang == 'ur';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(_edition),
                initialValue: _edition,
                isExpanded: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _label(
                    'اختر الترجمة أو التفسير',
                    'Select translation or tafsir',
                    'Vælg oversættelse eller tafsir',
                    'Tefsir veya meal seçin',
                  ),
                ),
                items: [
                  for (final entry in LicensedQuranRepository.editions)
                    DropdownMenuItem(
                      value: entry.id,
                      child: Text(entry.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  if (value == null || value == _edition) return;
                  setState(() {
                    _edition = value;
                    _load();
                  });
                },
              ),
              const SizedBox(height: 10),
              Text(source.credit, style: Theme.of(context).textTheme.bodySmall),
              Text('Source: https://github.com/bahaback-hub/quran-app',
                style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<String>>(
            future: _verses,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_label(
                        'تعذر تحميل النسخة',
                        'Cannot load edition',
                        'Udgaven kan ikke indlæses',
                        'Metin yüklenemedi',
                      )),
                      TextButton.icon(
                        onPressed: () => setState(_load),
                        icon: const Icon(Icons.refresh),
                        label: Text(_label('إعادة المحاولة', 'Retry',
                          'Prøv igen', 'Yeniden dene')),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final texts = snapshot.data!;
              return ListView.builder(
                key: PageStorageKey<String>(
                  'licensed_${source.id}_${widget.surahNumber}',
                ),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                itemCount: texts.length,
                itemBuilder: (context, index) => Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: isRtl
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.surahNumber}:${index + 1}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          texts[index],
                          textDirection: isRtl
                            ? TextDirection.rtl : TextDirection.ltr,
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: source.lang == 'ar' ? 22 : 19,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
