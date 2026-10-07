import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(
  Widget child, {
  double width = 360,
  ThemeMode mode = ThemeMode.light,
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
    'button groups support keyboard activation and disabled actions',
    (tester) async {
      var actions = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          FButtonGroup(
            children: [
              FButton(
                onPressed: () => actions++,
                focusNode: focus,
                child: const Text('Save'),
              ),
              const FButton(onPressed: null, child: Text('Archive')),
            ],
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.text('Archive'));
      expect(actions, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('input group focuses, submits, and blocks disabled actions', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    String? submitted;
    var actions = 0;
    var enabled = true;
    late StateSetter update;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return FInputGroup(
              enabled: enabled,
              leading: const Icon(Icons.search),
              trailing: FButton(
                onPressed: () => actions++,
                child: const Text('Go'),
              ),
              child: FInput(
                focusNode: focus,
                onSubmitted: (value) => submitted = value,
              ),
            );
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'hello');
    expect(focus.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'hello');
    await tester.tap(find.text('Go'));
    expect(actions, 1);
    update(() => enabled = false);
    await tester.pump();
    await tester.tap(find.text('Go'), warnIfMissed: false);
    expect(actions, 1);
    expect(focus.hasFocus, isFalse);
  });

  testWidgets(
    'native select validates, saves, and resets to its initial value',
    (tester) async {
      final form = GlobalKey<FormState>();
      final select = GlobalKey<FormFieldState<String>>();
      String? saved;
      await tester.pumpWidget(
        host(
          Form(
            key: form,
            child: FNativeSelect<String>(
              key: select,
              items: const {'a': 'Africa', 'e': 'Europe'},
              validator: (value) => value == null ? 'Choose a region' : null,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Choose a region'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Africa').last);
      await tester.pumpAndSettle();
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect(saved, 'a');
      form.currentState!.reset();
      await tester.pump();
      expect(select.currentState!.value, isNull);
      expect(find.text('Choose a region'), findsNothing);
    },
  );

  testWidgets('label transfers focus to its associated input', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FLabel('Project name', focusNode: focus),
            FInput(focusNode: focus),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Project name'));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('item actions respect disabled state', (tester) async {
    var clicks = 0;
    await tester.pumpWidget(
      host(
        FItemGroup(
          children: [
            FItem(title: const Text('Active'), onPressed: () => clicks++),
            FItem(
              title: const Text('Disabled'),
              enabled: false,
              onPressed: () => clicks++,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Active'));
    await tester.tap(find.text('Disabled'));
    expect(clicks, 1);
  });

  testWidgets('drawer scrolls and returns the selected result', (tester) async {
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => FButton(
            onPressed: () async {
              result = await showFDrawer<bool>(
                context: context,
                builder: (context, controller) => FDrawer(
                  title: 'Activity',
                  controller: controller,
                  actions: [
                    FButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Done'),
                    ),
                  ],
                  child: Column(
                    children: List.generate(
                      30,
                      (index) =>
                          SizedBox(height: 48, child: Text('Event $index')),
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    await tester.drag(find.text('Event 0'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(FDrawer), findsNothing);
  });

  testWidgets('removing an attachment does not activate its open action', (
    tester,
  ) async {
    var opens = 0, removes = 0;
    await tester.pumpWidget(
      host(
        FAttachment(
          name: 'brief.pdf',
          onPressed: () => opens++,
          onRemove: () => removes++,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Remove brief.pdf'));
    expect(removes, 1);
    expect(opens, 0);
    await tester.tap(find.text('brief.pdf'));
    expect(opens, 1);
  });

  testWidgets(
    'message scroller follows latest content without moving readers',
    (tester) async {
      var count = 18;
      var lastHeight = 80.0;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 240,
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return FMessageScroller(
                  children: List.generate(
                    count,
                    (index) => SizedBox(
                      height: index == count - 1 ? lastHeight : 80,
                      child: Text('Message $index'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(find.byType(ListView));
      final controller = list.controller!;
      expect(controller.position.extentAfter, lessThan(1));
      update(() => count++);
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(1));
      update(() => lastHeight = 180);
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(1));
      controller.jumpTo(controller.offset - 300);
      await tester.pump();
      final readingPosition = controller.offset;
      update(() => count++);
      await tester.pumpAndSettle();
      expect(controller.offset, readingPosition);
      expect(find.text('Jump to latest'), findsOneWidget);
      await tester.tap(find.text('Jump to latest'));
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(1));
      expect(find.text('Jump to latest'), findsNothing);
    },
  );

  testWidgets('messaging, typography, and grouping adapt to narrow RTL layouts', (
    tester,
  ) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        host(
          Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FTypography(
                    'A heading that wraps to fit',
                    variant: FTypographyVariant.h2,
                  ),
                  FButtonGroup(
                    axis: Axis.vertical,
                    children: [
                      FButton(onPressed: () {}, child: const Text('Save')),
                      FButton(onPressed: () {}, child: const Text('Close')),
                    ],
                  ),
                  const FMessage(
                    author: 'Sofia',
                    avatar: FAvatar(fallback: 'SC'),
                    child: Text(
                      'A message with enough text to wrap across several lines.',
                    ),
                  ),
                  const FMessage(
                    outgoing: true,
                    avatar: FAvatar(fallback: 'AM'),
                    child: Text('An outgoing reply.'),
                  ),
                  const FAspectRatio(ratio: 2, child: Text('Cover')),
                ],
              ),
            ),
          ),
          mode: mode,
          width: 240,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(FAspectRatio)).height, 120);
    }
  });
}
