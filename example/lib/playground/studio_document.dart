import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'document.dart';

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
    Map<String, ScreenAction> actions = const {},
  }) : actions = Map.unmodifiable(actions);
  final String id, notes;
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
    Map<String, ScreenAction>? actions,
  }) => Artboard(
    id: id ?? this.id,
    document: document ?? this.document,
    position: position ?? this.position,
    size: size ?? this.size,
    notes: notes ?? this.notes,
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
      screens.add(
        Artboard(
          id: map['id'],
          document: document,
          notes: map['notes'],
          actions: actions,
          position: Offset(
            number(map, 'x', 0, 10000),
            number(map, 'y', 0, 10000),
          ),
          size: Size(
            number(map, 'width', 320, 1600),
            number(map, 'height', 480, 1400),
          ),
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
        document: welcome,
        actions: {
          if (button != null) button.id: const ScreenAction(target: 'settings'),
        },
      ),
      Artboard(
        id: 'settings',
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
      position: _nextPosition(),
    );
    selectedId = id;
    commit(project.copyWith(screens: [...project.screens, screen]));
  }

  Offset _nextPosition() => Offset(
    (selected.position.dx + selected.size.width + 170)
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
