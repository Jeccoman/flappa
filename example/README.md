# Flappa UI showcase

[Live site](https://jeccoman.github.io/flappa/) · [Components](https://jeccoman.github.io/flappa/#/components) · [Playground](https://jeccoman.github.io/flappa/#/playground)

Run `flutter pub get` and `flutter run -d chrome` from this directory.

Browse thirteen sections, switch between light and dark themes, adjust accent color/radius, and expand component source code. Use Command+K or Control+K to search. All account/invitation actions are local demonstrations with no backend.

For native mobile component testing, launch an Android emulator or iOS Simulator, find it with `flutter devices`, and run `flutter run -t lib/main_components.dart -d <device-id>`. This entry point opens the component gallery directly, without the website landing page or a browser phone frame. In VS Code, select **Flappa UI components (emulator or device)** and choose your simulator or connected phone. Test typing, touch gestures, dialogs, and device rotation using the emulator controls.

See the [package README](../README.md) for installation and source-copy commands, or the [component guide](../doc/components.md) for APIs.

The app opens on the landing page. The browser routes are `/#/`, `/#/components`, and `/#/playground`; hash routing works with a static web server. The landing page links to the component explorer and the visual playground.

GitHub Actions publishes the site to GitHub Pages after formatting, analysis, tests, and the release build pass on `main`. The build uses `flutter build web --release --base-href /flappa/` so assets load from the repository's Pages path. Pull requests run the checks without deploying. To redeploy the current version, run the **Flutter** workflow manually from GitHub Actions.

The playground has 17 block types, including rows, columns, and containers. Select a layout before adding blocks to place them inside it. Select a leaf to add siblings. Use Layers to navigate the hierarchy, then **Move into**, **Move up**, or **Move down** in Properties to arrange blocks. On the canvas, select a block and drag its handle to an insertion target, including targets inside layouts. Empty layouts show a drop area. Use **Screen settings** to clear selection and add blocks at the root.

Rows use equal-width children and stack automatically when less than 480 px is available or each child would get less than 180 px. Disable **Stack on narrow screens** to keep a row horizontal. Each layout has its own padding and spacing. **Interact** hides editor controls and lets you test the screen. Try Welcome, Settings, Dashboard, Layouts, or Blank; replacing a screen can be undone.

Projects support up to 100 blocks and eight nesting levels. Duplicating or deleting a layout includes its children. Project JSON uses version 2; version 1 imports and saved drafts are migrated when loaded. Invalid parents, cycles, and excessive nesting are rejected before replacing your screen. Exported Dart preserves the hierarchy, responsive behavior, styling, and initial control values.

Drafts save to this browser's local storage when available. There is no account or server storage. Export code downloads a runnable `main.dart` using the `flappa_ui` package; add the library to your Flutter project first. Copy project JSON to keep an editable backup, then use Import to restore it. Native builds retain drafts in memory and copy code when file downloads are unavailable. Input values entered in Interact mode are temporary. Exported buttons display local toast feedback until you connect your app logic.
