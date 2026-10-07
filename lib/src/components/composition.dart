import 'package:flutter/material.dart';
import '../theme/theme.dart';

class FButtonGroup extends StatelessWidget {
  const FButtonGroup({
    super.key,
    required this.children,
    this.axis = Axis.horizontal,
    this.label,
  });
  final List<Widget> children;
  final Axis axis;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final horizontal = axis == Axis.horizontal;
    final content = Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            SizedBox(
              width: horizontal ? 1 : null,
              height: horizontal ? null : 1,
              child: ColoredBox(color: theme.colors.border),
            ),
          children[i],
        ],
      ],
    );
    return Semantics(
      container: true,
      label: label,
      child: ClipRRect(
        borderRadius: theme.borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: theme.borderRadius,
            border: Border.all(color: theme.colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Theme(
              data: Theme.of(context).copyWith(
                extensions: [
                  ...Theme.of(context).extensions.values.where(
                    (extension) => extension is! FThemeData,
                  ),
                  theme.copyWith(radius: 0),
                ],
              ),
              child: horizontal
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: IntrinsicHeight(child: content),
                    )
                  : IntrinsicWidth(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class FInputGroup extends StatefulWidget {
  const FInputGroup({
    super.key,
    required this.child,
    this.leading,
    this.trailing,
    this.header,
    this.footer,
    this.errorText,
    this.enabled = true,
  });
  final Widget child;
  final Widget? leading, trailing, header, footer;
  final String? errorText;
  final bool enabled;
  @override
  State<FInputGroup> createState() => _FInputGroupState();
}

class _FInputGroupState extends State<FInputGroup> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final c = theme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          canRequestFocus: false,
          onFocusChange: (value) => setState(() => _focused = value),
          child: Container(
            decoration: BoxDecoration(
              color: widget.enabled ? c.background : c.muted,
              borderRadius: theme.borderRadius,
              border: Border.all(
                color: widget.errorText != null
                    ? c.destructive
                    : _focused
                    ? c.ring
                    : c.border,
                width: _focused ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(_focused ? 0 : 1),
              child: IgnorePointer(
                ignoring: !widget.enabled,
                child: ExcludeFocus(
                  excluding: !widget.enabled,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: Theme.of(context)
                          .inputDecorationTheme
                          .copyWith(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                          ),
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(size: 18, color: c.mutedForeground),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 13,
                          color: c.mutedForeground,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.header != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  0,
                                ),
                                child: widget.header!,
                              ),
                            Row(
                              children: [
                                if (widget.leading != null)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 12,
                                    ),
                                    child: widget.leading!,
                                  ),
                                Expanded(child: widget.child),
                                if (widget.trailing != null)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 8,
                                    ),
                                    child: widget.trailing!,
                                  ),
                              ],
                            ),
                            if (widget.footer != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  10,
                                ),
                                child: widget.footer!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              liveRegion: true,
              child: Text(
                widget.errorText!,
                style: TextStyle(color: c.destructive, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class FLabel extends StatelessWidget {
  const FLabel(
    this.text, {
    super.key,
    this.required = false,
    this.enabled = true,
    this.focusNode,
  });
  final String text;
  final bool required, enabled;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    final child = Text(
      '$text${required ? ' *' : ''}',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: enabled
            ? FTheme.of(context).colors.foreground
            : FTheme.of(context).colors.mutedForeground,
      ),
    );
    return focusNode == null
        ? child
        : Semantics(
            button: enabled,
            child: GestureDetector(
              onTap: enabled ? focusNode!.requestFocus : null,
              child: MouseRegion(
                cursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: child,
              ),
            ),
          );
  }
}

class FFieldSet extends StatelessWidget {
  const FFieldSet({
    super.key,
    required this.legend,
    required this.children,
    this.description,
    this.spacing = 20,
  });
  final String legend;
  final String? description;
  final List<Widget> children;
  final double spacing;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            legend,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              description!,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: FTheme.of(context).colors.mutedForeground,
              ),
            ),
          ),
        for (final child in children)
          Padding(
            padding: EdgeInsets.only(top: spacing),
            child: child,
          ),
      ],
    ),
  );
}

enum FItemVariant { plain, outline, muted }

class FItem extends StatelessWidget {
  const FItem({
    super.key,
    required this.title,
    this.description,
    this.leading,
    this.trailing,
    this.footer,
    this.onPressed,
    this.variant = FItemVariant.outline,
    this.enabled = true,
  });
  final Widget title;
  final Widget? description, leading, trailing, footer;
  final VoidCallback? onPressed;
  final FItemVariant variant;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    return Semantics(
      button: onPressed != null,
      enabled: onPressed == null ? null : enabled,
      child: Material(
        color: variant == FItemVariant.muted ? t.colors.muted : t.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: t.borderRadius,
          side: BorderSide(
            color: variant == FItemVariant.outline
                ? t.colors.border
                : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Opacity(
              opacity: enabled ? 1 : .5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (leading != null) ...[
                        IconTheme.merge(
                          data: const IconThemeData(size: 20),
                          child: leading!,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DefaultTextStyle.merge(
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              child: title,
                            ),
                            if (description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: DefaultTextStyle.merge(
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: t.colors.mutedForeground,
                                  ),
                                  child: description!,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 12),
                        trailing!,
                      ],
                    ],
                  ),
                  if (footer != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: footer!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FItemGroup extends StatelessWidget {
  const FItemGroup({
    super.key,
    required this.children,
    this.spacing = 8,
    this.dividers = false,
  });
  final List<Widget> children;
  final double spacing;
  final bool dividers;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0)
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing / 2),
            child: dividers ? const Divider() : const SizedBox.shrink(),
          ),
        children[i],
      ],
    ],
  );
}

class FAspectRatio extends StatelessWidget {
  const FAspectRatio({super.key, required this.child, this.ratio = 16 / 9})
    : assert(ratio > 0 && ratio < double.infinity);
  final Widget child;
  final double ratio;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: FTheme.of(context).borderRadius,
    child: AspectRatio(
      aspectRatio: ratio,
      child: ColoredBox(color: FTheme.of(context).colors.muted, child: child),
    ),
  );
}

enum FTypographyVariant {
  h1,
  h2,
  h3,
  h4,
  paragraph,
  lead,
  large,
  small,
  muted,
  quote,
  code,
}

class FTypography extends StatelessWidget {
  const FTypography(
    this.text, {
    super.key,
    this.variant = FTypographyVariant.paragraph,
    this.textAlign,
    this.selectable = false,
  });
  final String text;
  final FTypographyVariant variant;
  final TextAlign? textAlign;
  final bool selectable;
  @override
  Widget build(BuildContext context) {
    final c = FTheme.of(context).colors;
    final heading = {
      FTypographyVariant.h1,
      FTypographyVariant.h2,
      FTypographyVariant.h3,
      FTypographyVariant.h4,
    }.contains(variant);
    final size = switch (variant) {
      FTypographyVariant.h1 => 36.0,
      FTypographyVariant.h2 => 30.0,
      FTypographyVariant.h3 => 24.0,
      FTypographyVariant.h4 => 20.0,
      FTypographyVariant.lead => 20.0,
      FTypographyVariant.large => 18.0,
      FTypographyVariant.small ||
      FTypographyVariant.muted ||
      FTypographyVariant.code => 13.0,
      _ => 14.0,
    };
    final style = TextStyle(
      fontSize: size,
      height: heading ? 1.2 : 1.65,
      fontWeight: heading || variant == FTypographyVariant.large
          ? FontWeight.w600
          : FontWeight.w400,
      letterSpacing: heading ? -.7 : 0,
      fontStyle: variant == FTypographyVariant.quote
          ? FontStyle.italic
          : FontStyle.normal,
      fontFamily: variant == FTypographyVariant.code ? 'monospace' : null,
      color:
          variant == FTypographyVariant.muted ||
              variant == FTypographyVariant.lead
          ? c.mutedForeground
          : c.foreground,
    );
    Widget child = selectable
        ? SelectableText(text, style: style, textAlign: textAlign)
        : Text(text, style: style, textAlign: textAlign);
    if (variant == FTypographyVariant.quote) {
      child = Container(
        padding: const EdgeInsetsDirectional.only(start: 16),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: c.border, width: 3),
          ),
        ),
        child: child,
      );
    }
    if (variant == FTypographyVariant.code) {
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: c.muted,
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      );
    }
    return Semantics(header: heading, child: child);
  }
}

enum FMarkerVariant { inline, border, separator }

class FMarker extends StatelessWidget {
  const FMarker({
    super.key,
    required this.label,
    this.icon,
    this.variant = FMarkerVariant.inline,
    this.live = false,
    this.onPressed,
  });
  final String label;
  final Widget? icon;
  final FMarkerVariant variant;
  final bool live;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final c = FTheme.of(context).colors;
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(
              child: IconTheme.merge(
                data: IconThemeData(size: 14, color: c.mutedForeground),
                child: icon!,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: c.mutedForeground),
            ),
          ),
        ],
      ),
    );
    if (onPressed != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: FTheme.of(context).borderRadius,
          child: content,
        ),
      );
    }
    if (variant == FMarkerVariant.border) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: content,
        ),
      );
    }
    if (variant == FMarkerVariant.separator) {
      content = Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 12),
          Flexible(flex: 2, child: content),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      );
    }
    return Semantics(
      liveRegion: live,
      button: onPressed != null,
      child: content,
    );
  }
}

class FDirection extends StatelessWidget {
  const FDirection({
    super.key,
    required this.textDirection,
    required this.child,
  });
  final TextDirection textDirection;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: textDirection, child: child);
}
