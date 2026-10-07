import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'button.dart';

class FChartDatum {
  const FChartDatum({required this.label, required this.value, this.color});
  final String label;
  final double value;
  final Color? color;
}

String _format(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
Color _color(BuildContext context, FChartDatum value, int index) =>
    value.color ??
    (index == 0
        ? FTheme.of(context).colors.primary
        : const [
            Color(0xFF3B82F6),
            Color(0xFF14B8A6),
            Color(0xFFF59E0B),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ][(index - 1) % 5]);
void _validate(List<FChartDatum> data, int? selected, {bool positive = false}) {
  if (data.any((d) => !d.value.isFinite || (positive && d.value < 0))) {
    throw ArgumentError(
      'Chart values must be finite${positive ? ' and non-negative' : ''}.',
    );
  }
  if (selected != null && (selected < 0 || selected >= data.length)) {
    throw RangeError.index(selected, data, 'selectedIndex');
  }
}

class FChartLegend extends StatelessWidget {
  const FChartLegend({
    super.key,
    required this.data,
    this.selectedIndex,
    this.onSelected,
    this.showValues = true,
    this.valueFormatter,
  });
  final List<FChartDatum> data;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;
  final bool showValues;
  final String Function(double)? valueFormatter;
  @override
  Widget build(BuildContext context) {
    _validate(data, selectedIndex);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < data.length; i++)
          Builder(
            builder: (context) {
              final marker = Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: _color(context, data[i], i),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
              final label = Text(
                '${data[i].label}${showValues ? ' · ${(valueFormatter ?? _format)(data[i].value)}' : ''}',
                style: const TextStyle(fontSize: 12),
              );
              if (onSelected == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      marker,
                      const SizedBox(width: 8),
                      Flexible(child: label),
                    ],
                  ),
                );
              }
              return Semantics(
                selected: selectedIndex == i,
                child: FButton(
                  onPressed: () => onSelected!(i),
                  variant: selectedIndex == i
                      ? FButtonVariant.secondary
                      : FButtonVariant.ghost,
                  size: FButtonSize.small,
                  leading: marker,
                  child: label,
                ),
              );
            },
          ),
      ],
    );
  }
}

class FBarChart extends StatelessWidget {
  const FBarChart({
    super.key,
    required this.data,
    this.height = 220,
    this.selectedIndex,
    this.onSelected,
    this.valueFormatter,
    this.label = 'Bar chart',
  }) : assert(height >= 100);
  final List<FChartDatum> data;
  final double height;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;
  final String Function(double)? valueFormatter;
  final String label;
  @override
  Widget build(BuildContext context) {
    _validate(data, selectedIndex);
    final c = FTheme.of(context).colors;
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No data', style: TextStyle(color: c.mutedForeground)),
        ),
      );
    }
    final scale = math.max(
      1.0,
      data.map((d) => d.value.abs()).reduce(math.max),
    );
    final low = math.min(
      0.0,
      data.map((d) => d.value / scale).reduce(math.min),
    );
    final high = math.max(
      0.0,
      data.map((d) => d.value / scale).reduce(math.max),
    );
    final range = high == low ? 1.0 : high - low;
    final plotHeight = height - 40;
    final zero = high / range * plotHeight;
    return Semantics(
      label: label,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(constraints.maxWidth, data.length * 52.0),
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < data.length; i++)
                  Expanded(
                    child: Semantics(
                      label:
                          '${data[i].label}: ${(valueFormatter ?? _format)(data[i].value)}',
                      selected: selectedIndex == i,
                      button: onSelected != null,
                      child: Tooltip(
                        message:
                            '${data[i].label}: ${(valueFormatter ?? _format)(data[i].value)}',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onSelected == null
                                ? null
                                : () => onSelected!(i),
                            child: ExcludeSemantics(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: plotHeight,
                                    child: Stack(
                                      children: [
                                        for (var tick = 0; tick <= 4; tick++)
                                          Positioned(
                                            top: tick * plotHeight / 4,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 1,
                                              color: c.border.withValues(
                                                alpha: .6,
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          top: zero.clamp(0, plotHeight - 1),
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 1,
                                            color: c.border,
                                          ),
                                        ),
                                        Positioned(
                                          left: 10,
                                          right: 10,
                                          top: data[i].value >= 0
                                              ? zero -
                                                    data[i].value /
                                                        scale /
                                                        range *
                                                        plotHeight
                                              : zero,
                                          height:
                                              data[i].value.abs() /
                                              scale /
                                              range *
                                              plotHeight,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: _color(context, data[i], i)
                                                  .withValues(
                                                    alpha:
                                                        selectedIndex == null ||
                                                            selectedIndex == i
                                                        ? 1
                                                        : .35,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      data[i].label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: c.mutedForeground,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FDonutChart extends StatelessWidget {
  const FDonutChart({
    super.key,
    required this.data,
    this.size = 220,
    this.thickness = 28,
    this.selectedIndex,
    this.onSelected,
    this.center,
    this.label = 'Donut chart',
  }) : assert(size > 0),
       assert(thickness > 0 && thickness < size / 2);
  final List<FChartDatum> data;
  final double size, thickness;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;
  final Widget? center;
  final String label;
  @override
  Widget build(BuildContext context) {
    _validate(data, selectedIndex, positive: true);
    final total = data.fold<double>(0, (sum, d) => sum + d.value);
    if (!total.isFinite) throw ArgumentError('Chart total must be finite.');
    final c = FTheme.of(context).colors;
    final colors = [
      for (var i = 0; i < data.length; i++)
        _color(context, data[i], i).withValues(
          alpha: selectedIndex == null || selectedIndex == i ? 1 : .35,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimension = math.min(size, constraints.maxWidth);
        final stroke = math.min(thickness, dimension / 3);
        return Center(
          child: Semantics(
            label:
                '$label. ${data.map((d) => '${d.label}: ${_format(d.value)}').join(', ')}',
            image: true,
            child: SizedBox.square(
              dimension: dimension,
              child: GestureDetector(
                onTapUp: onSelected == null
                    ? null
                    : (event) {
                        if (total == 0) return;
                        final offset =
                            event.localPosition -
                            Offset(dimension / 2, dimension / 2);
                        final distance = offset.distance;
                        if (distance < dimension / 2 - stroke ||
                            distance > dimension / 2) {
                          return;
                        }
                        final angle =
                            (math.atan2(offset.dy, offset.dx) + math.pi / 2) %
                            (math.pi * 2);
                        var end = 0.0;
                        for (var i = 0; i < data.length; i++) {
                          end += data[i].value / total * math.pi * 2;
                          if (angle < end) {
                            onSelected!(i);
                            break;
                          }
                        }
                      },
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: data.map((d) => d.value).toList(),
                    colors: colors,
                    background: c.muted,
                    thickness: stroke,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(stroke + 12),
                      child:
                          center ??
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                total == 0 ? 'No data' : _format(total),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.7,
                                ),
                              ),
                              if (total > 0)
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    color: c.mutedForeground,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.background,
    required this.thickness,
  });
  final List<double> values;
  final List<Color> colors;
  final Color background;
  final double thickness;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(thickness / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawOval(rect, paint..color = background);
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      if (sweep > 0) {
        canvas.drawArc(rect, start, sweep, false, paint..color = colors[i]);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.thickness != thickness ||
      oldDelegate.values.length != values.length ||
      Iterable<int>.generate(values.length).any(
        (i) =>
            oldDelegate.values[i] != values[i] ||
            oldDelegate.colors[i] != colors[i],
      );
}
