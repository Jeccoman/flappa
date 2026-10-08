import 'dart:convert';
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'document.dart';

const accentColors = [
  null,
  Color(0xFF087F5B),
  Color(0xFF2563EB),
  Color(0xFF7C3AED),
  Color(0xFFBE123C),
];
const accentNames = ['Zinc', 'Emerald', 'Blue', 'Violet', 'Rose'];

FThemeData documentTheme(ScreenDocument document) {
  final brightness = document.dark ? Brightness.dark : Brightness.light;
  final colors = FColors.zinc(brightness: brightness);
  final accent = accentColors[document.accent];
  return FThemeData(
    brightness: brightness,
    radius: document.radius,
    colors: accent == null
        ? colors
        : colors.copyWith(
            primary: accent,
            primaryForeground: Colors.white,
            ring: accent,
          ),
  );
}

List<double> chartValues(String text) => text.split(',').take(12).map((entry) {
  final value = double.tryParse(entry.trim());
  return value != null && value.isFinite
      ? value.clamp(-1000000, 1000000).toDouble()
      : 0.0;
}).toList();

class ScreenBlockView extends StatefulWidget {
  const ScreenBlockView({
    super.key,
    required this.block,
    this.children = const [],
    this.onPressed,
  });
  final ScreenBlock block;
  final VoidCallback? onPressed;
  final List<Widget> children;
  @override
  State<ScreenBlockView> createState() => _ScreenBlockViewState();
}

class _ScreenBlockViewState extends State<ScreenBlockView> {
  late bool _checked = widget.block.value >= .5;
  @override
  void didUpdateWidget(ScreenBlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.value != widget.block.value) {
      _checked = widget.block.value >= .5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    return switch (block.kind) {
      BlockKind.row || BlockKind.column || BlockKind.container => ScreenLayout(
        block: block,
        children: widget.children,
      ),
      BlockKind.heading => FTypography(
        block.title,
        variant: FTypographyVariant.h2,
      ),
      BlockKind.text => FTypography(
        block.title,
        variant: FTypographyVariant.muted,
      ),
      BlockKind.input => FField(
        label: block.title,
        child: FInput(placeholder: block.detail, semanticLabel: block.title),
      ),
      BlockKind.button => FButton(
        onPressed:
            widget.onPressed ?? () => showFToast(context, title: block.title),
        variant: FButtonVariant.values[block.variant],
        child: Text(block.title),
      ),
      BlockKind.card => FCard(
        title: Text(block.title),
        description: Text(block.detail),
      ),
      BlockKind.badge => Align(
        alignment: Alignment.centerLeft,
        child: FBadge(
          variant:
              FBadgeVariant.values[block.variant % FBadgeVariant.values.length],
          child: Text(block.title),
        ),
      ),
      BlockKind.alert => FAlert(
        title: Text(block.title),
        description: Text(block.detail),
      ),
      BlockKind.toggle => FSwitch(
        value: _checked,
        onChanged: (value) => setState(() => _checked = value),
        label: block.title,
      ),
      BlockKind.checkbox => FCheckbox(
        value: _checked,
        onChanged: (value) => setState(() => _checked = value ?? false),
        label: block.title,
      ),
      BlockKind.progress => FProgress(value: block.value),
      BlockKind.divider => const FSeparator(),
      BlockKind.spacer => SizedBox(height: block.value * 64),
      BlockKind.avatar => Align(
        alignment: Alignment.centerLeft,
        child: FAvatar(fallback: block.title),
      ),
      BlockKind.chart => FCard(
        title: Text(block.title),
        child: FBarChart(
          height: 180,
          data: [
            for (final (i, value) in chartValues(block.detail).indexed)
              FChartDatum(label: '${i + 1}', value: value),
          ],
        ),
      ),
    };
  }
}

class ScreenLayout extends StatelessWidget {
  const ScreenLayout({super.key, required this.block, required this.children});
  final ScreenBlock block;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.all(block.padding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal =
              block.kind == BlockKind.row &&
              (!block.responsive ||
                  (constraints.maxWidth >= 480 &&
                      constraints.maxWidth >=
                          children.length * 180 +
                              (children.length - 1) * block.gap));
          if (children.isEmpty) return const SizedBox(height: 24);
          final spaced = <Widget>[
            for (final (index, child) in children.indexed) ...[
              if (index > 0)
                SizedBox(
                  width: horizontal ? block.gap : null,
                  height: horizontal ? null : block.gap,
                ),
              if (horizontal) Expanded(child: child) else child,
            ],
          ];
          return horizontal
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: spaced,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: spaced,
                );
        },
      ),
    );
    if (block.kind != BlockKind.container) return content;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FTheme.of(context).colors.muted,
        border: Border.all(color: FTheme.of(context).colors.border),
        borderRadius: FTheme.of(context).borderRadius,
      ),
      child: content,
    );
  }
}

String dartString(String value) => jsonEncode(value).replaceAll(r'$', r'\$');

String exportDart(
  ScreenDocument document, {
  String screenClass = 'GeneratedScreen',
  bool includeEntrypoint = true,
  Map<String, String> buttonActions = const {},
  bool allowBack = false,
}) {
  late String Function(ScreenBlock) blockCode;
  String childrenCode(List<ScreenBlock> blocks, double gap, bool horizontal) =>
      [
        for (final (i, child) in blocks.indexed) ...[
          if (i > 0) 'const SizedBox(${horizontal ? 'width' : 'height'}: $gap)',
          horizontal
              ? 'Expanded(child: ${blockCode(child)})'
              : blockCode(child),
        ],
      ].join(',\n');
  blockCode = (ScreenBlock block) {
    final index = document.blocks.indexOf(block);
    if (block.kind.isLayout) {
      final children = document.childrenOf(block.id);
      final String layout;
      if (children.isEmpty) {
        layout = 'const SizedBox(height: 24)';
      } else if (block.kind == BlockKind.row && block.responsive) {
        final widgets = children.map(blockCode).join(',\n');
        layout =
            """LayoutBuilder(builder: (context, constraints) {
          final children = <Widget>[$widgets];
          final horizontal = constraints.maxWidth >= 480 && constraints.maxWidth >= ${children.length * 180 + (children.length - 1) * block.gap};
          final spaced = <Widget>[
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: horizontal ? ${block.gap} : null, height: horizontal ? null : ${block.gap}),
              if (horizontal) Expanded(child: children[i]) else children[i],
            ],
          ];
          return horizontal
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: spaced)
              : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced);
        })""";
      } else if (block.kind == BlockKind.row) {
        layout =
            'Row(crossAxisAlignment: CrossAxisAlignment.start, children: [${childrenCode(children, block.gap, true)}])';
      } else {
        layout =
            'Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [${childrenCode(children, block.gap, false)}])';
      }
      final padded =
          'Padding(padding: const EdgeInsets.all(${block.padding}), child: $layout)';
      return block.kind == BlockKind.container
          ? 'DecoratedBox(decoration: BoxDecoration(color: FTheme.of(context).colors.muted, border: Border.all(color: FTheme.of(context).colors.border), borderRadius: FTheme.of(context).borderRadius), child: $padded)'
          : padded;
    }
    final title = dartString(block.title), detail = dartString(block.detail);
    return switch (block.kind) {
      BlockKind.row ||
      BlockKind.column ||
      BlockKind.container => throw StateError('Layout handled above'),
      BlockKind.heading =>
        'FTypography($title, variant: FTypographyVariant.h2)',
      BlockKind.text =>
        'FTypography($title, variant: FTypographyVariant.muted)',
      BlockKind.input =>
        'FField(label: $title, child: FInput(placeholder: $detail, semanticLabel: $title))',
      BlockKind.button =>
        'FButton(onPressed: ${buttonActions[block.id] ?? '() => showFToast(context, title: $title)'}, variant: FButtonVariant.${FButtonVariant.values[block.variant].name}, child: Text($title))',
      BlockKind.card =>
        'FCard(title: Text($title), description: Text($detail))',
      BlockKind.badge =>
        'Align(alignment: Alignment.centerLeft, child: FBadge(variant: FBadgeVariant.${FBadgeVariant.values[block.variant % FBadgeVariant.values.length].name}, child: Text($title)))',
      BlockKind.alert =>
        'FAlert(title: Text($title), description: Text($detail))',
      BlockKind.toggle =>
        'FSwitch(value: _value$index, onChanged: (value) => setState(() => _value$index = value), label: $title)',
      BlockKind.checkbox =>
        'FCheckbox(value: _value$index, onChanged: (value) => setState(() => _value$index = value ?? false), label: $title)',
      BlockKind.progress => 'FProgress(value: ${block.value})',
      BlockKind.divider => 'const FSeparator()',
      BlockKind.spacer => 'const SizedBox(height: ${block.value * 64})',
      BlockKind.avatar =>
        'Align(alignment: Alignment.centerLeft, child: FAvatar(fallback: $title))',
      BlockKind.chart =>
        'FCard(title: Text($title), child: FBarChart(height: 180, data: const [${chartValues(block.detail).indexed.map((entry) => 'FChartDatum(label: "${entry.$1 + 1}", value: ${entry.$2})').join(', ')}]))',
    };
  };

  final accent = accentColors[document.accent];
  final brightness = document.dark ? 'dark' : 'light';
  final theme = accent == null
      ? 'colors'
      : 'colors.copyWith(primary: const Color(0x${accent.toARGB32().toRadixString(16)}), primaryForeground: Colors.white, ring: const Color(0x${accent.toARGB32().toRadixString(16)}))';
  final fields = [
    for (final (i, block) in document.blocks.indexed)
      if (block.kind == BlockKind.toggle || block.kind == BlockKind.checkbox)
        '  bool _value$i = ${block.value >= .5};',
  ].join('\n');
  final children = [
    for (final (i, block) in document.childrenOf(null).indexed) ...[
      if (i > 0) '              const SizedBox(height: ${document.gap}),',
      '              ${blockCode(block)},',
    ],
  ].join('\n');
  final entrypoint =
      '''import 'package:flutter/material.dart';
import 'package:flappa_ui/flappa_ui.dart';

void main() {
  final colors = FColors.zinc(brightness: Brightness.$brightness);
  runApp(FlappaApp(
    title: ${dartString(document.name)},
    themeMode: ThemeMode.light,
    theme: FThemeData(brightness: Brightness.$brightness, radius: ${document.radius}, colors: $theme),
    home: const $screenClass(),
  ));
}

''';
  return '''${includeEntrypoint ? entrypoint : ''}
class $screenClass extends StatefulWidget {
  const $screenClass({super.key});
  @override
  State<$screenClass> createState() => _${screenClass}State();
}

class _${screenClass}State extends State<$screenClass> {
$fields
  @override
  Widget build(BuildContext context) {
    final colors = FColors.zinc(brightness: Brightness.$brightness);
    final theme = FThemeData(brightness: Brightness.$brightness, radius: ${document.radius}, colors: $theme);
    return Theme(data: theme.toThemeData(), child: Builder(builder: (context) => Scaffold(
    appBar: AppBar(title: Text(${dartString(document.name)}, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), automaticallyImplyLeading: $allowBack),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(${document.padding}),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
$children
              ],
            ),
          ),
        ),
      ),
    ),
  )));
  }
}
''';
}
