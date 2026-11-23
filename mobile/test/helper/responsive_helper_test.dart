import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salatime/helper/responsive_helper.dart';

void main() {
  for (final width in [320.0, 390.0, 649.0, 650.0, 840.0, 1024.0, 1299.0, 1300.0, 1920.0]) {
    testWidgets('layout classes are exclusive at $width', (tester) async {
      late List<bool> classes;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(builder: (context) {
            classes = [
              ResponsiveHelper.isMobile(context),
              ResponsiveHelper.isTab(context),
              ResponsiveHelper.isDesktop(context),
            ];
            return const SizedBox();
          }),
        ),
      );
      expect(classes.where((value) => value).length, 1);
      expect(classes, [width < 650, width >= 650 && width < 1300, width >= 1300]);
    });
  }
}
