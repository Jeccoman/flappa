import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum FBadgeVariant { primary, secondary, outline, destructive }

class FBadge extends StatelessWidget {
  const FBadge({
    super.key,
    required this.child,
    this.variant = FBadgeVariant.secondary,
  });
  final Widget child;
  final FBadgeVariant variant;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    final c = t.colors;
    final (background, foreground) = switch (variant) {
      FBadgeVariant.primary => (c.primary, c.primaryForeground),
      FBadgeVariant.secondary => (c.secondary, c.secondaryForeground),
      FBadgeVariant.outline => (Colors.transparent, c.foreground),
      FBadgeVariant.destructive => (c.destructive, c.destructiveForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(t.radius),
        border: Border.all(
          color: variant == FBadgeVariant.outline
              ? c.border
              : Colors.transparent,
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );
  }
}

class FCard extends StatelessWidget {
  const FCard({
    super.key,
    this.title,
    this.description,
    this.child,
    this.footer,
    this.padding = const EdgeInsets.all(24),
  });
  final Widget? title, description, child, footer;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.colors.card,
        borderRadius: t.borderRadius,
        border: Border.all(color: t.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: padding,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              DefaultTextStyle.merge(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.4,
                ),
                child: title!,
              ),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: t.colors.mutedForeground,
                  ),
                  child: description!,
                ),
              ),
            if (child != null)
              Padding(
                padding: EdgeInsets.only(
                  top: title != null || description != null ? 24 : 0,
                ),
                child: child!,
              ),
            if (footer != null)
              Padding(padding: const EdgeInsets.only(top: 24), child: footer!),
          ],
        ),
      ),
    );
  }
}

class FAlert extends StatelessWidget {
  const FAlert({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.info_outline,
    this.destructive = false,
  });
  final Widget title;
  final Widget? description;
  final IconData icon;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    final color = destructive ? t.colors.destructive : t.colors.foreground;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: t.borderRadius,
          border: Border.all(
            color: destructive ? color.withValues(alpha: .4) : t.colors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    child: title,
                  ),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          color: destructive ? color : t.colors.mutedForeground,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        child: description!,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAvatar extends StatelessWidget {
  const FAvatar({
    super.key,
    this.image,
    required this.fallback,
    this.size = 40,
    this.semanticLabel,
  });
  final ImageProvider? image;
  final String fallback;
  final double size;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final c = FTheme.of(context).colors;
    return Semantics(
      label: semanticLabel ?? fallback,
      image: true,
      child: ExcludeSemantics(
        child: ClipOval(
          child: Container(
            width: size,
            height: size,
            color: c.muted,
            child: image == null
                ? _fallback(c)
                : Image(
                    image: image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => _fallback(c),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _fallback(FColors c) => Center(
    child: Text(
      fallback,
      style: TextStyle(
        color: c.foreground,
        fontSize: size * .32,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class FAvatarGroup extends StatelessWidget {
  const FAvatarGroup({super.key, required this.children, this.overlap = 10});
  final List<FAvatar> children;
  final double overlap;
  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final height = children.map((a) => a.size).reduce((a, b) => a > b ? a : b);
    final width =
        children.fold<double>(0, (sum, a) => sum + a.size) -
        overlap * (children.length - 1);
    var start = 0.0;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          for (final avatar in children)
            PositionedDirectional(
              start: (() {
                final current = start;
                start += avatar.size - overlap;
                return current;
              })(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FTheme.of(context).colors.background,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: SizedBox(
                    width: avatar.size - 4,
                    height: avatar.size - 4,
                    child: avatar,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FSeparator extends StatelessWidget {
  const FSeparator({super.key, this.axis = Axis.horizontal});
  final Axis axis;
  @override
  Widget build(BuildContext context) =>
      axis == Axis.horizontal ? const Divider() : const VerticalDivider();
}

class FProgress extends StatelessWidget {
  const FProgress({super.key, this.value, this.label, this.height = 6})
    : assert(value == null || (value >= 0 && value <= 1));
  final double? value;
  final String? label;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: LinearProgressIndicator(
      value: value,
      minHeight: height,
      semanticsLabel: label,
      semanticsValue: value == null ? null : '${(value! * 100).round()}%',
    ),
  );
}

class FSpinner extends StatelessWidget {
  const FSpinner({super.key, this.size = 20, this.label = 'Loading'});
  final double size;
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: label),
  );
}

class FSkeleton extends StatefulWidget {
  const FSkeleton({
    super.key,
    this.width,
    this.height = 20,
    this.circular = false,
  });
  final double? width;
  final double height;
  final bool circular;
  @override
  State<FSkeleton> createState() => _FSkeletonState();
}

class _FSkeletonState extends State<FSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FadeTransition(
      opacity: Tween<double>(begin: .4, end: 1).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: FTheme.of(context).colors.muted,
          borderRadius: BorderRadius.circular(
            widget.circular ? widget.height : FTheme.of(context).radius,
          ),
        ),
      ),
    ),
  );
}

class FTooltip extends StatelessWidget {
  const FTooltip({super.key, required this.message, required this.child});
  final String message;
  final Widget child;
  @override
  Widget build(BuildContext context) => Tooltip(message: message, child: child);
}

class FKbd extends StatelessWidget {
  const FKbd(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = FTheme.of(context).colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: c.muted,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: c.mutedForeground,
        ),
      ),
    );
  }
}

class FEmpty extends StatelessWidget {
  const FEmpty({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.action,
  });
  final String title;
  final String? description;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 32, color: FTheme.of(context).colors.mutedForeground),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FTheme.of(context).colors.mutedForeground,
              height: 1.5,
            ),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class FScrollArea extends StatelessWidget {
  const FScrollArea({
    super.key,
    required this.child,
    this.controller,
    this.axis = Axis.vertical,
  });
  final Widget child;
  final ScrollController? controller;
  final Axis axis;
  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: controller,
    child: SingleChildScrollView(
      controller: controller,
      scrollDirection: axis,
      child: child,
    ),
  );
}
