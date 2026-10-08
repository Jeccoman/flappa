## Unreleased

- Canvas device frames move freely with a whole-screen move mode, foreground selection for overlaps, negative coordinates, and undoable movement without grid snapping.

- Canvas adds component and screen trash buttons, focused Delete/Backspace shortcuts, and undoable deletion of nested layouts and their links.

- Canvas adds selectable realistic phone, tablet, laptop, and monitor frames with rotation, finishes, safe areas, and device-aware flow testing and PNG export.

- Canvas supports component palette drag-and-drop, nested insertion, block reordering, and atomic cross-screen moves with touch support.

- Website: multi-screen canvas with movable artboards, zoom, device sizes, navigation links, and interactive flows.
- Website: export connected Flutter screens, AI prompts, editable project JSON, and screen PNGs; migrate earlier playground drafts.

## 0.2.0

- Code blocks support line wrapping, a wrap toggle, a fixed line-number gutter, and distinct JSON/YAML key highlighting.
- Clipboard operations prevent overlapping requests and report failures without claiming success.
- Playground adds nested rows, columns, containers, responsive layouts, and a Layouts starter.
- Canvas drag handles and drop targets support reordering and moving blocks between layouts, with inspector controls as an alternative.
- Subtree duplication, deletion, undo/redo, and Dart export preserve nested structure and control state.
- Project format v2 supports up to 100 blocks and eight levels; existing v1 projects and browser drafts still load.
- Icon buttons expose tooltip labels to assistive technology. Canvas blocks support keyboard selection, and playground inputs retain accessible labels in generated code.

## 0.1.0

- Initial release with 71 component widgets and six overlay helpers.
- Semantic theme tokens, light and dark themes, and configurable colors and radius.
- Forms, navigation, overlays, charts, tables, code blocks, messaging, and questionnaires.
- Source-copy CLI with 12 component groups, dependency resolution, and local-edit protection.
- Component explorer, native emulator entry point, and visual screen playground with Dart export.
