import 'package:flappa_ui_example/main_components.dart' as gallery;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('native gallery opens components within device safe areas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.reset);
    gallery.main();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('COMPONENTS / BUTTONS'), findsOneWidget);
    expect(find.byTooltip('Mobile preview'), findsNothing);
    expect(
      tester.getTopLeft(find.byTooltip('Open navigation')).dy,
      greaterThanOrEqualTo(59),
    );
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Forms'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'On a phone');
    expect(find.text('On a phone'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
