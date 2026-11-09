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

The control strip currently connects to native Krita operations for:

- Undo and redo
- Save and export
- Brush and eraser selection, plus the supported picker and rectangle tools
- Brush size and opacity
- Adding a paint layer
- Returning to the home screen without closing the open document

The canvas controller remains responsible for painting input, pressure handling, and canvas gestures. The QML strip is only a control surface, not a replacement painting engine.

## Current limitations

- Brush preset browsing and editing are not yet connected to Krita's resource models.
- A live layer list and layer selection/visibility controls are not yet exposed in the mobile panel.
- The controls are a first functional workspace shell; phone/tablet layout refinement remains.
- An Android build and device test are still required to verify Qt Quick/OpenGL coexistence, stylus pressure, and touch gestures on target hardware.

Desktop builds are unchanged; all mobile workspace hosting code is guarded by `Q_OS_ANDROID`.
