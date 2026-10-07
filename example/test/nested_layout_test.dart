import 'dart:convert';
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flappa_ui_example/playground/canvas_editor.dart';
import 'package:flappa_ui_example/playground/document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version 1 drafts migrate and version 2 preserves layout settings', () {
    final legacy =
        jsonDecode(templateDocument('Welcome').encode())
            as Map<String, dynamic>;
    legacy['version'] = 1;
    for (final block in legacy['blocks'] as List) {
      for (final key in ['parentId', 'padding', 'gap', 'responsive']) {
        (block as Map).remove(key);
      }
    }
    final restored = ScreenDocument.decode(jsonEncode(legacy));
    expect(restored.childrenOf(null).length, 7);
    expect(jsonDecode(restored.encode())['version'], 2);
    final nested = templateDocument('Layouts');
    final roundTrip = ScreenDocument.decode(nested.encode());
    expect(roundTrip.encode(), nested.encode());
    expect(roundTrip.childrenOf('block_1').length, 2);
    expect(() => roundTrip.blocks.clear(), throwsUnsupportedError);
  });

  test(
    'imports reject orphans, non-layout parents, cycles and excessive depth',
    () {
      ScreenDocument document(List<ScreenBlock> blocks) =>
          ScreenDocument(blocks: blocks);
      final row = newBlock(BlockKind.row, 'row');
      final text = newBlock(BlockKind.text, 'text');
      for (final blocks in [
        [row.copyWith(parentId: 'missing')],
        [row.copyWith(parentId: 'text'), text],
        [row.copyWith(parentId: 'row')],
        [
          row.copyWith(parentId: 'other'),
          newBlock(BlockKind.column, 'other').copyWith(parentId: 'row'),
        ],
        [
          for (var i = 0; i < 9; i++)
            newBlock(
              BlockKind.column,
              '$i',
            ).copyWith(parentId: i == 0 ? null : '${i - 1}'),
        ],
        [row.copyWith(gap: -1)],
      ]) {
        expect(
          () => ScreenDocument.decode(document(blocks).encode()),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'moving, copying and deleting subtrees preserves identity and history',
    () {
      final controller = PlaygroundController(templateDocument('Layouts'));
      addTearDown(controller.dispose);
      final original = controller.document.encode();
      expect(controller.canMove('block_1', 'block_2'), isFalse);
      controller.moveBlock('block_1', parentId: 'block_2', index: 0);
      expect(controller.document.encode(), original);
      controller.moveBlock('block_6', parentId: 'block_3', index: 1);
      expect(controller.document.childrenOf('block_3').map((b) => b.id), [
        'block_7',
        'block_6',
        'block_8',
      ]);
      controller.moveSibling('block_6', -1);
      expect(controller.document.childrenOf('block_3').first.id, 'block_6');
      controller.duplicate('block_3');
      final clone = controller.selected!;
      expect(clone.parentId, 'block_1');
      final children = controller.document.childrenOf(clone.id);
      expect(children.length, 3);
      expect(
        children.map((b) => b.title),
        controller.document.childrenOf('block_3').map((b) => b.title),
      );
      expect(
        children.map((b) => b.id).toSet().intersection({
          'block_6',
          'block_7',
          'block_8',
        }),
        isEmpty,
      );
      controller.remove('block_1');
      expect(controller.document.blocks.length, 1);
      controller.undo();
      expect(controller.document.find(clone.id), isNotNull);
      controller.redo();
      expect(controller.document.blocks.length, 1);
    },
  );

  test('insertion respects selection, capacity and maximum layout depth', () {
    final controller = PlaygroundController(templateDocument('Blank'));
    addTearDown(controller.dispose);
    for (var i = 0; i < 8; i++) {
      controller.add(BlockKind.column);
    }
    expect(controller.document.blocks.length, 8);
    controller.add(BlockKind.text);
    expect(controller.document.blocks.length, 8);
    expect(
      controller.canMove(
        controller.document.blocks.first.id,
        controller.selectedId,
      ),
      isFalse,
    );
    controller.select(null);
    controller.add(BlockKind.text);
    expect(controller.selected!.parentId, isNull);
    final full = PlaygroundController(
      ScreenDocument(
        blocks: [for (var i = 0; i < 100; i++) newBlock(BlockKind.text, '$i')],
      ),
    );
    addTearDown(full.dispose);
    expect(full.canDuplicate('0'), isFalse);
    full.add(BlockKind.row);
    expect(full.document.blocks.length, 100);
  });

  for (final width in [390.0, 800.0]) {
    testWidgets('nested layouts render and rows adapt at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = PlaygroundController(templateDocument('Layouts'));
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        FlappaApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScreenCanvasContent(
                controller: controller,
                interact: true,
                onSelect: controller.select,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final create = tester.getTopLeft(find.text('Create'));
      final connect = tester.getTopLeft(find.text('Connect'));
      if (width < 480) {
        expect(connect.dy, greaterThan(create.dy));
      } else {
        expect(connect.dy, closeTo(create.dy, 1));
        expect(connect.dx, greaterThan(create.dx));
      }
      await tester.tap(find.text('Weekly updates'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('canvas drag reorders siblings and undo restores the screen', (
    tester,
  ) async {
    final controller = PlaygroundController(
      ScreenDocument(
        blocks: [
          for (var i = 0; i < 3; i++)
            newBlock(BlockKind.text, '$i').copyWith(title: 'Block $i'),
        ],
      ),
    );
    addTearDown(controller.dispose);
    controller.select('0');
    await tester.pumpWidget(
      FlappaApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: controller,
            builder: (context, child) => ScreenCanvasContent(
              controller: controller,
              interact: false,
              onSelect: controller.select,
            ),
          ),
        ),
      ),
    );
    final from = tester.getCenter(find.byKey(const ValueKey('drag-0')));
    final to = tester.getCenter(find.byKey(const ValueKey('drop-root-3')));
    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
    expect(controller.document.childrenOf(null).map((b) => b.id), [
      '1',
      '2',
      '0',
    ]);
    controller.undo();
    await tester.pumpAndSettle();
    expect(controller.document.childrenOf(null).map((b) => b.id), [
      '0',
      '1',
      '2',
    ]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('canvas drop reparents a block into an empty layout', (
    tester,
  ) async {
    final controller = PlaygroundController(
      ScreenDocument(
        blocks: [
          newBlock(BlockKind.text, 'text'),
          newBlock(BlockKind.container, 'container'),
        ],
      ),
    );
    addTearDown(controller.dispose);
    controller.select('text');
    await tester.pumpWidget(
      FlappaApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: controller,
            builder: (context, child) => ScreenCanvasContent(
              controller: controller,
              interact: false,
              onSelect: controller.select,
            ),
          ),
        ),
      ),
    );
    final from = tester.getCenter(find.byKey(const ValueKey('drag-text')));
    final to = tester.getCenter(find.byKey(const ValueKey('drop-container-0')));
    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
    expect(controller.document.find('text')!.parentId, 'container');
    expect(controller.document.childrenOf(null).map((b) => b.id), [
      'container',
    ]);
    expect(tester.takeException(), isNull);
  });
}
