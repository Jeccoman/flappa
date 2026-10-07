import 'dart:convert';
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flappa_ui_example/playground/devices.dart';
import 'package:flappa_ui_example/playground/document.dart';
import 'package:flappa_ui_example/playground/studio_document.dart';
import 'package:flappa_ui_example/playground/studio_page.dart';
import 'package:flappa_ui_example/playground/studio_render.dart';
import 'package:flappa_ui_example/platform/browser.dart' as browser;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('device selection, rotation and finishes survive export and undo', () {
    final controller = StudioController(starterProject());
    addTearDown(controller.dispose);
    for (final device in CanvasDevice.all) {
      final selected = controller.selected
          .withDevice(device)
          .copyWith(finish: DeviceFinish.blue);
      controller.update(selected);
      expect(controller.selected.deviceId, device.id);
      if (device.canRotate) {
        controller.update(controller.selected.rotated());
        expect(
          controller.selected.size,
          Size(device.viewport.height, device.viewport.width),
        );
        expect(controller.selected.landscape, isTrue);
        controller.undo();
        expect(controller.selected.size, device.viewport);
        controller.redo();
      }
      final restored = StudioProject.decode(controller.project.encode());
      expect(restored.encode(), controller.project.encode());
      expect(restored.find(controller.selectedId)!.finish, DeviceFinish.blue);
      final previous = controller.selected;
      controller.add('Blank');
      expect(controller.selected.deviceId, previous.deviceId);
      expect(controller.selected.size, previous.size);
      expect(controller.selected.landscape, previous.landscape);
      expect(controller.selected.finish, previous.finish);
      controller.undo();
    }
  });

  test(
    'old projects remain frameless and invalid device metadata is rejected',
    () {
      final old = jsonDecode(starterProject().encode()) as Map<String, dynamic>;
      for (final screen in old['screens'] as List) {
        (screen as Map).remove('device');
        screen.remove('finish');
        screen.remove('landscape');
      }
      final restored = StudioProject.decode(jsonEncode(old));
      expect(restored.screens.every((s) => s.deviceId == 'none'), isTrue);
      for (final patch in [
        {'device': 'unknown'},
        {'device': 'android'},
        {'landscape': 'yes'},
        {'device': 'monitor', 'landscape': true},
        {'finish': 'rainbow'},
      ]) {
        final data =
            jsonDecode(starterProject().encode()) as Map<String, dynamic>;
        (data['screens'][0] as Map).addAll(patch);
        expect(
          () => StudioProject.decode(jsonEncode(data)),
          throwsFormatException,
        );
      }
    },
  );

  for (final device in CanvasDevice.all.where(
    (d) => d.kind != DeviceKind.none,
  )) {
    testWidgets('${device.label} renders correct viewport and safe areas', (
      tester,
    ) async {
      for (final landscape in [false, if (device.canRotate) true]) {
        final screen = Artboard(
          id: 'device',
          document: templateDocument('Welcome'),
        ).withDevice(device);
        final oriented = landscape ? screen.rotated() : screen;
        await tester.pumpWidget(
          FlappaApp(
            home: Scaffold(
              body: DeviceStage(
                screen: oriented,
                child: Builder(
                  builder: (context) {
                    expect(MediaQuery.sizeOf(context), oriented.size);
                    expect(
                      MediaQuery.paddingOf(context),
                      device.safeArea(landscape),
                    );
                    return ArtboardContent(screen: oriented);
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(DeviceFrame), findsOneWidget);
        expect(tester.getSize(find.byType(DeviceFrame)), oriented.frameSize);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('choose and rotate a phone, then drag into its screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
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
    await tester.tap(find.byKey(const ValueKey('device-blank')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Android phone').last);
    await tester.pumpAndSettle();
    expect(find.byType(DeviceFrame), findsOneWidget);
    await tester.tap(find.text('Rotate device'));
    await tester.pumpAndSettle();
    final start = tester.getCenter(
      find.byKey(const ValueKey('canvas-part-heading')),
    );
    final end = tester.getCenter(find.byKey(const ValueKey('drop-root-0')));
    await tester.dragFrom(start, end - start);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 450));
    final saved = StudioProject.decode(
      browser.readStorage('flappa.canvas.v1')!,
    );
    expect(saved.screens.single.deviceId, 'android');
    expect(saved.screens.single.landscape, isTrue);
    expect(saved.screens.single.document.blocks.single.kind, BlockKind.heading);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
