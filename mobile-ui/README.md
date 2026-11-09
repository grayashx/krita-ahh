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

The control strip connects to native Krita operations for undo, redo, save, export, tool selection, brush size, brush opacity, eraser mode, and paint-layer creation.

### Brushes and colors

- The brush panel queries Krita's `PaintOpPresets` resource model, filters by preset name, and activates the selected native `KisPaintOpPreset` through the canvas resource provider.
- Foreground and background colors can be set using hexadecimal color values, read from the live canvas resource provider, and swapped using Krita's native color resources.

### Layers

The layer panel traverses the active document's actual node tree. It supports active-node selection, visibility, rename, removal, paint-layer creation, layer opacity, lock state, and raising/lowering the selected node through Krita's node manager.

Layer identifiers cross the QML boundary as hexadecimal strings rather than JavaScript numbers, preserving full pointer precision on 64-bit Android builds. Each operation resolves the identifier against the current active document before acting.

### Adaptive layout

On narrow phone widths the brush and layer panels are mutually exclusive to conserve canvas space. At tablet widths both panels can remain open side by side. The QML control widget can expand for its panels while the native canvas remains a separate widget below it.

The canvas controller remains responsible for painting input, pressure handling, and canvas gestures. The QML strip is only a control surface, not a replacement painting engine.

## Validation and limitations

- Static source review confirms the bridge reads the actual brush resource model, active document node tree, and Krita canvas color resources.
- Layer locking currently uses the node's native lock setter; advanced layer properties such as blending modes, alpha inheritance, clipping groups, and masks are not exposed in the mobile panel.
- Brush preset editing/tagging/import-export and richer color selection UI remain outside this panel.
- No Android build or device runtime test has been performed for this PR. Qt Quick/OpenGL coexistence, QML sizing, stylus pressure, touch gestures, and Android color input still require verification on target hardware.
- Desktop builds are unchanged; all mobile workspace hosting code is guarded by `Q_OS_ANDROID`.
