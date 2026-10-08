import 'dart:convert';
import 'dart:io';
import 'package:flappa_ui_example/playground/document.dart';
import 'package:flappa_ui_example/playground/render.dart';
import 'package:flappa_ui_example/playground/studio_document.dart';
import 'package:flappa_ui_example/playground/studio_render.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the public package, documented setup, and exports work in a separate app',
    () async {
      final configFile = File('.dart_tool/package_config.json').absolute;
      final config =
          jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
      final package = (config['packages'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((entry) => entry['name'] == 'flappa_ui');
      final root = Directory.fromUri(
        configFile.uri.resolve(package['rootUri'] as String),
      );
      final consumer = await Directory.systemTemp.createTemp(
        'flappa-consumer-',
      );
      addTearDown(() => consumer.delete(recursive: true));
      Future<void> write(String path, String content) async {
        final file = File('${consumer.path}/$path');
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      }

      Future<void> flutter(List<String> args) async {
        final result = await Process.run(
          'flutter',
          args,
          workingDirectory: consumer.path,
        );
        expect(
          result.exitCode,
          0,
          reason: '${args.join(' ')}\n${result.stdout}\n${result.stderr}',
        );
      }

      final symbols = <String>{};
      final widgets = <String>{};
      await for (final file in Directory(
        '${root.path}/lib/src',
      ).list(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final source = await file.readAsString();
        symbols.addAll(
          RegExp(
            r'\b(?:class|enum)\s+(F\w+)',
          ).allMatches(source).map((m) => m[1]!),
        );
        symbols.addAll(
          RegExp(
            r'^(?:Future[^\n]*|void) (showF\w+)',
            multiLine: true,
          ).allMatches(source).map((m) => m[1]!),
        );
        widgets.addAll(
          RegExp(
            r'class (F\w+)(?:<[^\n]+?>)? extends (?:StatelessWidget|StatefulWidget|FormField)',
          ).allMatches(source).map((m) => m[1]!),
        );
      }
      final guide = await File('${root.path}/doc/components.md').readAsString();
      for (final widget in widgets) {
        expect(
          guide,
          contains('`$widget`'),
          reason: '$widget must have public usage documentation',
        );
      }
      expect(
        symbols,
        containsAll([
          'FlappaApp',
          'FButton',
          'FInput',
          'FCard',
          'FTypography',
          'showFDialog',
        ]),
      );
      await write('pubspec.yaml', '''name: flappa_consumer_check
publish_to: none
environment:
  sdk: '>=3.10.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flappa_ui:
    path: ${jsonEncode(root.path)}
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: true
''');
      await write(
        'lib/public_api.dart',
        "import 'package:flappa_ui/flappa_ui.dart' as flappa;\nfinal publicApi = <Object>[${symbols.map((s) => 'flappa.$s').join(',')}];\n",
      );
      await write(
        'lib/main.dart',
        await File('${root.path}/example/example.dart').readAsString(),
      );
      final readme = await File('${root.path}/README.md').readAsString();
      await write(
        'lib/readme.dart',
        RegExp(r'```dart\n([\s\S]*?)\n```').firstMatch(readme)![1]!,
      );
      final allBlocks = ScreenDocument(
        name: 'All public blocks',
        blocks: [
          for (final kind in BlockKind.values) newBlock(kind, kind.name),
        ],
      );
      final exported = exportDart(allBlocks);
      expect(exported, contains('FTypography('));
      expect(exported, isNot(contains('/src/')));
      await write('lib/blocks.dart', exported);
      await write('lib/flow.dart', exportStudioDart(starterProject()));
      await write('test/consumer_test.dart', consumerTests);
      await flutter(['pub', 'get', '--offline']);
      await flutter(['analyze']);
      await flutter(['test']);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

const consumerTests = r'''
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flappa_consumer_check/main.dart' as example;
import 'package:flappa_consumer_check/readme.dart' as readme;
import 'package:flappa_consumer_check/blocks.dart' as blocks;
import 'package:flappa_consumer_check/flow.dart' as flow;
import 'package:flappa_consumer_check/public_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every public type and overlay helper is available through one import', () {
    expect(publicApi, containsAll([FButton, FInput, FCard, FlappaApp, FTypography, showFDialog]));
  });

  testWidgets('the README app starts with the public package', (tester) async {
    readme.main();
    await tester.pumpAndSettle();
    expect(find.byType(FButton), findsOneWidget);
    expect(FTheme.of(tester.element(find.byType(FButton))), isA<FThemeData>());
    await tester.tap(find.byType(FButton));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [390.0, 1440.0]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('package example validates and saves at $width in $mode', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(FlappaApp(themeMode: mode, home: const example.ExampleScreen()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save preferences'));
        await tester.pumpAndSettle();
        expect(find.text('Enter your name'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), ' Ada ');
        await tester.tap(find.text('Product updates'));
        await tester.pumpAndSettle();
        expect(tester.widget<FSwitch>(find.byType(FSwitch)).value, isFalse);
        await tester.tap(find.text('Save preferences'));
        await tester.pumpAndSettle();
        expect(find.text('Preferences saved for Ada'), findsOneWidget);
        expect(find.text('Product updates are off.'), findsOneWidget);
        expect(find.text('Enter your name'), findsNothing);
        expect(FTheme.of(tester.element(find.byType(FCard))).brightness,
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets('every canvas block runs and controls update at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      blocks.main();
      await tester.pumpAndSettle();
      expect(find.byType(FTypography), findsNWidgets(2));
      expect(find.byType(FButton), findsOneWidget);
      expect(find.byType(FInput), findsOneWidget);
      expect(find.byType(FBarChart), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Works outside the playground');
      final toggle = find.byType(FSwitch);
      await tester.ensureVisible(toggle);
      final before = tester.widget<FSwitch>(toggle).value;
      await tester.tap(find.descendant(of: toggle, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(tester.widget<FSwitch>(toggle).value, !before);
      final checkbox = find.byType(FCheckbox);
      await tester.ensureVisible(checkbox);
      final checked = tester.widget<FCheckbox>(checkbox).value;
      await tester.tap(find.descendant(of: checkbox, matching: find.byType(Checkbox)));
      await tester.pumpAndSettle();
      expect(tester.widget<FCheckbox>(checkbox).value, !checked!);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('exported Flappa buttons navigate and return between screens', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    flow.main();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Make it yours.'), findsOneWidget);
    await tester.ensureVisible(find.text('Save preferences'));
    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome aboard.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
''';
