import 'dart:ui' show SemanticsAction;
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(
  Widget child, {
  ThemeMode mode = ThemeMode.light,
  double width = 360,
}) => FlappaApp(
  themeMode: mode,
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  testWidgets(
    'highlighting preserves source, whitespace, and multiline strings',
    (tester) async {
      const source =
          "// example\nconst url = 'https://example.com';\nfinal text = r'''raw // string\n  with indentation''';\n/* outer /* nested */ comment */\nreturn 0xFF;\n";
      for (final language in FCodeLanguage.values) {
        await tester.pumpWidget(
          host(FCodeBlock(code: source, language: language)),
        );
        final text = tester.widget<SelectableText>(find.byType(SelectableText));
        expect(text.textSpan!.toPlainText(), source);
        if (language != FCodeLanguage.plain) {
          final colors = text.textSpan!.children!
              .cast<TextSpan>()
              .map((span) => span.style!.color)
              .toSet();
          expect(colors.length, greaterThan(1));
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'copy writes only original source and gives temporary inline feedback',
    (tester) async {
      const source = 'const name = "Flappa";\n';
      String? copied;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(host(const FCodeBlock(code: source)));
      await tester.tap(find.byTooltip('Copy code'));
      await tester.pump();
      expect(copied, source);
      expect(find.text('Copied'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Copy'), findsOneWidget);
    },
  );

  testWidgets('clipboard failure offers retry instead of claiming success', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'unavailable');
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(host(const FCodeBlock(code: 'flutter run')));
    await tester.tap(find.byTooltip('Copy code'));
    await tester.pump();
    expect(find.text('Retry copy'), findsOneWidget);
    expect(find.text('Copied'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long snippets scroll on both axes in a narrow dark block', (
    tester,
  ) async {
    final source = List.generate(
      80,
      (i) => "final message$i = '${'a long value ' * 12}';",
    ).join('\n');
    await tester.pumpWidget(
      host(
        FCodeBlock(
          code: source,
          filename: 'a_very_long_filename_that_should_ellipsize.dart',
          maxHeight: 220,
        ),
        mode: ThemeMode.dark,
        width: 280,
      ),
    );
    await tester.pumpAndSettle();
    final scrolls = tester.widgetList<SingleChildScrollView>(
      find.descendant(
        of: find.byType(FCodeBlock),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    final gutter = find.text(List.generate(80, (i) => '${i + 1}').join('\n'));
    expect(
      tester.getSize(gutter).height,
      closeTo(tester.getSize(find.byType(SelectableText)).height, 1),
    );
    for (final scroll in scrolls) {
      expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));
      scroll.controller!.jumpTo(100);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!
          .toPlainText(),
      source,
    );
  });

  testWidgets('changing the source resets copy feedback and syntax', (
    tester,
  ) async {
    await tester.pumpWidget(host(const FCodeBlock(code: 'final a = 1;')));
    await tester.tap(find.byTooltip('Copy code'));
    await tester.pump();
    await tester.pumpWidget(host(const FCodeBlock(code: 'final b = 2;')));
    expect(find.text('Copied'), findsNothing);
    expect(
      tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!
          .toPlainText(),
      'final b = 2;',
    );
  });
  testWidgets(
    'wrapping preserves source, aligns the gutter and survives toggles',
    (tester) async {
      final source =
          "final message = '${'long text ' * 24}';\n\nreturn message;\n";
      await tester.pumpWidget(
        host(FCodeBlock(code: source, maxHeight: 180), width: 280),
      );
      await tester.tap(find.byTooltip('Wrap lines'));
      await tester.pumpAndSettle();
      final scrolls = tester.widgetList<SingleChildScrollView>(
        find.descendant(
          of: find.byType(FCodeBlock),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(scrolls.map((s) => s.scrollDirection), [Axis.vertical]);
      expect(
        scrolls.single.controller!.position.maxScrollExtent,
        greaterThan(0),
      );
      expect(
        tester
            .widget<SelectableText>(find.byType(SelectableText))
            .textSpan!
            .toPlainText(),
        source,
      );
      expect(find.textContaining('1\n\n'), findsOneWidget);
      await tester.tap(find.byTooltip('Scroll long lines'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wrapped code supports enlarged text in narrow layouts', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: FCodeBlock(
            code: 'final text = "${'long value ' * 10}";\nreturn text;',
            wrapLines: true,
          ),
        ),
        width: 320,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('JSON keys and string values have distinct highlighting', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FCodeBlock(
          code: '{"name": "Flappa"}',
          language: FCodeLanguage.json,
        ),
      ),
    );
    final spans = tester
        .widget<SelectableText>(find.byType(SelectableText))
        .textSpan!
        .children!
        .cast<TextSpan>();
    final key = spans.firstWhere((s) => s.text == '"name"');
    final value = spans.firstWhere((s) => s.text == '"Flappa"');
    expect(key.style!.color, isNot(value.style!.color));
  });
  testWidgets('icon controls expose names and wrap state to accessibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(const FCodeBlock(code: 'final a = 1;')));
    expect(find.bySemanticsLabel('Wrap lines'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Wrap lines'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(find.byTooltip('Wrap lines'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Scroll long lines'), findsOneWidget);
    semantics.dispose();
  });
}
