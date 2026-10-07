import 'dart:async';
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../platform/browser.dart' as browser;
import '../site/site_widgets.dart';
import 'document.dart';
import 'canvas_editor.dart';
import 'render.dart';

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({
    super.key,
    required this.onHome,
    required this.onComponents,
  });
  final VoidCallback onHome, onComponents;
  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  late final PlaygroundController _controller;
  Timer? _saveTimer;
  String _saved = '', _status = 'Local draft';
  bool _interact = false, _layers = false;
  int _panel = 1;
  ScreenDocument get _document => _controller.document;

  @override
  void initState() {
    super.initState();
    ScreenDocument? initial;
    final stored = browser.readDraft();
    if (stored != null) {
      try {
        initial = ScreenDocument.decode(stored);
        _status = 'Draft restored';
      } catch (_) {
        _status = 'Could not restore draft';
      }
    }
    _controller = PlaygroundController(initial)..addListener(_changed);
    _saved = _document.encode();
  }

  void _changed() {
    final encoded = _document.encode();
    if (encoded != _saved) {
      _saved = encoded;
      _status = 'Saving…';
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 400), () {
        final saved = browser.saveDraft(encoded);
        if (mounted) {
          setState(
            () => _status = saved
                ? 'Saved in this browser'
                : 'In memory · export to keep',
          );
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    browser.saveDraft(_document.encode());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final code = exportDart(_document);
    await showFDialog<void>(
      context: context,
      builder: (context) => FDialog(
        maxWidth: 820,
        title: 'Your screen. Your code.',
        description:
            'Add flappa_ui to your Flutter project, then use this as lib/main.dart. Buttons show local feedback; connect your own app logic.',
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _document.encode()));
              if (context.mounted) {
                showFToast(context, title: 'Project JSON copied');
              }
            },
            child: const Text('Copy project JSON'),
          ),
          FButton(
            onPressed: () async {
              if (browser.downloadText('main.dart', code)) {
                if (context.mounted) {
                  showFToast(context, title: 'main.dart downloaded');
                }
              } else {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  showFToast(context, title: 'Dart code copied');
                }
              }
            },
            leading: const Icon(Icons.download_outlined),
            child: const Text('Download Dart'),
          ),
        ],
        child: FCodeBlock(
          code: code,
          filename: 'main.dart',
          fontFamily: 'JetBrainsMono',
          maxHeight: 300,
        ),
      ),
    );
  }

  Future<void> _import() async {
    final result = await showFDialog<ScreenDocument>(
      context: context,
      builder: (context) => const _ImportProjectDialog(),
    );
    if (result != null && mounted) _controller.commit(result);
  }

  Widget _palette() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: FButton(
                size: FButtonSize.small,
                variant: !_layers
                    ? FButtonVariant.secondary
                    : FButtonVariant.ghost,
                onPressed: () => setState(() => _layers = false),
                child: const Text('Blocks'),
              ),
            ),
            Expanded(
              child: FButton(
                size: FButtonSize.small,
                variant: _layers
                    ? FButtonVariant.secondary
                    : FButtonVariant.ghost,
                onPressed: () => setState(() => _layers = true),
                child: const Text('Layers'),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: _layers
            ? ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _document.blocks.length,
                itemBuilder: (context, i) {
                  final block = _document.orderedBlocks[i];
                  return ListTile(
                    key: ValueKey(block.id),
                    contentPadding: EdgeInsets.only(
                      left: 8.0 + _document.depthOf(block.id) * 12,
                      right: 8,
                    ),
                    dense: true,
                    selected: _controller.selectedId == block.id,
                    leading: Icon(blockIcon(block.kind), size: 18),
                    title: Text(
                      block.title.isEmpty ? block.kind.label : block.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      block.kind.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () => _controller.select(block.id),
                  );
                },
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  Text(
                    'THE BUILDING BLOCKS',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.3,
                      color: FTheme.of(context).colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click to add. Drag onto the canvas.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  for (final kind in BlockKind.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Draggable<BlockDrag>(
                        data: BlockDrag.create(kind),
                        maxSimultaneousDrags:
                            _controller.canInsert(_controller.insertionParent)
                            ? 1
                            : 0,
                        feedback: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(kind.label),
                          ),
                        ),
                        child: FButton(
                          key: ValueKey('add-${kind.name}'),
                          variant: FButtonVariant.outline,
                          leading: Icon(blockIcon(kind)),
                          trailing: const Icon(Icons.add, size: 14),
                          onPressed:
                              !_controller.canInsert(
                                _controller.insertionParent,
                              )
                              ? null
                              : () {
                                  _controller.add(kind);
                                  setState(() {
                                    _interact = false;
                                    _panel = 1;
                                  });
                                },
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(kind.label),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${_document.blocks.length} / 100 blocks',
          style: TextStyle(
            fontSize: 11,
            color: FTheme.of(context).colors.mutedForeground,
          ),
        ),
      ),
    ],
  );

  Widget _inspector() {
    final block = _controller.selected;
    final siblings = _document.childrenOf(block?.parentId);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                block == null ? 'Screen settings' : block.kind.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (block != null)
              FButton(
                onPressed: () => _controller.select(null),
                variant: FButtonVariant.ghost,
                size: FButtonSize.icon,
                tooltip: 'Screen settings',
                child: const Icon(Icons.tune),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (block != null) ...[
          if (![
            BlockKind.divider,
            BlockKind.spacer,
            BlockKind.progress,
          ].contains(block.kind))
            PropertyField(
              key: ValueKey('${block.id}-title'),
              label: block.kind.isLayout
                  ? 'Layout name'
                  : block.kind == BlockKind.text
                  ? 'Content'
                  : 'Label',
              value: block.title,
              maxLength: 2000,
              onChanged: (value) =>
                  _controller.update(block.copyWith(title: value)),
            ),
          if ([
            BlockKind.input,
            BlockKind.card,
            BlockKind.alert,
            BlockKind.chart,
          ].contains(block.kind)) ...[
            const SizedBox(height: 16),
            PropertyField(
              key: ValueKey('${block.id}-detail'),
              label: block.kind == BlockKind.chart
                  ? 'Values, separated by commas'
                  : block.kind == BlockKind.input
                  ? 'Placeholder'
                  : 'Description',
              value: block.detail,
              maxLength: 10000,
              onChanged: (value) =>
                  _controller.update(block.copyWith(detail: value)),
            ),
          ],
          if (block.kind == BlockKind.button ||
              block.kind == BlockKind.badge) ...[
            const SizedBox(height: 16),
            FField(
              label: 'Variant',
              child: FSelect<int>(
                value: block.variant % (block.kind == BlockKind.button ? 6 : 4),
                items: {
                  for (
                    var i = 0;
                    i < (block.kind == BlockKind.button ? 6 : 4);
                    i++
                  )
                    i: block.kind == BlockKind.button
                        ? FButtonVariant.values[i].name
                        : FBadgeVariant.values[i].name,
                },
                onChanged: (value) {
                  if (value != null) {
                    _controller.update(block.copyWith(variant: value));
                  }
                },
              ),
            ),
          ],
          if ([BlockKind.progress, BlockKind.spacer].contains(block.kind)) ...[
            const SizedBox(height: 16),
            Text(
              block.kind == BlockKind.spacer
                  ? 'Height · ${(block.value * 64).round()} px'
                  : 'Progress · ${(block.value * 100).round()}%',
            ),
            FSlider(
              value: block.value,
              max: 1,
              onChanged: (value) =>
                  _controller.update(block.copyWith(value: value)),
            ),
          ],
          if ([BlockKind.toggle, BlockKind.checkbox].contains(block.kind)) ...[
            const SizedBox(height: 16),
            FSwitch(
              value: block.value >= .5,
              label: 'Initially selected',
              onChanged: (value) =>
                  _controller.update(block.copyWith(value: value ? 1 : 0)),
            ),
          ],
          if (block.kind.isLayout) ...[
            for (final (label, value, max) in [
              ('Layout padding', block.padding, 64.0),
              ('Layout spacing', block.gap, 48.0),
            ]) ...[
              Text('$label · ${value.round()} px'),
              FSlider(
                value: value,
                max: max,
                divisions: max.toInt() ~/ 2,
                onChanged: (value) => _controller.update(
                  label == 'Layout padding'
                      ? block.copyWith(padding: value)
                      : block.copyWith(gap: value),
                ),
              ),
            ],
            if (block.kind == BlockKind.row)
              FSwitch(
                value: block.responsive,
                label: 'Stack on narrow screens',
                onChanged: (value) =>
                    _controller.update(block.copyWith(responsive: value)),
              ),
            const SizedBox(height: 12),
            const Text(
              'Select this layout, then add blocks to place them inside.',
              style: TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          FField(
            label: 'Move into',
            child: FSelect<String>(
              value: block.parentId ?? '',
              items: {
                '': 'Screen root',
                for (final parent in _document.orderedBlocks)
                  if (parent.kind.isLayout &&
                      _controller.canMove(block.id, parent.id))
                    parent.id:
                        '${'  ' * _document.depthOf(parent.id)}${_document.labelFor(parent)}',
              },
              onChanged: (value) {
                if (value == null || value == (block.parentId ?? '')) return;
                final parentId = value.isEmpty ? null : value;
                _controller.moveBlock(
                  block.id,
                  parentId: parentId,
                  index: _document.childrenOf(parentId).length,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FButton(
                tooltip: 'Move up',
                variant: FButtonVariant.outline,
                size: FButtonSize.icon,
                onPressed: siblings.first.id == block.id
                    ? null
                    : () => _controller.moveSibling(block.id, -1),
                child: const Icon(Icons.arrow_upward),
              ),
              FButton(
                tooltip: 'Move down',
                variant: FButtonVariant.outline,
                size: FButtonSize.icon,
                onPressed: siblings.last.id == block.id
                    ? null
                    : () => _controller.moveSibling(block.id, 1),
                child: const Icon(Icons.arrow_downward),
              ),
              FButton(
                tooltip: 'Duplicate block',
                variant: FButtonVariant.outline,
                size: FButtonSize.icon,
                onPressed: !_controller.canDuplicate(block.id)
                    ? null
                    : () => _controller.duplicate(block.id),
                child: const Icon(Icons.copy_outlined),
              ),
              FButton(
                tooltip: 'Delete block',
                variant: FButtonVariant.outline,
                size: FButtonSize.icon,
                onPressed: () => _controller.remove(block.id),
                child: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const FSeparator(),
          const SizedBox(height: 24),
        ],
        PropertyField(
          key: const ValueKey('screen-name'),
          label: 'Screen name',
          value: _document.name,
          maxLength: 120,
          onChanged: (value) =>
              _controller.commit(_document.copyWith(name: value)),
        ),
        const SizedBox(height: 20),
        FField(
          label: 'Accent',
          child: FSelect<int>(
            value: _document.accent,
            items: {
              for (var i = 0; i < accentNames.length; i++) i: accentNames[i],
            },
            onChanged: (value) =>
                _controller.commit(_document.copyWith(accent: value)),
          ),
        ),
        const SizedBox(height: 16),
        FSwitch(
          value: _document.dark,
          label: 'Dark canvas',
          onChanged: (value) =>
              _controller.commit(_document.copyWith(dark: value)),
        ),
        const SizedBox(height: 20),
        for (final (label, value, max) in [
          ('Padding', _document.padding, 64.0),
          ('Spacing', _document.gap, 48.0),
          ('Radius', _document.radius, 24.0),
        ]) ...[
          Text(
            '$label · ${value.round()} px',
            style: const TextStyle(fontSize: 12),
          ),
          FSlider(
            value: value,
            max: max,
            divisions: max.toInt() ~/ 2,
            onChanged: (value) => _controller.commit(switch (label) {
              'Padding' => _document.copyWith(padding: value),
              'Spacing' => _document.copyWith(gap: value),
              _ => _document.copyWith(radius: value),
            }),
          ),
        ],
      ],
    );
  }

  Widget _canvas() => Column(
    children: [
      Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: FTheme.of(context).colors.border),
          ),
        ),
        child: Row(
          children: [
            const Text('Screen canvas', style: TextStyle(fontSize: 12)),
            const Spacer(),
            FToggle(
              value: _interact,
              onChanged: (value) => setState(() => _interact = value),
              child: Text(_interact ? 'Editing paused · Interact' : 'Interact'),
            ),
          ],
        ),
      ),
      Expanded(
        child: DragTarget<BlockDrag>(
          onWillAcceptWithDetails: (details) =>
              !_interact &&
              details.data.kind != null &&
              _controller.canInsert(null),
          onAcceptWithDetails: (details) =>
              _controller.add(details.data.kind!, parentId: null),
          builder: (context, candidates, rejected) => CustomPaint(
            painter: DotGridPainter(color: FTheme.of(context).colors.border),
            child: Container(
              color: candidates.isEmpty
                  ? Colors.transparent
                  : const Color(0x22087F5B),
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Theme(
                    data: documentTheme(_document).toThemeData(),
                    child: Builder(
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: FTheme.of(context).colors.border,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: ScaffoldMessenger(
                            child: Scaffold(
                              appBar: AppBar(
                                title: Text(
                                  _document.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                automaticallyImplyLeading: false,
                              ),
                              body: SingleChildScrollView(
                                padding: EdgeInsets.all(_document.padding),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 640,
                                    ),
                                    child: ScreenCanvasContent(
                                      controller: _controller,
                                      interact: _interact,
                                      onSelect: (id) {
                                        _controller.select(id);
                                        if (MediaQuery.sizeOf(context).width <
                                            1100) {
                                          setState(() => _panel = 2);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          _interact
              ? 'Try the screen. Form entries are temporary.'
              : 'Select a block to edit · Changes save locally',
          style: TextStyle(
            fontSize: 11,
            color: FTheme.of(context).colors.mutedForeground,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
          _controller.undo,
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
          _controller.undo,
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
          _controller.redo,
      const SingleActivator(
        LogicalKeyboardKey.keyZ,
        control: true,
        shift: true,
      ): _controller.redo,
    },
    child: Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final c = FTheme.of(context).colors;
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.border)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SiteBrand(onPressed: widget.onHome),
                          const SizedBox(width: 16),
                          Text(
                            '/ playground',
                            style: TextStyle(
                              fontSize: 13,
                              color: c.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (constraints.maxWidth > 760)
                            Text(
                              _status,
                              style: TextStyle(
                                fontSize: 11,
                                color: c.mutedForeground,
                              ),
                            ),
                          FButton(
                            tooltip: 'Undo',
                            variant: FButtonVariant.ghost,
                            size: FButtonSize.icon,
                            onPressed: _controller.canUndo
                                ? _controller.undo
                                : null,
                            child: const Icon(Icons.undo),
                          ),
                          FButton(
                            tooltip: 'Redo',
                            variant: FButtonVariant.ghost,
                            size: FButtonSize.icon,
                            onPressed: _controller.canRedo
                                ? _controller.redo
                                : null,
                            child: const Icon(Icons.redo),
                          ),
                          FButton(
                            variant: FButtonVariant.outline,
                            onPressed: _import,
                            child: const Text('Import'),
                          ),
                          FButton(
                            onPressed: _export,
                            leading: const Icon(Icons.code),
                            child: const Text('Export code'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.border)),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'START WITH',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: c.mutedForeground,
                        ),
                      ),
                      for (final template in [
                        'Welcome',
                        'Settings',
                        'Dashboard',
                        'Layouts',
                        'Blank',
                      ])
                        FButton(
                          size: FButtonSize.small,
                          variant: FButtonVariant.ghost,
                          onPressed: () {
                            _controller.commit(templateDocument(template));
                            setState(() => _panel = 1);
                          },
                          child: Text(template),
                        ),
                      FButton(
                        size: FButtonSize.small,
                        variant: FButtonVariant.link,
                        onPressed: widget.onComponents,
                        child: const Text('All components ↗'),
                      ),
                    ],
                  ),
                ),
                if (!wide)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        for (final (i, label) in [
                          'Add blocks',
                          'Canvas',
                          'Properties',
                        ].indexed)
                          Expanded(
                            child: FButton(
                              size: FButtonSize.small,
                              variant: _panel == i
                                  ? FButtonVariant.secondary
                                  : FButtonVariant.ghost,
                              onPressed: () => setState(() => _panel = i),
                              child: Text(label),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: 232, child: _palette()),
                            VerticalDivider(width: 1, color: c.border),
                            Expanded(child: _canvas()),
                            VerticalDivider(width: 1, color: c.border),
                            SizedBox(width: 280, child: _inspector()),
                          ],
                        )
                      : IndexedStack(
                          index: _panel,
                          children: [_palette(), _canvas(), _inspector()],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

IconData blockIcon(BlockKind kind) => switch (kind) {
  BlockKind.heading => Icons.title,
  BlockKind.text => Icons.notes,
  BlockKind.input => Icons.input,
  BlockKind.button => Icons.smart_button_outlined,
  BlockKind.card => Icons.crop_landscape,
  BlockKind.badge => Icons.sell_outlined,
  BlockKind.alert => Icons.info_outline,
  BlockKind.toggle => Icons.toggle_on_outlined,
  BlockKind.checkbox => Icons.check_box_outlined,
  BlockKind.progress => Icons.linear_scale,
  BlockKind.divider => Icons.horizontal_rule,
  BlockKind.spacer => Icons.height,
  BlockKind.avatar => Icons.account_circle_outlined,
  BlockKind.chart => Icons.bar_chart,
  BlockKind.row => Icons.view_column_outlined,
  BlockKind.column => Icons.view_agenda_outlined,
  BlockKind.container => Icons.crop_square,
};

class PropertyField extends StatefulWidget {
  const PropertyField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.maxLength,
  });
  final String label, value;
  final int maxLength;
  final ValueChanged<String> onChanged;
  @override
  State<PropertyField> createState() => _PropertyFieldState();
}

class _PropertyFieldState extends State<PropertyField> {
  late final _text = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(PropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_text.text != widget.value) {
      _text.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FField(
    label: widget.label,
    child: FInput(
      controller: _text,
      semanticLabel: widget.label,
      inputFormatters: [LengthLimitingTextInputFormatter(widget.maxLength)],
      onChanged: widget.onChanged,
    ),
  );
}

class _ImportProjectDialog extends StatefulWidget {
  const _ImportProjectDialog();
  @override
  State<_ImportProjectDialog> createState() => _ImportProjectDialogState();
}

class _ImportProjectDialogState extends State<_ImportProjectDialog> {
  final _text = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    ScreenDocument document;
    try {
      document = ScreenDocument.decode(_text.text);
    } catch (_) {
      setState(
        () => _error =
            'Invalid project. Use a Flappa export with valid layouts (version 1 or 2).',
      );
      return;
    }
    Navigator.pop(context, document);
  }

  @override
  Widget build(BuildContext context) => FDialog(
    title: 'Open a project',
    description:
        'Paste a project JSON exported by this playground. You can undo the import.',
    actions: [FButton(onPressed: _submit, child: const Text('Import project'))],
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FInput(
          controller: _text,
          semanticLabel: 'Project JSON',
          placeholder: '{ "version": 2, … }',
          maxLines: 8,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: FTheme.of(context).colors.destructive),
              ),
            ),
          ),
      ],
    ),
  );
}
