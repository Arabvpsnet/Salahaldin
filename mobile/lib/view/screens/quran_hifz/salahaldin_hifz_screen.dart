import 'package:flutter/material.dart';
import 'package:salatime/service/quran/salahaldin_hifz_service.dart';
import 'package:salatime/service/reading/reading_progress_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local Quran memorization. No cloud sync or external Quran data.
class SalahaldinHifzScreen extends StatefulWidget {
  const SalahaldinHifzScreen({super.key, this.initialSurah = 1});

  final int initialSurah;

  static String titleFor(BuildContext context) =>
      switch (Localizations.localeOf(context).languageCode) {
        'da' => 'Min hifzplan',
        'tr' => 'Hafızlık planım',
        'en' => 'My memorization plan',
        _ => 'خطة الحفظ والمراجعة',
      };

  @override
  State<SalahaldinHifzScreen> createState() => _SalahaldinHifzScreenState();
}

class _SalahaldinHifzScreenState extends State<SalahaldinHifzScreen> {
  SalahaldinHifzStore? _store;
  HifzSession? _session;
  bool _loading = true;
  late int _surah;
  int _first = 1;
  int _last = 5;
  int _repetitions = 5;
  HifzReview _review = HifzReview.tomorrow;

  @override
  void initState() {
    super.initState();
    _surah = widget.initialSurah.clamp(1, 114).toInt();
    _last = _ayahCount(_surah).clamp(1, 5).toInt();
    _initialize();
  }

  int _ayahCount(int surah) => QuranReadingKeys.verseCounts[surah - 1];

  Future<void> _initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final store = SalahaldinHifzStore(preferences);
    final saved = store.restore();
    if (!mounted) return;
    setState(() {
      _store = store;
      _session = saved;
      if (saved != null) {
        _surah = saved.plan.surah;
        _first = saved.plan.firstAyah;
        _last = saved.plan.lastAyah;
        _repetitions = saved.plan.repetitions;
        _review = saved.plan.review;
      }
      _loading = false;
    });
  }

  String _label(String ar, String en, String da, String tr) =>
      switch (Localizations.localeOf(context).languageCode) {
        'da' => da,
        'tr' => tr,
        'en' => en,
        _ => ar,
      };

  String _reviewLabel(HifzReview review) => switch (review) {
    HifzReview.today => _label('اليوم', 'Today', 'I dag', 'Bugün'),
    HifzReview.tomorrow => _label('غدًا', 'Tomorrow', 'I morgen', 'Yarın'),
    HifzReview.threeDays =>
      _label('بعد ٣ أيام', 'In 3 days', 'Om 3 dage', '3 gün sonra'),
    HifzReview.week =>
      _label('بعد أسبوع', 'In one week', 'Om en uge', 'Bir hafta sonra'),
  };

  Future<void> _start() async {
    final store = _store;
    if (store == null) return;
    final plan = HifzPlan.create(
      surah: _surah,
      firstAyah: _first,
      lastAyah: _last,
      repetitions: _repetitions,
      review: _review,
    );
    final session = HifzSession.start(plan);
    await store.save(session);
    if (!mounted) return;
    setState(() => _session = session);
  }

  Future<void> _advance() async {
    final store = _store;
    final session = _session;
    if (store == null || session == null || session.isComplete) return;
    final updated = session.advance();
    await store.save(updated);
    if (!mounted) return;
    setState(() => _session = updated);
  }

  Future<void> _clear() async {
    await _store?.clear();
    if (!mounted) return;
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(SalahaldinHifzScreen.titleFor(context)),
        actions: [
          if (_session != null)
            IconButton(
              tooltip: _label('مسح الخطة', 'Clear plan', 'Slet plan', 'Planı sil'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _clear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _label(
                            'خطة لحفظ الآيات وتكرارها دون إنترنت',
                            'Plan verse repetition offline',
                            'Planlæg gentagelse af vers offline',
                            'Ayet tekrarını çevrimdışı planla',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 15),
                        Text(_label('السورة', 'Surah', 'Sura', 'Sure')),
                        DropdownButton<int>(
                          value: _surah,
                          isExpanded: true,
                          items: List.generate(
                            114,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text(
                                _label('السورة ', 'Surah ', 'Sura ', 'Sure ') +
                                    (index + 1).toString(),
                              ),
                            ),
                          ),
                          onChanged: (number) {
                            if (number == null) return;
                            setState(() {
                              _surah = number;
                              _first = 1;
                              _last = _ayahCount(number).clamp(1, 5).toInt();
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ayahPicker(
                                _label('من الآية', 'From', 'Fra vers', 'Başlangıç'),
                                _first, 1, _last,
                                (n) => setState(() => _first = n),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ayahPicker(
                                _label('إلى الآية', 'To', 'Til vers', 'Bitiş'),
                                _last, _first, _ayahCount(_surah),
                                (n) => setState(() => _last = n),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${_label('عدد التكرارات', 'Repetitions', 'Gentagelser', 'Tekrar')} · $_repetitions",
                        ),
                        Slider(
                          value: _repetitions.toDouble(),
                          min: 1, max: 20, divisions: 19,
                          label: _repetitions.toString(),
                          onChanged: (value) =>
                              setState(() => _repetitions = value.round()),
                        ),
                        Text(_label(
                          'موعد المراجعة',
                          'Review after finishing',
                          'Gentag efter afslutning',
                          'Tamamladıktan sonra tekrar',
                        )),
                        DropdownButton<HifzReview>(
                          value: _review,
                          isExpanded: true,
                          items: HifzReview.values
                              .map((choice) => DropdownMenuItem(
                                value: choice,
                                child: Text(_reviewLabel(choice)),
                              )).toList(),
                          onChanged: (choice) {
                            if (choice != null) setState(() => _review = choice);
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text(_label(
                            'ابدأ خطة جديدة', 'Start a new plan',
                            'Start ny plan', 'Yeni plan başlat',
                          )),
                          onPressed: _start,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_session != null)
                  Card(
                    color: scheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _session!.isComplete
                              ? _label('أتممت جلسة الحفظ', 'Session complete',
                                  'Session afsluttet', 'Oturum tamamlandı')
                              : _label('جلسة الحفظ الحالية', 'Current session',
                                  'Aktuel session', 'Mevcut oturum'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${_label('الآية الحالية', 'Current verse', 'Nuværende vers', 'Geçerli ayet')}: ${_session!.currentAyah}",
                          ),
                          Text(
                            "${_label('التكرار المكتمل', 'Completed rounds', 'Færdige runder', 'Tamamlanan tekrar')}: ${_session!.completedRepetitions}/${_session!.plan.repetitions}",
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: _session!.progress),
                          const SizedBox(height: 14),
                          if (!_session!.isComplete)
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(_label(
                                'حفظت هذه الآية • التالي',
                                'Verse reviewed • Next',
                                'Vers gentaget • Næste',
                                'Ayet tekrarlandı • İleri',
                              )),
                              onPressed: _advance,
                            )
                          else
                            Text(
                              "${_label('المراجعة التالية', 'Next review', 'Næste gentagelse', 'Sonraki tekrar')}: ${_session!.plan.reviewDate(_session!.updatedAt.toLocal()).toIso8601String().split('T').first}",
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  _label(
                    'تُحفظ الخطة على جهازك فقط. لا تُنقل إلى الخادم أو الحساب.',
                    'Your memorization activity stays on this device only.',
                    'Din hifzplan gemmes kun på denne enhed.',
                    'Ezber planınız yalnızca bu cihazda saklanır.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }

  Widget _ayahPicker(
      String title, int value, int min, int max, ValueChanged<int> onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        DropdownButton<int>(
          value: value,
          isExpanded: true,
          items: [
            for (var n = min; n <= max; n++)
              DropdownMenuItem(value: n, child: Text(n.toString())),
          ],
          onChanged: (number) {
            if (number != null) onChange(number);
          },
        ),
      ],
    );
  }
}
