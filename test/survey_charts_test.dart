import 'dart:async';
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(
  Widget child, {
  double width = 320,
  ThemeMode mode = ThemeMode.light,
}) => FlappaApp(
  themeMode: mode,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'questionnaire validates, preserves choices, skips, and submits immutable answers',
    (tester) async {
      Map<String, FQuestionAnswer>? result;
      await tester.pumpWidget(
        host(
          FQuestionnaire(
            questions: const [
              FQuestion(
                id: 'one',
                title: 'Choose one',
                choices: [
                  FQuestionChoice(value: 'a', label: 'Alpha'),
                  FQuestionChoice(value: 'b', label: 'Beta'),
                ],
              ),
              FQuestion(
                id: 'two',
                title: 'Choose several',
                required: false,
                multiple: true,
                choices: [
                  FQuestionChoice(value: 'x', label: 'Extra'),
                  FQuestionChoice(value: 'y', label: 'Yes'),
                ],
              ),
            ],
            onSubmitted: (answers) => result = answers,
          ),
        ),
      );
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(
        find.text('Choose or enter an answer to continue.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.tap(find.text('Extra'));
      await tester.pump();
      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.tap(find.text('Previous'));
      await tester.pump();
      expect(
        tester
            .widget<FChoiceCard>(find.widgetWithText(FChoiceCard, 'Alpha'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(
        tester
            .widget<FChoiceCard>(find.widgetWithText(FChoiceCard, 'Extra'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FChoiceCard>(find.widgetWithText(FChoiceCard, 'Yes'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(result!['one']!.selected, {'a'});
      expect(result!['two']!.skipped, isTrue);
      expect(result!['two']!.selected, isEmpty);
      expect(() => result!['one']!.selected.add('bad'), throwsUnsupportedError);
      expect(() => result!.clear(), throwsUnsupportedError);
      expect(find.text('All done'), findsOneWidget);
      await tester.tap(find.text('Start again'));
      await tester.pump();
      expect(
        tester
            .widget<FChoiceCard>(find.widgetWithText(FChoiceCard, 'Alpha'))
            .selected,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'freeform answers replace single choices and retain focus while editing',
    (tester) async {
      Map<String, FQuestionAnswer>? result;
      await tester.pumpWidget(
        host(
          FQuestionnaire(
            questions: [
              FQuestion(
                id: 'q',
                title: 'Choose or write',
                allowText: true,
                choices: const [FQuestionChoice(value: 'a', label: 'Alpha')],
                validator: (answer) =>
                    answer.selected.isEmpty && answer.text.length < 5
                    ? 'Write more'
                    : null,
              ),
            ],
            onSubmitted: (answers) => result = answers,
          ),
        ),
      );
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'Hey');
      await tester.pump();
      expect(
        tester.widget<FChoiceCard>(find.byType(FChoiceCard)).selected,
        isFalse,
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.tap(find.text('Submit answers'));
      await tester.pump();
      expect(find.text('Write more'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'A different answer');
      await tester.pump();
      await tester.tap(find.text('Submit answers'));
      await tester.pumpAndSettle();
      expect(result!['q']!.text, 'A different answer');
      expect(result!['q']!.selected, isEmpty);
    },
  );

  testWidgets(
    'submission errors preserve answers and duplicate submissions are blocked',
    (tester) async {
      var calls = 0;
      final request = Completer<void>();
      await tester.pumpWidget(
        host(
          FQuestionnaire(
            questions: const [
              FQuestion(id: 'q', title: 'Your answer', allowText: true),
            ],
            onSubmitted: (_) {
              calls++;
              return request.future;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Keep my answer');
      await tester.tap(find.text('Submit answers'));
      await tester.pump();
      await tester.tap(find.text('Submit answers'));
      await tester.pump();
      expect(calls, 1);
      request.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not submit your answers. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Keep my answer'), findsOneWidget);
      expect(find.text('All done'), findsNothing);
    },
  );

  testWidgets('choice cards respond to keyboard activation', (tester) async {
    var selected = false;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      host(
        FChoiceCard(
          title: 'Plan',
          selected: false,
          focusNode: focus,
          onChanged: (value) => selected = value,
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, isTrue);
  });

  testWidgets(
    'bar chart handles negative and zero values and returns selection',
    (tester) async {
      int? selected;
      await tester.pumpWidget(
        host(
          FBarChart(
            data: const [
              FChartDatum(label: 'Loss', value: -30),
              FChartDatum(label: 'Flat', value: 0),
              FChartDatum(label: 'Gain', value: 20),
            ],
            onSelected: (index) => selected = index,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Gain: 20'));
      await tester.pump();
      expect(selected, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        host(const FBarChart(data: [FChartDatum(label: 'Zero', value: 0)])),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('donut ignores center clicks and exposes each value', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      host(
        FDonutChart(
          data: const [
            FChartDatum(label: 'Direct', value: 50),
            FChartDatum(label: 'Search', value: 50),
          ],
          onSelected: (index) => selected = index,
        ),
      ),
    );
    final center = tester.getCenter(find.byType(FDonutChart));
    await tester.tapAt(center);
    expect(selected, isNull);
    await tester.tapAt(center + const Offset(-95, 0));
    expect(selected, 1);
    expect(
      find.bySemanticsLabel(RegExp(r'Donut chart\. Direct: 50, Search: 50')),
      findsOneWidget,
    );
  });

  testWidgets('charts handle empty data and reject invalid values', (
    tester,
  ) async {
    await tester.pumpWidget(host(const FDonutChart(data: [])));
    expect(find.text('No data'), findsOneWidget);
    await tester.pumpWidget(host(const FBarChart(data: [])));
    expect(find.text('No data'), findsOneWidget);
    await tester.pumpWidget(
      host(const FDonutChart(data: [FChartDatum(label: 'Invalid', value: -1)])),
    );
    expect(tester.takeException(), isArgumentError);
    await tester.pumpWidget(
      host(
        const FBarChart(
          data: [FChartDatum(label: 'Invalid', value: double.nan)],
        ),
      ),
    );
    expect(tester.takeException(), isArgumentError);
  });

  testWidgets(
    'legend selection works and static legends are not disabled buttons',
    (tester) async {
      int? selected;
      const data = [
        FChartDatum(label: 'Direct', value: 20),
        FChartDatum(label: 'Search', value: 10),
      ];
      await tester.pumpWidget(
        host(FChartLegend(data: data, onSelected: (index) => selected = index)),
      );
      await tester.tap(find.text('Search · 10'));
      expect(selected, 1);
      await tester.pumpWidget(host(const FChartLegend(data: data)));
      expect(find.byType(FButton), findsNothing);
    },
  );

  testWidgets('table scrolls and presents headers, footer, and caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FTable(
          headers: [Text('Invoice'), Text('Amount')],
          rows: [
            [Text('INV-001'), Text('250.00')],
          ],
          footer: [Text('Total'), Text('250.00')],
          caption: 'Recent invoices',
          numericColumns: {1},
        ),
        width: 260,
      ),
    );
    expect(find.text('Recent invoices'), findsOneWidget);
    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    await tester.drag(horizontal, const Offset(-200, 0));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      host(
        const FTable(
          headers: [Text('One')],
          rows: [
            [Text('A'), Text('B')],
          ],
        ),
      ),
    );
    expect(tester.takeException(), isArgumentError);
  });

  testWidgets(
    'marker actions and RTL direction compose in narrow dark layouts',
    (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        host(
          FDirection(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FMarker(
                  label: 'A longer status that can wrap',
                  variant: FMarkerVariant.separator,
                ),
                FMarker(
                  label: 'Open activity',
                  icon: const Icon(Icons.history),
                  variant: FMarkerVariant.border,
                  onPressed: () => pressed = true,
                ),
              ],
            ),
          ),
          width: 240,
          mode: ThemeMode.dark,
        ),
      );
      expect(
        Directionality.of(tester.element(find.text('Open activity'))),
        TextDirection.rtl,
      );
      await tester.tap(find.text('Open activity'));
      expect(pressed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
