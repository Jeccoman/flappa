# Flappa UI showcase

[Live site](https://jeccoman.github.io/flappa/) · [Components](https://jeccoman.github.io/flappa/#/components) · [Playground](https://jeccoman.github.io/flappa/#/playground)

Run `flutter pub get` and `flutter run -d chrome` from this directory.

Browse thirteen sections, switch between light and dark themes, adjust accent color/radius, and expand component source code. Use Command+K or Control+K to search. All account/invitation actions are local demonstrations with no backend.

For native mobile component testing, launch an Android emulator or iOS Simulator, find it with `flutter devices`, and run `flutter run -t lib/main_components.dart -d <device-id>`. This entry point opens the component gallery directly, without the website landing page or a browser phone frame. In VS Code, select **Flappa UI components (emulator or device)** and choose your simulator or connected phone. Test typing, touch gestures, dialogs, and device rotation using the emulator controls.

See the [package README](../README.md) for installation and source-copy commands, or the [component guide](../doc/components.md) for APIs.

The app opens on the landing page. The browser routes are `/#/`, `/#/components`, and `/#/playground`; hash routing works with a static web server. The landing page links to the component explorer and the visual playground.

GitHub Actions publishes the site to GitHub Pages after formatting, analysis, tests, and the release build pass on `main`. The build uses `flutter build web --release --base-href /flappa/` so assets load from the repository's Pages path. Pull requests run the checks without deploying. To redeploy the current version, run the **Flutter** workflow manually from GitHub Actions.

The playground opens a zoomable canvas inspired by [M3E Canvas](https://github.com/lnkiai/m3e-canvas), implemented with Flappa components. Add up to 20 screens, choose phone/tablet/desktop artboard sizes, and drag screen titles or device frames to arrange them. Choose **Move screens** to drag anywhere on a device; switch back to **Edit blocks** to work on its components. Movement follows the pointer at any zoom without grid snapping, including left and above the original canvas origin. Selecting a screen brings it in front of overlapping screens. Each move is one Undo step.

In Properties, choose a **Device**: an iPhone-style phone, Android phone, tablet, laptop, or desktop monitor. Phone and tablet devices support **Rotate device**; finishes include Graphite, Silver, and Blue. Device presets use logical Flutter viewport sizes, with status bars and safe areas inside the frame. Choose **No device frame** for a plain artboard. Existing projects stay frameless until you choose a device; new screens inherit the selected screen’s device settings. Device choices persist in project JSON, appear in Test flow, and are included in PNG exports.

Select a screen in the sidebar to focus it; use the zoom controls or Fit all screens to navigate. On narrow displays, switch between Screens, Canvas, and Properties.

Keep **Edit blocks** enabled to drag components from the sidebar directly into artboards. Drop between blocks to reorder, inside rows/columns/containers to nest, or on another artboard to move a block and its children there. Use each block’s drag handle to move it. The trash icon deletes a block, including any nested children and button links. Select a block and press Delete or Backspace for the same action; typing in property fields keeps normal text-editing behavior. Screen headers also have a trash icon. Undo restores deleted blocks, screens, and links. Button links move with their blocks, and each drop is one Undo step. On mobile, hold a component in the horizontal palette for a moment, then drag it into the canvas; tapping adds it to the selected screen. Disable Edit blocks to inspect the clean design. PNG exports always omit editing controls.

In Properties, connect each button to a screen or **Go back**, select a slide/fade/instant transition, and choose the start screen. **Test flow** runs those links at the available viewport size. Restart resets the flow. Behavior notes appear in the exported AI prompt; they do not execute in the prototype. Unlinked buttons show local feedback. Input values and switches are temporary local state.

**Export** provides runnable Flutter code for the entire flow, an AI prompt for the project or selected screen, and editable project JSON. Add `flappa_ui` to your Flutter app and use the Dart download as `lib/main.dart`; navigation, transitions, screen themes, and nested layouts are included. **Export screen PNG** captures the selected artboard’s visible area at 2× resolution in the browser. **Import** accepts canvas projects and older single-screen JSON. Deleting a screen removes its inbound links, and Undo restores both.

Double-click an artboard or choose **Edit components** to open its screen editor; **All screens** returns to the canvas. The playground has 17 block types, including rows, columns, and containers. Select a layout before adding blocks to place them inside it. Select a leaf to add siblings. Use Layers to navigate the hierarchy, then **Move into**, **Move up**, or **Move down** in Properties to arrange blocks. On the canvas, select a block and drag its handle to an insertion target, including targets inside layouts. Empty layouts show a drop area. Use **Screen settings** to clear selection and add blocks at the root.

Rows use equal-width children and stack automatically when less than 480 px is available or each child would get less than 180 px. Disable **Stack on narrow screens** to keep a row horizontal. Each layout has its own padding and spacing. **Interact** hides editor controls and lets you test the screen. Try Welcome, Settings, Dashboard, Layouts, or Blank; replacing a screen can be undone.

Projects support up to 100 blocks and eight nesting levels. Duplicating or deleting a layout includes its children. Project JSON uses version 2; version 1 imports and saved drafts are migrated when loaded. Invalid parents, cycles, and excessive nesting are rejected before replacing your screen. Exported Dart preserves the hierarchy, responsive behavior, styling, and initial control values.

Canvas drafts save to this browser’s local storage when available. Earlier single-screen drafts become the first artboard without overwriting the original draft. There is no account or server storage. Download project JSON to keep an editable backup. Native builds retain drafts in memory and copy text exports when downloads are unavailable. Both the canvas and screen editor support Undo/Redo and Command/Control+Z (Shift to redo).
