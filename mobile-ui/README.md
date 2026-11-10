# Android mobile UI

The Android build uses a touch-first QML home screen and a compact, task-focused painting workspace around Krita's native painting engine.

## Workspace design

Each Android `KisView` keeps Krita's existing `KisCanvasController` and OpenGL canvas as the actual painting surface. A separate QML control strip is placed above it in the view's widget layout; it does not cover the canvas or intercept stylus input.

The workspace favors a short list of common actions:
- A compact document bar for home, undo, redo, save and export.
- A horizontally scrollable primary tool strip with common painting and drawing tools.
- Direct foreground/background swatches, a one-tap color swap, and brush size/opacity controls.
- One contextual panel at a time. Brush and layer management stay collapsed until opened.

## Brushes

Brushes are queried from Krita's native `PaintOpPresets` resource model. The mobile brush panel supports:
- Search by preset name.
- Browse existing Krita brush tags/categories.
- Add or remove a preset from Krita's `★ My Favorites` tag.
- Hide an unwanted preset by deactivating it in the native resource model.
- Open the selected preset in Krita's existing Brush Editor.

The native Brush Editor remains responsible for editing paintop settings, saving changes, saving a new preset, creating a preset from a brush engine, reloading defaults, and renaming. The mobile workspace does not implement a second brush-settings engine.

## Layers

The layer panel uses the active document's real node tree and node manager. It supports:
- Paint layers, groups, and mask node identification.
- Visibility, rename, lock, opacity, and layer ordering.
- Multi-selection for group operations.
- Native blend modes filtered by the selected layer's color space.
- Alpha lock on paint layers.
- Alpha inheritance on compatible layers.
- Pass-through on group layers.
- Creating and ungrouping groups, creating clipping groups, and adding transparency, selection, transform, filter, or colorize masks.

Layer property changes that support it are applied through Krita's undo-aware node-property and node-manager APIs. Node identifiers cross the QML boundary as hexadecimal strings rather than JavaScript numbers, preserving full pointer precision on 64-bit Android builds. Every layer operation resolves the identifier against the current active document before acting.

## Color selection

Tapping either color swatch opens a compact HSV picker. Artists can choose hue, saturation and value directly, enter a hexadecimal color, switch between foreground/background targets, and reuse recent colors from Krita's own color history. The bridge listens to native foreground/background color changes, so eyedropper and other canvas changes update the swatches too.

## Native tools

Tool selection switches Krita's registered native tool factories. The mobile eraser is Krita's brush tool with native eraser mode enabled; selecting another tool clears that mode. The native canvas and input systems continue to handle painting, pressure and canvas interaction.

## Android support and validation

- Android normal and small screen sizes are declared as supported.
- The mobile CMake target already links Qt Quick, QuickWidgets, and QuickControls2.
- Static source review checks the QML bridge calls against the declared native bridge API and the referenced Krita layer/resource interfaces.
- No Android SDK/NDK or connected Android device is available in this execution environment, so this branch has not been APK-built, installed, or runtime-tested. Qt Quick/OpenGL coexistence, stylus input, touch gestures, pressure/tilt, and device-specific performance still need target-device verification.
- Desktop builds remain outside the Android-only workspace host path; mobile workspace hosting is guarded by `Q_OS_ANDROID`.

## Not exposed in the compact workspace yet

Brush preset file import/export, brush preset duplication, custom tag creation/renaming, advanced mask parameter dialogs, and the full set of Krita's specialized layer types remain available through Krita's broader native resource and layer workflows rather than being duplicated as extra mobile controls.
