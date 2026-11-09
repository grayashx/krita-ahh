# Android mobile UI

The Android build uses a touch-first QML home screen and a hybrid painting workspace.

## Home screen

- The QML home screen is hosted by `KisMainWindow`.
- Recent documents are supplied by Krita's real recent-document model.
- New canvas and Open file invoke Krita's native actions.
- Selecting a recent document opens it through Krita's document loader.
- The native welcome page remains available as a fallback if the home QML fails to load.

## Painting workspace

Each Android `KisView` keeps Krita's existing `KisCanvasController` and OpenGL canvas as the actual painting surface. A separate QML control strip is placed above it in the view's widget layout; it does not cover the canvas or intercept stylus and touch input.

The control strip connects to native Krita operations for undo, redo, save, export, tool selection, brush size, opacity, eraser mode, and paint-layer creation.

The brush panel queries Krita's `PaintOpPresets` resource model, filters by preset name, and activates the selected `KisPaintOpPreset` through the existing canvas resource provider. It does not maintain a duplicate or hard-coded preset catalog.

The layer panel traverses the active document's actual node tree. It supports selecting the active node, toggling visibility, renaming, and removing a node, and creating a paint layer through Krita's node manager. Layer identifiers are in-process node identities and are only used to route UI actions back to the current document.

On narrow phone widths the brush and layer panels are mutually exclusive to conserve canvas space. At tablet widths both panels can remain open side by side. The QML widget can expand for the panels while the native canvas remains a separate widget below it.

The canvas controller remains responsible for painting input, pressure handling, and canvas gestures. The QML strip is only a control surface, not a replacement painting engine.

## Validation and limitations

- Static source review confirms that brush presets and layers are read from Krita's existing resource and document models.
- Brush preset editing, tagging, import/export management, layer reordering, and richer layer properties remain outside this mobile panel.
- No Android build or device runtime test has been performed for this PR. Qt Quick/OpenGL coexistence, stylus pressure, touch gestures, and responsive sizing still require verification on target hardware.
- Desktop builds are unchanged; all mobile workspace hosting code is guarded by `Q_OS_ANDROID`.
