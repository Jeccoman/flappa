import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import 'button.dart';

/// Standard DataTable semantics, sorting, and selection with Flappa styling.
/// The owner supplies sorted rows when a column's onSort callback fires.
class FDataTable extends StatelessWidget {
  const FDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
  });
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<bool?>? onSelectAll;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    return ClipRRect(
      borderRadius: t.borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: t.colors.border),
          borderRadius: t.borderRadius,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : 0,
              ),
              child: DataTable(
                columns: columns,
                rows: rows,
                sortColumnIndex: sortColumnIndex,
                sortAscending: sortAscending,
                onSelectAll: onSelectAll,
                headingRowColor: WidgetStatePropertyAll(
                  t.colors.muted.withValues(alpha: .5),
                ),
                headingTextStyle: TextStyle(
                  color: t.colors.mutedForeground,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                dataTextStyle: TextStyle(
                  color: t.colors.foreground,
                  fontSize: 14,
                ),
                dividerThickness: 1,
                horizontalMargin: 16,
                columnSpacing: 28,
                headingRowHeight: 44,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FCarousel extends StatefulWidget {
  const FCarousel({
    super.key,
    required this.children,
    this.height = 240,
    this.onChanged,
  });
  final List<Widget> children;
  final double height;
  final ValueChanged<int>? onChanged;
  @override
  State<FCarousel> createState() => _FCarouselState();
}

class _FCarouselState extends State<FCarousel> {
  @override
  void initState() {
    super.initState();
    assert(widget.children.isNotEmpty);
  }

  final PageController _controller = PageController();
  int _index = 0;
  void _go(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant FCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.children.isNotEmpty);
    if (_index >= widget.children.length) {
      _index = widget.children.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.jumpToPage(_index);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: widget.height,
        child: PageView(
          controller: _controller,
          onPageChanged: (value) {
            setState(() => _index = value);
            widget.onChanged?.call(value);
          },
          children: widget.children,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FButton(
            onPressed: _index > 0 ? () => _go(_index - 1) : null,
            variant: FButtonVariant.outline,
            size: FButtonSize.icon,
            tooltip: 'Previous slide',
            child: const Icon(Icons.arrow_back),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                '${_index + 1} / ${widget.children.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: FTheme.of(context).colors.mutedForeground,
                ),
              ),
            ),
          ),
          FButton(
            onPressed: _index < widget.children.length - 1
                ? () => _go(_index + 1)
                : null,
            variant: FButtonVariant.outline,
            size: FButtonSize.icon,
            tooltip: 'Next slide',
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    ],
  );
}

/// Two panels with a draggable and keyboard-operable divider. Requires bounded
/// constraints along [axis]. The ratio is internally owned after initialization.
class FResizable extends StatefulWidget {
  const FResizable({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialRatio = .5,
    this.minRatio = .15,
    this.maxRatio = .85,
    this.onChanged,
  }) : assert(minRatio >= 0 && maxRatio <= 1 && minRatio < maxRatio),
       assert(initialRatio >= minRatio && initialRatio <= maxRatio);
  final Widget first, second;
  final Axis axis;
  final double initialRatio, minRatio, maxRatio;
  final ValueChanged<double>? onChanged;
  @override
  State<FResizable> createState() => _FResizableState();
}

class _FResizableState extends State<FResizable> {
  late double _ratio = widget.initialRatio;
  bool _focused = false;
  void _set(double ratio) {
    setState(() => _ratio = ratio.clamp(widget.minRatio, widget.maxRatio));
    widget.onChanged?.call(_ratio);
  }

  @override
  void didUpdateWidget(covariant FResizable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ratio = _ratio.clamp(widget.minRatio, widget.maxRatio);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = widget.axis == Axis.horizontal;
      final extent = horizontal ? constraints.maxWidth : constraints.maxHeight;
      assert(
        extent.isFinite && extent >= 12,
        'FResizable needs a bounded extent of at least 12 pixels.',
      );
      final available = math.max(0.0, extent - 12);
      final handle = Semantics(
        label: 'Resize panels',
        value: '${(_ratio * 100).round()}%',
        increasedValue:
            '${((_ratio + .05).clamp(widget.minRatio, widget.maxRatio) * 100).round()}%',
        decreasedValue:
            '${((_ratio - .05).clamp(widget.minRatio, widget.maxRatio) * 100).round()}%',
        onIncrease: () => _set(_ratio + .05),
        onDecrease: () => _set(_ratio - .05),
        child: Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final increase = horizontal
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowDown;
            final decrease = horizontal
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowUp;
            final direction =
                horizontal && Directionality.of(context) == TextDirection.rtl
                ? -1
                : 1;
            if (event.logicalKey == increase) {
              _set(_ratio + .05 * direction);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == decrease) {
              _set(_ratio - .05 * direction);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            cursor: horizontal
                ? SystemMouseCursors.resizeColumn
                : SystemMouseCursors.resizeRow,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: horizontal
                  ? (event) {
                      if (available > 0) {
                        _set(
                          _ratio +
                              event.delta.dx /
                                  available *
                                  (Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? -1
                                      : 1),
                        );
                      }
                    }
                  : null,
              onVerticalDragUpdate: horizontal
                  ? null
                  : (event) {
                      if (available > 0) {
                        _set(_ratio + event.delta.dy / available);
                      }
                    },
              child: Container(
                width: horizontal ? 12 : null,
                height: horizontal ? null : 12,
                color: _focused
                    ? FTheme.of(context).colors.ring.withValues(alpha: .2)
                    : FTheme.of(context).colors.muted,
                child: Center(
                  child: Icon(
                    horizontal ? Icons.drag_indicator : Icons.more_horiz,
                    size: 12,
                    color: FTheme.of(context).colors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return Flex(
        direction: widget.axis,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: horizontal ? available * _ratio : null,
            height: horizontal ? null : available * _ratio,
            child: ClipRect(child: widget.first),
          ),
          handle,
          Expanded(child: ClipRect(child: widget.second)),
        ],
      );
    },
  );
}

/// Lightweight sparkline/area chart. Values must be finite. Exposes a text
/// summary to screen readers; use a data table for detailed accessible values.
class FChart extends StatelessWidget {
  const FChart({
    super.key,
    required this.values,
    this.height = 160,
    this.color,
    this.fill = true,
    this.label = 'Trend',
  });
  final List<double> values;
  final double height;
  final Color? color;
  final bool fill;
  final String label;
  @override
  Widget build(BuildContext context) {
    assert(values.length >= 2);
    assert(values.every((value) => value.isFinite));
    return Semantics(
      label:
          '$label. ${values.length} values, from ${values.first} to ${values.last}. Minimum ${values.reduce(math.min)}, maximum ${values.reduce(math.max)}.',
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ChartPainter(
            values: List.of(values),
            color: color ?? FTheme.of(context).colors.primary,
            gridColor: FTheme.of(context).colors.border,
            fill: fill,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.fill,
  });
  final List<double> values;
  final Color color, gridColor;
  final bool fill;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final min = values.reduce(math.min), max = values.reduce(math.max);
    final range = max == min ? 1 : max - min;
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          i / (values.length - 1) * size.width,
          max == min
              ? size.height / 2
              : size.height -
                    8 -
                    (values[i] - min) / range * (size.height - 16),
        ),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    if (fill) {
      final area = Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: .18),
              color.withValues(alpha: .01),
            ],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.fill != fill ||
      oldDelegate.values.length != values.length ||
      Iterable<int>.generate(
        values.length,
      ).any((i) => values[i] != oldDelegate.values[i]);
}
