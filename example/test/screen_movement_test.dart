import 'package:flappa_ui/flappa_ui.dart';
import 'package:flappa_ui_example/platform/browser.dart' as browser;
import 'package:flappa_ui_example/playground/devices.dart';
import 'package:flappa_ui_example/playground/document.dart';
import 'package:flappa_ui_example/playground/studio_document.dart';
import 'package:flappa_ui_example/playground/studio_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StudioProject fixture() => StudioProject(
    startId: 'phone',
    screens: [
      Artboard(
        id: 'phone',
        document: templateDocument('Welcome'),
        position: const Offset(10, 10),
      ).withDevice(CanvasDevice.find('iphone')!),
      Artboard(
        id: 'laptop',
        document: templateDocument('Settings'),
        position: const Offset(220, 130),
      ).withDevice(CanvasDevice.find('laptop')!),
    ],
  );

  Future<void> open(WidgetTester tester, {double width = 1440}) async {
    tester.view.physicalSize = Size(width, 1000);
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

  TransformationController transform(WidgetTester tester) => tester
      .widget<InteractiveViewer>(find.byType(InteractiveViewer))
      .transformationController!;
  Finder board(String id) => find.byKey(ValueKey('artboard-$id'));
  Finder handle(String id) => find.byKey(ValueKey('artboard-handle-$id'));
  StudioProject saved() =>
      StudioProject.decode(browser.readStorage('flappa.canvas.v1')!);
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 450));
  }

  test('negative canvas positions survive export and restore', () {
    final project = fixture();
    final moved = project.copyWith(
      screens: [
        project.screens.first.copyWith(position: const Offset(-240.5, -800)),
        project.screens.last,
      ],
    );
    expect(StudioProject.decode(moved.encode()).encode(), moved.encode());
  });

  testWidgets('frame dragging crosses the origin without snapping or panning', (
    tester,
  ) async {
    await open(tester);
    final matrix = transform(tester).value.clone();
    final scale = matrix.getMaxScaleOnAxis();
    final before = tester.getTopLeft(board('phone'));
    const delta = Offset(-53, -31);
    await tester.dragFrom(before + Offset(180 * scale, 6 * scale), delta);
    await settle(tester);
    final position = saved().find('phone')!.position;
    expect(position.dx, closeTo(10 + delta.dx / scale, .01));
    expect(position.dy, closeTo(10 + delta.dy / scale, .01));
    expect(
      tester.getTopLeft(board('phone')).dx,
      closeTo(before.dx + delta.dx, .01),
    );
    expect(transform(tester).value, matrix);
    expect(
      saved().find('laptop')!.position,
      fixture().find('laptop')!.position,
    );
    await tester.tap(find.byTooltip('Undo'));
    await settle(tester);
    expect(saved().encode(), fixture().encode());
    expect(
      tester
          .widget<FButton>(
            find
                .ancestor(
                  of: find.byTooltip('Undo'),
                  matching: find.byType(FButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Redo'));
    await settle(tester);
    expect(saved().find('phone')!.position, position);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('move mode drags the whole device at width $width', (
      tester,
    ) async {
      await open(tester, width: width);
      await tester.tap(find.byTooltip('Move screens'));
      await tester.pumpAndSettle();
      final matrix = transform(tester).value.clone();
      final scale = matrix.getMaxScaleOnAxis();
      final before = tester.getTopLeft(board('phone'));
      const delta = Offset(47, 63);
      await tester.dragFrom(before + Offset(150, 250) * scale, delta);
      await settle(tester);
      expect(
        saved().find('phone')!.position.dx,
        closeTo(10 + delta.dx / scale, .01),
      );
      expect(
        saved().find('phone')!.position.dy,
        closeTo(10 + delta.dy / scale, .01),
      );
      expect(transform(tester).value, matrix);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'selected overlapping screen comes forward and remains draggable',
    (tester) async {
      await open(tester);
      final scale = transform(tester).value.getMaxScaleOnAxis();
      await tester.tapAt(
        tester.getTopLeft(handle('laptop')) + Offset(550, 24) * scale,
      );
      await tester.pumpAndSettle();
      final first = tester.getTopLeft(board('laptop'));
      const delta = Offset(71, 42);
      await tester.dragFrom(first + Offset(60, 10) * scale, delta);
      await settle(tester);
      expect(
        saved().find('laptop')!.position.dx,
        closeTo(220 + delta.dx / scale, .01),
      );
      expect(saved().find('phone')!.position, const Offset(10, 10));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('cancelled frame drag restores position without adding history', (
    tester,
  ) async {
    await open(tester);
    final scale = transform(tester).value.getMaxScaleOnAxis();
    final before = tester.getTopLeft(board('phone'));
    final gesture = await tester.startGesture(
      before + Offset(180, 6) * scale,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(70, 40));
    await tester.pump();
    await gesture.cancel();
    await settle(tester);
    expect(tester.getTopLeft(board('phone')), before);
    expect(saved().encode(), fixture().encode());
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
