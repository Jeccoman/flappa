import 'package:flappa_ui/flappa_ui.dart';
import 'package:flappa_ui_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('all showcase sections render at $width px', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (var section = 0; section < sections.length; section++) {
        await tester.pumpWidget(
          FlappaApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ComponentDemos(
                  key: ValueKey(section),
                  section: section,
                  onNavigate: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester.takeException(),
          isNull,
          reason: '${sections[section]} at $width px',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('responsive shell opens mobile navigation and switches theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ShowcaseApp());
    await tester.pumpAndSettle();
    expect(find.text('Your next idea,\nbeautifully built.'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forms'));
    await tester.pumpAndSettle();
    expect(find.text('Input & textarea'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('customizer updates accent, radius, and dark mode live', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ShowcaseApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue'));
    await tester.pumpAndSettle();
    expect(
      FTheme.of(tester.element(find.text('Make it yours'))).colors.primary,
      const Color(0xFF2563EB),
    );
    await tester.tap(find.byType(FSelect<double>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Soft · 12 px').last);
    await tester.pumpAndSettle();
    expect(FTheme.of(tester.element(find.text('Make it yours'))).radius, 12);
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(
      FTheme.of(tester.element(find.text('Make it yours'))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('expandable code preserves visible component input state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FlappaApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DemoCard(
              title: 'Input',
              description: 'Try it',
              code: "const FInput(placeholder: 'Name');",
              child: FInput(placeholder: 'Name'),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'My unsaved value');
    await tester.tap(find.byTooltip('Show code'));
    await tester.pumpAndSettle();
    expect(find.byType(FCodeBlock), findsNWidgets(2));
    expect(
      tester.widgetList<FCodeBlock>(find.byType(FCodeBlock)).first.code,
      "import 'package:flappa_ui/flappa_ui.dart';",
    );
    expect(find.text('example.dart'), findsOneWidget);
    expect(find.text('My unsaved value'), findsOneWidget);
    expect(find.text('Preview'), findsNothing);
    await tester.tap(find.byTooltip('Hide code'));
    await tester.pumpAndSettle();
    expect(find.text('My unsaved value'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('getting started assigns the correct language to each block', (
    tester,
  ) async {
    await tester.pumpWidget(
      FlappaApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ComponentDemos(section: 8, onNavigate: (_) {}),
          ),
        ),
      ),
    );
    final languages = tester
        .widgetList<FCodeBlock>(find.byType(FCodeBlock))
        .map((block) => block.language);
    expect(languages, [
      FCodeLanguage.bash,
      FCodeLanguage.dart,
      FCodeLanguage.bash,
    ]);
    expect(tester.takeException(), isNull);
  });
}
