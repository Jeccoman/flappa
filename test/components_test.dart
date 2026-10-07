import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {ThemeMode mode = ThemeMode.light}) => FlappaApp(
  themeMode: mode,
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

void main() {
  test(
    'semantic colors interpolate and custom tokens survive theme installation',
    () {
      final light = FThemeData();
      final dark = FThemeData(brightness: Brightness.dark);
      expect(light.colors.background, Colors.white);
      expect(dark.colors.background, const Color(0xFF09090B));
      expect(light.lerp(dark, 0).colors.primary, light.colors.primary);
      expect(light.lerp(dark, 1).colors.primary, dark.colors.primary);
      final custom = light.copyWith(
        radius: 16,
        colors: light.colors.copyWith(primary: Colors.blue),
      );
      expect(custom.toThemeData().extension<FThemeData>()!.radius, 16);
      expect(custom.toThemeData().colorScheme.primary, Colors.blue);
    },
  );

  testWidgets(
    'buttons activate by keyboard and loading/disabled prevent actions',
    (tester) async {
      var clicks = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FButton(
                onPressed: () => clicks++,
                focusNode: focus,
                child: const Text('Run'),
              ),
              const FButton(onPressed: null, child: Text('Disabled')),
              FButton(
                onPressed: () => clicks++,
                loading: true,
                child: const Text('Loading'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Run'));
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.text('Disabled'));
      await tester.tap(find.text('Loading'));
      expect(clicks, 2);
    },
  );

  testWidgets('input participates in Form validation and saves the value', (
    tester,
  ) async {
    final key = GlobalKey<FormState>();
    String? saved;
    await tester.pumpWidget(
      host(
        Form(
          key: key,
          child: FInput(
            validator: (value) => value!.isEmpty ? 'Required' : null,
            onSaved: (value) => saved = value,
          ),
        ),
      ),
    );
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Flutter');
    expect(key.currentState!.validate(), isTrue);
    key.currentState!.save();
    expect(saved, 'Flutter');
  });

  testWidgets('checkbox cycles tristate and switch is controlled', (
    tester,
  ) async {
    bool? checked = false;
    var enabled = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FCheckbox(
                value: checked,
                tristate: true,
                label: 'Accept',
                onChanged: (value) => setState(() => checked = value),
              ),
              FSwitch(
                value: enabled,
                label: 'Notifications',
                onChanged: (value) => setState(() => enabled = value),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(checked, isTrue);
    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(checked, isNull);
    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(checked, isFalse);
    await tester.tap(find.text('Notifications'));
    await tester.pump();
    expect(enabled, isTrue);
  });

  testWidgets('combobox filters and selects using keyboard', (tester) async {
    String? selected;
    await tester.pumpWidget(
      host(
        FCombobox<String>(
          items: const ['Dart', 'Swift', 'Rust'],
          labelOf: (value) => value,
          onChanged: (value) => selected = value,
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'sw');
    await tester.pumpAndSettle();
    expect(find.text('Swift'), findsOneWidget);
    expect(find.text('Rust'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(selected, 'Swift');
  });

  testWidgets('select reflects externally changed values', (tester) async {
    Widget select(String value) => host(
      FSelect<String>(
        items: const {'a': 'Alpha', 'b': 'Beta'},
        value: value,
        onChanged: (_) {},
      ),
    );
    await tester.pumpWidget(select('a'));
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      'a',
    );
    await tester.pumpWidget(select('b'));
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      'b',
    );
  });

  testWidgets('tabs switch by click and arrow keys', (tester) async {
    var index = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => FTabs(
            index: index,
            onChanged: (value) => setState(() => index = value),
            tabs: const [
              FTab(label: 'First', child: Text('First panel')),
              FTab(label: 'Second', child: Text('Second panel')),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Second'));
    await tester.pump();
    expect(find.text('Second panel'), findsOneWidget);
    final button = find.widgetWithText(TextButton, 'Second');
    Focus.of(
      tester.element(
        find.descendant(of: button, matching: find.text('Second')),
      ),
    ).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(index, 0);
    expect(find.text('First panel'), findsOneWidget);
  });

  testWidgets('accordion closes its previous panel in single mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FAccordion(
          items: [
            FAccordionItem(id: 'a', title: Text('A'), child: Text('Body A')),
            FAccordionItem(id: 'b', title: Text('B'), child: Text('Body B')),
          ],
        ),
      ),
    );
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.text('Body A'), findsOneWidget);
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(find.text('Body A'), findsNothing);
    expect(find.text('Body B'), findsOneWidget);
  });

  testWidgets('pagination disables boundary actions and moves to next page', (
    tester,
  ) async {
    var page = 1;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => FPagination(
            page: page,
            pageCount: 12,
            onChanged: (value) => setState(() => page = value),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Previous page'));
    expect(page, 1);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pump();
    expect(page, 2);
    await tester.tap(find.text('12'));
    await tester.pump();
    expect(page, 12);
    await tester.tap(find.byTooltip('Next page'));
    expect(page, 12);
  });

  testWidgets('OTP accepts pasted digits and limits length', (tester) async {
    String? complete;
    await tester.pumpWidget(
      host(FInputOTP(length: 4, onCompleted: (value) => complete = value)),
    );
    await tester.enterText(find.byType(TextFormField), '12x3456');
    expect(complete, '1234');
  });

  testWidgets('confirmation returns explicit choice', (tester) async {
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => FButton(
            onPressed: () async => result = await showFConfirm(
              context: context,
              title: 'Delete?',
              description: 'Confirm deletion',
              confirmLabel: 'Delete',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  for (final side in FSheetSide.values) {
    testWidgets('${side.name} sheet opens and closes without layout errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => FButton(
              onPressed: () => showFSheet<void>(
                context: context,
                side: side,
                builder: (_) => const Text('Panel content'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close panel'));
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsNothing);
    });
  }

  testWidgets('command filters keywords and selects with arrow keys', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        FCommand<String>(
          items: const [
            FCommandItem(value: 'a', label: 'Alpha'),
            FCommandItem(value: 'b', label: 'Beta', keywords: ['second']),
          ],
          onSelected: (value) => selected = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(selected, 'b');
    await tester.enterText(find.byType(TextFormField), 'second');
    await tester.pump();
    expect(find.text('Alpha'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(selected, 'b');
    await tester.enterText(find.byType(TextFormField), 'missing');
    await tester.pump();
    expect(find.text('No results found.'), findsOneWidget);
  });

  testWidgets('resizable panel clamps drag ratio', (tester) async {
    double? ratio;
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 200,
          child: FResizable(
            first: const Text('Left'),
            second: const Text('Right'),
            onChanged: (value) => ratio = value,
          ),
        ),
      ),
    );
    await tester.drag(find.byIcon(Icons.drag_indicator), const Offset(300, 0));
    await tester.pump();
    expect(ratio, .85);
    expect(tester.takeException(), isNull);
  });

  testWidgets('carousel advances and clamps after item removal', (
    tester,
  ) async {
    var count = 3;
    late StateSetter update;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return FCarousel(
              children: [
                for (var i = 0; i < count; i++) Center(child: Text('Slide $i')),
              ],
            );
          },
        ),
      ),
    );
    await tester.tap(find.byTooltip('Next slide'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    update(() => count = 1);
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skeleton respects reduced motion', (tester) async {
    await tester.pumpWidget(
      host(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: FSkeleton(width: 100),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('chart supports flat and negative data in both themes', (
    tester,
  ) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        host(const FChart(values: [-4, -4, -4]), mode: mode),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('context menu opens on long press and returns selected action', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        FContextMenu<String>(
          items: const [FMenuItem(value: 'copy', label: 'Copy item')],
          onSelected: (value) => selected = value,
          child: const SizedBox(
            height: 100,
            child: Center(child: Text('Target')),
          ),
        ),
      ),
    );
    await tester.longPress(find.text('Target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy item'));
    await tester.pumpAndSettle();
    expect(selected, 'copy');
  });

  testWidgets('menubar exposes actions and preserves disabled items', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        FMenubar<String>(
          menus: const [
            FMenu(
              label: 'File',
              items: [
                FMenuItem(value: 'new', label: 'New project'),
                FMenuItem(value: 'export', label: 'Export', enabled: false),
              ],
            ),
          ],
          onSelected: (value) => selected = value,
        ),
      ),
    );
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    final disabled = tester.widget<MenuItemButton>(
      find.widgetWithText(MenuItemButton, 'Export'),
    );
    expect(disabled.onPressed, isNull);
    await tester.tap(find.text('New project'));
    await tester.pumpAndSettle();
    expect(selected, 'new');
  });

  testWidgets('hover card opens on tap and disposes pending timers safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const FHoverCard(content: Text('Details'), child: Text('Profile'))),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('date range dialog opens and cancellation preserves value', (
    tester,
  ) async {
    DateTimeRange? selected;
    await tester.pumpWidget(
      host(
        FDateRangePicker(value: null, onChanged: (value) => selected = value),
      ),
    );
    await tester.tap(find.text('Pick a date range'));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });
}
