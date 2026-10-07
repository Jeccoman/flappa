import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import 'button.dart';

class FTab {
  const FTab({required this.label, required this.child, this.icon});
  final String label;
  final Widget child;
  final IconData? icon;
}

/// Controlled tabs. Arrow keys, Home, and End move the selected tab.
class FTabs extends StatelessWidget {
  const FTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });
  final List<FTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    assert(tabs.isNotEmpty && index >= 0 && index < tabs.length);
    final t = FTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final rtl = Directionality.of(context) == TextDirection.rtl;
            final delta = event.logicalKey == LogicalKeyboardKey.arrowRight
                ? (rtl ? -1 : 1)
                : event.logicalKey == LogicalKeyboardKey.arrowLeft
                ? (rtl ? 1 : -1)
                : 0;
            if (delta != 0) {
              onChanged((index + delta) % tabs.length);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.home) {
              onChanged(0);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.end) {
              onChanged(tabs.length - 1);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: t.colors.muted,
              borderRadius: t.borderRadius,
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: index == i,
                      child: Container(
                        decoration: BoxDecoration(
                          color: index == i
                              ? t.colors.background
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            (t.radius - 3).clamp(0, double.infinity),
                          ),
                          boxShadow: index == i
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .06),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: FButton(
                          variant: FButtonVariant.ghost,
                          size: FButtonSize.small,
                          onPressed: () => onChanged(i),
                          leading: tabs[i].icon == null
                              ? null
                              : Icon(tabs[i].icon),
                          child: Text(
                            tabs[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        KeyedSubtree(key: ValueKey(index), child: tabs[index].child),
      ],
    );
  }
}

class FAccordionItem {
  const FAccordionItem({
    required this.id,
    required this.title,
    required this.child,
  });
  final String id;
  final Widget title, child;
}

class FAccordion extends StatefulWidget {
  const FAccordion({
    super.key,
    required this.items,
    this.multiple = false,
    this.initiallyExpanded = const {},
    this.onChanged,
  });
  final List<FAccordionItem> items;
  final bool multiple;
  final Set<String> initiallyExpanded;
  final ValueChanged<Set<String>>? onChanged;
  @override
  State<FAccordion> createState() => _FAccordionState();
}

class _FAccordionState extends State<FAccordion> {
  late final Set<String> _expanded = widget.multiple
      ? {...widget.initiallyExpanded}
      : widget.initiallyExpanded.take(1).toSet();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final item in widget.items)
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: FTheme.of(context).colors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                expanded: _expanded.contains(item.id),
                child: FButton(
                  variant: FButtonVariant.ghost,
                  onPressed: () {
                    setState(() {
                      if (_expanded.contains(item.id)) {
                        _expanded.remove(item.id);
                      } else {
                        if (!widget.multiple) _expanded.clear();
                        _expanded.add(item.id);
                      }
                    });
                    widget.onChanged?.call(Set.unmodifiable(_expanded));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(child: item.title),
                        Icon(
                          _expanded.contains(item.id)
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_expanded.contains(item.id))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: item.child,
                ),
            ],
          ),
        ),
    ],
  );
}

class FCollapsible extends StatelessWidget {
  const FCollapsible({
    super.key,
    required this.expanded,
    required this.onChanged,
    required this.title,
    required this.child,
  });
  final bool expanded;
  final ValueChanged<bool> onChanged;
  final Widget title, child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        expanded: expanded,
        child: FButton(
          variant: FButtonVariant.ghost,
          onPressed: () => onChanged(!expanded),
          trailing: Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
          child: title,
        ),
      ),
      if (expanded)
        Padding(padding: const EdgeInsets.only(top: 12), child: child),
    ],
  );
}

class FBreadcrumbItem {
  const FBreadcrumbItem(this.label, {this.onPressed});
  final String label;
  final VoidCallback? onPressed;
}

class FBreadcrumb extends StatelessWidget {
  const FBreadcrumb({super.key, required this.items});
  final List<FBreadcrumbItem> items;
  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0)
          Icon(
            Icons.chevron_right,
            size: 14,
            color: FTheme.of(context).colors.mutedForeground,
          ),
        if (items[i].onPressed != null)
          FButton(
            onPressed: items[i].onPressed,
            variant: FButtonVariant.link,
            size: FButtonSize.small,
            child: Text(items[i].label),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              items[i].label,
              style: TextStyle(
                fontSize: 14,
                color: i == items.length - 1
                    ? FTheme.of(context).colors.foreground
                    : FTheme.of(context).colors.mutedForeground,
              ),
            ),
          ),
      ],
    ],
  );
}

/// One-based pagination with a compact window for large data sets.
class FPagination extends StatelessWidget {
  const FPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
  }) : assert(pageCount > 0),
       assert(page > 0 && page <= pageCount);
  final int page, pageCount;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final pages = {
      1,
      pageCount,
      for (var p = page - 1; p <= page + 1; p++)
        if (p > 0 && p <= pageCount) p,
    }.toList()..sort();
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FButton(
          onPressed: page == 1 ? null : () => onChanged(page - 1),
          variant: FButtonVariant.ghost,
          size: FButtonSize.icon,
          tooltip: 'Previous page',
          child: const Icon(Icons.chevron_left),
        ),
        for (var i = 0; i < pages.length; i++) ...[
          if (i > 0 && pages[i] - pages[i - 1] > 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('…'),
            ),
          Semantics(
            selected: pages[i] == page,
            label: 'Page ${pages[i]}',
            child: FButton(
              onPressed: () => onChanged(pages[i]),
              variant: pages[i] == page
                  ? FButtonVariant.outline
                  : FButtonVariant.ghost,
              size: FButtonSize.icon,
              child: Text('${pages[i]}'),
            ),
          ),
        ],
        FButton(
          onPressed: page == pageCount ? null : () => onChanged(page + 1),
          variant: FButtonVariant.ghost,
          size: FButtonSize.icon,
          tooltip: 'Next page',
          child: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class FNavigationItem {
  const FNavigationItem({required this.label, this.icon, this.badge});
  final String label;
  final IconData? icon;
  final Widget? badge;
}

class FNavigationMenu extends StatelessWidget {
  const FNavigationMenu({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.axis = Axis.horizontal,
  });
  final List<FNavigationItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final Axis axis;
  @override
  Widget build(BuildContext context) {
    final children = [
      for (var i = 0; i < items.length; i++)
        Semantics(
          selected: index == i,
          child: FButton(
            onPressed: () => onChanged(i),
            variant: index == i
                ? FButtonVariant.secondary
                : FButtonVariant.ghost,
            leading: items[i].icon == null ? null : Icon(items[i].icon),
            trailing: items[i].badge,
            child: axis == Axis.vertical
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(items[i].label),
                  )
                : Text(items[i].label),
          ),
        ),
    ];
    return axis == Axis.horizontal
        ? Wrap(spacing: 4, runSpacing: 4, children: children)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: child,
                  ),
                )
                .toList(),
          );
  }
}

class FSidebar extends StatelessWidget {
  const FSidebar({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.width = 240,
  });
  final Widget child;
  final Widget? header, footer;
  final double width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    decoration: BoxDecoration(
      color: FTheme.of(context).colors.card,
      border: BorderDirectional(
        end: BorderSide(color: FTheme.of(context).colors.border),
      ),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(padding: const EdgeInsets.all(20), child: header!),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
          if (footer != null)
            Padding(padding: const EdgeInsets.all(16), child: footer!),
        ],
      ),
    ),
  );
}
