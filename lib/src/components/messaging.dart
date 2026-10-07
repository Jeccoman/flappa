import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'button.dart';

enum FAttachmentStatus { ready, uploading, error }

class FAttachment extends StatelessWidget {
  const FAttachment({
    super.key,
    required this.name,
    this.description,
    this.preview,
    this.onPressed,
    this.onRemove,
    this.status = FAttachmentStatus.ready,
    this.progress,
  });
  final String name;
  final String? description;
  final Widget? preview;
  final VoidCallback? onPressed, onRemove;
  final FAttachmentStatus status;
  final double? progress;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    return Material(
      color: t.colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: t.borderRadius,
        side: BorderSide(
          color: status == FAttachmentStatus.error
              ? t.colors.destructive
              : t.colors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onPressed,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child:
                                preview ??
                                ColoredBox(
                                  color: t.colors.muted,
                                  child: Icon(
                                    status == FAttachmentStatus.error
                                        ? Icons.error_outline
                                        : Icons.insert_drive_file_outlined,
                                    size: 18,
                                    color: status == FAttachmentStatus.error
                                        ? t.colors.destructive
                                        : t.colors.mutedForeground,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status == FAttachmentStatus.uploading
                                    ? 'Uploading${progress == null ? '…' : ' ${(progress! * 100).round()}%'}'
                                    : status == FAttachmentStatus.error
                                    ? 'Upload failed'
                                    : description ?? 'Attachment',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: status == FAttachmentStatus.error
                                      ? t.colors.destructive
                                      : t.colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onRemove != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: FButton(
                    onPressed: onRemove,
                    variant: FButtonVariant.ghost,
                    size: FButtonSize.icon,
                    tooltip: 'Remove $name',
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
            ],
          ),
          if (status == FAttachmentStatus.uploading)
            LinearProgressIndicator(
              value: progress?.clamp(0, 1),
              minHeight: 3,
              semanticsLabel: 'Uploading $name',
            ),
        ],
      ),
    );
  }
}

enum FBubbleVariant { incoming, outgoing, plain }

class FBubble extends StatelessWidget {
  const FBubble({
    super.key,
    required this.child,
    this.variant = FBubbleVariant.incoming,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });
  final Widget child;
  final FBubbleVariant variant;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    final outgoing = variant == FBubbleVariant.outgoing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: outgoing
            ? t.colors.primary
            : variant == FBubbleVariant.plain
            ? Colors.transparent
            : t.colors.muted,
        borderRadius: BorderRadius.circular(t.radius + 4),
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: outgoing ? t.colors.primaryForeground : t.colors.foreground,
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: outgoing
                  ? t.colors.primaryForeground
                  : t.colors.foreground,
              size: 16,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class FMessage extends StatelessWidget {
  const FMessage({
    super.key,
    required this.child,
    this.outgoing = false,
    this.avatar,
    this.author,
    this.timestamp,
    this.actions = const [],
    this.maxWidth = 480,
  });
  final Widget child;
  final bool outgoing;
  final Widget? avatar;
  final String? author, timestamp;
  final List<Widget> actions;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    final c = FTheme.of(context).colors;
    return Align(
      alignment: outgoing
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: outgoing
            ? (Directionality.of(context) == TextDirection.ltr
                  ? TextDirection.rtl
                  : TextDirection.ltr)
            : Directionality.of(context),
        children: [
          if (avatar != null) ...[avatar!, const SizedBox(width: 10)],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: outgoing
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (author != null || timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (author != null)
                            Text(
                              author!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (timestamp != null)
                            Text(
                              timestamp!,
                              style: TextStyle(
                                fontSize: 11,
                                color: c.mutedForeground,
                              ),
                            ),
                        ],
                      ),
                    ),
                  FBubble(
                    variant: outgoing
                        ? FBubbleVariant.outgoing
                        : FBubbleVariant.incoming,
                    child: child,
                  ),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(spacing: 4, children: actions),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FMessageScroller extends StatefulWidget {
  const FMessageScroller({
    super.key,
    required this.children,
    this.contentVersion,
    this.spacing = 16,
    this.padding = const EdgeInsets.all(16),
    this.jumpLabel = 'Jump to latest',
  });
  final List<Widget> children;
  final Object? contentVersion;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final String jumpLabel;
  @override
  State<FMessageScroller> createState() => _FMessageScrollerState();
}

class _FMessageScrollerState extends State<FMessageScroller> {
  final _controller = ScrollController();
  bool _atEnd = true;
  bool _scheduled = false;
  @override
  void initState() {
    super.initState();
    _controller.addListener(_trackPosition);
    _follow();
  }

  void _trackPosition() {
    if (!_controller.hasClients) return;
    final atEnd = _controller.position.extentAfter < 40;
    if (atEnd != _atEnd) setState(() => _atEnd = atEnd);
  }

  void _follow() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted && _controller.hasClients && _atEnd) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant FMessageScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_atEnd) _follow();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          if (_atEnd) _follow();
          return false;
        },
        child: ListView.separated(
          controller: _controller,
          padding: widget.padding,
          itemCount: widget.children.length,
          separatorBuilder: (_, index) => SizedBox(height: widget.spacing),
          itemBuilder: (_, index) => widget.children[index],
        ),
      ),
      if (!_atEnd)
        PositionedDirectional(
          bottom: 12,
          end: 12,
          child: FButton(
            onPressed: () {
              setState(() => _atEnd = true);
              if (MediaQuery.disableAnimationsOf(context)) {
                _controller.jumpTo(_controller.position.maxScrollExtent);
              } else {
                _controller.animateTo(
                  _controller.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            },
            variant: FButtonVariant.secondary,
            leading: const Icon(Icons.arrow_downward),
            child: Text(widget.jumpLabel),
          ),
        ),
    ],
  );
}
