# Flappa UI

A shadcn-inspired Flutter UI library with light and dark themes, composable components, and source you can own.

Includes a component explorer, a source-copy CLI, and a visual canvas with connected screens, interactive flows, and Flutter code export.

[Live site](https://jeccoman.github.io/flappa/) · [Components](https://jeccoman.github.io/flappa/#/components) · [Playground](https://jeccoman.github.io/flappa/#/playground) · [pub.dev](https://pub.dev/packages/flappa_ui)

Requires Flutter 3.38+ and Dart 3.10+.

## Install

```sh
flutter pub add flappa_ui
```

## Use

```dart
import 'package:flutter/material.dart';
import 'package:flappa_ui/flappa_ui.dart';

void main() => runApp(
  FlappaApp(
    home: Scaffold(
      body: Center(
        child: FButton(
          onPressed: () {},
          child: const Text('Get started'),
        ),
      ),
    ),
  ),
);
```

## Run the site

From this repository:

```sh
cd example
flutter pub get
flutter run -d chrome
```

Browse components or open the playground to build screens and export Flutter code. See the [example guide](example/README.md) for emulator testing and saved projects.

## Copy the source

From an app with Flappa UI installed:

```sh
dart run flappa_ui add button forms
dart run flappa_ui add all
```

Components are copied into `lib/ui` with their dependencies. Import `ui/flappa_ui.dart` to use and customize them.

[Component guide](doc/components.md) · [Changelog](CHANGELOG.md) · [MIT license](LICENSE)
