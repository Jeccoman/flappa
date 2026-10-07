import 'dart:convert';
import 'package:flutter/foundation.dart';

enum BlockKind {
  heading,
  text,
  input,
  button,
  card,
  badge,
  alert,
  toggle,
  checkbox,
  progress,
  divider,
  spacer,
  avatar,
  chart,
  row,
  column,
  container,
}

extension BlockLabel on BlockKind {
  bool get isLayout =>
      this == BlockKind.row ||
      this == BlockKind.column ||
      this == BlockKind.container;
  String get label => switch (this) {
    BlockKind.heading => 'Heading',
    BlockKind.text => 'Text',
    BlockKind.input => 'Input',
    BlockKind.button => 'Button',
    BlockKind.card => 'Card',
    BlockKind.badge => 'Badge',
    BlockKind.alert => 'Alert',
    BlockKind.toggle => 'Switch',
    BlockKind.checkbox => 'Checkbox',
    BlockKind.progress => 'Progress',
    BlockKind.divider => 'Divider',
    BlockKind.spacer => 'Spacer',
    BlockKind.avatar => 'Avatar',
    BlockKind.chart => 'Bar chart',
    BlockKind.row => 'Row',
    BlockKind.column => 'Column',
    BlockKind.container => 'Container',
  };
}

const _unchangedParent = Object();

class ScreenBlock {
  const ScreenBlock({
    required this.id,
    required this.kind,
    this.title = '',
    this.detail = '',
    this.value = .6,
    this.variant = 0,
    this.parentId,
    this.padding = 16,
    this.gap = 12,
    this.responsive = true,
  });
  final String id, title, detail;
  final BlockKind kind;
  final double value;
  final int variant;
  final String? parentId;
  final double padding, gap;
  final bool responsive;

  ScreenBlock copyWith({
    String? id,
    String? title,
    String? detail,
    double? value,
    int? variant,
    Object? parentId = _unchangedParent,
    double? padding,
    double? gap,
    bool? responsive,
  }) => ScreenBlock(
    id: id ?? this.id,
    kind: kind,
    title: title ?? this.title,
    detail: detail ?? this.detail,
    value: value ?? this.value,
    variant: variant ?? this.variant,
    parentId: identical(parentId, _unchangedParent)
        ? this.parentId
        : parentId as String?,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    responsive: responsive ?? this.responsive,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'detail': detail,
    'value': value,
    'variant': variant,
    'parentId': parentId,
    'padding': padding,
    'gap': gap,
    'responsive': responsive,
  };

  factory ScreenBlock.fromJson(Map<String, dynamic> json) {
    final kind = BlockKind.values
        .where((kind) => kind.name == json['kind'])
        .firstOrNull;
    if (kind == null ||
        json['id'] is! String ||
        (json['id'] as String).isEmpty ||
        json['title'] is! String ||
        json['detail'] is! String ||
        json['value'] is! num ||
        json['variant'] is! int) {
      throw const FormatException('Invalid component properties.');
    }
    final parent = json['parentId'];
    final padding = json['padding'] ?? 16;
    final gap = json['gap'] ?? 12;
    final responsive = json['responsive'] ?? true;
    if ((parent != null && (parent is! String || parent.isEmpty)) ||
        padding is! num ||
        !padding.isFinite ||
        padding < 0 ||
        padding > 64 ||
        gap is! num ||
        !gap.isFinite ||
        gap < 0 ||
        gap > 48 ||
        responsive is! bool) {
      throw const FormatException('Invalid layout properties.');
    }
    final value = (json['value'] as num).toDouble();
    final variant = json['variant'] as int;
    if (!value.isFinite ||
        value < 0 ||
        value > 1 ||
        variant < 0 ||
        variant > 5 ||
        (json['title'] as String).length > 2000 ||
        (json['detail'] as String).length > 10000) {
      throw const FormatException('Component properties are out of range.');
    }
    return ScreenBlock(
      id: json['id'],
      kind: kind,
      title: json['title'],
      detail: json['detail'],
      value: value,
      variant: variant,
      parentId: parent as String?,
      padding: padding.toDouble(),
      gap: gap.toDouble(),
      responsive: responsive,
    );
  }
}

class ScreenDocument {
  ScreenDocument({
    this.name = 'My screen',
    this.padding = 24,
    this.gap = 16,
    this.radius = 10,
    this.accent = 0,
    this.dark = false,
    List<ScreenBlock> blocks = const [],
  }) : blocks = List.unmodifiable(blocks);
  final String name;
  final double padding, gap, radius;
  final int accent;
  final bool dark;
  final List<ScreenBlock> blocks;

  List<ScreenBlock> childrenOf(String? parentId) =>
      blocks.where((block) => block.parentId == parentId).toList();

  ScreenBlock? find(String? id) =>
      blocks.where((block) => block.id == id).firstOrNull;

  String labelFor(ScreenBlock block) => block.title.isNotEmpty
      ? block.title
      : '${block.kind.label} ${blocks.where((b) => b.kind == block.kind).toList().indexOf(block) + 1}';

  int depthOf(String id) {
    var depth = 0;
    var current = find(id);
    final seen = <String>{};
    while (current?.parentId != null) {
      if (!seen.add(current!.id)) throw const FormatException('Cyclic layout.');
      current = find(current.parentId);
      depth++;
    }
    return depth;
  }

  Set<String> subtreeIds(String id) {
    final result = <String>{};
    void visit(String current) {
      if (!result.add(current)) return;
      for (final child in childrenOf(current)) {
        visit(child.id);
      }
    }

    visit(id);
    return result;
  }

  List<ScreenBlock> get orderedBlocks {
    final result = <ScreenBlock>[];
    void visit(String? parentId) {
      for (final block in childrenOf(parentId)) {
        result.add(block);
        visit(block.id);
      }
    }

    visit(null);
    return result;
  }

  ScreenDocument copyWith({
    String? name,
    double? padding,
    double? gap,
    double? radius,
    int? accent,
    bool? dark,
    List<ScreenBlock>? blocks,
  }) => ScreenDocument(
    name: name ?? this.name,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    radius: radius ?? this.radius,
    accent: accent ?? this.accent,
    dark: dark ?? this.dark,
    blocks: blocks ?? this.blocks,
  );

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'version': 2,
    'name': name,
    'padding': padding,
    'gap': gap,
    'radius': radius,
    'accent': accent,
    'dark': dark,
    'blocks': blocks.map((block) => block.toJson()).toList(),
  });

  factory ScreenDocument.decode(String source) {
    if (source.length > 500000) {
      throw const FormatException('Project is too large.');
    }
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic> ||
        ![1, 2].contains(json['version']) ||
        json['name'] is! String ||
        (json['name'] as String).length > 120 ||
        json['dark'] is! bool ||
        json['accent'] is! int ||
        json['accent'] < 0 ||
        json['accent'] > 4 ||
        json['blocks'] is! List ||
        (json['blocks'] as List).length > 100) {
      throw const FormatException('This is not a supported Flappa project.');
    }
    double dimension(String key, double max) {
      final value = json[key];
      if (value is! num || !value.isFinite || value < 0 || value > max) {
        throw FormatException('Invalid $key.');
      }
      return value.toDouble();
    }

    final blocks = (json['blocks'] as List).map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid component.');
      }
      return ScreenBlock.fromJson(value);
    }).toList();
    if (blocks.map((b) => b.id).toSet().length != blocks.length) {
      throw const FormatException('Component identifiers must be unique.');
    }
    final document = ScreenDocument(
      name: json['name'],
      dark: json['dark'],
      accent: json['accent'],
      padding: dimension('padding', 64),
      gap: dimension('gap', 48),
      radius: dimension('radius', 24),
      blocks: blocks,
    );
    for (final block in blocks) {
      if (block.parentId != null &&
          !(document.find(block.parentId)?.kind.isLayout ?? false)) {
        throw const FormatException('Missing layout parent.');
      }
      if (document.depthOf(block.id) >= 8) {
        throw const FormatException('Layouts support up to eight levels.');
      }
    }
    return document;
  }
}

ScreenBlock newBlock(BlockKind kind, String id) => ScreenBlock(
  id: id,
  kind: kind,
  title: switch (kind) {
    BlockKind.heading => 'Make something great.',
    BlockKind.text => 'Every good idea deserves a thoughtful interface.',
    BlockKind.input => 'Email address',
    BlockKind.button => 'Continue',
    BlockKind.card => 'Your next chapter',
    BlockKind.badge => 'New release',
    BlockKind.alert => 'You’re all set',
    BlockKind.toggle => 'Email notifications',
    BlockKind.checkbox => 'I agree to the terms',
    BlockKind.avatar => 'JD',
    BlockKind.chart => 'Weekly activity',
    _ => '',
  },
  detail: switch (kind) {
    BlockKind.input => 'you@example.com',
    BlockKind.card => 'A little space for your next big idea.',
    BlockKind.alert => 'Your changes have been saved.',
    BlockKind.chart => '12, 28, 18, 42, 32, 50, 38',
    _ => '',
  },
);

ScreenDocument templateDocument(String template) {
  ScreenBlock block(
    BlockKind kind,
    int id, {
    String? title,
    String? detail,
    double? value,
  }) => newBlock(
    kind,
    'block_$id',
  ).copyWith(title: title, detail: detail, value: value);
  return switch (template) {
    'Settings' => ScreenDocument(
      name: 'Your preferences',
      blocks: [
        block(BlockKind.heading, 0, title: 'Make it yours.'),
        block(
          BlockKind.text,
          1,
          title: 'A few small choices. A better everyday experience.',
        ),
        block(BlockKind.input, 2, title: 'Display name', detail: 'Alex Morgan'),
        block(BlockKind.divider, 3),
        block(BlockKind.toggle, 4, title: 'Product updates', value: 1),
        block(BlockKind.toggle, 5, title: 'Weekly digest', value: 0),
        block(BlockKind.button, 6, title: 'Save preferences'),
      ],
    ),
    'Dashboard' => ScreenDocument(
      name: 'Workspace overview',
      accent: 1,
      blocks: [
        block(BlockKind.badge, 0, title: 'Your workspace'),
        block(BlockKind.heading, 1, title: 'Looking good, Alex.'),
        block(BlockKind.text, 2, title: 'Here’s what’s happening this week.'),
        block(
          BlockKind.card,
          3,
          title: '2,840',
          detail: 'Total views · Last 7 days',
        ),
        block(BlockKind.chart, 4),
        block(
          BlockKind.alert,
          5,
          title: 'A little milestone',
          detail: 'Your first project is ready to share.',
        ),
      ],
    ),
    'Layouts' => ScreenDocument(
      name: 'A little room to grow',
      blocks: [
        block(BlockKind.heading, 0, title: 'Your workspace.'),
        block(BlockKind.row, 1),
        block(BlockKind.container, 2).copyWith(parentId: 'block_1'),
        block(BlockKind.container, 3).copyWith(parentId: 'block_1'),
        block(
          BlockKind.heading,
          4,
          title: 'Create',
        ).copyWith(parentId: 'block_2'),
        block(
          BlockKind.text,
          5,
          title: 'Make space for your next idea.',
        ).copyWith(parentId: 'block_2'),
        block(
          BlockKind.button,
          6,
          title: 'New project',
        ).copyWith(parentId: 'block_2'),
        block(
          BlockKind.heading,
          7,
          title: 'Connect',
        ).copyWith(parentId: 'block_3'),
        block(
          BlockKind.toggle,
          8,
          title: 'Weekly updates',
        ).copyWith(parentId: 'block_3'),
      ],
    ),
    'Blank' => ScreenDocument(blocks: []),
    _ => ScreenDocument(
      name: 'Welcome aboard',
      blocks: [
        block(BlockKind.badge, 0, title: 'A fresh start'),
        block(BlockKind.heading, 1, title: 'Welcome aboard.'),
        block(
          BlockKind.text,
          2,
          title: 'A space for your ideas to become something real.',
        ),
        block(BlockKind.input, 3, title: 'Full name', detail: 'Alex Morgan'),
        block(BlockKind.input, 4),
        block(BlockKind.button, 5, title: 'Create account'),
        block(
          BlockKind.text,
          6,
          title: 'Already part of the team? Welcome back.',
        ),
      ],
    ),
  };
}

class PlaygroundController extends ChangeNotifier {
  PlaygroundController([ScreenDocument? initial])
    : _document = initial ?? templateDocument('Welcome');
  ScreenDocument _document;
  final List<ScreenDocument> _past = [], _future = [];
  int _serial = 0;
  String? selectedId;
  ScreenDocument get document => _document;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  ScreenBlock? get selected => _document.find(selectedId);

  void select(String? id) {
    selectedId = _document.find(id)?.id;
    notifyListeners();
  }

  void commit(ScreenDocument next) {
    if (next.encode() == _document.encode()) return;
    _past.add(_document);
    if (_past.length > 50) _past.removeAt(0);
    _future.clear();
    _document = next;
    _reconcile();
  }

  void _reconcile() {
    if (selected == null) selectedId = null;
    notifyListeners();
  }

  String _id() {
    String id;
    do {
      id = 'node_${_serial++}';
    } while (_document.blocks.any((b) => b.id == id));
    return id;
  }

  String? get insertionParent =>
      selected?.kind.isLayout == true ? selectedId : selected?.parentId;

  bool canInsert(String? parentId) =>
      _document.blocks.length < 100 &&
      (parentId == null ||
          (_document.find(parentId)?.kind.isLayout == true &&
              _document.depthOf(parentId) < 7));

  void add(BlockKind kind, {Object? parentId = _unchangedParent, int? index}) {
    final parent = identical(parentId, _unchangedParent)
        ? insertionParent
        : parentId as String?;
    if (!canInsert(parent)) return;
    final block = newBlock(kind, _id()).copyWith(parentId: parent);
    final siblings = _document.childrenOf(parent);
    final position = index ?? siblings.length;
    if (position < 0 || position > siblings.length) return;
    final blocks = [..._document.blocks];
    blocks.insert(
      position == siblings.length
          ? blocks.length
          : blocks.indexOf(siblings[position]),
      block,
    );
    selectedId = block.id;
    commit(_document.copyWith(blocks: blocks));
  }

  void update(ScreenBlock block) {
    final current = _document.find(block.id);
    if (current == null ||
        current.kind != block.kind ||
        current.parentId != block.parentId) {
      return;
    }
    commit(
      _document.copyWith(
        blocks: [
          for (final current in _document.blocks)
            if (current.id == block.id) block else current,
        ],
      ),
    );
  }

  void remove(String id) {
    final ids = _document.subtreeIds(id);
    commit(
      _document.copyWith(
        blocks: _document.blocks.where((b) => !ids.contains(b.id)).toList(),
      ),
    );
  }

  bool canDuplicate(String id) =>
      _document.find(id) != null &&
      _document.blocks.length + _document.subtreeIds(id).length <= 100;

  void duplicate(String id) {
    if (!canDuplicate(id)) return;
    final ids = _document.subtreeIds(id);
    final copies = {for (final id in ids) id: _id()};
    final subtree = _document.orderedBlocks.where((b) => ids.contains(b.id));
    final blocks = [..._document.blocks];
    final clones = [
      for (final block in subtree)
        block.copyWith(
          id: copies[block.id],
          parentId: copies[block.parentId] ?? block.parentId,
        ),
    ];
    blocks.insertAll(blocks.indexWhere((b) => b.id == id) + 1, clones);
    selectedId = copies[id];
    commit(_document.copyWith(blocks: blocks));
  }

  bool canMove(String id, String? parentId) {
    final block = _document.find(id);
    if (block == null) return false;
    if (parentId != null && _document.find(parentId)?.kind.isLayout != true) {
      return false;
    }
    final subtree = _document.subtreeIds(id);
    if (subtree.contains(parentId)) return false;
    final height =
        subtree.map(_document.depthOf).reduce((a, b) => a > b ? a : b) -
        _document.depthOf(id);
    return (parentId == null ? 0 : _document.depthOf(parentId) + 1) + height <
        8;
  }

  void moveBlock(String id, {required String? parentId, required int index}) {
    if (!canMove(id, parentId)) return;
    final block = _document.find(id)!;
    if (block.parentId == parentId &&
        _document.childrenOf(parentId).indexOf(block) == index) {
      return;
    }
    final siblings = _document
        .childrenOf(parentId)
        .where((b) => b.id != id)
        .toList();
    if (index < 0 || index > siblings.length) return;
    final blocks = _document.blocks.where((b) => b.id != id).toList();
    blocks.insert(
      index == siblings.length
          ? blocks.length
          : blocks.indexOf(siblings[index]),
      block.copyWith(parentId: parentId),
    );
    commit(_document.copyWith(blocks: blocks));
  }

  void moveSibling(String id, int delta) {
    final block = _document.find(id);
    if (block == null) return;
    final siblings = _document.childrenOf(block.parentId);
    moveBlock(
      id,
      parentId: block.parentId,
      index: siblings.indexOf(block) + delta,
    );
  }

  void move(int from, int to) {
    final roots = _document.childrenOf(null);
    if (from < 0 || from >= roots.length || to < 0 || to >= roots.length) {
      return;
    }
    moveBlock(roots[from].id, parentId: null, index: to);
  }

  void undo() {
    if (!canUndo) return;
    _future.add(_document);
    _document = _past.removeLast();
    _reconcile();
  }

  void redo() {
    if (!canRedo) return;
    _past.add(_document);
    _document = _future.removeLast();
    _reconcile();
  }
}
