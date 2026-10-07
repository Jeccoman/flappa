import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'extra_demos.dart';
import 'site/site_app.dart';
import 'site/site_widgets.dart' show PackageLink;
import 'survey_chart_demos.dart';
import 'widgets/demo_card.dart';

export 'widgets/demo_card.dart';

void main() => runApp(const SiteApp());

class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({
    super.key,
    this.onHome,
    this.onPlayground,
    this.initialSection = 0,
  });
  final int initialSection;
  final VoidCallback? onHome, onPlayground;
  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  bool _dark = false;
  Color? _accent;
  double _radius = 8;
  FThemeData _theme(Brightness brightness) {
    final colors = FColors.zinc(brightness: brightness);
    return FThemeData(
      brightness: brightness,
      radius: _radius,
      colors: _accent == null
          ? colors
          : colors.copyWith(
              primary: _accent,
              primaryForeground: Colors.white,
              ring: _accent,
            ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flappa UI — Beautifully built',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light).toThemeData(),
    darkTheme: _theme(Brightness.dark).toThemeData(),
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    home: ShowcasePage(
      initialSection: widget.initialSection,
      onHome: widget.onHome,
      onPlayground: widget.onPlayground,
      dark: _dark,
      onThemeChanged: () => setState(() => _dark = !_dark),
      accent: _accent,
      onAccentChanged: (value) => setState(() => _accent = value),
      radius: _radius,
      onRadiusChanged: (value) => setState(() => _radius = value),
    ),
  );
}

const sections = [
  'Overview',
  'Buttons',
  'Forms',
  'Navigation',
  'Feedback',
  'Overlays',
  'Data',
  'Layout',
  'Getting started',
  'Building blocks',
  'Messages',
  'Questionnaires',
  'Charts & tables',
];
const sectionIcons = [
  Icons.grid_view_outlined,
  Icons.smart_button_outlined,
  Icons.edit_note_outlined,
  Icons.account_tree_outlined,
  Icons.notifications_none_outlined,
  Icons.layers_outlined,
  Icons.table_chart_outlined,
  Icons.view_quilt_outlined,
  Icons.terminal_outlined,
  Icons.widgets_outlined,
  Icons.chat_bubble_outline,
  Icons.quiz_outlined,
  Icons.bar_chart_outlined,
];
const descriptions = [
  'Thoughtfully crafted components. Ready for your next Flutter app.',
  'Every action, with the right emphasis. Six variants, one simple API.',
  'Make filling out a form feel effortless, from the first input to the last.',
  'Give every screen a sense of place and every action a clear destination.',
  'Keep people informed with clear, considered feedback.',
  'A little more context, right where you need it.',
  'Bring clarity to your data with tables and lightweight charts.',
  'Flexible foundations for interfaces of every shape and size.',
  'A small setup. A whole new starting point.',
  'Compose everyday interfaces with a few well-chosen pieces.',
  'Thoughtful conversations, attachments, and a place to catch up.',
  'Good questions make a great starting point.',
  'Find the patterns. Share the details. Make it clear.',
];

class ShowcasePage extends StatefulWidget {
  const ShowcasePage({
    super.key,
    required this.dark,
    required this.onThemeChanged,
    required this.accent,
    required this.onAccentChanged,
    required this.radius,
    required this.onRadiusChanged,
    this.onHome,
    this.onPlayground,
    this.initialSection = 0,
  });
  final VoidCallback? onHome, onPlayground;
  final int initialSection;
  final bool dark;
  final VoidCallback onThemeChanged;
  final Color? accent;
  final ValueChanged<Color?> onAccentChanged;
  final double radius;
  final ValueChanged<double> onRadiusChanged;
  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  late int _section = widget.initialSection;
  final ScrollController _scroll = ScrollController();
  final _scaffold = GlobalKey<ScaffoldState>();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _navigate(int section) {
    setState(() => _section = section);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _scaffold.currentState?.closeDrawer();
  }

  Future<void> _search() async {
    final section = await showFCommand<int>(
      context: context,
      placeholder: 'Find a component…',
      items: [
        for (var i = 0; i < sections.length; i++)
          FCommandItem(
            value: i,
            label: sections[i],
            icon: sectionIcons[i],
            description: descriptions[i],
          ),
      ],
    );
    if (section != null && mounted) _navigate(section);
  }

  Widget _brand() => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: FTheme.of(context).colors.foreground,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            Icons.polyline_outlined,
            size: 19,
            color: FTheme.of(context).colors.background,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'flappa',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '/ ui',
          style: TextStyle(
            fontSize: 20,
            letterSpacing: -1,
            color: FTheme.of(context).colors.mutedForeground,
          ),
        ),
      ],
    ),
  );
  Widget _sidebar() => FSidebar(
    width: 224,
    header: Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(onTap: widget.onHome, child: _brand()),
          if (widget.onPlayground != null) ...[
            const SizedBox(height: 18),
            FButton(
              onPressed: widget.onPlayground,
              variant: FButtonVariant.outline,
              leading: const Icon(Icons.dashboard_customize_outlined),
              child: const Text('Playground'),
            ),
          ],
        ],
      ),
    ),
    footer: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Flutter native',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: FTheme.of(context).colors.mutedForeground,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'v0.1.0',
          style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Text(
            'WORKSPACE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              color: FTheme.of(context).colors.mutedForeground,
            ),
          ),
        ),
        FNavigationMenu(
          axis: Axis.vertical,
          index: _section,
          onChanged: _navigate,
          items: [
            for (var i = 0; i < sections.length; i++)
              FNavigationItem(
                label: sections[i],
                icon: sectionIcons[i],
                badge: i == 0 ? const FBadge(child: Text('New')) : null,
              ),
          ],
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FTheme.of(context).colors.muted.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FTheme.of(context).colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.code, size: 20),
                const SizedBox(height: 12),
                const Text(
                  'Your code. Your rules.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'Copy, compose, and make it your own.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: FTheme.of(context).colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                FButton(
                  onPressed: () => _navigate(8),
                  variant: FButtonVariant.link,
                  size: FButtonSize.small,
                  child: const Text('Get started →'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = FTheme.of(context).colors;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _search,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _search,
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1000;
          return Scaffold(
            key: _scaffold,
            drawer: desktop
                ? null
                : Drawer(width: 260, child: SafeArea(child: _sidebar())),
            body: SafeArea(
              child: Row(
                children: [
                  if (desktop) _sidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 72,
                          padding: EdgeInsets.symmetric(
                            horizontal: desktop ? 36 : 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: c.border)),
                          ),
                          child: Row(
                            children: [
                              if (!desktop) ...[
                                FButton(
                                  onPressed: () =>
                                      _scaffold.currentState?.openDrawer(),
                                  variant: FButtonVariant.ghost,
                                  size: FButtonSize.icon,
                                  tooltip: 'Open navigation',
                                  child: const Icon(Icons.menu),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                desktop ? 'Component library' : 'flappa / ui',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              if (constraints.maxWidth > 650)
                                SizedBox(
                                  width: 250,
                                  child: FButton(
                                    onPressed: _search,
                                    variant: FButtonVariant.outline,
                                    leading: const Icon(Icons.search),
                                    trailing: const FKbd('⌘ K'),
                                    child: const Text('Search components'),
                                  ),
                                )
                              else
                                FButton(
                                  onPressed: _search,
                                  variant: FButtonVariant.ghost,
                                  size: FButtonSize.icon,
                                  tooltip: 'Search components',
                                  child: const Icon(Icons.search),
                                ),
                              const SizedBox(width: 8),
                              FButton(
                                onPressed: widget.onThemeChanged,
                                variant: FButtonVariant.ghost,
                                size: FButtonSize.icon,
                                tooltip: widget.dark
                                    ? 'Switch to light mode'
                                    : 'Switch to dark mode',
                                child: Icon(
                                  widget.dark
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                ),
                              ),
                              if (constraints.maxWidth > 450) ...[
                                const SizedBox(width: 8),
                                FButton(
                                  onPressed: _customize,
                                  variant: FButtonVariant.outline,
                                  leading: const Icon(Icons.tune),
                                  child: const Text('Customize'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: SelectionArea(
                            child: SingleChildScrollView(
                              controller: _scroll,
                              padding: EdgeInsets.all(desktop ? 36 : 20),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1200,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_section == 0)
                                        _hero()
                                      else ...[
                                        Text(
                                          'COMPONENTS / ${sections[_section].toUpperCase()}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            letterSpacing: 1.8,
                                            fontWeight: FontWeight.w500,
                                            color: c.mutedForeground,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          sections[_section],
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          descriptions[_section],
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: c.mutedForeground,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                      ],
                                      ComponentDemos(
                                        key: ValueKey(_section),
                                        section: _section,
                                        onNavigate: _navigate,
                                      ),
                                      const SizedBox(height: 48),
                                      const FSeparator(),
                                      const SizedBox(height: 20),
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            'Built with Flutter. Made to be yours.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: c.mutedForeground,
                                            ),
                                          ),
                                          Text(
                                            'Flappa UI · MIT license · Inspired by shadcn/ui',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: c.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hero() {
    final c = FTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const FBadge(
              variant: FBadgeVariant.outline,
              child: Text('INTRODUCING FLAPPA UI'),
            ),
            Text(
              'Open source. All yours.',
              style: TextStyle(color: c.mutedForeground, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) => Text(
            'Your next idea,\nbeautifully built.',
            style: TextStyle(
              fontSize: constraints.maxWidth < 500 ? 38 : 54,
              height: 1.06,
              fontWeight: FontWeight.w700,
              letterSpacing: -2.6,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Text(
            'A collection of beautifully crafted Flutter components.\nComposable, customizable, and ready to make your own.',
            style: TextStyle(
              color: c.mutedForeground,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FButton(
              onPressed: () => _navigate(8),
              trailing: const Icon(Icons.arrow_forward),
              child: const Text('Start building'),
            ),
            FButton(
              onPressed: () => _navigate(1),
              variant: FButtonVariant.outline,
              child: const Text('Explore components'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: c.muted.withValues(alpha: .45),
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.terminal, size: 16, color: c.mutedForeground),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'flutter pub add flappa_ui',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              FButton(
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: 'flutter pub add flappa_ui'),
                  );
                  if (mounted) showFToast(context, title: 'Command copied');
                },
                size: FButtonSize.icon,
                variant: FButtonVariant.ghost,
                tooltip: 'Copy install command',
                child: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'A little of what’s possible',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                letterSpacing: -.5,
              ),
            ),
            if (MediaQuery.sizeOf(context).width > 600)
              Text(
                'COMPOSABLE. CUSTOMIZABLE. FLUTTER.',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.4,
                  color: c.mutedForeground,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _customize() => showFSheet<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocalState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Make it yours',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'One theme. Every component.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 32),
          const Text(
            'Accent color',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in <String, Color?>{
                'Zinc': null,
                'Blue': const Color(0xFF2563EB),
                'Green': const Color(0xFF15803D),
                'Violet': const Color(0xFF7C3AED),
                'Orange': const Color(0xFFC2410C),
              }.entries)
                FButton(
                  onPressed: () {
                    widget.onAccentChanged(entry.value);
                    setLocalState(() {});
                  },
                  variant: FButtonVariant.outline,
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color:
                          entry.value ?? FTheme.of(context).colors.foreground,
                      shape: BoxShape.circle,
                    ),
                  ),
                  child: Text(entry.key),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Corner radius',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          FSelect<double>(
            items: {
              0: 'Sharp · 0 px',
              4: 'Subtle · 4 px',
              8: 'Classic · 8 px',
              12: 'Soft · 12 px',
            },
            value: widget.radius,
            onChanged: (value) {
              widget.onRadiusChanged(value!);
              setLocalState(() {});
            },
          ),
          const SizedBox(height: 28),
          FSwitch(
            value: widget.dark,
            onChanged: (_) {
              widget.onThemeChanged();
              setLocalState(() {});
            },
            label: 'Dark mode',
          ),
          const SizedBox(height: 32),
          const FAlert(
            title: Text('Semantic by design'),
            description: Text(
              'Colors and radius flow through the entire library, including native Flutter controls.',
            ),
          ),
        ],
      ),
    ),
  );
}

class ComponentDemos extends StatefulWidget {
  const ComponentDemos({
    super.key,
    required this.section,
    required this.onNavigate,
  });
  final int section;
  final ValueChanged<int> onNavigate;
  @override
  State<ComponentDemos> createState() => _ComponentDemosState();
}

class _ComponentDemosState extends State<ComponentDemos> {
  bool _email = true, _push = false, _terms = false, _expanded = false;
  double _volume = 45;
  String? _framework = 'Flutter', _plan = 'pro', _language;
  int _tab = 0, _page = 1;
  DateTime? _date;
  DateTimeRange? _dateRange;
  RangeValues _range = const RangeValues(25, 75);
  Set<String> _format = {'bold'};
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Alex Morgan');
  final _mail = TextEditingController(text: 'alex@acme.com');
  bool _sortAsc = true;
  int _sortColumn = 0;
  final _selected = <String>{};
  final _people = <({String name, String email, String role, String status})>[
    (
      name: 'Alex Morgan',
      email: 'alex@acme.com',
      role: 'Owner',
      status: 'Active',
    ),
    (
      name: 'Sofia Chen',
      email: 'sofia@acme.com',
      role: 'Developer',
      status: 'Active',
    ),
    (
      name: 'James Wilson',
      email: 'james@acme.com',
      role: 'Designer',
      status: 'Invited',
    ),
    (
      name: 'Olivia Park',
      email: 'olivia@acme.com',
      role: 'Developer',
      status: 'Active',
    ),
  ];
  @override
  void dispose() {
    _name.dispose();
    _mail.dispose();
    super.dispose();
  }

  void _toast(String title) => showFToast(context, title: title);
  Widget _grid(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth > 760 ? 2 : 1;
      final width = (constraints.maxWidth - (count - 1) * 20) / count;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
  @override
  Widget build(BuildContext context) => switch (widget.section) {
    0 => _overview(),
    1 => _buttons(),
    2 => _forms(),
    3 => _navigation(),
    4 => _feedback(),
    5 => _overlays(),
    6 => _data(),
    7 => _layout(),
    9 => const CompositionDemos(),
    10 => const MessagingDemos(),
    11 => const SurveyDemos(),
    12 => const ChartDemos(),
    _ => _gettingStarted(),
  };

  Widget _overview() => _grid([
    FCard(
      title: Row(
        children: [
          const Expanded(child: Text('Create your account')),
          const FBadge(variant: FBadgeVariant.outline, child: Text('01')),
        ],
      ),
      description: const Text('Your next great project starts here.'),
      footer: FButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _toast('Account preview created for ${_name.text}');
          }
        },
        trailing: const Icon(Icons.arrow_forward),
        child: const Text('Create account'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FField(
              label: 'Full name',
              child: FInput(
                controller: _name,
                semanticLabel: 'Full name',
                placeholder: 'Alex Morgan',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name'
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            FField(
              label: 'Email address',
              child: FInput(
                controller: _mail,
                semanticLabel: 'Email address',
                placeholder: 'you@company.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)
                    ? 'Enter a valid email address'
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            FField(
              label: 'Framework',
              child: FSelect<String>(
                items: const {
                  'Flutter': 'Flutter',
                  'React Native': 'React Native',
                  'SwiftUI': 'SwiftUI',
                },
                value: _framework,
                onChanged: (value) => setState(() => _framework = value),
              ),
            ),
          ],
        ),
      ),
    ),
    FCard(
      title: Row(
        children: [
          const Expanded(child: Text('Overview')),
          FDropdownMenu<String>(
            items: const [
              FMenuItem(value: 'week', label: 'This week'),
              FMenuItem(value: 'month', label: 'This month'),
            ],
            onSelected: (value) => _toast('Viewing this $value'),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.more_horiz, size: 20),
            ),
          ),
        ],
      ),
      description: const Text('Your activity is looking good.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '24,680',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.trending_up, size: 14, color: Color(0xFF16A34A)),
              const SizedBox(width: 5),
              const Text(
                '12.8%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'from last month',
                style: TextStyle(
                  fontSize: 12,
                  color: FTheme.of(context).colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const FChart(
            values: [
              12,
              20,
              16,
              29,
              25,
              38,
              34,
              31,
              47,
              42,
              54,
              48,
              62,
              57,
              71,
              66,
              80,
              75,
              88,
              84,
              98,
            ],
            height: 162,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final month in ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'])
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 11,
                    color: FTheme.of(context).colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    FCard(
      title: const Text('The right people, together'),
      description: const Text('Invite your team to build something great.'),
      footer: FButton(
        onPressed: _invite,
        variant: FButtonVariant.outline,
        leading: const Icon(Icons.add),
        child: const Text('Invite a teammate'),
      ),
      child: Column(
        children: [
          _person('SC', 'Sofia Chen', 'sofia@acme.com', 'Owner'),
          const SizedBox(height: 20),
          _person('JW', 'James Wilson', 'james@acme.com', 'Member'),
          const SizedBox(height: 20),
          _person('OP', 'Olivia Park', 'olivia@acme.com', 'Member'),
        ],
      ),
    ),
    FCard(
      title: const Text('A space that feels like you'),
      description: const Text('Choose what you want to hear from us.'),
      footer: FButton(
        onPressed: () => _toast('Preferences saved'),
        child: const Text('Save preferences'),
      ),
      child: Column(
        children: [
          FSwitch(
            value: _email,
            onChanged: (value) => setState(() => _email = value),
            label: 'Email notifications',
            description: 'The important things, in your inbox.',
          ),
          const SizedBox(height: 14),
          const FSeparator(),
          const SizedBox(height: 14),
          FSwitch(
            value: _push,
            onChanged: (value) => setState(() => _push = value),
            label: 'Push notifications',
            description: 'A gentle nudge when it matters.',
          ),
          const SizedBox(height: 24),
          FAlert(
            icon: Icons.auto_awesome_outlined,
            title: const Text('A little less noise.'),
            description: const Text(
              'You’re always in control. Update your preferences any time.',
            ),
          ),
        ],
      ),
    ),
  ]);
  Widget _person(String initials, String name, String email, String role) =>
      Row(
        children: [
          FAvatar(fallback: initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: FTheme.of(context).colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          FBadge(variant: FBadgeVariant.outline, child: Text(role)),
        ],
      );

  Widget _buttons() => _grid([
    DemoCard(
      title: 'Button',
      description: 'Six variants for a clear visual hierarchy.',
      code:
          "FButton(\n  onPressed: () {},\n  variant: FButtonVariant.outline,\n  child: const Text('Button'),\n)",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final variant in FButtonVariant.values)
            FButton(
              onPressed: () => _toast('${variant.name} pressed'),
              variant: variant,
              child: Text(variant.name),
            ),
        ],
      ),
    ),
    DemoCard(
      title: 'Sizes & states',
      description: 'Small, medium, large, and icon buttons.',
      code:
          "FButton(\n  onPressed: save,\n  loading: isSaving,\n  leading: const Icon(Icons.save_outlined),\n  child: const Text('Save'),\n)",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FButton(
            onPressed: () => _toast('Small'),
            size: FButtonSize.small,
            child: const Text('Small'),
          ),
          FButton(
            onPressed: () => _toast('Medium'),
            child: const Text('Medium'),
          ),
          FButton(
            onPressed: () => _toast('Large'),
            size: FButtonSize.large,
            child: const Text('Large'),
          ),
          FButton(
            onPressed: () => _toast('Added'),
            size: FButtonSize.icon,
            tooltip: 'Add item',
            child: const Icon(Icons.add),
          ),
          const FButton(onPressed: null, child: Text('Disabled')),
          FButton(
            onPressed: () {},
            loading: true,
            child: const Text('Please wait'),
          ),
        ],
      ),
    ),
    DemoCard(
      title: 'Toggle group',
      description: 'Controlled selection, with multiple values.',
      code:
          "FToggleGroup<String>(\n  items: const {'bold': Text('B'), 'italic': Text('I')},\n  value: selected,\n  multiple: true,\n  onChanged: (value) => setState(() => selected = value),\n)",
      child: FToggleGroup<String>(
        items: const {
          'bold': Icon(Icons.format_bold),
          'italic': Icon(Icons.format_italic),
          'underline': Icon(Icons.format_underlined),
        },
        value: _format,
        multiple: true,
        onChanged: (value) => setState(() => _format = value),
      ),
    ),
    DemoCard(
      title: 'Badge',
      description: 'Small details that say a lot.',
      code:
          "const FBadge(\n  variant: FBadgeVariant.outline,\n  child: Text('In progress'),\n)",
      child: const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FBadge(variant: FBadgeVariant.primary, child: Text('Default')),
          FBadge(child: Text('Secondary')),
          FBadge(variant: FBadgeVariant.outline, child: Text('Outline')),
          FBadge(
            variant: FBadgeVariant.destructive,
            child: Text('Destructive'),
          ),
        ],
      ),
    ),
  ]);

  Widget _forms() => _grid([
    DemoCard(
      title: 'Input & textarea',
      description: 'Native editing, autofill, and form validation.',
      code:
          "FField(\n  label: 'Email',\n  child: FInput(\n    placeholder: 'you@example.com',\n    validator: (value) => value!.isEmpty ? 'Required' : null,\n  ),\n)",
      child: Column(
        children: [
          const FField(
            label: 'Email',
            child: FInput(
              placeholder: 'you@example.com',
              semanticLabel: 'Email',
              prefix: Icon(Icons.mail_outline, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          const FField(
            label: 'Your message',
            description: 'A few words can go a long way.',
            child: FTextarea(
              placeholder: 'Tell us a little about your project…',
            ),
          ),
          const SizedBox(height: 20),
          const FInput(placeholder: 'Disabled input', enabled: false),
        ],
      ),
    ),
    DemoCard(
      title: 'Select & combobox',
      description: 'A familiar dropdown, or search to find it faster.',
      code:
          "FCombobox<String>(\n  items: const ['Dart', 'TypeScript', 'Swift'],\n  value: language,\n  labelOf: (value) => value,\n  onChanged: (value) => setState(() => language = value),\n)",
      child: Column(
        children: [
          FField(
            label: 'Framework',
            child: FSelect<String>(
              items: const {
                'Flutter': 'Flutter',
                'React Native': 'React Native',
                'SwiftUI': 'SwiftUI',
              },
              value: _framework,
              onChanged: (value) => setState(() => _framework = value),
            ),
          ),
          const SizedBox(height: 20),
          FField(
            label: 'Language',
            child: FCombobox<String>(
              items: const ['Dart', 'TypeScript', 'Swift', 'Kotlin', 'Rust'],
              value: _language,
              labelOf: (value) => value,
              onChanged: (value) => setState(() => _language = value),
            ),
          ),
        ],
      ),
    ),
    DemoCard(
      title: 'Checkbox, switch & radio',
      description: 'Simple choices with accessible native controls.',
      code:
          "FSwitch(\n  value: enabled,\n  label: 'Airplane mode',\n  onChanged: (value) => setState(() => enabled = value),\n)",
      child: Column(
        children: [
          FCheckbox(
            value: _terms,
            onChanged: (value) => setState(() => _terms = value!),
            label: 'Accept terms and conditions',
            description: 'You agree to our terms of service.',
          ),
          const SizedBox(height: 16),
          FSwitch(
            value: _email,
            onChanged: (value) => setState(() => _email = value),
            label: 'Airplane mode',
          ),
          const SizedBox(height: 12),
          FRadioGroup<String>(
            items: const {
              'free': 'Free — for your next idea',
              'pro': 'Pro — for your growing team',
              'enterprise': 'Enterprise — for everyone',
            },
            value: _plan,
            onChanged: (value) => setState(() => _plan = value),
          ),
        ],
      ),
    ),
    DemoCard(
      title: 'Slider, date & one-time code',
      description: 'The small interactions that make a difference.',
      code:
          "FDatePicker(\n  value: date,\n  onChanged: (value) => setState(() => date = value),\n)",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Volume · ${_volume.round()}%'),
          FSlider(
            value: _volume,
            onChanged: (value) => setState(() => _volume = value),
          ),
          const SizedBox(height: 20),
          FField(
            label: 'Date',
            child: Align(
              alignment: Alignment.centerLeft,
              child: FDatePicker(
                value: _date,
                onChanged: (value) => setState(() => _date = value),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FField(
            label: 'Verification code',
            description: 'Paste a 6-digit code to try it out.',
            child: FInputOTP(
              onCompleted: (code) => _toast('Code entered: $code'),
            ),
          ),
        ],
      ),
    ),
    DemoCard(
      title: 'Range controls',
      description: 'Choose a window, from values to dates.',
      code:
          "FRangeSlider(\n  values: range,\n  onChanged: (value) => setState(() => range = value),\n)",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Range · ${_range.start.round()}–${_range.end.round()}'),
          FRangeSlider(
            values: _range,
            onChanged: (value) => setState(() => _range = value),
          ),
          const SizedBox(height: 20),
          FDateRangePicker(
            value: _dateRange,
            onChanged: (value) => setState(() => _dateRange = value),
          ),
        ],
      ),
    ),
  ]);

  Widget _navigation() => _grid([
    DemoCard(
      title: 'Tabs',
      description: 'One space, a few different perspectives.',
      code:
          "FTabs(\n  index: index,\n  onChanged: (value) => setState(() => index = value),\n  tabs: const [\n    FTab(label: 'Account', child: Text('Your account')),\n    FTab(label: 'Password', child: Text('Your password')),\n  ],\n)",
      child: FTabs(
        index: _tab,
        onChanged: (value) => setState(() => _tab = value),
        tabs: [
          FTab(
            label: 'Account',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FField(
                  label: 'Display name',
                  child: FInput(initialValue: 'Alex Morgan'),
                ),
                const SizedBox(height: 16),
                FButton(
                  onPressed: () => _toast('Account saved'),
                  child: const Text('Save changes'),
                ),
              ],
            ),
          ),
          FTab(
            label: 'Password',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FField(
                  label: 'New password',
                  child: FInput(
                    obscureText: true,
                    placeholder: 'Enter a new password',
                  ),
                ),
                const SizedBox(height: 16),
                FButton(
                  onPressed: () => _toast('Password preview saved'),
                  child: const Text('Update password'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    const DemoCard(
      title: 'Accordion',
      description: 'Details, when you want them.',
      code:
          "FAccordion(items: const [\n  FAccordionItem(\n    id: 'open',\n    title: Text('Is it open source?'),\n    child: Text('Yes. MIT licensed.'),\n  ),\n])",
      child: FAccordion(
        items: [
          FAccordionItem(
            id: 'accessible',
            title: Text('Is it accessible?'),
            child: Text(
              'Built on Flutter controls with focus, keyboard, and screen-reader support. Test accessibility in your final app.',
            ),
          ),
          FAccordionItem(
            id: 'themed',
            title: Text('Can I customize the theme?'),
            child: Text(
              'Yes. Use semantic colors, a custom font family, and your preferred corner radius.',
            ),
          ),
          FAccordionItem(
            id: 'source',
            title: Text('Can I own the source?'),
            child: Text(
              'Use the CLI to copy component groups into your project, then edit freely.',
            ),
          ),
        ],
      ),
    ),
    DemoCard(
      title: 'Breadcrumb & pagination',
      description: 'Help people find their way.',
      code:
          "FPagination(\n  page: page,\n  pageCount: 10,\n  onChanged: (value) => setState(() => page = value),\n)",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FBreadcrumb(
            items: [
              FBreadcrumbItem('Home', onPressed: () => _toast('Home')),
              FBreadcrumbItem(
                'Components',
                onPressed: () => _toast('Components'),
              ),
              const FBreadcrumbItem('Navigation'),
            ],
          ),
          const SizedBox(height: 28),
          FPagination(
            page: _page,
            pageCount: 10,
            onChanged: (value) => setState(() => _page = value),
          ),
        ],
      ),
    ),
    DemoCard(
      title: 'Collapsible',
      description: 'A compact home for supporting content.',
      code:
          "FCollapsible(\n  expanded: open,\n  onChanged: (value) => setState(() => open = value),\n  title: const Text('Dependencies'),\n  child: const Text('Only Flutter.'),\n)",
      child: FCollapsible(
        expanded: _expanded,
        onChanged: (value) => setState(() => _expanded = value),
        title: const Text('One dependency. Infinite possibilities.'),
        child: const FAlert(
          title: Text('Just Flutter'),
          description: Text(
            'No third-party runtime packages. Everything you see is built using the Flutter SDK.',
          ),
        ),
      ),
    ),
  ]);

  Widget _feedback() => _grid([
    const DemoCard(
      title: 'Alert',
      description: 'Useful context, clearly communicated.',
      code:
          "const FAlert(\n  title: Text('Heads up!'),\n  description: Text('You can customize every component.'),\n)",
      child: Column(
        children: [
          FAlert(
            title: Text('Heads up!'),
            description: Text(
              'You can customize every component in your project.',
            ),
          ),
          SizedBox(height: 16),
          FAlert(
            destructive: true,
            icon: Icons.error_outline,
            title: Text('Something went wrong'),
            description: Text('Your session expired. Please sign in again.'),
          ),
        ],
      ),
    ),
    DemoCard(
      title: 'Toast',
      description: 'A little confirmation goes a long way.',
      code:
          "showFToast(\n  context,\n  title: 'Changes saved',\n  description: 'Your project is up to date.',\n);",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FButton(
            onPressed: () => showFToast(
              context,
              title: 'Changes saved',
              description: 'Your project is up to date.',
            ),
            variant: FButtonVariant.outline,
            child: const Text('Show toast'),
          ),
          FButton(
            onPressed: () => showFToast(
              context,
              title: 'Could not save',
              description: 'Try again in a moment.',
              destructive: true,
            ),
            variant: FButtonVariant.outline,
            child: const Text('Show error'),
          ),
          FButton(
            onPressed: () => showFToast(
              context,
              title: 'Item archived',
              actionLabel: 'Undo',
              onAction: () => _toast('Restored'),
            ),
            variant: FButtonVariant.outline,
            child: const Text('With action'),
          ),
        ],
      ),
    ),
    DemoCard(
      title: 'Progress & skeleton',
      description: 'Make waiting feel considered.',
      code:
          "const FProgress(value: 0.65, label: 'Upload');\nconst FSkeleton(width: 180, height: 16);",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Uploading files…', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          FProgress(value: _volume / 100, label: 'Upload'),
          FSlider(
            value: _volume,
            onChanged: (value) => setState(() => _volume = value),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              FSkeleton(width: 40, height: 40, circular: true),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FSkeleton(width: 180, height: 14),
                    SizedBox(height: 8),
                    FSkeleton(width: 120, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    const DemoCard(
      title: 'Avatar, tooltip & keyboard',
      description: 'A familiar face and a helpful hint.',
      code:
          "const FAvatar(fallback: 'AM');\nconst FTooltip(message: 'Your team', child: Icon(Icons.group));\nconst FKbd('⌘ K');",
      child: Wrap(
        spacing: 24,
        runSpacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FAvatarGroup(
            children: [
              FAvatar(fallback: 'AM'),
              FAvatar(fallback: 'SC'),
              FAvatar(fallback: 'JW'),
              FAvatar(fallback: '+2'),
            ],
          ),
          FTooltip(
            message: 'Your team is looking good.',
            child: Icon(Icons.info_outline, size: 20),
          ),
          FKbd('⌘ K'),
          FSpinner(),
        ],
      ),
    ),
    DemoCard(
      title: 'Empty state',
      description: 'A fresh start, with a clear next step.',
      code:
          "FEmpty(\n  title: 'No projects yet',\n  description: 'Your next idea belongs here.',\n  action: FButton(onPressed: create, child: const Text('Create project')),\n)",
      child: FEmpty(
        title: 'No projects yet',
        description: 'Your next idea belongs here.',
        action: FButton(
          onPressed: () => _toast('Project created'),
          leading: const Icon(Icons.add),
          child: const Text('Create project'),
        ),
      ),
    ),
  ]);
  Widget _overlays() => _grid([
    DemoCard(
      title: 'Dialog',
      description: 'Give an important moment a little space.',
      code:
          "showFDialog<void>(\n  context: context,\n  builder: (context) => FDialog(\n    title: 'Edit profile',\n    child: const FInput(placeholder: 'Name'),\n  ),\n);",
      child: Center(
        child: FButton(
          onPressed: _invite,
          variant: FButtonVariant.outline,
          child: const Text('Invite teammate'),
        ),
      ),
    ),
    DemoCard(
      title: 'Alert dialog',
      description: 'A chance to pause before a big decision.',
      code:
          "final confirmed = await showFConfirm(\n  context: context,\n  title: 'Delete project?',\n  description: 'This action cannot be undone.',\n  destructive: true,\n);",
      child: Center(
        child: FButton(
          onPressed: () async {
            final confirmed = await showFConfirm(
              context: context,
              title: 'Delete this project?',
              description:
                  'This is a demonstration. No real project will be deleted.',
              confirmLabel: 'Delete project',
              destructive: true,
            );
            if (mounted) {
              _toast(confirmed ? 'Demo project deleted' : 'Project kept');
            }
          },
          variant: FButtonVariant.outline,
          child: const Text('Show confirmation'),
        ),
      ),
    ),
    DemoCard(
      title: 'Sheet & drawer',
      description: 'Keep the page in view while you explore.',
      code:
          "showFSheet<void>(\n  context: context,\n  side: FSheetSide.right,\n  builder: (_) => const Text('Your settings'),\n);",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final side in FSheetSide.values)
            FButton(
              onPressed: () => showFSheet<void>(
                context: context,
                side: side,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'A little more detail',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sheets keep supporting tasks close to the main experience.',
                    ),
                    const SizedBox(height: 24),
                    const FField(
                      label: 'Project name',
                      child: FInput(initialValue: 'My next idea'),
                    ),
                    const SizedBox(height: 24),
                    FButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Save changes'),
                    ),
                  ],
                ),
              ),
              variant: FButtonVariant.outline,
              child: Text(side.name),
            ),
        ],
      ),
    ),
    DemoCard(
      title: 'Popover & dropdown',
      description: 'The right tools, within reach.',
      code:
          "FPopover(\n  builder: (_, toggle) => FButton(\n    onPressed: toggle, child: const Text('Open'),\n  ),\n  child: const Text('Context, right here.'),\n)",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FPopover(
            builder: (context, toggle) => FButton(
              onPressed: toggle,
              variant: FButtonVariant.outline,
              child: const Text('Open popover'),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dimensions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text('Set the dimensions for this layer.'),
                SizedBox(height: 16),
                FField(
                  label: 'Width',
                  child: FInput(initialValue: '100%'),
                ),
              ],
            ),
          ),
          FDropdownMenu<String>(
            items: const [
              FMenuItem(
                value: 'Profile',
                label: 'Profile',
                icon: Icons.person_outline,
              ),
              FMenuItem(
                value: 'Settings',
                label: 'Settings',
                icon: Icons.settings_outlined,
              ),
              FMenuItem(
                value: 'Sign out',
                label: 'Sign out',
                icon: Icons.logout,
                destructive: true,
              ),
            ],
            onSelected: _toast,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: FTheme.of(context).colors.border),
                borderRadius: FTheme.of(context).borderRadius,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('My account', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    DemoCard(
      title: 'Command',
      description: 'Search, find, and take action.',
      code:
          "final action = await showFCommand<String>(\n  context: context,\n  items: const [FCommandItem(value: 'new', label: 'New project')],\n);",
      child: FCommand<String>(
        items: const [
          FCommandItem(
            value: 'Calendar',
            label: 'Calendar',
            icon: Icons.calendar_today_outlined,
            keywords: ['date', 'schedule'],
          ),
          FCommandItem(
            value: 'Search',
            label: 'Search projects',
            icon: Icons.search,
          ),
          FCommandItem(
            value: 'Settings',
            label: 'Settings',
            icon: Icons.settings_outlined,
          ),
        ],
        onSelected: _toast,
      ),
    ),
    DemoCard(
      title: 'Menubar & context menu',
      description: 'Familiar desktop interactions, with touch support.',
      code:
          "FContextMenu<String>(\n  items: const [FMenuItem(value: 'copy', label: 'Copy')],\n  onSelected: handleAction,\n  child: const Text('Right-click or long-press'),\n)",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FMenubar<String>(
            menus: const [
              FMenu(
                label: 'File',
                items: [
                  FMenuItem(value: 'New project', label: 'New project'),
                  FMenuItem(value: 'Export', label: 'Export'),
                ],
              ),
              FMenu(
                label: 'Edit',
                items: [
                  FMenuItem(value: 'Undo', label: 'Undo'),
                  FMenuItem(value: 'Redo', label: 'Redo', enabled: false),
                ],
              ),
            ],
            onSelected: _toast,
          ),
          const SizedBox(height: 20),
          FContextMenu<String>(
            items: const [
              FMenuItem(
                value: 'Copied',
                label: 'Copy',
                icon: Icons.copy_outlined,
              ),
              FMenuItem(
                value: 'Archived',
                label: 'Archive',
                icon: Icons.archive_outlined,
              ),
            ],
            onSelected: _toast,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: FTheme.of(context).colors.muted,
                borderRadius: FTheme.of(context).borderRadius,
              ),
              child: const Center(
                child: Text(
                  'Right-click or long-press here',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    const DemoCard(
      title: 'Hover card',
      description: 'A little more about the person behind the name.',
      code:
          "FHoverCard(\n  content: const Text('A little more context.'),\n  child: const Text('@flappa'),\n)",
      child: Center(
        child: FHoverCard(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FAvatar(fallback: 'UI'),
              SizedBox(height: 12),
              Text('Flappa UI', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('Composable Flutter components, beautifully built.'),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              '@flappa',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    ),
  ]);
  Widget _data() {
    final people = [..._people]
      ..sort(
        (a, b) =>
            (_sortColumn == 0
                ? a.name.compareTo(b.name)
                : a.role.compareTo(b.role)) *
            (_sortAsc ? 1 : -1),
      );
    void sort(int column, bool ascending) => setState(() {
      _sortColumn = column;
      _sortAsc = ascending;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FCard(
          title: const Text('Your team'),
          description: const Text(
            'A shared space for people doing great work.',
          ),
          footer: Text(
            '${_selected.length} of ${people.length} row(s) selected.',
            style: TextStyle(
              fontSize: 12,
              color: FTheme.of(context).colors.mutedForeground,
            ),
          ),
          child: FDataTable(
            sortColumnIndex: _sortColumn,
            sortAscending: _sortAsc,
            onSelectAll: (value) => setState(() {
              if (value == true) {
                _selected.addAll(_people.map((p) => p.email));
              } else {
                _selected.clear();
              }
            }),
            columns: [
              DataColumn(label: const Text('Name'), onSort: sort),
              DataColumn(label: const Text('Role'), onSort: sort),
              const DataColumn(label: Text('Status')),
            ],
            rows: people
                .map(
                  (person) => DataRow(
                    selected: _selected.contains(person.email),
                    onSelectChanged: (value) => setState(() {
                      if (value == true) {
                        _selected.add(person.email);
                      } else {
                        _selected.remove(person.email);
                      }
                    }),
                    cells: [
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              person.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: FTheme.of(
                                  context,
                                ).colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(person.role)),
                      DataCell(
                        FBadge(
                          variant: person.status == 'Active'
                              ? FBadgeVariant.secondary
                              : FBadgeVariant.outline,
                          child: Text(person.status),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        _grid([
          const DemoCard(
            title: 'Area chart',
            description: 'A lightweight view of your progress.',
            code:
                "const FChart(\n  values: [12, 18, 15, 28, 23, 40, 36, 52],\n  label: 'Weekly activity',\n)",
            child: FChart(
              values: [12, 18, 15, 28, 23, 40, 36, 52],
              label: 'Weekly activity',
            ),
          ),
          const DemoCard(
            title: 'Line chart',
            description: 'Just the signal, without the noise.',
            code:
                "const FChart(\n  values: [20, 30, 26, 42, 34, 50, 46, 68],\n  fill: false,\n)",
            child: FChart(
              values: [20, 30, 26, 42, 34, 50, 46, 68],
              fill: false,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _layout() => _grid([
    DemoCard(
      title: 'Resizable panels',
      description: 'Drag the divider, or focus it and use arrow keys.',
      code:
          "SizedBox(\n  height: 200,\n  child: FResizable(\n    first: const Center(child: Text('One')),\n    second: const Center(child: Text('Two')),\n  ),\n)",
      child: SizedBox(
        height: 200,
        child: FResizable(
          first: Container(
            color: FTheme.of(context).colors.muted.withValues(alpha: .4),
            child: const Center(
              child: Text('One', style: TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
          second: const Center(
            child: Text('Two', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    ),
    DemoCard(
      title: 'Carousel',
      description: 'A sequence worth swiping through.',
      code:
          "FCarousel(\n  children: [\n    Container(child: const Center(child: Text('One'))),\n    Container(child: const Center(child: Text('Two'))),\n  ],\n)",
      child: FCarousel(
        height: 200,
        children: [
          for (var i = 1; i <= 4; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: FTheme.of(context).colors.muted,
                borderRadius: FTheme.of(context).borderRadius,
              ),
              child: Center(
                child: Text(
                  '0$i',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    DemoCard(
      title: 'Calendar',
      description: 'A little room to plan ahead.',
      code:
          "FCalendar(\n  value: selectedDate,\n  firstDate: DateTime(2020),\n  lastDate: DateTime(2030),\n  onChanged: (value) => setState(() => selectedDate = value),\n)",
      child: FCalendar(
        value: _date ?? DateTime(2026, 10, 6),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        onChanged: (value) => setState(() => _date = value),
      ),
    ),
    DemoCard(
      title: 'Scroll area',
      description: 'A tidy home for longer lists.',
      code:
          "SizedBox(\n  height: 200,\n  child: FScrollArea(child: Column(children: items)),\n)",
      child: SizedBox(
        height: 250,
        child: FScrollArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 1; i <= 16; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Component $i',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const FSeparator(),
              ],
            ],
          ),
        ),
      ),
    ),
  ]);
  Widget _gettingStarted() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const FAlert(
        icon: Icons.code,
        title: Text('Two ways to make it yours'),
        description: Text(
          'Use the package directly, or copy the source into your app. Both share the same API.',
        ),
      ),
      const SizedBox(height: 24),
      const FCard(
        title: Text('01 · Install Flappa UI'),
        description: Text(
          'Run this from your Flutter app. Requires Flutter 3.38+ and Dart 3.10+.',
        ),
        child: CodeBlock(
          'flutter pub add flappa_ui',
          language: FCodeLanguage.bash,
          filename: 'Terminal',
        ),
      ),
      const Align(alignment: Alignment.centerLeft, child: PackageLink()),
      const SizedBox(height: 20),
      const FCard(
        title: Text('02 · Set the foundation'),
        description: Text(
          'Wrap your app with FlappaApp to enable the theme and dark mode.',
        ),
        child: CodeBlock(
          "import 'package:flutter/material.dart';\nimport 'package:flappa_ui/flappa_ui.dart';\n\nvoid main() => runApp(FlappaApp(\n  home: Scaffold(\n    body: Center(\n      child: FButton(\n        onPressed: () {},\n        child: const Text('Hello, Flappa'),\n      ),\n    ),\n  ),\n));",
          filename: 'lib/main.dart',
        ),
      ),
      const SizedBox(height: 20),
      const FCard(
        title: Text('03 · Own the source (optional)'),
        description: Text(
          'Run from your Flutter app root. Copy only the groups you need, including their dependencies.',
        ),
        child: CodeBlock(
          'dart run flappa_ui init\ndart run flappa_ui add button forms\n\n# Or get the whole collection\ndart run flappa_ui add all\n\n# Then import your local source\n# import \'ui/flappa_ui.dart\';',
          language: FCodeLanguage.bash,
        ),
      ),
      const SizedBox(height: 20),
      FButton(
        onPressed: () => widget.onNavigate(1),
        trailing: const Icon(Icons.arrow_forward),
        child: const Text('Explore the components'),
      ),
    ],
  );
  Future<void> _invite() async {
    final form = GlobalKey<FormState>();
    final invitedEmail = TextEditingController();
    final value = await showFDialog<String>(
      context: context,
      builder: (context) => FDialog(
        title: 'Better, together.',
        description: 'Invite a teammate to your workspace.',
        actions: [
          FButton(
            onPressed: () => Navigator.pop(context),
            variant: FButtonVariant.outline,
            child: const Text('Cancel'),
          ),
          FButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, invitedEmail.text);
              }
            },
            child: const Text('Send invitation'),
          ),
        ],
        child: Form(
          key: form,
          child: FField(
            label: 'Email address',
            child: FInput(
              controller: invitedEmail,
              autofocus: true,
              placeholder: 'teammate@company.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  value == null ||
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)
                  ? 'Enter a valid email address'
                  : null,
            ),
          ),
        ),
      ),
    );
    // The route transition may still be using the field's controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    invitedEmail.dispose();
    if (value != null && mounted) {
      showFToast(
        context,
        title: 'Invitation preview created',
        description: 'For $value. This showcase does not send email.',
      );
    }
  }
}
