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


## Canvas input and responsive layout

The Android workspace keeps the native canvas as a separate widget below the QML control strip. The OpenGL canvas accepts Qt touch events; Krita's existing input manager receives touch begin/update/end/cancel and native-gesture events, as well as tablet press/move/release. The default Krita input profile already defines canvas pan, zoom, rotation, and touch-gesture mappings. This pass does not replace those gestures with a second QML gesture system.

The control strip now:
- Preserves at least 120 px for the native canvas while allowing the controls to shrink to 104 px on short screens.
- Uses a compact top-bar and control sizing below 420 px width, and wider tool targets on tablet-sized layouts.
- Shrinks its fixed rows on short/landscape layouts.
- Makes the active contextual panel vertically scrollable when the remaining height is too small for all controls.
- Keeps the canvas itself free of QML overlays and gesture interception.

### Static regression checks

Run from the repository root:

```sh
python3 mobile-ui/tests/verify_mobile_workspace.py
```

The checks cover duplicate QML function names, QML-to-native bridge consistency, native canvas/widget ordering, touch/tablet event-path declarations, default input-profile gesture mappings, and responsive layout constraints. They are source-level checks, not a QML runtime test or Android device test.

### Physical-device verification still required

This execution environment has no Android SDK/NDK or connected device. The changes have not been APK-built or tested on hardware. Before calling input verification complete, test on at least one phone and one tablet in portrait and landscape:
- Stylus strokes at light, medium, and firm pressure; verify pressure response and tilt where the device reports it.
- Continuous strokes near all four canvas edges and while the canvas is zoomed/rotated.
- Finger pan, pinch zoom, and rotation using the active Krita input profile.
- Finger input while a stylus is hovering or drawing, including palm rejection and cancellation.
- Undo/redo after stylus strokes, and switching between canvas tools and QML controls.
- Confirm the canvas remains usable with each contextual panel open on short screens.

## Document workflow and performance

The mobile document bar reads the active document caption and modified flag from
Krita's current `KisDocument`. These values are refreshed from native document
signals; the mobile UI does not maintain a separate save state. Save, Save As,
and Export continue through Krita's existing document-save implementation.
Opening files, creating documents, and opening recent files use Krita's native
actions and recent-document model.

Brush preset lookup is deferred until the brush panel is opened. Search changes
are debounced, and document changes refresh only the visible resource panel.
This avoids rebuilding the preset catalogue on every keystroke or refreshing
hidden layer and brush panels unnecessarily.

## Release preparation

See [the Android release checklist](RELEASE_CHECKLIST.md) for the Android
packaging inputs, version and application-identity checks, signing requirements,
and the device verification gate. The automated workflow runs source-level
mobile checks only; it does not build or sign an APK.

## Building an installable APK

Use the manual **Build Android APK** GitHub Actions workflow and select the
target ABI. It runs the native Krita Android build through the KDE Android
builder image and then uses Krita's existing `build-android-package.py`
packaging script. The output is an installable **debug APK** uploaded as a
workflow artifact; it is not a signed production release.

The Android target requires Qt Quick, Qt Quick Widgets, and Qt Quick Controls 2.
CMake now treats those modules as required on Android so an incomplete Qt
toolchain fails during configuration rather than later in the C++ build.

The project is native Qt/Krita, not Tauri. Preserve the native QWidget/OpenGL
canvas and Krita brush engine; do not introduce a Tauri webview as an alternate
canvas host.
