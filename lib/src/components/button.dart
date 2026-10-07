import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum FButtonVariant { primary, secondary, outline, ghost, destructive, link }

enum FButtonSize { small, medium, large, icon }

class FButton extends StatelessWidget {
  const FButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = FButtonVariant.primary,
    this.size = FButtonSize.medium,
    this.leading,
    this.trailing,
    this.loading = false,
    this.autofocus = false,
    this.focusNode,
    this.tooltip,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? leading, trailing;
  final FButtonVariant variant;
  final FButtonSize size;
  final bool loading, autofocus;
  final FocusNode? focusNode;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    final c = t.colors;
    final (bg, fg) = switch (variant) {
      FButtonVariant.primary => (c.primary, c.primaryForeground),
      FButtonVariant.secondary => (c.secondary, c.secondaryForeground),
      FButtonVariant.destructive => (c.destructive, c.destructiveForeground),
      FButtonVariant.outline ||
      FButtonVariant.ghost => (Colors.transparent, c.foreground),
      FButtonVariant.link => (Colors.transparent, c.primary),
    };
    final height = switch (size) {
      FButtonSize.small => 36.0,
      FButtonSize.large => 48.0,
      _ => 40.0,
    };
    final button = TextButton(
      onPressed: loading ? null : onPressed,
      autofocus: autofocus,
      focusNode: focusNode,
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        minimumSize: WidgetStatePropertyAll(
          Size(size == FButtonSize.icon ? height : 0, height),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: size == FButtonSize.icon
                ? 10
                : size == FButtonSize.small
                ? 12
                : 16,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? bg.withValues(alpha: bg.a * .5)
              : bg,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.disabled) ? fg.withValues(alpha: .5) : fg,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.hovered) ||
                  s.contains(WidgetState.focused) ||
                  s.contains(WidgetState.pressed)
              ? fg.withValues(alpha: .08)
              : null,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.focused)
                ? c.ring
                : variant == FButtonVariant.outline
                ? c.border
                : Colors.transparent,
            width: s.contains(WidgetState.focused) ? 2 : 1,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: t.borderRadius),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: variant == FButtonVariant.link
                ? TextDecoration.underline
                : null,
          ),
        ),
      ),
      child: IconTheme.merge(
        data: const IconThemeData(size: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                  semanticsLabel: 'Loading',
                ),
              ),
              const SizedBox(width: 8),
            ] else if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            Flexible(child: child),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class FToggle extends StatelessWidget {
  const FToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
    this.tooltip,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget child;
  final String? tooltip;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    child: FButton(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      variant: value ? FButtonVariant.secondary : FButtonVariant.ghost,
      tooltip: tooltip,
      child: child,
    ),
  );
}

class FToggleGroup<T> extends StatelessWidget {
  const FToggleGroup({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.multiple = false,
  });
  final Map<T, Widget> items;
  final Set<T> value;
  final ValueChanged<Set<T>>? onChanged;
  final bool multiple;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    children: [
      for (final item in items.entries)
        FToggle(
          value: value.contains(item.key),
          onChanged: onChanged == null
              ? null
              : (selected) {
                  final next = multiple ? {...value} : <T>{};
                  if (selected) {
                    next.add(item.key);
                  } else {
                    next.remove(item.key);
                  }
                  onChanged!(next);
                },
          child: item.value,
        ),
    ],
  );
}
