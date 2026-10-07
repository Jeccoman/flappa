import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../platform/browser.dart' as browser;
import '../site/site_widgets.dart';
import 'document.dart';
import 'devices.dart';
import 'canvas_editor.dart';
import 'studio_drag.dart';
import 'playground_page.dart';
import 'studio_document.dart';
import 'studio_render.dart';

class StudioPage extends StatefulWidget {
  const StudioPage({
    super.key,
    required this.onHome,
    required this.onComponents,
  });
  final VoidCallback onHome, onComponents;
  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  static const storageKey = 'flappa.canvas.v1';
  late final StudioController _controller;
  final _transform = TransformationController();
  final _images = <String, GlobalKey>{};
  Timer? _saveTimer;
  String _encoded = '', _status = 'Local draft';
  String? _editing;
  int _panel = 1;
  bool _fitted = false, _dirty = false;
  bool _parts = true, _arrange = true, _capturing = false;
  Size _viewport = Size.zero;
  Offset? _dragPosition, _dragPointer;
  String? _dragId;
  StudioProject get _project => _controller.project;

  @override
  void initState() {
    super.initState();
    StudioProject? initial;
    final stored = browser.readStorage(storageKey);
    try {
      if (stored != null) {
        initial = StudioProject.decode(stored);
        _status = 'Draft restored';
      } else {
        final old = browser.readDraft();
        initial = starterProject(
          old == null ? null : ScreenDocument.decode(old),
        );
      }
    } on FormatException {
      _status = 'Draft unreadable · import a backup to restore';
    }
    _controller = StudioController(initial ?? starterProject())
      ..addListener(_changed);
    _encoded = _project.encode();
  }

  void _changed() {
    final encoded = _project.encode();
    if (_encoded != encoded) {
      _encoded = encoded;
      _dirty = true;
      _status = 'Saving…';
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 400), _save);
    }
    setState(() {});
  }

  void _save() {
    final saved = browser.saveStorage(storageKey, _project.encode());
    if (mounted) {
      setState(
        () => _status = saved
            ? 'Saved in this browser'
            : 'In memory · export to keep',
      );
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_dirty) browser.saveStorage(storageKey, _project.encode());
    _controller.dispose();
    _transform.dispose();
    super.dispose();
  }

  Offset _position(Artboard screen) =>
      _dragId == screen.id ? _dragPosition! : screen.position;
  Rect _bounds(Iterable<Artboard> screens) => screens
      .map(
        (s) => Rect.fromLTWH(
          s.position.dx,
          s.position.dy,
          s.frameSize.width,
          s.frameSize.height + 48,
        ),
      )
      .reduce((a, b) => a.expandToInclude(b));
  void _fit({bool selected = false}) {
    if (_viewport.isEmpty) return;
    final bounds = _bounds(
      selected ? [_controller.selected] : _project.screens,
    ).inflate(56);
    final scale = math
        .min(_viewport.width / bounds.width, _viewport.height / bounds.height)
        .clamp(.2, 1.0);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        _viewport.width / 2 - bounds.center.dx * scale,
        _viewport.height / 2 - bounds.center.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _zoom(double factor) {
    final old = _transform.value.getMaxScaleOnAxis();
    final scale = (old * factor).clamp(.2, 2.0);
    final center = _transform.toScene(_viewport.center(Offset.zero));
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        _viewport.width / 2 - center.dx * scale,
        _viewport.height / 2 - center.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _edit(Artboard screen) => setState(() => _editing = screen.id);
  Future<void> _add() async {
    final template = await showFDialog<String>(
      context: context,
      builder: (context) => FDialog(
        title: 'Add a screen',
        description: 'Start with a template or a blank artboard.',
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final name in [
              'Welcome',
              'Settings',
              'Dashboard',
              'Layouts',
              'Blank',
            ])
              FButton(
                variant: FButtonVariant.outline,
                onPressed: () => Navigator.pop(context, name),
                child: Text(name),
              ),
          ],
        ),
      ),
    );
    if (!mounted || template == null) return;
    _controller.add(template);
    setState(() => _panel = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fit(selected: true);
    });
  }

  Future<void> _import() async {
    final result = await showFDialog<StudioProject>(
      context: context,
      builder: (_) => const _CanvasImportDialog(),
    );
    if (result == null || !mounted) return;
    _controller.commit(result);
    _fit();
  }

  Future<void> _png() async {
    try {
      setState(() => _capturing = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          _images[_controller.selected.id]?.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null || !mounted) return;
      final saved = browser.downloadBytes(
        'flappa-screen.png',
        data.buffer.asUint8List(),
        'image/png',
      );
      if (mounted) {
        showFToast(
          context,
          title: saved
              ? 'Screen PNG downloaded'
              : 'PNG downloads are available in the browser',
        );
      }
    } catch (_) {
      if (mounted) {
        showFToast(context, title: 'Could not capture this screen. Try again.');
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _export() async {
    var tab = 0;
    var currentOnly = false;
    await showFDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final text = switch (tab) {
            1 => exportStudioPrompt(
              _project,
              screenId: currentOnly ? _controller.selected.id : null,
            ),
            2 => _project.encode(),
            _ => exportStudioDart(_project),
          };
          final filename = [
            'main.dart',
            'flappa-prompt.txt',
            'flappa-project.json',
          ][tab];
          return FDialog(
            maxWidth: 900,
            title: 'From canvas to app',
            description: tab == 0
                ? 'Add flappa_ui to your Flutter app and replace lib/main.dart. Screen links and transitions are included.'
                : tab == 1
                ? 'Copy this brief into your coding assistant. Behavior notes guide implementation; they do not run in the prototype.'
                : 'Keep an editable backup of every screen, link, and layout.',
            actions: [
              FButton(
                variant: FButtonVariant.outline,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    showFToast(context, title: 'Copied to clipboard');
                  }
                },
                leading: const Icon(Icons.copy_outlined),
                child: const Text('Copy'),
              ),
              FButton(
                onPressed: () async {
                  final saved = browser.downloadText(filename, text);
                  if (!saved) {
                    await Clipboard.setData(ClipboardData(text: text));
                  }
                  if (context.mounted) {
                    showFToast(
                      context,
                      title: saved
                          ? '$filename downloaded'
                          : 'Copied to clipboard',
                    );
                  }
                },
                leading: const Icon(Icons.download_outlined),
                child: const Text('Download'),
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, label) in [
                      'Flutter code',
                      'AI prompt',
                      'Project JSON',
                    ].indexed)
                      FButton(
                        size: FButtonSize.small,
                        variant: tab == i
                            ? FButtonVariant.secondary
                            : FButtonVariant.ghost,
                        onPressed: () => setDialogState(() => tab = i),
                        child: Text(label),
                      ),
                  ],
                ),
                if (tab == 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FSwitch(
                      value: currentOnly,
                      label: 'Selected screen only',
                      onChanged: (value) =>
                          setDialogState(() => currentOnly = value),
                    ),
                  ),
                const SizedBox(height: 16),
                FCodeBlock(
                  code: text,
                  filename: filename,
                  fontFamily: 'JetBrainsMono',
                  maxHeight: 340,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addPart(BlockKind kind) {
    final screen = _controller.selected;
    _controller.dropBlock(
      BlockDrag.create(kind),
      screen.id,
      null,
      screen.document.childrenOf(null).length,
    );
    setState(() => _arrange = true);
  }

  Widget _screenList() {
    final c = FTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: PropertyField(
            label: 'Project name',
            value: _project.name,
            maxLength: 120,
            onChanged: (value) =>
                _controller.commit(_project.copyWith(name: value)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final parts in [true, false])
                Expanded(
                  child: FButton(
                    size: FButtonSize.small,
                    variant: _parts == parts
                        ? FButtonVariant.secondary
                        : FButtonVariant.ghost,
                    onPressed: () => setState(() => _parts = parts),
                    child: Text(parts ? 'Blocks' : 'Screens'),
                  ),
                ),
            ],
          ),
        ),
        const FSeparator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            _parts
                ? 'DRAG A COMPONENT ONTO A SCREEN'
                : 'SCREENS  /  ${_project.screens.length}',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: c.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: _parts
              ? ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: BlockKind.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => CanvasPart(
                    kind: BlockKind.values[index],
                    onDragStarted: () => setState(() => _arrange = true),
                    onAdd: () => _addPart(BlockKind.values[index]),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final screen in _project.screens)
                      ListTile(
                        key: ValueKey('screen-list-${screen.id}'),
                        dense: true,
                        selected: screen.id == _controller.selectedId,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        leading: Icon(
                          screen.size.width < 600
                              ? Icons.smartphone_outlined
                              : Icons.desktop_windows_outlined,
                          size: 18,
                        ),
                        title: Text(
                          screen.document.name.isEmpty
                              ? 'Untitled screen'
                              : screen.document.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: screen.id == _project.startId
                            ? const Text(
                                'Start screen',
                                style: TextStyle(fontSize: 10),
                              )
                            : null,
                        onTap: () {
                          _controller.select(screen.id);
                          setState(() => _panel = 1);
                          _fit(selected: true);
                        },
                        onLongPress: () => _edit(screen),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FButton(
                variant: FButtonVariant.outline,
                onPressed: _project.screens.length < 20 ? _add : null,
                leading: const Icon(Icons.add),
                child: const Text('Add screen'),
              ),
              const SizedBox(height: 12),
              FButton(
                variant: FButtonVariant.ghost,
                onPressed: widget.onComponents,
                child: const Text('All components ↗'),
              ),
              const SizedBox(height: 8),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: c.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inspector() {
    final screen = _controller.selected;
    final buttons = screen.document.orderedBlocks.where(
      (b) => b.kind == BlockKind.button,
    );
    final c = FTheme.of(context).colors;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'SCREEN SETTINGS',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            color: c.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        PropertyField(
          key: ValueKey('${screen.id}-name'),
          label: 'Screen name',
          value: screen.document.name,
          maxLength: 120,
          onChanged: (name) => _controller.replaceDocument(
            screen.id,
            screen.document.copyWith(name: name),
          ),
        ),
        const SizedBox(height: 16),
        FField(
          label: 'Device',
          child: FSelect<String>(
            key: ValueKey('device-${screen.id}'),
            value: screen.deviceId,
            items: {
              for (final device in CanvasDevice.all) device.id: device.label,
            },
            onChanged: (value) {
              if (value == null) return;
              _controller.update(screen.withDevice(CanvasDevice.find(value)!));
              _fit(selected: true);
            },
          ),
        ),
        if (screen.device.kind != DeviceKind.none) ...[
          const SizedBox(height: 12),
          Text(
            '${screen.size.width.round()} × ${screen.size.height.round()} · ${screen.device.canRotate ? (screen.landscape ? 'Landscape' : 'Portrait') : 'Landscape'}',
            style: TextStyle(fontSize: 12, color: c.mutedForeground),
          ),
          const SizedBox(height: 12),
          FField(
            label: 'Finish',
            child: FSelect<DeviceFinish>(
              value: screen.finish,
              items: const {
                DeviceFinish.graphite: 'Graphite',
                DeviceFinish.silver: 'Silver',
                DeviceFinish.blue: 'Blue',
              },
              onChanged: (value) {
                if (value != null) {
                  _controller.update(screen.copyWith(finish: value));
                }
              },
            ),
          ),
          if (screen.device.canRotate) ...[
            const SizedBox(height: 12),
            FButton(
              variant: FButtonVariant.outline,
              leading: const Icon(Icons.screen_rotation_outlined),
              onPressed: () {
                _controller.update(screen.rotated());
                _fit(selected: true);
              },
              child: const Text('Rotate device'),
            ),
          ],
        ],
        if (screen.device.kind == DeviceKind.none)
          FField(
            label: 'Artboard size',
            child: FSelect<String>(
              value:
                  '${screen.size.width.round()}x${screen.size.height.round()}',
              items: {
                '390x844': 'Phone · 390 × 844',
                '768x1024': 'Tablet · 768 × 1024',
                '1280x800': 'Desktop · 1280 × 800',
                if (![
                  const Size(390, 844),
                  const Size(768, 1024),
                  const Size(1280, 800),
                ].contains(screen.size))
                  '${screen.size.width.round()}x${screen.size.height.round()}':
                      'Custom · ${screen.size.width.round()} × ${screen.size.height.round()}',
              },
              onChanged: (value) {
                if (value == null) return;
                final parts = value.split('x').map(double.parse).toList();
                _controller.update(
                  screen.copyWith(size: Size(parts[0], parts[1])),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        FButton(
          onPressed: () => _edit(screen),
          leading: const Icon(Icons.tune),
          child: const Text('Edit components'),
        ),
        const SizedBox(height: 12),
        FButton(
          variant: FButtonVariant.outline,
          onPressed: screen.id == _project.startId
              ? null
              : () => _controller.commit(_project.copyWith(startId: screen.id)),
          leading: const Icon(Icons.flag_outlined),
          child: Text(
            screen.id == _project.startId
                ? 'This is the start screen'
                : 'Set as start screen',
          ),
        ),
        const SizedBox(height: 24),
        const FSeparator(),
        const SizedBox(height: 24),
        Text(
          'ON TAP',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            color: c.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          buttons.isEmpty
              ? 'Add a button in Edit components to connect this screen.'
              : 'Connect buttons to another screen or go back.',
          style: TextStyle(fontSize: 12, height: 1.5, color: c.mutedForeground),
        ),
        for (final button in buttons) ...[
          const SizedBox(height: 16),
          FField(
            label: screen.document.labelFor(button),
            child: FSelect<String>(
              key: ValueKey('link-${screen.id}-${button.id}'),
              value: screen.actions[button.id]?.target ?? '',
              items: {
                '': 'Local feedback',
                ScreenAction.back: '← Go back',
                for (final target in _project.screens)
                  target.id: target.document.name.isEmpty
                      ? 'Untitled screen'
                      : target.document.name,
              },
              onChanged: (value) {
                if (value == null) return;
                _controller.link(
                  button.id,
                  value.isEmpty
                      ? null
                      : ScreenAction(
                          target: value,
                          transition:
                              screen.actions[button.id]?.transition ??
                              FlowTransition.slide,
                        ),
                );
              },
            ),
          ),
          if (screen.actions[button.id] != null &&
              screen.actions[button.id]!.target != ScreenAction.back) ...[
            const SizedBox(height: 8),
            FField(
              label: 'Transition',
              child: FSelect<FlowTransition>(
                value: screen.actions[button.id]!.transition,
                items: const {
                  FlowTransition.slide: 'Slide',
                  FlowTransition.fade: 'Fade',
                  FlowTransition.instant: 'Instant',
                },
                onChanged: (value) {
                  if (value != null) {
                    _controller.link(
                      button.id,
                      ScreenAction(
                        target: screen.actions[button.id]!.target,
                        transition: value,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ],
        const SizedBox(height: 24),
        PropertyField(
          key: ValueKey('${screen.id}-notes'),
          label: 'Behavior notes',
          value: screen.notes,
          maxLength: 10000,
          onChanged: (notes) =>
              _controller.update(screen.copyWith(notes: notes)),
        ),
        const SizedBox(height: 6),
        Text(
          'Included in your AI prompt.',
          style: TextStyle(fontSize: 11, color: c.mutedForeground),
        ),
        const SizedBox(height: 24),
        FButton(
          variant: FButtonVariant.outline,
          onPressed: _png,
          leading: const Icon(Icons.image_outlined),
          child: const Text('Export screen PNG'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FButton(
              size: FButtonSize.small,
              variant: FButtonVariant.outline,
              onPressed: _project.screens.length < 20
                  ? () {
                      _controller.duplicate();
                      _fit(selected: true);
                    }
                  : null,
              child: const Text('Duplicate'),
            ),
            FButton(
              size: FButtonSize.small,
              variant: FButtonVariant.ghost,
              onPressed: _project.screens.length > 1
                  ? _controller.remove
                  : null,
              child: const Text('Delete screen'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _board(Artboard screen) {
    final selected = _controller.selectedId == screen.id;
    final c = FTheme.of(context).colors;
    return Positioned(
      left: _position(screen).dx,
      top: _position(screen).dy,
      width: screen.frameSize.width,
      height: screen.frameSize.height + 48,
      child: Column(
        children: [
          GestureDetector(
            key: ValueKey('artboard-handle-${screen.id}'),
            dragStartBehavior: DragStartBehavior.down,
            behavior: HitTestBehavior.opaque,
            onTap: () => _controller.select(screen.id),
            onPanStart: (details) {
              _controller.select(screen.id);
              setState(() {
                _dragId = screen.id;
                _dragPosition = screen.position;
                _dragPointer = details.globalPosition;
              });
            },
            onPanUpdate: (details) => setState(() {
              _dragPosition = Offset(
                (screen.position.dx +
                        (details.globalPosition.dx - _dragPointer!.dx) /
                            _transform.value.getMaxScaleOnAxis())
                    .clamp(0, 10000),
                (screen.position.dy +
                        (details.globalPosition.dy - _dragPointer!.dy) /
                            _transform.value.getMaxScaleOnAxis())
                    .clamp(0, 10000),
              );
            }),
            onPanEnd: (_) {
              final position = Offset(
                (_dragPosition!.dx / 8).round() * 8.0,
                (_dragPosition!.dy / 8).round() * 8.0,
              );
              setState(() {
                _dragId = null;
                _dragPosition = null;
              });
              _controller.update(screen.copyWith(position: position));
            },
            onPanCancel: () => setState(() {
              _dragId = null;
              _dragPosition = null;
            }),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Icon(
                    screen.id == _project.startId
                        ? Icons.flag_outlined
                        : Icons.drag_indicator,
                    size: 18,
                    color: selected ? c.foreground : c.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      screen.document.name.isEmpty
                          ? 'Untitled screen'
                          : screen.document.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.foreground,
                      ),
                    ),
                  ),
                  Text(
                    '${screen.size.width.round()} × ${screen.size.height.round()}',
                    style: TextStyle(fontSize: 10, color: c.mutedForeground),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    tooltip: 'Edit ${screen.document.name}',
                    size: FButtonSize.icon,
                    variant: FButtonVariant.ghost,
                    onPressed: () => _edit(screen),
                    child: const Icon(Icons.edit_outlined, size: 16),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              foregroundDecoration: BoxDecoration(
                border: screen.device.kind != DeviceKind.none
                    ? null
                    : Border.all(
                        color: selected ? c.foreground : c.border,
                        width: selected ? 2 : 1,
                      ),
              ),
              decoration: BoxDecoration(
                boxShadow: screen.device.kind != DeviceKind.none
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Padding(
                padding: EdgeInsets.zero,
                child: GestureDetector(
                  key: ValueKey('artboard-${screen.id}'),
                  onTap: () => _controller.select(screen.id),
                  onDoubleTap: () => _edit(screen),
                  child: RepaintBoundary(
                    key: _images.putIfAbsent(screen.id, GlobalKey.new),
                    child: DeviceFrame(
                      device: screen.device,
                      screenSize: screen.size,
                      landscape: screen.landscape,
                      finish: screen.finish,
                      dark: screen.document.dark,
                      child: _arrange && !_capturing
                          ? DraggableArtboard(
                              key: ValueKey('editable-${screen.id}'),
                              screen: screen,
                              controller: _controller,
                            )
                          : AbsorbPointer(
                              child: ExcludeSemantics(
                                child: ArtboardContent(screen: screen),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _canvas() => LayoutBuilder(
    builder: (context, constraints) {
      final resized = _viewport != constraints.biggest;
      _viewport = constraints.biggest;
      if (!_fitted || resized) {
        _fitted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fit(selected: constraints.maxWidth < 600);
        });
      }
      final c = FTheme.of(context).colors;
      final bounds = _bounds(_project.screens);
      return ColoredBox(
        color: c.muted.withValues(alpha: .3),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transform,
                constrained: false,
                minScale: .2,
                maxScale: 2,
                boundaryMargin: const EdgeInsets.all(20000),
                trackpadScrollCausesScale: true,
                child: SizedBox(
                  width: math.max(2000, bounds.right + 1000),
                  height: math.max(1600, bounds.bottom + 1000),
                  child: CustomPaint(
                    painter: DotGridPainter(color: c.border),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _FlowPainter(
                              project: _project,
                              color: c.mutedForeground,
                              position: _position,
                            ),
                          ),
                        ),
                        for (final screen in _project.screens) _board(screen),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 12,
              child: IgnorePointer(
                child: Text(
                  _arrange
                      ? 'Drag components or their handles · Drop into highlighted slots'
                      : 'Drag a screen title to move · Double-click to edit',
                  style: TextStyle(fontSize: 11, color: c.mutedForeground),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: c.background,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FToggle(
                          value: _arrange,
                          onChanged: (value) =>
                              setState(() => _arrange = value),
                          child: const Text('Edit blocks'),
                        ),
                        FButton(
                          tooltip: 'Zoom out',
                          size: FButtonSize.icon,
                          variant: FButtonVariant.ghost,
                          onPressed: () => _zoom(1 / 1.2),
                          child: const Icon(Icons.remove, size: 18),
                        ),
                        ValueListenableBuilder<Matrix4>(
                          valueListenable: _transform,
                          builder: (_, value, _) => SizedBox(
                            width: 46,
                            child: Text(
                              '${(value.getMaxScaleOnAxis() * 100).round()}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        FButton(
                          tooltip: 'Zoom in',
                          size: FButtonSize.icon,
                          variant: FButtonVariant.ghost,
                          onPressed: () => _zoom(1.2),
                          child: const Icon(Icons.add, size: 18),
                        ),
                        FButton(
                          tooltip: 'Fit all screens',
                          size: FButtonSize.icon,
                          variant: FButtonVariant.ghost,
                          onPressed: _fit,
                          child: const Icon(Icons.fit_screen, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final editing = _editing == null ? null : _project.find(_editing!);
    if (editing != null) {
      return PlaygroundPage(
        key: ValueKey('editor-${editing.id}'),
        onHome: widget.onHome,
        onComponents: widget.onComponents,
        initialDocument: editing.document,
        designWidth: editing.size.width,
        persistDraft: false,
        onDocumentChanged: (document) =>
            _controller.replaceDocument(editing.id, document),
        onCanvas: () => setState(() => _editing = null),
      );
    }
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            _controller.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            _controller.undo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): _controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            _controller.redo,
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
                              '/ canvas',
                              style: TextStyle(
                                fontSize: 13,
                                color: c.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (constraints.maxWidth > 1300)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  _status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: c.mutedForeground,
                                  ),
                                ),
                              ),
                            FButton(
                              tooltip: 'Undo',
                              size: FButtonSize.icon,
                              variant: FButtonVariant.ghost,
                              onPressed: _controller.canUndo
                                  ? _controller.undo
                                  : null,
                              child: const Icon(Icons.undo, size: 18),
                            ),
                            FButton(
                              tooltip: 'Redo',
                              size: FButtonSize.icon,
                              variant: FButtonVariant.ghost,
                              onPressed: _controller.canRedo
                                  ? _controller.redo
                                  : null,
                              child: const Icon(Icons.redo, size: 18),
                            ),
                            FButton(
                              variant: FButtonVariant.ghost,
                              onPressed: _import,
                              child: const Text('Import'),
                            ),
                            FButton(
                              variant: FButtonVariant.outline,
                              leading: const Icon(Icons.play_arrow_outlined),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => FlowPlayer(project: _project),
                                ),
                              ),
                              child: const Text('Test flow'),
                            ),
                            FButton(
                              leading: const Icon(
                                Icons.ios_share_outlined,
                                size: 16,
                              ),
                              onPressed: _export,
                              child: const Text('Export'),
                            ),
                          ],
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
                            'Screens',
                            'Canvas',
                            'Properties',
                          ].indexed)
                            Expanded(
                              child: FButton(
                                variant: _panel == i
                                    ? FButtonVariant.secondary
                                    : FButtonVariant.ghost,
                                onPressed: () => setState(() {
                                  _panel = i;
                                  if (i == 0) _parts = false;
                                }),
                                child: Text(label),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (!wide && _panel == 1)
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        itemCount: BlockKind.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => CanvasPart(
                          kind: BlockKind.values[index],
                          onDragStarted: () => setState(() => _arrange = true),
                          touch: true,
                          onAdd: () => _addPart(BlockKind.values[index]),
                        ),
                      ),
                    ),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(width: 216, child: _screenList()),
                              VerticalDivider(width: 1, color: c.border),
                              Expanded(child: _canvas()),
                              VerticalDivider(width: 1, color: c.border),
                              SizedBox(width: 288, child: _inspector()),
                            ],
                          )
                        : IndexedStack(
                            index: _panel,
                            children: [_screenList(), _canvas(), _inspector()],
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
}

class _FlowPainter extends CustomPainter {
  _FlowPainter({
    required this.project,
    required this.color,
    required this.position,
  });
  final StudioProject project;
  final Color color;
  final Offset Function(Artboard) position;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final screen in project.screens) {
      final targets = screen.actions.values.map((a) => a.target).toSet();
      for (final id in targets) {
        final target = project.find(id);
        if (target == null || target.id == screen.id) continue;
        final forward = position(target).dx >= position(screen).dx;
        final start =
            position(screen) +
            Offset(forward ? screen.frameSize.width : 0, 100);
        final end =
            position(target) +
            Offset(forward ? 0 : target.frameSize.width, 100);
        final bend =
            math.max(64.0, (end.dx - start.dx).abs() / 2) * (forward ? 1 : -1);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx + bend,
            start.dy,
            end.dx - bend,
            end.dy,
            end.dx,
            end.dy,
          );
        canvas.drawPath(path, paint);
        canvas.drawCircle(start, 3, Paint()..color = color);
        canvas.drawPath(
          Path()
            ..moveTo(end.dx + (forward ? -8 : 8), end.dy - 5)
            ..lineTo(end.dx, end.dy)
            ..lineTo(end.dx + (forward ? -8 : 8), end.dy + 5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FlowPainter oldDelegate) => true;
}

class _CanvasImportDialog extends StatefulWidget {
  const _CanvasImportDialog();
  @override
  State<_CanvasImportDialog> createState() => _CanvasImportDialogState();
}

class _CanvasImportDialogState extends State<_CanvasImportDialog> {
  final _text = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FDialog(
    title: 'Import a canvas',
    description:
        'Paste a canvas project or an earlier Flappa screen export. You can undo the import.',
    actions: [
      FButton(
        onPressed: () {
          try {
            Navigator.pop(context, StudioProject.decode(_text.text));
          } on FormatException catch (error) {
            setState(() => _error = error.message);
          }
        },
        child: const Text('Import project'),
      ),
    ],
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FInput(controller: _text, semanticLabel: 'Project JSON', maxLines: 8),
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
