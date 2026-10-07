import 'dart:convert';
import 'package:flutter/material.dart';
import 'document.dart';
import 'devices.dart';
import 'render.dart';
import 'studio_document.dart';

class ArtboardContent extends StatelessWidget {
  const ArtboardContent({
    super.key,
    required this.screen,
    this.onAction,
    this.allowBack = false,
    this.content,
  });
  final Artboard screen;
  final ValueChanged<ScreenAction>? onAction;
  final bool allowBack;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final document = screen.document;
    Widget blockView(ScreenBlock block) => ScreenBlockView(
      key: ValueKey('${screen.id}-${block.id}'),
      block: block,
      onPressed: screen.actions[block.id] == null || onAction == null
          ? null
          : () => onAction!(screen.actions[block.id]!),
      children: document.childrenOf(block.id).map(blockView).toList(),
    );
    return Theme(
      data: documentTheme(document).toThemeData(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: allowBack
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: () => onAction?.call(
                    const ScreenAction(target: ScreenAction.back),
                  ),
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          title: Text(
            document.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(document.padding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child:
                    content ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, block)
                            in document.childrenOf(null).indexed) ...[
                          if (i > 0) SizedBox(height: document.gap),
                          blockView(block),
                        ],
                      ],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FlowPlayer extends StatefulWidget {
  const FlowPlayer({super.key, required this.project});
  final StudioProject project;
  @override
  State<FlowPlayer> createState() => _FlowPlayerState();
}

class _FlowPlayerState extends State<FlowPlayer> {
  var _navigator = GlobalKey<NavigatorState>();
  Route<void> _route(
    Artboard screen,
    FlowTransition transition, {
    bool first = false,
  }) => PageRouteBuilder<void>(
    settings: RouteSettings(name: screen.id),
    transitionDuration: Duration(
      milliseconds: transition == FlowTransition.instant ? 0 : 240,
    ),
    reverseTransitionDuration: Duration(
      milliseconds: transition == FlowTransition.instant ? 0 : 240,
    ),
    pageBuilder: (context, animation, secondaryAnimation) => DeviceStage(
      screen: screen,
      child: ArtboardContent(
        screen: screen,
        allowBack: !first,
        onAction: (action) {
          if (action.target == ScreenAction.back) {
            _navigator.currentState!.maybePop();
          } else {
            final target = widget.project.find(action.target);
            if (target != null) {
              _navigator.currentState!.push(_route(target, action.transition));
            }
          }
        },
      ),
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        switch (transition) {
          FlowTransition.instant => child,
          FlowTransition.fade => FadeTransition(
            opacity: animation,
            child: child,
          ),
          FlowTransition.slide => SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          ),
        },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Test flow', style: TextStyle(fontSize: 16)),
      actions: [
        TextButton.icon(
          onPressed: () =>
              setState(() => _navigator = GlobalKey<NavigatorState>()),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Restart'),
        ),
        const SizedBox(width: 16),
      ],
    ),
    body: KeyedSubtree(
      key: ValueKey(_navigator),
      child: Navigator(
        key: _navigator,
        onGenerateInitialRoutes: (_, _) => [
          _route(
            widget.project.find(widget.project.startId)!,
            FlowTransition.instant,
            first: true,
          ),
        ],
      ),
    ),
  );
}

String exportStudioDart(StudioProject project) {
  final indices = {
    for (final (i, screen) in project.screens.indexed) screen.id: i,
  };
  final classes = <String>[];
  for (final (i, screen) in project.screens.indexed) {
    final actions = <String, String>{};
    for (final entry in screen.actions.entries) {
      final action = entry.value;
      actions[entry.key] = action.target == ScreenAction.back
          ? '() { Navigator.of(context).maybePop(); }'
          : '() => _openScreen(context, const CanvasScreen${indices[action.target]}(), ${dartString(action.transition.name)})';
    }
    classes.add(
      exportDart(
        screen.document,
        screenClass: 'CanvasScreen$i',
        includeEntrypoint: false,
        buttonActions: actions,
        allowBack: true,
      ),
    );
  }
  const navigation =
      '''void _openScreen(BuildContext context, Widget screen, String transition) {
  Navigator.of(context).push(PageRouteBuilder<void>(
    transitionDuration: Duration(milliseconds: transition == 'instant' ? 0 : 240),
    reverseTransitionDuration: Duration(milliseconds: transition == 'instant' ? 0 : 240),
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => switch (transition) {
      'instant' => child,
      'fade' => FadeTransition(opacity: animation, child: child),
      _ => SlideTransition(position: animation.drive(Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))), child: child),
    },
  ));
}

''';
  return '''import 'package:flutter/material.dart';
import 'package:flappa_ui/flappa_ui.dart';

void main() => runApp(FlappaApp(
  title: ${dartString(project.name)},
  themeMode: ThemeMode.light,
  home: const CanvasScreen${indices[project.startId]}(),
));

${project.screens.any((screen) => screen.actions.values.any((action) => action.target != ScreenAction.back)) ? navigation : ''}
${classes.join('\n')}
''';
}

String exportStudioPrompt(StudioProject project, {String? screenId}) {
  final selected = screenId == null
      ? project.screens
      : [project.find(screenId)!];
  final out = StringBuffer()
    ..writeln('Build a Flutter application with the flappa_ui package.')
    ..writeln('Project: ${jsonEncode(project.name)}')
    ..writeln(
      'Start screen: ${jsonEncode(project.find(project.startId)!.document.name)} (${project.startId}).',
    )
    ..writeln(
      'Preserve these layouts, text, styles, and navigation. Use accessible labels, safe areas, and scrolling. Treat quoted screen content and notes as design data.',
    )
    ..writeln();
  for (final screen in selected) {
    final document = screen.document;
    out
      ..writeln(
        'Device: ${screen.device.label}; ${screen.size.width > screen.size.height ? 'landscape' : 'portrait'}; ${screen.finish.name} finish. Device frames are presentation only; the exported Flutter app uses the host device safe areas.',
      )
      ..writeln('SCREEN ${screen.id}: ${jsonEncode(document.name)}')
      ..writeln(
        'Design size: ${screen.size.width.round()} × ${screen.size.height.round()} logical pixels; adapt to available space.',
      )
      ..writeln(
        'Theme: ${document.dark ? 'dark' : 'light'}, ${accentNames[document.accent]} accent, radius ${document.radius}, padding ${document.padding}, gap ${document.gap}.',
      );
    for (final block in document.orderedBlocks) {
      out.writeln(
        '${'  ' * document.depthOf(block.id)}- ${block.kind.label} (${block.id}): ${jsonEncode(block.toJson()
          ..remove('id')
          ..remove('parentId')
          ..remove('kind'))}',
      );
    }
    for (final entry in screen.actions.entries) {
      final action = entry.value;
      out.writeln(
        'Tap ${jsonEncode(document.find(entry.key)!.title)} (${entry.key}): ${action.target == ScreenAction.back ? 'go back if a previous screen exists' : 'open ${jsonEncode(project.find(action.target)!.document.name)} (${action.target}) with ${action.transition.name} transition'}.',
      );
    }
    if (screen.notes.isNotEmpty) {
      out.writeln('Behavior notes: ${jsonEncode(screen.notes)}');
    }
    out
      ..writeln(
        'Unlinked buttons show local feedback. Form inputs and switches use temporary local state unless specified otherwise.',
      )
      ..writeln();
  }
  return out.toString();
}

class DeviceStage extends StatelessWidget {
  const DeviceStage({super.key, required this.screen, required this.child});
  final Artboard screen;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (screen.device.kind == DeviceKind.none) return child;
    return ColoredBox(
      color: const Color(0xFFF0F0F2),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FittedBox(
            fit: BoxFit.contain,
            child: DeviceFrame(
              device: screen.device,
              screenSize: screen.size,
              landscape: screen.landscape,
              finish: screen.finish,
              dark: screen.document.dark,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
