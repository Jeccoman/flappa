import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'document.dart';
import 'render.dart';

class BlockDrag {
  const BlockDrag.create(this.kind) : id = null, sourceId = null;
  const BlockDrag.move(this.id, {this.sourceId}) : kind = null;
  final BlockKind? kind;
  final String? id, sourceId;
}

class ScreenCanvasContent extends StatelessWidget {
  const ScreenCanvasContent({
    super.key,
    required this.controller,
    required this.interact,
    required this.onSelect,
    this.sourceId,
    this.canDrop,
    this.onDrop,
    this.showHandles = false,
  });
  final String? sourceId;
  final bool Function(BlockDrag, String?)? canDrop;
  final void Function(BlockDrag, String?, int)? onDrop;
  final bool showHandles;
  final PlaygroundController controller;
  final bool interact;
  final ValueChanged<String> onSelect;
  ScreenDocument get document => controller.document;

  Widget _slot(String? parentId, int index, {bool empty = false}) {
    return DragTarget<BlockDrag>(
      key: ValueKey('drop-${parentId ?? 'root'}-$index'),
      onWillAcceptWithDetails: (details) =>
          !interact &&
          (canDrop?.call(details.data, parentId) ??
              (details.data.sourceId == sourceId &&
                  (details.data.id == null
                      ? controller.canInsert(parentId)
                      : controller.canMove(details.data.id!, parentId)))),
      onAcceptWithDetails: (details) {
        final drag = details.data;
        if (onDrop != null) {
          onDrop!(drag, parentId, index);
          return;
        }
        if (drag.id == null) {
          controller.add(drag.kind!, parentId: parentId, index: index);
        } else {
          final siblings = document.childrenOf(parentId);
          final oldIndex = siblings.indexWhere((block) => block.id == drag.id);
          controller.moveBlock(
            drag.id!,
            parentId: parentId,
            index: oldIndex >= 0 && oldIndex < index ? index - 1 : index,
          );
        }
      },
      builder: (context, candidates, rejected) => Container(
        height: empty ? 64 : 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? Colors.transparent
              : FTheme.of(context).colors.primary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(4),
          border: candidates.isEmpty
              ? null
              : Border.all(color: FTheme.of(context).colors.primary),
        ),
        child: empty
            ? Text(
                parentId == null
                    ? 'Add a block or drop one here.'
                    : 'Drop blocks here, or select this layout and add blocks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: FTheme.of(context).colors.mutedForeground,
                ),
              )
            : showHandles
            ? Container(height: 1, color: FTheme.of(context).colors.border)
            : null,
      ),
    );
  }

  List<Widget> _children(String? parentId) {
    final blocks = document.childrenOf(parentId);
    if (blocks.isEmpty && !interact) return [_slot(parentId, 0, empty: true)];
    return [
      for (final (index, block) in blocks.indexed)
        if (interact)
          _block(block)
        else
          Column(
            key: ValueKey('position-${block.id}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _slot(parentId, index),
              _block(block),
              if (index == blocks.length - 1) _slot(parentId, index + 1),
            ],
          ),
    ];
  }

  Widget _block(ScreenBlock block) => Builder(
    builder: (context) {
      final selected = controller.selectedId == block.id;
      final content = ScreenBlockView(
        key: ValueKey('view-${block.id}'),
        block: block,
        children: block.kind.isLayout ? _children(block.id) : const [],
      );
      if (interact) return content;
      final colors = FTheme.of(context).colors;
      void select() => onSelect(block.id);
      final selectable = block.kind.isLayout
          ? content
          : Semantics(
              button: true,
              label: 'Select ${block.kind.label}: ${block.title}',
              selected: selected,
              onTap: select,
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: select,
                  child: AbsorbPointer(child: content),
                ),
              ),
            );
      return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.enter): select},
        child: Focus(
          child: Container(
            key: ValueKey('canvas-${block.id}'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(document.radius),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : block.kind.isLayout
                    ? colors.border
                    : Colors.transparent,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHandles || selected || block.kind.isLayout)
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          onPressed: select,
                          variant: FButtonVariant.ghost,
                          size: FButtonSize.small,
                          child: Text(
                            document.labelFor(block),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Draggable<BlockDrag>(
                        data: BlockDrag.move(block.id, sourceId: sourceId),
                        dragAnchorStrategy: pointerDragAnchorStrategy,
                        feedback: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('Move ${block.kind.label}'),
                          ),
                        ),
                        child: Tooltip(
                          message: 'Drag to move ${block.kind.label}',
                          child: Semantics(
                            label:
                                'Drag to move ${block.kind.label}. Move controls are in ${sourceId == null ? 'Properties' : 'Edit components'}.',
                            child: SizedBox(
                              key: ValueKey('drag-${block.id}'),
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.drag_indicator,
                                size: 18,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                selectable,
              ],
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final children = _children(null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) SizedBox(height: document.gap),
          child,
        ],
      ],
    );
  }
}
