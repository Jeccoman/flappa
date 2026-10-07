import 'dart:convert';
import 'dart:io';
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flappa_ui_example/playground/document.dart';
import 'package:flappa_ui_example/playground/playground_page.dart';
import 'package:flappa_ui_example/playground/render.dart';
import 'package:flappa_ui_example/site/landing_page.dart';
import 'package:flappa_ui_example/site/site_app.dart';
import 'package:flappa_ui_example/platform/browser.dart' as browser;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'document editing, ordering and history round trip without aliasing',
    () {
      final controller = PlaygroundController(templateDocument('Blank'));
      addTearDown(controller.dispose);
      controller.add(BlockKind.heading);
      final first = controller.selected!;
      controller.update(first.copyWith(title: 'Hello'));
      controller.duplicate(first.id);
      expect(controller.document.blocks.length, 2);
      expect(controller.document.blocks.map((b) => b.id).toSet().length, 2);
      controller.add(BlockKind.input);
      final input = controller.selected!;
      controller.move(2, 0);
      expect(controller.document.blocks.first.id, input.id);
      controller.remove(first.id);
      expect(controller.document.blocks.length, 2);
      controller.undo();
      expect(controller.document.blocks.length, 3);
      controller.redo();
      expect(controller.document.blocks.length, 2);
      final restored = ScreenDocument.decode(controller.document.encode());
      expect(restored.encode(), controller.document.encode());
      expect(() => restored.blocks.clear(), throwsUnsupportedError);
      controller.undo();
      controller.add(BlockKind.card);
      expect(controller.canRedo, isFalse);
    },
  );

  test('invalid imported projects fail before replacing a screen', () {
    final project =
        jsonDecode(templateDocument('Welcome').encode())
            as Map<String, dynamic>;
    for (final invalid in [
      {...project, 'version': 99},
      {...project, 'padding': -1},
      {...project, 'gap': 'six'},
      {...project, 'accent': 100},
      {
        ...project,
        'blocks': [project['blocks'][0], project['blocks'][0]],
      },
      {
        ...project,
        'blocks': [
          {'kind': 'unknown'},
        ],
      },
    ]) {
      expect(
        () => ScreenDocument.decode(jsonEncode(invalid)),
        throwsFormatException,
      );
    }
  });

  test('every exported widget compiles, including escaped user text', () async {
    final folder = Directory('.dart_tool/playground_export_check')
      ..createSync(recursive: true);
    addTearDown(() => folder.deleteSync(recursive: true));
    for (final name in ['Welcome', 'Settings', 'Dashboard', 'Blank']) {
      File(
        '${folder.path}/${name.toLowerCase()}.dart',
      ).writeAsStringSync(exportDart(templateDocument(name)));
    }
    final all = ScreenDocument(
      name: 'Quotes " and dollars \$ and newline\n',
      dark: true,
      accent: 4,
      blocks: [
        for (final kind in BlockKind.values)
          newBlock(
            kind,
            kind.name,
          ).copyWith(title: 'Quotes " and \${notCode} \\ line\nnext'),
      ],
    );
    File('${folder.path}/all.dart').writeAsStringSync(exportDart(all));
    final result = await Process.run('dart', ['analyze', folder.path]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(chartValues('8, bad, NaN, Infinity, -4'), [
      8.0,
      0.0,
      0.0,
      0.0,
      -4.0,
    ]);
  });

  for (final width in [390.0, 800.0, 1440.0]) {
    testWidgets('landing and playground render at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        FlappaApp(
          home: LandingPage(onComponents: () {}, onPlayground: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Less boilerplate.\nMore beautiful.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      browser.saveDraft(templateDocument('Welcome').encode());
      await tester.pumpWidget(
        FlappaApp(
          home: PlaygroundPage(onHome: () {}, onComponents: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Welcome aboard.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width < 1100) {
        await tester.tap(find.text('Add blocks'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('add-heading')));
      await tester.pumpAndSettle();
      if (width < 1100) {
        await tester.tap(find.text('Properties'));
        await tester.pumpAndSettle();
      }
      final field = find.descendant(
        of: find.widgetWithText(FField, 'Label'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(field, 'A screen I made');
      await tester.pump(const Duration(milliseconds: 450));
      if (width < 1100) {
        await tester.tap(find.text('Canvas'));
        await tester.pumpAndSettle();
      }
      expect(find.text('A screen I made'), findsWidgets);
      await tester.tap(find.text('Export code'));
      await tester.pumpAndSettle();
      expect(find.text('Your screen. Your code.'), findsOneWidget);
      expect(
        tester.widget<FCodeBlock>(find.byType(FCodeBlock)).code,
        contains('A screen I made'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('project import recovers from invalid JSON and can be undone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    browser.saveDraft(templateDocument('Welcome').encode());
    await tester.pumpWidget(
      FlappaApp(
        home: PlaygroundPage(onHome: () {}, onComponents: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    final input = find.descendant(
      of: find.byType(FDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(input, 'not json');
    await tester.tap(find.text('Import project'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Invalid project. Check the JSON and use a version 1 Flappa export.',
      ),
      findsOneWidget,
    );
    await tester.enterText(input, templateDocument('Settings').encode());
    await tester.tap(find.text('Import project'));
    await tester.pumpAndSettle();
    expect(find.byType(FDialog), findsNothing);
    expect(find.text('Your preferences'), findsWidgets);
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome aboard'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('landing navigation opens playground and explorer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SiteApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open playground'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaygroundPage), findsOneWidget);
    await tester.tap(find.text('All components ↗'));
    await tester.pumpAndSettle();
    expect(find.text('Component library'), findsOneWidget);
    expect(find.byTooltip('Mobile preview'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
