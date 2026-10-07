import 'dart:convert';
import 'dart:io';
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flappa_ui_example/platform/browser.dart' as browser;
import 'package:flappa_ui_example/playground/document.dart';
import 'package:flappa_ui_example/playground/playground_page.dart';
import 'package:flappa_ui_example/playground/studio_document.dart';
import 'package:flappa_ui_example/playground/studio_page.dart';
import 'package:flappa_ui_example/playground/studio_render.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canvas round trip and legacy screen migration preserve layout', () {
    final project = starterProject(templateDocument('Layouts'));
    expect(StudioProject.decode(project.encode()).encode(), project.encode());
    expect(() => project.screens.clear(), throwsUnsupportedError);
    expect(() => project.screens.first.actions.clear(), throwsUnsupportedError);
    final old = templateDocument('Layouts');
    final migrated = StudioProject.decode(old.encode());
    expect(migrated.screens.single.document.encode(), old.encode());
    expect(migrated.startId, migrated.screens.single.id);
  });

  test(
    'imports reject invalid geometry, identities, actions and references',
    () {
      final valid =
          jsonDecode(starterProject().encode()) as Map<String, dynamic>;
      final screens = valid['screens'] as List;
      final first = screens.first as Map<String, dynamic>;
      final invalid = <Map<String, dynamic>>[
        {...valid, 'version': 999},
        {...valid, 'screens': []},
        {...valid, 'screens': List.filled(21, first)},
        {...valid, 'startId': 'missing'},
        {
          ...valid,
          'screens': [first, first],
        },
        for (final patch in [
          {'x': -1},
          {'width': 0},
          {'height': 'tall'},
          {'notes': 42},
          {
            'actions': {
              'missing': {'target': 'settings', 'transition': 'slide'},
            },
          },
          {
            'actions': {
              'block_5': {'target': 'unknown', 'transition': 'slide'},
            },
          },
          {
            'actions': {
              'block_5': {'target': 'settings', 'transition': 'spin'},
            },
          },
          {
            'actions': {
              'block_0': {'target': 'settings', 'transition': 'slide'},
            },
          },
        ])
          {
            ...valid,
            'screens': [
              {...first, ...patch},
              screens.last,
            ],
          },
      ];
      for (final item in invalid) {
        expect(
          () => StudioProject.decode(jsonEncode(item)),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'deletion cleans inbound links, editing cleans removed buttons, history restores both',
    () {
      final controller = StudioController(starterProject());
      addTearDown(controller.dispose);
      controller.select('settings');
      controller.remove();
      expect(controller.project.screens, hasLength(1));
      expect(controller.project.screens.single.actions, isEmpty);
      controller.undo();
      expect(
        controller.project.find('welcome')!.actions['block_5']!.target,
        'settings',
      );
      controller.select('welcome');
      controller.replaceDocument('welcome', templateDocument('Blank'));
      expect(controller.selected.actions, isEmpty);
      controller.undo();
      expect(controller.selected.actions, hasLength(1));
      controller.duplicate();
      expect(controller.selected.id, isNot('welcome'));
      expect(controller.selected.document.blocks.length, 7);
      expect(controller.project.screens.length, 3);
      controller.undo();
      controller.add('Dashboard');
      expect(controller.canRedo, isFalse);
      expect(
        StudioProject.decode(controller.project.encode()).screens.length,
        3,
      );
    },
  );

  test(
    'all multi-screen Dart exports compile with links, themes and escaped text',
    () async {
      final folder = Directory('.dart_tool/studio_export_check')
        ..createSync(recursive: true);
      addTearDown(() => folder.deleteSync(recursive: true));
      final project = starterProject();
      File(
        '${folder.path}/linked.dart',
      ).writeAsStringSync(exportStudioDart(project));
      File('${folder.path}/blank.dart').writeAsStringSync(
        exportStudioDart(
          StudioProject.decode(templateDocument('Blank').encode()),
        ),
      );
      final varied = StudioProject(
        startId: 's2',
        name: 'Dollar \${danger} "quote"\n',
        screens: [
          for (final (i, name) in [
            'Welcome',
            'Settings',
            'Dashboard',
            'Layouts',
          ].indexed)
            Artboard(
              id: 's$i',
              document: templateDocument(
                name,
              ).copyWith(dark: i.isOdd, accent: i, name: '\$Quotes "\\'),
              actions: {
                for (final block in templateDocument(
                  name,
                ).blocks.where((b) => b.kind == BlockKind.button))
                  block.id: ScreenAction(
                    target: 's${(i + 1) % 4}',
                    transition: FlowTransition.values[i % 3],
                  ),
              },
            ),
        ],
      );
      final code = exportStudioDart(varied);
      expect(code, contains('home: const CanvasScreen2()'));
      File('${folder.path}/varied.dart').writeAsStringSync(code);
      final result = await Process.run('dart', [
        '--suppress-analytics',
        'analyze',
        folder.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final prompt = exportStudioPrompt(varied);
      expect(prompt, contains('Start screen:'));
      expect(prompt, contains('slide transition'));
      expect(
        exportStudioPrompt(varied, screenId: 's3'),
        isNot(contains('SCREEN s0:')),
      );
    },
  );

  testWidgets(
    'flow buttons navigate, go back, and restart without leaving player',
    (tester) async {
      await tester.pumpWidget(
        FlappaApp(home: FlowPlayer(project: starterProject())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Make it yours.'), findsOneWidget);
      await tester.tap(find.text('Save preferences'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome aboard.'), findsOneWidget);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restart'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome aboard.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 800.0, 1440.0]) {
    testWidgets('canvas editing and exports work at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      browser.saveStorage('flappa.canvas.v1', starterProject().encode());
      await tester.pumpWidget(
        FlappaApp(
          home: StudioPage(onHome: () {}, onComponents: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width < 1100) {
        await tester.tap(find.text('Properties'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Edit components'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaygroundPage), findsOneWidget);
      if (width < 1100) {
        await tester.tap(find.text('Add blocks'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('add-heading')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All screens'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaygroundPage), findsNothing);
      await tester.pump(const Duration(milliseconds: 450));
      final saved = StudioProject.decode(
        browser.readStorage('flappa.canvas.v1')!,
      );
      expect(saved.find('welcome')!.document.blocks.length, 8);
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FCodeBlock>(find.byType(FCodeBlock)).code,
        contains('CanvasScreen1'),
      );
      await tester.tap(find.text('AI prompt'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FCodeBlock>(find.byType(FCodeBlock)).code,
        contains('Create account'),
      );
      await tester.tap(find.text('Project JSON'));
      await tester.pumpAndSettle();
      expect(
        StudioProject.decode(
          tester.widget<FCodeBlock>(find.byType(FCodeBlock)).code,
        ).screens.length,
        2,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('moving an artboard respects zoom and is one undo step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    browser.saveStorage('flappa.canvas.v1', starterProject().encode());
    await tester.pumpWidget(
      FlappaApp(
        home: StudioPage(onHome: () {}, onComponents: () {}),
      ),
    );
    await tester.pumpAndSettle();
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final scale = viewer.transformationController!.value.getMaxScaleOnAxis();
    final handle = find.byKey(const ValueKey('artboard-handle-welcome'));
    final before = tester.getTopLeft(handle);
    await tester.dragFrom(
      tester.getTopLeft(handle) + Offset(50 * scale, 24 * scale),
      const Offset(80, 40),
    );
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(handle);
    expect(after.dx - before.dx, closeTo(80, 4));
    expect(after.dy - before.dy, closeTo(40, 4));
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(handle), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
