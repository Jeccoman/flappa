import 'package:flappa_ui/flappa_ui.dart';
import 'package:flappa_ui_example/platform/browser.dart' as browser;
import 'package:flappa_ui_example/playground/document.dart';
import 'package:flappa_ui_example/playground/studio_document.dart';
import 'package:flappa_ui_example/playground/studio_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

StudioProject fixture() => StudioProject(
  startId: 'first',
  screens: [
    Artboard(
      id: 'first',
      document: ScreenDocument(
        name: 'First screen',
        blocks: [
          newBlock(BlockKind.container, 'group').copyWith(title: 'My group'),
          newBlock(
            BlockKind.button,
            'button',
          ).copyWith(parentId: 'group', title: 'Continue'),
          newBlock(BlockKind.text, 'leaf').copyWith(title: 'Remove me'),
        ],
      ),
      actions: const {'button': ScreenAction(target: 'second')},
    ),
    Artboard(
      id: 'second',
      position: const Offset(640, 80),
      document: ScreenDocument(
        name: 'Second screen',
        blocks: [newBlock(BlockKind.text, 'leaf').copyWith(title: 'Keep me')],
      ),
    ),
  ],
);

void main() {
  test('deleting a layout removes its children and links in one undo step', () {
    final project = fixture();
    final controller = StudioController(project);
    addTearDown(controller.dispose);
    controller.removeBlock('first', 'group');
    expect(controller.project.find('first')!.document.blocks.map((b) => b.id), [
      'leaf',
    ]);
    expect(controller.project.find('first')!.actions, isEmpty);
    expect(
      controller.project.find('second')!.document.blocks.single.id,
      'leaf',
    );
    controller.undo();
    expect(controller.project.encode(), project.encode());
    controller.redo();
    expect(controller.project.find('first')!.document.find('group'), isNull);
    controller.removeBlock('first', 'missing');
    controller.removeBlock('missing', 'leaf');
    controller.undo();
    expect(controller.project.encode(), project.encode());
    controller.removeBlock('second', 'leaf');
    expect(controller.project.find('second')!.document.blocks, isEmpty);
    expect(StudioProject.decode(controller.project.encode()).screens.length, 2);
  });

  Future<void> open(WidgetTester tester, {double width = 1440}) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    browser.saveStorage('flappa.canvas.v1', fixture().encode());
    await tester.pumpWidget(
      FlappaApp(
        home: StudioPage(onHome: () {}, onComponents: () {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder block(String screen, String id) => find.descendant(
    of: find.byKey(ValueKey('editable-$screen')),
    matching: find.byKey(ValueKey(id)),
  );
  StudioProject saved() =>
      StudioProject.decode(browser.readStorage('flappa.canvas.v1')!);
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 450));
  }

  testWidgets(
    'canvas trash buttons delete nested blocks and whole screens with undo',
    (tester) async {
      await open(tester);
      await tester.tap(block('first', 'delete-group'));
      await settle(tester);
      expect(saved().find('first')!.document.blocks, hasLength(1));
      expect(saved().find('first')!.actions, isEmpty);
      await tester.tap(find.byTooltip('Undo'));
      await settle(tester);
      expect(saved().find('first')!.actions, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('delete-screen-second')));
      await settle(tester);
      expect(saved().screens, hasLength(1));
      expect(saved().screens.single.actions, isEmpty);
      expect(
        tester
            .widget<FButton>(find.byKey(const ValueKey('delete-screen-first')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Undo'));
      await settle(tester);
      expect(saved().screens, hasLength(2));
      expect(saved().find('first')!.actions, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final key in [LogicalKeyboardKey.delete, LogicalKeyboardKey.backspace]) {
    testWidgets(
      '${key.keyLabel} deletes only the focused component and preserves text editing',
      (tester) async {
        await open(tester);
        final heading = find.descendant(
          of: block('first', 'canvas-leaf'),
          matching: find.widgetWithText(FButton, 'Remove me'),
        );
        await tester.tap(heading);
        await tester.pump();
        await tester.sendKeyEvent(key);
        await settle(tester);
        expect(saved().find('first')!.document.find('leaf'), isNull);
        expect(saved().find('second')!.document.find('leaf'), isNotNull);
        await tester.tap(find.byTooltip('Undo'));
        await settle(tester);
        await tester.tap(heading);
        await tester.pump();
        final input = find.descendant(
          of: find.widgetWithText(FField, 'Screen name'),
          matching: find.byType(TextFormField),
        );
        await tester.tap(input);
        await tester.enterText(input, 'Edited name');
        await tester.sendKeyEvent(key);
        await settle(tester);
        expect(saved().find('first')!.document.find('leaf'), isNotNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('trash buttons can be activated with keyboard focus', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(
      find.descendant(
        of: block('first', 'canvas-leaf'),
        matching: find.widgetWithText(FButton, 'Remove me'),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(saved().find('first')!.document.find('leaf'), isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('trash buttons are reachable on a phone', (tester) async {
    await open(tester, width: 390);
    await tester.tap(block('first', 'delete-group'));
    await settle(tester);
    expect(saved().find('first')!.document.find('group'), isNull);
    await tester.tap(find.byTooltip('Undo'));
    await settle(tester);
    expect(saved().find('first')!.document.find('group'), isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
