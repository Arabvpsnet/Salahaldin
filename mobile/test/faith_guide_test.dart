import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salatime/view/screens/faith_guide/faith_guide_screen.dart';

void main() {
  testWidgets('faith guide opens both sections and selects Kurdish RTL', (
    tester,
  ) async {
    await tester.runAsync(
      () => rootBundle.loadString('assets/faith/guide.json'),
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FaithGuideEntries())),
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
    await tester.tap(find.text('Ruqyah'));
    await tester.pumpAndSettle();
    expect(find.text('Magic, the evil eye and possession'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('An-Nas · الناس'), 200);
    expect(find.text('An-Nas · الناس'), findsOneWidget);
  });
}
