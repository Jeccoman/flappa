import 'package:flappa_ui/flappa_ui.dart';
import 'package:flappa_ui_example/platform/browser.dart' as browser;
import 'package:flappa_ui_example/playground/canvas_editor.dart';
import 'package:flappa_ui_example/playground/document.dart';
import 'package:flappa_ui_example/playground/studio_document.dart';
import 'package:flappa_ui_example/playground/studio_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StudioProject project() => StudioProject(
  startId: 'a',
  screens: [
    Artboard(
      id: 'a',
      document: ScreenDocument(
        name: 'First',
        blocks: [
          newBlock(BlockKind.container, 'box'),
          newBlock(BlockKind.text, 'item'),
        ],
      ),
      size: const Size(390, 700),
    ),
    Artboard(
      id: 'b',
      document: ScreenDocument(
        name: 'Second',
        blocks: [newBlock(BlockKind.text, 'item')],
      ),
      position: const Offset(640, 80),
      size: const Size(390, 700),
    ),
  ],
);

void main() {
  test(
    'cross-screen moves remap collisions and preserve subtrees and links atomically',
    () {
      final document = templateDocument('Layouts');
      final initial = StudioProject(
        startId: 'a',
        screens: [
          Artboard(
            id: 'a',
            document: document,
            actions: const {
              'block_6': ScreenAction(
                target: 'b',
                transition: FlowTransition.fade,
              ),
            },
          ),
          Artboard(id: 'b', document: document),
        ],
      );
      final controller = StudioController(initial);
      addTearDown(controller.dispose);
      controller.dropBlock(
        const BlockDrag.move('block_2', sourceId: 'a'),
        'b',
        'block_3',
        0,
      );
      final a = controller.project.find('a')!,
          b = controller.project.find('b')!;
      expect(a.document.find('block_2'), isNull);
      expect(a.actions, isEmpty);
      final moved = b.document.childrenOf('block_3').first;
      expect(moved.id, isNot('block_2'));
      expect(b.document.childrenOf(moved.id), hasLength(3));
      expect(b.actions.values.single.target, 'b');
      expect(b.actions.values.single.transition, FlowTransition.fade);
      expect(b.document.find(b.actions.keys.single)!.parentId, moved.id);
      expect(
        StudioProject.decode(controller.project.encode()).encode(),
        controller.project.encode(),
      );
      controller.undo();
      expect(controller.project.encode(), initial.encode());
      controller.redo();
      expect(controller.project.find('a')!.actions, isEmpty);
    },
  );

  test(
    'drop validation prevents cycles, invalid parents, depth and capacity overflow',
    () {
      final controller = StudioController(
        StudioProject(
          startId: 'a',
          screens: [
            Artboard(id: 'a', document: templateDocument('Layouts')),
            Artboard(
              id: 'b',
              document: ScreenDocument(
                blocks: [
                  for (var i = 0; i < 99; i++)
                    newBlock(BlockKind.text, 'item$i'),
                ],
              ),
            ),
            Artboard(
              id: 'deep',
              document: ScreenDocument(
                blocks: [
                  for (var i = 0; i < 8; i++)
                    newBlock(
                      BlockKind.column,
                      'level$i',
                    ).copyWith(parentId: i == 0 ? null : 'level${i - 1}'),
                ],
              ),
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);
      expect(
        controller.canDropBlock(
          const BlockDrag.move('block_1', sourceId: 'a'),
          'a',
          'block_2',
        ),
        isFalse,
      );
      expect(
        controller.canDropBlock(
          const BlockDrag.move('block_2', sourceId: 'a'),
          'b',
          null,
        ),
        isFalse,
      );
      expect(
        controller.canDropBlock(
          const BlockDrag.create(BlockKind.button),
          'deep',
          'level7',
        ),
        isFalse,
      );
      expect(
        controller.canDropBlock(
          const BlockDrag.move('block_2', sourceId: 'a'),
          'deep',
          'level6',
        ),
        isFalse,
      );
      expect(
        controller.canDropBlock(
          const BlockDrag.create(BlockKind.button),
          'a',
          'block_0',
        ),
        isFalse,
      );
      final before = controller.project.encode();
      controller.dropBlock(
        const BlockDrag.move('block_1', sourceId: 'a'),
        'a',
        'block_2',
        0,
      );
      controller.dropBlock(
        const BlockDrag.create(BlockKind.button),
        'a',
        null,
        999,
      );
      expect(controller.project.encode(), before);
    },
  );

  testWidgets(
    'palette drops into layouts, handles reorder and move between artboards at zoom',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      browser.saveStorage('flappa.canvas.v1', project().encode());
      await tester.pumpWidget(
        FlappaApp(
          home: StudioPage(onHome: () {}, onComponents: () {}),
        ),
      );
      await tester.pumpAndSettle();
      Finder inBoard(String screen, String key) => find.descendant(
        of: find.byKey(ValueKey('editable-$screen')),
        matching: find.byKey(ValueKey(key)),
      );
      Future<void> drag(Finder from, Finder to) async {
        final start = tester.getCenter(from), end = tester.getCenter(to);
        await tester.dragFrom(start, end - start);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 450));
      }

      StudioProject saved() =>
          StudioProject.decode(browser.readStorage('flappa.canvas.v1')!);
      await drag(
        find.byKey(const ValueKey('canvas-part-button')),
        inBoard('a', 'drop-box-0'),
      );
      expect(
        saved().find('a')!.document.childrenOf('box').single.kind,
        BlockKind.button,
      );
      await drag(inBoard('a', 'drag-item'), inBoard('a', 'drop-root-0'));
      expect(saved().find('a')!.document.childrenOf(null).first.id, 'item');
      await drag(inBoard('a', 'drag-box'), inBoard('b', 'drop-root-0'));
      expect(saved().find('a')!.document.find('box'), isNull);
      expect(
        saved().find('b')!.document.childrenOf('box').single.kind,
        BlockKind.button,
      );
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 450));
      expect(saved().find('a')!.document.childrenOf('box'), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'phone palette supports long-press dragging without leaving canvas',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      browser.saveStorage(
        'flappa.canvas.v1',
        StudioProject(
          startId: 'blank',
          screens: [Artboard(id: 'blank', document: templateDocument('Blank'))],
        ).encode(),
      );
      await tester.pumpWidget(
        FlappaApp(
          home: StudioPage(onHome: () {}, onComponents: () {}),
        ),
      );
      await tester.pumpAndSettle();
      final start = tester.getCenter(
        find.byKey(const ValueKey('canvas-part-heading')).hitTestable(),
      );
      final end = tester.getCenter(find.byKey(const ValueKey('drop-root-0')));
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveTo(end);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 450));
      final saved = StudioProject.decode(
        browser.readStorage('flappa.canvas.v1')!,
      );
      expect(
        saved.screens.single.document.blocks.single.kind,
        BlockKind.heading,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
