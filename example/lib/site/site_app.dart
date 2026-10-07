import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart' show ShowcaseApp;
import '../playground/studio_page.dart';
import 'landing_page.dart';

enum SiteSection { home, components, playground }

class SiteApp extends StatefulWidget {
  const SiteApp({super.key});
  @override
  State<SiteApp> createState() => _SiteAppState();
}

class _SiteAppState extends State<SiteApp> {
  final _router = SiteRouter();
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Flappa UI — Build something beautiful',
    debugShowCheckedModeBanner: false,
    theme: FThemeData(radius: 8).toThemeData(),
    routerDelegate: _router,
    routeInformationParser: const SiteRouteParser(),
  );
}

class SiteRouteParser extends RouteInformationParser<SiteSection> {
  const SiteRouteParser();
  @override
  Future<SiteSection> parseRouteInformation(
    RouteInformation routeInformation,
  ) => SynchronousFuture(switch (routeInformation.uri.path) {
    '/components' => SiteSection.components,
    '/playground' => SiteSection.playground,
    _ => SiteSection.home,
  });
  @override
  RouteInformation restoreRouteInformation(SiteSection configuration) =>
      RouteInformation(
        uri: Uri(
          path: configuration == SiteSection.home
              ? '/'
              : '/${configuration.name}',
        ),
      );
}

class SiteRouter extends RouterDelegate<SiteSection> with ChangeNotifier {
  SiteSection _section = SiteSection.home;
  final _navigator = GlobalKey<NavigatorState>();
  @override
  SiteSection get currentConfiguration => _section;
  void go(SiteSection section) {
    _section = section;
    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(SiteSection configuration) async {
    _section = configuration;
  }

  @override
  Future<bool> popRoute() async {
    if (await _navigator.currentState?.maybePop() ?? false) return true;
    if (_section == SiteSection.home) return false;
    go(SiteSection.home);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_section == SiteSection.components) {
      return ShowcaseApp(
        onHome: () => go(SiteSection.home),
        onPlayground: () => go(SiteSection.playground),
      );
    }
    return Navigator(
      key: _navigator,
      pages: [
        MaterialPage<void>(
          key: ValueKey(_section),
          child: _section == SiteSection.playground
              ? StudioPage(
                  onHome: () => go(SiteSection.home),
                  onComponents: () => go(SiteSection.components),
                )
              : LandingPage(
                  onComponents: () => go(SiteSection.components),
                  onPlayground: () => go(SiteSection.playground),
                ),
        ),
      ],
      onDidRemovePage: (_) {},
    );
  }
}
