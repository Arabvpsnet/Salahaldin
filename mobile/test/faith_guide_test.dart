import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salatime/view/screens/faith_guide/faith_guide_screen.dart';

void main() {
  final guideSource = File('assets/faith/guide.json').readAsStringSync();

  test('Ramadan and the library have text in all fifteen guide languages', () {
    final guides = (jsonDecode(guideSource) as Map<String, dynamic>)
        .cast<String, Map<String, dynamic>>();
    expect(guides.keys, unorderedEquals([
      'ar', 'en', 'da', 'bs', 'tr', 'ckb', 'kmr', 'de',
      'fr', 'ur', 'id', 'ms', 'es', 'bn', 'fa',
    ]));
    final requiredKeys = guides['ar']!.keys.where(
      (key) =>
          key.startsWith('ramadan') ||
          key.startsWith('library') ||
          key == 'reciter',
    );
    for (final entry in guides.entries) {
      for (final key in requiredKeys) {
        expect(
          entry.value[key],
          isA<String>().having((text) => text.trim(), 'text', isNotEmpty),
          reason: '${entry.key}.$key',
        );
      }
    }
  });

  testWidgets('faith guide opens four sections and selects Kurdish RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: _GuideAssetBundle(guideSource),
          child: const Scaffold(body: FaithGuideEntries()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Learn about Islam'));
    await tester.pumpAndSettle();
    expect(find.text('How do I become Muslim?'), findsOneWidget);
    expect(find.text('The five pillars of Islam'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    final sorani = find.text('کوردیی سۆرانی').last;
    await tester.ensureVisible(sorani);
    await tester.tap(sorani);
    await tester.pumpAndSettle();
    final shahada = find.text('چۆن ببمە موسڵمان؟');
    expect(shahada, findsOneWidget);
    expect(Directionality.of(tester.element(shahada)), TextDirection.rtl);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ramadan'));
    await tester.pumpAndSettle();
    expect(find.text('What is Ramadan?'), findsOneWidget);
    expect(find.text('The ruling on fasting in Ramadan'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Essentials of a valid fast'), 200);
    expect(find.text('Essentials of a valid fast'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Islamic library'));
    await tester.pumpAndSettle();
    expect(find.text('The Qur’an'), findsOneWidget);
    expect(find.text('Qur’an translations and tafsir'), findsOneWidget);
    expect(find.text('Remembrance and supplications'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ruqyah'));
    await tester.pumpAndSettle();
    expect(find.text('Magic, the evil eye and possession'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mahmoud Khalil Al-Hussary • MP3Quran'),
      150,
    );
    await tester.scrollUntilVisible(find.text('An-Nas · الناس'), 200);
    expect(find.text('An-Nas · الناس'), findsOneWidget);
  });
}

class _GuideAssetBundle extends CachingAssetBundle {
  _GuideAssetBundle(this.guideSource);

  final String guideSource;

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      key == 'assets/faith/guide.json'
      ? SynchronousFuture(guideSource)
      : rootBundle.loadString(key, cache: cache);

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}
