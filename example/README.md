# Flappa UI showcase

Run `flutter pub get` and `flutter run -d chrome` from this directory.

Browse thirteen sections, switch between light and dark themes, adjust accent color/radius, and expand component source code. Use Command+K or Control+K to search. All account/invitation actions are local demonstrations with no backend.

For native mobile component testing, launch an Android emulator or iOS Simulator, find it with `flutter devices`, and run `flutter run -t lib/main_components.dart -d <device-id>`. This entry point opens the component gallery directly, without the website landing page or a browser phone frame. In VS Code, select **Flappa UI components (emulator or device)** and choose your simulator or connected phone. Test typing, touch gestures, dialogs, and device rotation using the emulator controls.

See the [package README](../README.md) for installation and source-copy commands, or the [component guide](../doc/components.md) for APIs.

The app opens on the landing page. The browser routes are `/#/`, `/#/components`, and `/#/playground`; hash routing works with a static web server. The landing page links to the component explorer and the visual playground.

The playground builds single-column screens with 14 block types. Click a block in the palette or drag it onto the canvas, select it to edit properties, and reorder it from Layers or the move buttons. Use Interact to test inputs and controls. Screen settings configure spacing, padding, radius, accent, and dark mode. Try the Welcome, Settings, Dashboard, or Blank starters; replacing a screen can be undone.

Drafts save to this browser's local storage when available. There is no account or server storage. Export code downloads a runnable `main.dart` using the `flappa_ui` package; add the library to your Flutter project first. Copy project JSON to keep an editable backup, then use Import to restore it. Native builds retain drafts in memory and copy code when file downloads are unavailable. Input values entered in Interact mode are temporary. Exported buttons display local toast feedback until you connect your app logic.
