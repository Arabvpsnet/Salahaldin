import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:salatime/service/quran/salahaldin_hifz_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('validates real 114-surah Quran boundaries', () {
    expect(
      () => HifzPlan.create(surah: 1, firstAyah: 1, lastAyah: 8),
      throwsRangeError,
    );
    expect(
      () => HifzPlan.create(surah: 115, firstAyah: 1, lastAyah: 1),
      throwsRangeError,
    );
    expect(
      () => HifzPlan.create(
        surah: 2,
        firstAyah: 5,
        lastAyah: 4,
      ),
      throwsRangeError,
    );
    expect(
      () => HifzPlan.create(
        surah: 2,
        firstAyah: 1,
        lastAyah: 2,
        repetitions: 101,
      ),
      throwsRangeError,
    );
  });

  test('advances every ayah and completes exact repetitions', () {
    final plan = HifzPlan.create(
      surah: 1,
      firstAyah: 2,
      lastAyah: 4,
      repetitions: 2,
    );
    var session = HifzSession.start(
      plan,
      now: DateTime.utc(2026, 11, 21),
    );
    expect(session.progress, 0);
    session = session.advance();
    expect(session.currentAyah, 3);
    session = session.advance();
    expect(session.currentAyah, 4);
    session = session.advance();
    expect(session.currentAyah, 2);
    expect(session.completedRepetitions, 1);
    session = session.advance().advance().advance();
    expect(session.isComplete, isTrue);
    expect(session.progress, 1);
    expect(session.advance().toJson(), session.toJson());
  });

  test('review date uses calendar days over Copenhagen DST changes', () {
    final plan = HifzPlan.create(
      surah: 1,
      firstAyah: 1,
      lastAyah: 3,
      review: HifzReview.tomorrow,
    );
    expect(
      plan.reviewDate(DateTime(2026, 3, 28)).toIso8601String(),
      '2026-03-29T00:00:00.000Z',
    );
    expect(
      HifzPlan.create(
        surah: 1,
        firstAyah: 1,
        lastAyah: 3,
        review: HifzReview.week,
      ).reviewDate(DateTime(2026, 10, 24)).toIso8601String(),
      '2026-10-31T00:00:00.000Z',
    );
  });

  test('persists sessions offline and rejects old or tampered data', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SalahaldinHifzStore(prefs);
    final date = DateTime.utc(2026, 11, 21, 11);
    final plan = HifzPlan.create(
      surah: 2,
      firstAyah: 10,
      lastAyah: 12,
    );
    final session = HifzSession.start(plan, now: date).advance(now: date);
    expect(await store.save(session), isTrue);
    expect(
      store.restore(now: date.add(const Duration(hours: 2)))?.currentAyah,
      11,
    );
    expect(
      store.restore(now: date.add(const Duration(days: 8))),
      isNull,
    );

    final malicious = <String, dynamic>{
      ...session.toJson(),
      'currentAyah': 9999,
    };
    await prefs.setString(
      SalahaldinHifzStore.storageKey,
      jsonEncode(malicious),
    );
    expect(store.restore(now: date), isNull);
    await prefs.setString(SalahaldinHifzStore.storageKey, '{bad');
    expect(store.restore(now: date), isNull);
  });

  test('rejects future-dated resume records and clears only its own key',
      () async {
    SharedPreferences.setMockInitialValues({'another.preference': 'keep'});
    final prefs = await SharedPreferences.getInstance();
    final store = SalahaldinHifzStore(prefs);
    final plan = HifzPlan.create(
      surah: 1,
      firstAyah: 1,
      lastAyah: 7,
    );
    final now = DateTime.utc(2026, 11, 21);
    await store.save(
      HifzSession.start(plan, now: now.add(const Duration(days: 1))),
    );
    expect(store.restore(now: now), isNull);
    await store.clear();
    expect(prefs.getString('another.preference'), 'keep');
  });
}
