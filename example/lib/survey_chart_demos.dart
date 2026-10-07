import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'widgets/demo_card.dart';

class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 760 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 20) / columns;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class SurveyDemos extends StatefulWidget {
  const SurveyDemos({super.key});
  @override
  State<SurveyDemos> createState() => _SurveyDemosState();
}

class _SurveyDemosState extends State<SurveyDemos> {
  String _plan = 'team';
  bool _fail = false, _rtl = false;
  int _answered = 0;
  @override
  Widget build(BuildContext context) => _Grid(
    children: [
      DemoCard(
        title: 'Questionnaire',
        description: 'A few thoughtful questions. One step at a time.',
        code:
            "FQuestionnaire(\n  questions: const [\n    FQuestion(\n      id: 'platform',\n      title: 'What are you building?',\n      choices: [FQuestionChoice(value: 'app', label: 'An app')],\n    ),\n  ],\n  onSubmitted: (answers) async => saveAnswers(answers),\n)",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FQuestionnaire(
              questions: [
                const FQuestion(
                  id: 'platform',
                  title: 'What are you building?',
                  description:
                      'Choose a starting point, or tell us in your own words.',
                  allowText: true,
                  placeholder: 'Something else…',
                  choices: [
                    FQuestionChoice(
                      value: 'app',
                      label: 'A mobile app',
                      description: 'A great experience, wherever you go.',
                    ),
                    FQuestionChoice(
                      value: 'dashboard',
                      label: 'A dashboard',
                      description: 'Make complex information feel simple.',
                    ),
                  ],
                ),
                const FQuestion(
                  id: 'features',
                  title: 'What matters most?',
                  description:
                      'Choose as many as you like, or skip this question.',
                  required: false,
                  multiple: true,
                  choices: [
                    FQuestionChoice(
                      value: 'accessibility',
                      label: 'Accessibility',
                    ),
                    FQuestionChoice(value: 'themes', label: 'Custom themes'),
                    FQuestionChoice(value: 'performance', label: 'Performance'),
                  ],
                ),
                FQuestion(
                  id: 'idea',
                  title: 'Tell us a little about your idea.',
                  description: 'A sentence is a great place to start.',
                  allowText: true,
                  placeholder: 'I want to build…',
                  validator: (answer) => answer.text.trim().length < 10
                      ? 'Please write at least 10 characters.'
                      : null,
                ),
              ],
              onChanged: (answers) => setState(
                () => _answered = answers.values
                    .where((answer) => !answer.isEmpty)
                    .length,
              ),
              onSubmitted: (answers) async {
                await Future<void>.delayed(const Duration(milliseconds: 400));
                if (_fail) throw StateError('Demo failure');
              },
              completedBuilder: (_) => const FEmpty(
                title: 'Your brief is ready',
                description: 'This demo keeps your answers local.',
                icon: Icons.task_alt,
              ),
            ),
            const SizedBox(height: 24),
            const FSeparator(),
            const SizedBox(height: 12),
            FSwitch(
              value: _fail,
              label: 'Simulate a submission error',
              onChanged: (value) => setState(() => _fail = value),
            ),
            const SizedBox(height: 8),
            Text(
              '$_answered answered',
              style: TextStyle(
                fontSize: 12,
                color: FTheme.of(context).colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
      DemoCard(
        title: 'Choice cards',
        description: 'A little more context for an important choice.',
        code:
            "FChoiceCard(\n  title: 'Team',\n  description: 'For a small team with big ideas.',\n  selected: plan == 'team',\n  onChanged: (_) => setState(() => plan = 'team'),\n)",
        child: Column(
          children: [
            for (final entry in const {
              'personal': ('Personal', 'For your next side project.'),
              'team': ('Team', 'For a small team with big ideas.'),
              'studio': ('Studio', 'For everything you’re building together.'),
            }.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FChoiceCard(
                  title: entry.value.$1,
                  description: entry.value.$2,
                  selected: _plan == entry.key,
                  onChanged: (_) => setState(() => _plan = entry.key),
                ),
              ),
          ],
        ),
      ),
      DemoCard(
        title: 'Marker',
        description: 'Quiet milestones between the bigger moments.',
        code:
            "const FMarker(\n  label: 'Today',\n  variant: FMarkerVariant.separator,\n);\nconst FMarker(\n  label: 'All checks passed',\n  icon: Icon(Icons.check_circle_outline),\n);",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FMarker(label: 'Today', variant: FMarkerVariant.separator),
            const FMarker(
              label: 'Explored 4 files',
              icon: Icon(Icons.folder_open_outlined),
              variant: FMarkerVariant.border,
            ),
            const FMarker(
              label: 'All checks passed',
              icon: Icon(Icons.check_circle_outline),
              live: true,
            ),
            FMarker(
              label: 'View activity',
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => showFToast(context, title: 'Activity opened'),
            ),
          ],
        ),
      ),
      DemoCard(
        title: 'Direction',
        description: 'Let the layout follow the language.',
        code:
            "FDirection(\n  textDirection: TextDirection.rtl,\n  child: FItem(\n    title: const Text('Project settings'),\n    leading: const Icon(Icons.settings_outlined),\n  ),\n)",
        child: Column(
          children: [
            FSwitch(
              value: _rtl,
              label: 'Right-to-left layout',
              onChanged: (value) => setState(() => _rtl = value),
            ),
            const SizedBox(height: 20),
            FDirection(
              textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
              child: const FItem(
                title: Text('Project settings'),
                description: Text('Every detail, in the right place.'),
                leading: Icon(Icons.settings_outlined),
                trailing: Icon(Icons.chevron_right, size: 18),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class ChartDemos extends StatefulWidget {
  const ChartDemos({super.key});
  @override
  State<ChartDemos> createState() => _ChartDemosState();
}

class _ChartDemosState extends State<ChartDemos> {
  int? _bar, _donut;
  bool _compare = false;
  List<FChartDatum> get _activity => [
    for (final entry
        in (_compare
                ? const {
                    'Mon': 16.0,
                    'Tue': -8.0,
                    'Wed': 32.0,
                    'Thu': -12.0,
                    'Fri': 24.0,
                    'Sat': 6.0,
                  }
                : const {
                    'Mon': 48.0,
                    'Tue': 72.0,
                    'Wed': 56.0,
                    'Thu': 94.0,
                    'Fri': 68.0,
                    'Sat': 82.0,
                  })
            .entries)
      FChartDatum(
        label: entry.key,
        value: entry.value,
        color: FTheme.of(context).colors.primary,
      ),
  ];
  static const _sources = [
    FChartDatum(label: 'Direct', value: 420, color: Color(0xFF2563EB)),
    FChartDatum(label: 'Search', value: 310, color: Color(0xFF14B8A6)),
    FChartDatum(label: 'Referral', value: 170, color: Color(0xFF8B5CF6)),
    FChartDatum(label: 'Social', value: 100, color: Color(0xFFF59E0B)),
  ];
  @override
  Widget build(BuildContext context) => _Grid(
    children: [
      DemoCard(
        title: 'Bar chart',
        description: 'Explore each value with a click or a hover.',
        code:
            "FBarChart(\n  data: const [\n    FChartDatum(label: 'Mon', value: 48),\n    FChartDatum(label: 'Tue', value: 72),\n  ],\n  selectedIndex: selected,\n  onSelected: (index) => setState(() => selected = index),\n)",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FBarChart(
              data: _activity,
              selectedIndex: _bar,
              onSelected: (value) =>
                  setState(() => _bar = _bar == value ? null : value),
              label: 'Weekly activity',
            ),
            const SizedBox(height: 16),
            Text(
              _bar == null
                  ? 'Select a day to see its value.'
                  : '${_activity[_bar!].label} · ${_activity[_bar!].value.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                color: FTheme.of(context).colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            FSwitch(
              value: _compare,
              label: 'Show changes from last week',
              onChanged: (value) => setState(() => _compare = value),
            ),
          ],
        ),
      ),
      DemoCard(
        title: 'Donut chart & legend',
        description: 'A clear picture of where people come from.',
        code:
            "FDonutChart(\n  data: sources,\n  selectedIndex: selected,\n  onSelected: (index) => setState(() => selected = index),\n);\nFChartLegend(data: sources);",
        child: Column(
          children: [
            FDonutChart(
              data: _sources,
              selectedIndex: _donut,
              onSelected: (value) =>
                  setState(() => _donut = _donut == value ? null : value),
              center: _donut == null
                  ? null
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_sources[_donut!].value.toInt()}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _sources[_donut!].label,
                          style: TextStyle(
                            fontSize: 12,
                            color: FTheme.of(context).colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            FChartLegend(
              data: _sources,
              selectedIndex: _donut,
              onSelected: (value) =>
                  setState(() => _donut = _donut == value ? null : value),
            ),
          ],
        ),
      ),
      const DemoCard(
        title: 'Table',
        description: 'A simple table with a header, footer, and caption.',
        code:
            "const FTable(\n  headers: [Text('Invoice'), Text('Amount')],\n  rows: [\n    [Text('INV-001'), Text('250.00')],\n  ],\n  numericColumns: {1},\n  caption: 'Recent invoices',\n)",
        child: FTable(
          headers: [Text('Invoice'), Text('Status'), Text('Amount')],
          numericColumns: {2},
          striped: true,
          rows: [
            [Text('INV-001'), FBadge(child: Text('Paid')), Text('250.00')],
            [
              Text('INV-002'),
              FBadge(variant: FBadgeVariant.outline, child: Text('Pending')),
              Text('150.00'),
            ],
            [Text('INV-003'), FBadge(child: Text('Paid')), Text('350.00')],
          ],
          footer: [Text('Total'), Text(''), Text('750.00')],
          caption: 'A snapshot of your recent invoices.',
        ),
      ),
      const DemoCard(
        title: 'Empty chart states',
        description: 'An honest starting point while data is on its way.',
        code: "const FDonutChart(data: []);\nconst FBarChart(data: []);",
        child: FDonutChart(size: 180, thickness: 22, data: []),
      ),
    ],
  );
}
