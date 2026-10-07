import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'document.dart';
import 'canvas_editor.dart';
import 'devices.dart';

enum FlowTransition { slide, fade, instant }

class ScreenAction {
  const ScreenAction({
    required this.target,
    this.transition = FlowTransition.slide,
  });
  final String target;
  final FlowTransition transition;
  static const back = '@back';
  Map<String, String> toJson() => {
    'target': target,
    'transition': transition.name,
  };
}

class Artboard {
  Artboard({
    required this.id,
    required this.document,
    this.position = const Offset(80, 80),
    this.size = const Size(390, 844),
    this.notes = '',
    this.deviceId = 'none',
    this.landscape = false,
    this.finish = DeviceFinish.graphite,
    Map<String, ScreenAction> actions = const {},
  }) : actions = Map.unmodifiable(actions);
  final String id, notes, deviceId;
  final bool landscape;
  final DeviceFinish finish;
  CanvasDevice get device => CanvasDevice.find(deviceId)!;
  Size get frameSize => device.frameSize(size);
  Artboard withDevice(CanvasDevice value) => copyWith(
    deviceId: value.id,
    landscape: false,
    size: value.kind == DeviceKind.none ? size : value.viewport,
  );
  Artboard rotated() => device.canRotate
      ? copyWith(landscape: !landscape, size: device.screenSize(!landscape))
      : this;
  final ScreenDocument document;
  final Offset position;
  final Size size;
  final Map<String, ScreenAction> actions;

  Artboard copyWith({
    String? id,
    ScreenDocument? document,
    Offset? position,
    Size? size,
    String? notes,
    String? deviceId,
    bool? landscape,
    DeviceFinish? finish,
    Map<String, ScreenAction>? actions,
  }) => Artboard(
    id: id ?? this.id,
    document: document ?? this.document,
    position: position ?? this.position,
    size: size ?? this.size,
    notes: notes ?? this.notes,
    deviceId: deviceId ?? this.deviceId,
    landscape: landscape ?? this.landscape,
    finish: finish ?? this.finish,
    actions: actions ?? this.actions,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'document': jsonDecode(document.encode()),
    'x': position.dx,
    'y': position.dy,
    'width': size.width,
    'height': size.height,
    'notes': notes,
    'device': deviceId,
    'landscape': landscape,
    'finish': finish.name,
    'actions': actions.map((key, value) => MapEntry(key, value.toJson())),
  };
}

class StudioProject {
  StudioProject({
    this.name = 'Untitled flow',
    required this.startId,
    required List<Artboard> screens,
  }) : screens = List.unmodifiable(screens);
  final String name, startId;
  final List<Artboard> screens;
  Artboard? find(String id) =>
      screens.where((screen) => screen.id == id).firstOrNull;
  StudioProject copyWith({
    String? name,
    String? startId,
    List<Artboard>? screens,
  }) => StudioProject(
    name: name ?? this.name,
    startId: startId ?? this.startId,
    screens: screens ?? this.screens,
  );
  String encode() => const JsonEncoder.withIndent('  ').convert({
    'format': 'flappa-canvas',
    'version': 1,
    'name': name,
    'startId': startId,
    'screens': screens.map((screen) => screen.toJson()).toList(),
  });

  factory StudioProject.decode(String source) {
    if (source.length > 2000000) {
      throw const FormatException('Project is too large.');
    }
    final data = jsonDecode(source);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a project object.');
    }
    if (data['format'] == null) {
      return StudioProject(
        startId: 'screen_1',
        screens: [
          Artboard(id: 'screen_1', document: ScreenDocument.decode(source)),
        ],
      );
    }
    Never invalid() =>
        throw const FormatException('Invalid canvas project or screen links.');
    if (data['format'] != 'flappa-canvas' ||
        data['version'] != 1 ||
        data['name'] is! String ||
        (data['name'] as String).length > 120 ||
        data['startId'] is! String ||
        data['screens'] is! List) {
      invalid();
    }
    final items = data['screens'] as List;
    if (items.isEmpty || items.length > 20) invalid();
    final screens = <Artboard>[];
    double number(
      Map<String, dynamic> item,
      String key,
      double min,
      double max,
    ) {
      final value = item[key];
      if (value is! num || !value.isFinite || value < min || value > max) {
        invalid();
      }
      return (value).toDouble();
    }

    for (final item in items) {
      if (item is! Map<String, dynamic> ||
          item['id'] is! String ||
          (item['id'] as String).isEmpty ||
          item['id'] == ScreenAction.back ||
          (item['id'] as String).length > 120 ||
          item['notes'] is! String ||
          (item['notes'] as String).length > 10000 ||
          item['actions'] is! Map<String, dynamic>) {
        invalid();
      }
      final map = item;
      final document = ScreenDocument.decode(jsonEncode(map['document']));
      final actions = <String, ScreenAction>{};
      for (final entry in (map['actions'] as Map<String, dynamic>).entries) {
        final action = entry.value;
        if (document.find(entry.key)?.kind != BlockKind.button ||
            action is! Map<String, dynamic> ||
            action['target'] is! String) {
          invalid();
        }
        final transition = FlowTransition.values
            .where((t) => t.name == action['transition'])
            .firstOrNull;
        if (transition == null) invalid();
        actions[entry.key] = ScreenAction(
          target: action['target'],
          transition: transition,
        );
      }
      final deviceId = map['device'] ?? 'none';
      final landscape = map['landscape'] ?? false;
      final finish = DeviceFinish.values
          .where((value) => value.name == (map['finish'] ?? 'graphite'))
          .firstOrNull;
      if (deviceId is! String || landscape is! bool || finish == null) {
        invalid();
      }
      final device = CanvasDevice.find(deviceId);
      final size = Size(
        number(map, 'width', 320, 1600),
        number(map, 'height', 320, 1600),
      );
      if (device == null ||
          (landscape && !device.canRotate) ||
          (device.kind != DeviceKind.none &&
              size != device.screenSize(landscape))) {
        invalid();
      }
      screens.add(
        Artboard(
          id: map['id'],
          document: document,
          notes: map['notes'],
          deviceId: deviceId,
          landscape: landscape,
          finish: finish,
          actions: actions,
          position: Offset(
            number(map, 'x', 0, 10000),
            number(map, 'y', 0, 10000),
          ),
          size: size,
        ),
      );
    }
    final ids = screens.map((screen) => screen.id).toSet();
    if (ids.length != screens.length || !ids.contains(data['startId'])) {
      invalid();
    }
    for (final screen in screens) {
      if (screen.actions.values.any(
        (action) =>
            action.target != ScreenAction.back && !ids.contains(action.target),
      )) {
        invalid();
      }
    }
    return StudioProject(
      name: data['name'],
      startId: data['startId'],
      screens: screens,
    );
  }
}

StudioProject starterProject([ScreenDocument? draft]) {
  final welcome = draft ?? templateDocument('Welcome');
  final button = welcome.blocks
      .where((b) => b.kind == BlockKind.button)
      .firstOrNull;
  final settings = templateDocument('Settings');
  return StudioProject(
    name: 'My first flow',
    startId: 'welcome',
    screens: [
      Artboard(
        id: 'welcome',
        deviceId: 'iphone',
        document: welcome,
        actions: {
          if (button != null) button.id: const ScreenAction(target: 'settings'),
        },
      ),
      Artboard(
        id: 'settings',
        deviceId: 'iphone',
        document: settings,
        position: const Offset(640, 80),
        actions: {
          settings.blocks.last.id: const ScreenAction(
            target: ScreenAction.back,
          ),
        },
      ),
    ],
  );
}

class StudioController extends ChangeNotifier {
  StudioController(StudioProject project)
    : _project = project,
      selectedId = project.startId;
  StudioProject _project;
  StudioProject get project => _project;
  final List<StudioProject> _past = [], _future = [];
  String selectedId;
  Artboard get selected => project.find(selectedId) ?? project.screens.first;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  void select(String id) {
    if (project.find(id) == null || selectedId == id) return;
    selectedId = id;
    notifyListeners();
  }

  void commit(StudioProject next) {
    if (next.encode() == project.encode()) return;
    _past.add(project);
    if (_past.length > 50) _past.removeAt(0);
    _future.clear();
    _project = next;
    _notify();
  }

  void _notify() {
    if (project.find(selectedId) == null) selectedId = project.startId;
    notifyListeners();
  }

  void update(Artboard screen) => commit(
    project.copyWith(
      screens: [
        for (final item in project.screens)
          if (item.id == screen.id) screen else item,
      ],
    ),
  );
  void replaceDocument(String id, ScreenDocument document) {
    final screen = project.find(id);
    if (screen == null) return;
    update(
      screen.copyWith(
        document: document,
        actions: {
          for (final entry in screen.actions.entries)
            if (document.find(entry.key)?.kind == BlockKind.button)
              entry.key: entry.value,
        },
      ),
    );
  }

  void removeBlock(String screenId, String blockId) {
    final screen = project.find(screenId);
    if (screen == null || screen.document.find(blockId) == null) return;
    final ids = screen.document.subtreeIds(blockId);
    selectedId = screenId;
    replaceDocument(
      screenId,
      screen.document.copyWith(
        blocks: [
          for (final block in screen.document.blocks)
            if (!ids.contains(block.id)) block,
        ],
      ),
    );
  }

  bool canDropBlock(BlockDrag drag, String screenId, String? parentId) {
    final target = project.find(screenId);
    if (target == null) return false;
    final editor = PlaygroundController(target.document);
    try {
      if (drag.kind != null) return editor.canInsert(parentId);
      if (drag.sourceId == screenId) return editor.canMove(drag.id!, parentId);
      final source = project.find(drag.sourceId ?? '');
      final root = source?.document.find(drag.id);
      if (source == null || root == null || !editor.canInsert(parentId)) {
        return false;
      }
      final ids = source.document.subtreeIds(root.id);
      final height =
          ids.map(source.document.depthOf).reduce((a, b) => a > b ? a : b) -
          source.document.depthOf(root.id);
      final depth = parentId == null
          ? 0
          : target.document.depthOf(parentId) + 1;
      return target.document.blocks.length + ids.length <= 100 &&
          depth + height < 8;
    } finally {
      editor.dispose();
    }
  }

  void dropBlock(BlockDrag drag, String screenId, String? parentId, int index) {
    if (!canDropBlock(drag, screenId, parentId)) return;
    final target = project.find(screenId)!;
    final siblings = target.document.childrenOf(parentId);
    if (index < 0 || index > siblings.length) return;
    if (drag.kind != null || drag.sourceId == screenId) {
      final editor = PlaygroundController(target.document);
      try {
        if (drag.kind != null) {
          editor.add(drag.kind!, parentId: parentId, index: index);
        } else {
          final oldIndex = siblings.indexWhere((b) => b.id == drag.id);
          editor.moveBlock(
            drag.id!,
            parentId: parentId,
            index: oldIndex >= 0 && oldIndex < index ? index - 1 : index,
          );
        }
        selectedId = screenId;
        replaceDocument(screenId, editor.document);
      } finally {
        editor.dispose();
      }
      return;
    }
    final source = project.find(drag.sourceId!)!;
    final ids = source.document.subtreeIds(drag.id!);
    final used = target.document.blocks.map((b) => b.id).toSet();
    final remapped = <String, String>{};
    var serial = 0;
    for (final id in ids) {
      var candidate = id;
      while (!used.add(candidate)) {
        candidate = 'moved_${serial++}';
      }
      remapped[id] = candidate;
    }
    final moved = [
      for (final block in source.document.orderedBlocks)
        if (ids.contains(block.id))
          block.copyWith(
            id: remapped[block.id],
            parentId: block.id == drag.id ? parentId : remapped[block.parentId],
          ),
    ];
    final blocks = [...target.document.blocks];
    blocks.insertAll(
      index == siblings.length
          ? blocks.length
          : blocks.indexOf(siblings[index]),
      moved,
    );
    final nextSource = source.copyWith(
      document: source.document.copyWith(
        blocks: source.document.blocks
            .where((b) => !ids.contains(b.id))
            .toList(),
      ),
      actions: {
        for (final entry in source.actions.entries)
          if (!ids.contains(entry.key)) entry.key: entry.value,
      },
    );
    final nextTarget = target.copyWith(
      document: target.document.copyWith(blocks: blocks),
      actions: {
        ...target.actions,
        for (final entry in source.actions.entries)
          if (ids.contains(entry.key)) remapped[entry.key]!: entry.value,
      },
    );
    selectedId = screenId;
    commit(
      project.copyWith(
        screens: [
          for (final screen in project.screens)
            if (screen.id == source.id)
              nextSource
            else if (screen.id == target.id)
              nextTarget
            else
              screen,
        ],
      ),
    );
  }

  void link(String blockId, ScreenAction? action) {
    if (selected.document.find(blockId)?.kind != BlockKind.button) return;
    if (action != null &&
        action.target != ScreenAction.back &&
        project.find(action.target) == null) {
      return;
    }
    final actions = {...selected.actions};
    if (action == null) {
      actions.remove(blockId);
    } else {
      actions[blockId] = action;
    }
    update(selected.copyWith(actions: actions));
  }

  String _newId() {
    var i = 1;
    while (project.find('screen_$i') != null) {
      i++;
    }
    return 'screen_$i';
  }

  void add(String template) {
    if (project.screens.length >= 20) return;
    final id = _newId();
    final screen = Artboard(
      id: id,
      document: templateDocument(template),
      deviceId: selected.deviceId,
      size: selected.size,
      landscape: selected.landscape,
      finish: selected.finish,
      position: _nextPosition(),
    );
    selectedId = id;
    commit(project.copyWith(screens: [...project.screens, screen]));
  }

  Offset _nextPosition() => Offset(
    (selected.position.dx + selected.frameSize.width + 170)
        .clamp(0, 10000)
        .toDouble(),
    selected.position.dy,
  );
  void duplicate() {
    if (project.screens.length >= 20) return;
    final source = selected;
    final id = _newId();
    final screen = source.copyWith(
      id: id,
      position: _nextPosition(),
      document: source.document.copyWith(
        name:
            '${source.document.name.substring(0, source.document.name.length.clamp(0, 110))} copy',
      ),
      actions: {
        for (final entry in source.actions.entries)
          entry.key: ScreenAction(
            target: entry.value.target == source.id ? id : entry.value.target,
            transition: entry.value.transition,
          ),
      },
    );
    selectedId = id;
    commit(project.copyWith(screens: [...project.screens, screen]));
  }

  void remove() {
    if (project.screens.length == 1) return;
    final id = selected.id;
    final screens = [
      for (final screen in project.screens)
        if (screen.id != id)
          screen.copyWith(
            actions: {
              for (final entry in screen.actions.entries)
                if (entry.value.target != id) entry.key: entry.value,
            },
          ),
    ];
    commit(
      project.copyWith(
        screens: screens,
        startId: project.startId == id ? screens.first.id : project.startId,
      ),
    );
  }

  void undo() {
    if (!canUndo) return;
    _future.add(project);
    _project = _past.removeLast();
    _notify();
  }

  void redo() {
    if (!canRedo) return;
    _past.add(project);
    _project = _future.removeLast();
    _notify();
  }
}
