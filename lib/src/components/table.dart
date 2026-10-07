import 'package:flutter/material.dart';
import '../theme/theme.dart';

class FTable extends StatelessWidget {
  const FTable({
    super.key,
    required this.headers,
    required this.rows,
    this.footer,
    this.caption,
    this.numericColumns = const {},
    this.minWidth = 480,
    this.striped = false,
  });
  final List<Widget> headers;
  final List<List<Widget>> rows;
  final List<Widget>? footer;
  final String? caption;
  final Set<int> numericColumns;
  final double minWidth;
  final bool striped;
  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty ||
        rows.any((row) => row.length != headers.length) ||
        (footer != null && footer!.length != headers.length)) {
      throw ArgumentError('Every table row must match the non-empty header.');
    }
    final t = FTheme.of(context);
    TableRow row(
      List<Widget> cells, {
      bool heading = false,
      bool summary = false,
      bool alternate = false,
    }) => TableRow(
      decoration: BoxDecoration(
        color: heading || summary || alternate
            ? t.colors.muted.withValues(alpha: .5)
            : null,
      ),
      children: [
        for (var i = 0; i < cells.length; i++)
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Semantics(
              header: heading,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Align(
                  alignment: numericColumns.contains(i)
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: heading ? 12 : 14,
                      fontWeight: heading || summary
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: heading
                          ? t.colors.mutedForeground
                          : t.colors.foreground,
                    ),
                    child: cells[i],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
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
                    minWidth: constraints.maxWidth > minWidth
                        ? constraints.maxWidth
                        : minWidth,
                  ),
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(flex: 1),
                    border: TableBorder(
                      horizontalInside: BorderSide(color: t.colors.border),
                    ),
                    children: [
                      row(headers, heading: true),
                      for (var i = 0; i < rows.length; i++)
                        row(rows[i], alternate: striped && i.isOdd),
                      if (footer != null) row(footer!, summary: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              caption!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: t.colors.mutedForeground),
            ),
          ),
      ],
    );
  }
}
