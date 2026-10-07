import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import 'button.dart';
import 'forms.dart';

Future<T?> showFDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  builder: builder,
  barrierDismissible: barrierDismissible,
);

class FDialog extends StatelessWidget {
  const FDialog({
    super.key,
    required this.title,
    this.description,
    required this.child,
    this.actions = const [],
    this.maxWidth = 480,
    this.showClose = true,
  });
  final String title;
  final String? description;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool showClose;
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(24),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showClose)
                  FButton(
                    onPressed: () => Navigator.of(context).pop(),
                    variant: FButtonVariant.ghost,
                    size: FButtonSize.icon,
                    tooltip: 'Close dialog',
                    child: const Icon(Icons.close),
                  ),
              ],
            ),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  description!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: FTheme.of(context).colors.mutedForeground,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            child,
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> showFConfirm({
  required BuildContext context,
  required String title,
  required String description,
  String confirmLabel = 'Continue',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async =>
    await showFDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FDialog(
        title: title,
        showClose: false,
        actions: [
          FButton(
            onPressed: () => Navigator.pop(context, false),
            variant: FButtonVariant.outline,
            autofocus: true,
            child: Text(cancelLabel),
          ),
          FButton(
            onPressed: () => Navigator.pop(context, true),
            variant: destructive
                ? FButtonVariant.destructive
                : FButtonVariant.primary,
            child: Text(confirmLabel),
          ),
        ],
        child: Text(
          description,
          style: TextStyle(
            color: FTheme.of(context).colors.mutedForeground,
            height: 1.5,
          ),
        ),
      ),
    ) ??
    false;

enum FSheetSide { left, right, bottom }

Future<T?> showFSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  FSheetSide side = FSheetSide.right,
  double width = 400,
  String barrierLabel = 'Close panel',
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: barrierLabel,
  barrierColor: Colors.black.withValues(alpha: .45),
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 220),
  pageBuilder: (context, animation, secondary) {
    final t = FTheme.of(context);
    final bottom = side == FSheetSide.bottom;
    return Align(
      alignment: switch (side) {
        FSheetSide.left => Alignment.centerLeft,
        FSheetSide.right => Alignment.centerRight,
        FSheetSide.bottom => Alignment.bottomCenter,
      },
      child: Material(
        color: t.colors.card,
        child: SafeArea(
          child: Container(
            width: bottom
                ? double.infinity
                : width.clamp(0, MediaQuery.sizeOf(context).width),
            constraints: bottom
                ? BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .85,
                  )
                : null,
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: bottom ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FButton(
                    onPressed: () => Navigator.pop(context),
                    variant: FButtonVariant.ghost,
                    size: FButtonSize.icon,
                    tooltip: 'Close panel',
                    child: const Icon(Icons.close),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(child: SingleChildScrollView(child: builder(context))),
              ],
            ),
          ),
        ),
      ),
    );
  },
  transitionBuilder: (context, animation, secondary, child) => SlideTransition(
    position: Tween<Offset>(
      begin: switch (side) {
        FSheetSide.left => const Offset(-1, 0),
        FSheetSide.right => const Offset(1, 0),
        FSheetSide.bottom => const Offset(0, 1),
      },
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  ),
);

class FMenuItem<T> {
  const FMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.destructive = false,
  });
  final T value;
  final String label;
  final IconData? icon;
  final bool enabled, destructive;
}

class FDropdownMenu<T> extends StatelessWidget {
  const FDropdownMenu({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
    this.tooltip = 'Open menu',
  });
  final List<FMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget child;
  final String tooltip;
  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    tooltip: tooltip,
    onSelected: onSelected,
    position: PopupMenuPosition.under,
    itemBuilder: (context) => [
      for (final item in items)
        PopupMenuItem<T>(
          value: item.value,
          enabled: item.enabled,
          child: IconTheme.merge(
            data: IconThemeData(
              size: 16,
              color: item.destructive
                  ? FTheme.of(context).colors.destructive
                  : null,
            ),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon),
                  const SizedBox(width: 10),
                ],
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.destructive
                        ? FTheme.of(context).colors.destructive
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
    child: child,
  );
}

/// An anchored, dismissible panel. The builder receives a toggle callback.
class FPopover extends StatelessWidget {
  const FPopover({
    super.key,
    required this.builder,
    required this.child,
    this.width = 280,
  });
  final Widget Function(BuildContext, VoidCallback) builder;
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.colors.card),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(16)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: t.borderRadius,
            side: BorderSide(color: t.colors.border),
          ),
        ),
      ),
      menuChildren: [SizedBox(width: width, child: child)],
      builder: (context, controller, child) => builder(
        context,
        () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

void showFToast(
  BuildContext context, {
  required String title,
  String? description,
  bool destructive = false,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final t = FTheme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: t.borderRadius,
        side: BorderSide(
          color: destructive ? t.colors.destructive : t.colors.border,
        ),
      ),
      content: Row(
        children: [
          Icon(
            destructive ? Icons.error_outline : Icons.check_circle_outline,
            size: 20,
            color: destructive ? t.colors.destructive : t.colors.foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: t.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null)
                  Text(
                    description,
                    style: TextStyle(
                      color: t.colors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: t.colors.primary,
              onPressed: onAction,
            )
          : null,
    ),
  );
}

class FCommandItem<T> {
  const FCommandItem({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.keywords = const [],
  });
  final T value;
  final String label;
  final String? description;
  final IconData? icon;
  final List<String> keywords;
}

Future<T?> showFCommand<T>({
  required BuildContext context,
  required List<FCommandItem<T>> items,
  String placeholder = 'Type a command or search…',
}) => showFDialog<T>(
  context: context,
  builder: (context) => Dialog(
    child: SizedBox(
      width: 480,
      child: FCommand<T>(
        items: items,
        placeholder: placeholder,
        onSelected: (value) => Navigator.pop(context, value),
      ),
    ),
  ),
);

class FCommand<T> extends StatefulWidget {
  const FCommand({
    super.key,
    required this.items,
    required this.onSelected,
    this.placeholder = 'Type a command or search…',
  });
  final List<FCommandItem<T>> items;
  final ValueChanged<T> onSelected;
  final String placeholder;
  @override
  State<FCommand<T>> createState() => _FCommandState<T>();
}

class _FCommandState<T> extends State<FCommand<T>> {
  String _query = '';
  int _active = 0;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where(
          (item) =>
              '${item.label} ${item.description ?? ''} ${item.keywords.join(' ')}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    final active = filtered.isEmpty ? 0 : _active.clamp(0, filtered.length - 1);
    final t = FTheme.of(context);
    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent || filtered.isEmpty) {
          return KeyEventResult.ignored;
        }
        final delta = event.logicalKey == LogicalKeyboardKey.arrowDown
            ? 1
            : event.logicalKey == LogicalKeyboardKey.arrowUp
            ? -1
            : 0;
        if (delta == 0) return KeyEventResult.ignored;
        setState(() => _active = (active + delta) % filtered.length);
        if (_scroll.hasClients) {
          _scroll.jumpTo(
            (_active * 64.0).clamp(0, _scroll.position.maxScrollExtent),
          );
        }
        return KeyEventResult.handled;
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FInput(
              autofocus: true,
              placeholder: widget.placeholder,
              prefix: const Icon(Icons.search, size: 18),
              onChanged: (value) => setState(() {
                _query = value;
                _active = 0;
              }),
              onSubmitted: (_) {
                if (filtered.isNotEmpty) {
                  widget.onSelected(filtered[active].value);
                }
              },
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No results found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.colors.mutedForeground),
                ),
              )
            else
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    controller: _scroll,
                    itemExtent: 64,
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        selected: index == active,
                        selectedColor: t.colors.foreground,
                        selectedTileColor: t.colors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: t.borderRadius,
                        ),
                        leading: item.icon == null
                            ? null
                            : Icon(item.icon, size: 18),
                        title: Text(
                          item.label,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: item.description == null
                            ? null
                            : Text(
                                item.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                        onTap: () => widget.onSelected(item.value),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A right-click, long-press, or Shift+F10 menu around arbitrary content.
class FContextMenu<T> extends StatelessWidget {
  const FContextMenu({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
  });
  final List<FMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget child;

  Future<void> _open(BuildContext context, Offset position) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final point = overlay.globalToLocal(position);
    final result = await showMenu<T>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(point.dx, point.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            enabled: item.enabled,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 16,
                    color: item.destructive
                        ? FTheme.of(context).colors.destructive
                        : null,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.destructive
                        ? FTheme.of(context).colors.destructive
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) => Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            ((event.logicalKey == LogicalKeyboardKey.f10 &&
                    HardwareKeyboard.instance.isShiftPressed) ||
                event.logicalKey == LogicalKeyboardKey.contextMenu)) {
          final box = context.findRenderObject()! as RenderBox;
          _open(context, box.localToGlobal(box.size.center(Offset.zero)));
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapUp: (event) => _open(context, event.globalPosition),
        onLongPressStart: (event) => _open(context, event.globalPosition),
        child: child,
      ),
    ),
  );
}

class FMenu<T> {
  const FMenu({required this.label, required this.items});
  final String label;
  final List<FMenuItem<T>> items;
}

/// A native menu bar with arrow-key navigation and disabled/destructive items.
class FMenubar<T> extends StatelessWidget {
  const FMenubar({super.key, required this.menus, required this.onSelected});
  final List<FMenu<T>> menus;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    final style = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(t.colors.card),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: t.borderRadius,
          side: BorderSide(color: t.colors.border),
        ),
      ),
    );
    return MenuBar(
      style: style,
      children: [
        for (final menu in menus)
          SubmenuButton(
            menuStyle: style,
            menuChildren: [
              for (final item in menu.items)
                MenuItemButton(
                  onPressed: item.enabled ? () => onSelected(item.value) : null,
                  leadingIcon: item.icon == null
                      ? null
                      : Icon(item.icon, size: 16),
                  style: item.destructive
                      ? ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(
                            t.colors.destructive,
                          ),
                        )
                      : null,
                  child: Text(item.label, style: const TextStyle(fontSize: 14)),
                ),
            ],
            child: Text(menu.label, style: const TextStyle(fontSize: 14)),
          ),
      ],
    );
  }
}

/// Supplementary content revealed by hover, focus, or a tap. Prefer a dialog or
/// popover when the content is required to complete a task.
class FHoverCard extends StatefulWidget {
  const FHoverCard({
    super.key,
    required this.child,
    required this.content,
    this.width = 280,
    this.openDelay = const Duration(milliseconds: 250),
    this.closeDelay = const Duration(milliseconds: 150),
  });
  final Widget child, content;
  final double width;
  final Duration openDelay, closeDelay;
  @override
  State<FHoverCard> createState() => _FHoverCardState();
}

class _FHoverCardState extends State<FHoverCard> {
  final _controller = MenuController();
  Timer? _timer;
  void _open() {
    _timer?.cancel();
    _timer = Timer(widget.openDelay, () {
      if (mounted && !_controller.isOpen) _controller.open();
    });
  }

  void _close() {
    _timer?.cancel();
    _timer = Timer(widget.closeDelay, () {
      if (mounted && _controller.isOpen) _controller.close();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    return MenuAnchor(
      controller: _controller,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.colors.card),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: t.borderRadius,
            side: BorderSide(color: t.colors.border),
          ),
        ),
      ),
      menuChildren: [
        MouseRegion(
          onEnter: (_) => _timer?.cancel(),
          onExit: (_) => _close(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: widget.width, child: widget.content),
          ),
        ),
      ],
      builder: (context, controller, _) => MouseRegion(
        onEnter: (_) => _open(),
        onExit: (_) => _close(),
        child: Focus(
          onFocusChange: (focused) => focused ? _open() : _close(),
          child: GestureDetector(
            onTap: () {
              _timer?.cancel();
              controller.isOpen ? controller.close() : controller.open();
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

Future<T?> showFDrawer<T>({
  required BuildContext context,
  required ScrollableWidgetBuilder builder,
  double initialChildSize = .55,
  double minChildSize = .25,
  double maxChildSize = .95,
}) {
  assert(
    minChildSize > 0 &&
        minChildSize <= initialChildSize &&
        initialChildSize <= maxChildSize &&
        maxChildSize <= 1,
  );
  final t = FTheme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: t.colors.card,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(t.radius + 8)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        builder: builder,
      ),
    ),
  );
}

class FDrawer extends StatelessWidget {
  const FDrawer({
    super.key,
    required this.title,
    required this.controller,
    required this.child,
    this.description,
    this.actions = const [],
  });
  final String title;
  final String? description;
  final ScrollController controller;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    FButton(
                      onPressed: () => Navigator.pop(context),
                      variant: FButtonVariant.ghost,
                      size: FButtonSize.icon,
                      tooltip: 'Close drawer',
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      description!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: FTheme.of(context).colors.mutedForeground,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ),
      ],
    ),
  );
}
