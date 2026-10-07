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
}

extension BlockLabel on BlockKind {
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
  };
}

class ScreenBlock {
  const ScreenBlock({
    required this.id,
    required this.kind,
    this.title = '',
    this.detail = '',
    this.value = .6,
    this.variant = 0,
  });
  final String id, title, detail;
  final BlockKind kind;
  final double value;
  final int variant;

  ScreenBlock copyWith({
    String? id,
    String? title,
    String? detail,
    double? value,
    int? variant,
  }) => ScreenBlock(
    id: id ?? this.id,
    kind: kind,
    title: title ?? this.title,
    detail: detail ?? this.detail,
    value: value ?? this.value,
    variant: variant ?? this.variant,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'detail': detail,
    'value': value,
    'variant': variant,
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
    'version': 1,
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
        json['version'] != 1 ||
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
    return ScreenDocument(
      name: json['name'],
      dark: json['dark'],
      accent: json['accent'],
      padding: dimension('padding', 64),
      gap: dimension('gap', 48),
      radius: dimension('radius', 24),
      blocks: blocks,
    );
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
  ScreenBlock? get selected =>
      _document.blocks.where((b) => b.id == selectedId).firstOrNull;

  void select(String? id) {
    selectedId = id;
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

  void add(BlockKind kind) {
    if (_document.blocks.length >= 100) return;
    final block = newBlock(kind, _id());
    selectedId = block.id;
    commit(_document.copyWith(blocks: [..._document.blocks, block]));
  }

  void update(ScreenBlock block) => commit(
    _document.copyWith(
      blocks: [
        for (final current in _document.blocks)
          if (current.id == block.id) block else current,
      ],
    ),
  );
  void remove(String id) => commit(
    _document.copyWith(
      blocks: _document.blocks.where((b) => b.id != id).toList(),
    ),
  );
  void duplicate(String id) {
    if (_document.blocks.length >= 100) return;
    final index = _document.blocks.indexWhere((b) => b.id == id);
    if (index < 0) return;
    final blocks = [..._document.blocks];
    final copy = blocks[index].copyWith(id: _id());
    blocks.insert(index + 1, copy);
    selectedId = copy.id;
    commit(_document.copyWith(blocks: blocks));
  }

  void move(int from, int to) {
    if (from < 0 ||
        from >= _document.blocks.length ||
        to < 0 ||
        to >= _document.blocks.length ||
        from == to) {
      return;
    }
    final blocks = [..._document.blocks];
    blocks.insert(to, blocks.removeAt(from));
    commit(_document.copyWith(blocks: blocks));
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
