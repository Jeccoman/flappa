import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'canvas_editor.dart';
import 'document.dart';
import 'playground_page.dart' show blockIcon;
import 'studio_document.dart';
import 'studio_render.dart';

class CanvasPart extends StatelessWidget {
  const CanvasPart({
    super.key,
    required this.kind,
    required this.onAdd,
    this.touch = false,
    this.onDragStarted,
  });
  final BlockKind kind;
  final VoidCallback onAdd;
  final VoidCallback? onDragStarted;
  final bool touch;
  @override
  Widget build(BuildContext context) {
    final child = FButton(
      key: ValueKey('canvas-part-${kind.name}'),
      variant: FButtonVariant.outline,
      leading: Icon(blockIcon(kind), size: 16),
      onPressed: onAdd,
      child: Text(kind.label),
    );
    final feedback = Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(blockIcon(kind), size: 18),
            const SizedBox(width: 8),
            Text(kind.label),
          ],
        ),
      ),
    );
    final faded = Opacity(opacity: .35, child: child);
    return touch
        ? LongPressDraggable<BlockDrag>(
            data: BlockDrag.create(kind),
            onDragStarted: onDragStarted,
            delay: const Duration(milliseconds: 250),
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: feedback,
            childWhenDragging: faded,
            child: child,
          )
        : Draggable<BlockDrag>(
            data: BlockDrag.create(kind),
            onDragStarted: onDragStarted,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: feedback,
            childWhenDragging: faded,
            child: child,
          );
  }
}

class DraggableArtboard extends StatefulWidget {
  const DraggableArtboard({
    super.key,
    required this.screen,
    required this.controller,
  });
  final Artboard screen;
  final StudioController controller;
  @override
  State<DraggableArtboard> createState() => _DraggableArtboardState();
}

class _DraggableArtboardState extends State<DraggableArtboard> {
  late final _editor = PlaygroundController(widget.screen.document);
  @override
  void didUpdateWidget(DraggableArtboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.screen.document, widget.screen.document)) {
      _editor.commit(widget.screen.document);
    }
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DragTarget<BlockDrag>(
    key: ValueKey('screen-drop-${widget.screen.id}'),
    onWillAcceptWithDetails: (details) =>
        widget.controller.canDropBlock(details.data, widget.screen.id, null),
    onAcceptWithDetails: (details) => widget.controller.dropBlock(
      details.data,
      widget.screen.id,
      null,
      widget.screen.document.childrenOf(null).length,
    ),
    builder: (context, candidates, rejected) => Stack(
      children: [
        ArtboardContent(
          screen: widget.screen,
          content: ScreenCanvasContent(
            controller: _editor,
            interact: false,
            sourceId: widget.screen.id,
            showHandles: true,
            onSelect: (id) {
              widget.controller.select(widget.screen.id);
              setState(() => _editor.select(id));
            },
            canDrop: (drag, parentId) => widget.controller.canDropBlock(
              drag,
              widget.screen.id,
              parentId,
            ),
            onDrop: (drag, parentId, index) => widget.controller.dropBlock(
              drag,
              widget.screen.id,
              parentId,
              index,
            ),
          ),
        ),
        if (candidates.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: FTheme.of(context).colors.primary,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
