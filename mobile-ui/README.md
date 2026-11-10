# Android mobile UI

The Android build uses a touch-first QML home screen and a compact, task-focused painting workspace.

## Home screen

- The QML home screen is hosted by `KisMainWindow`.
- Recent documents are supplied by Krita's real recent-document model.
- New canvas and Open file invoke Krita's native actions.
- Selecting a recent document opens it through Krita's document loader.
- The native welcome page remains available as a fallback if the home QML fails to load.

## Painting workspace

Each Android `KisView` keeps Krita's existing `KisCanvasController` and OpenGL canvas as the actual painting surface. A separate QML control strip is placed above it in the view's widget layout; it does not cover the canvas or intercept stylus input.

The workspace is deliberately organized around a small number of common actions:
- A compact document bar for home, undo, redo, save and export.
- A horizontally scrollable primary tool strip for brush, eraser, picker, fill, gradient, line, ellipse and rectangle.
- A small More group for pencil, path, text and move tools.
- Direct foreground/background swatches, a one-tap color swap, and brush size/opacity controls.
- Mutually exclusive Brushes and Layers panels. Only the panel currently being used is expanded.

## Native tools and brushes

Tool selection switches Krita's registered native tool factories. The mobile eraser is Krita's brush tool with native eraser mode enabled; selecting another tool clears that mode. Brush presets are queried from Krita's `PaintOpPresets` resource model and activated through the active canvas resource provider.

## Color selection

Tapping either color swatch opens a compact HSV picker. Artists can choose hue, saturation and value directly, enter a hexadecimal color, switch between foreground/background targets, and reuse recent colors from Krita's own color history. The bridge listens to native foreground/background color changes, so eyedropper and other canvas changes update the swatches too. Color values continue to pass through Krita's native `KoColor` and canvas-resource systems.

## Layers

The layer panel traverses the active document's actual node tree. It supports active-node selection, visibility, rename, removal, paint-layer creation, layer opacity, lock state, and raising/lowering the selected node through Krita's node manager.

Layer identifiers cross the QML boundary as hexadecimal strings rather than JavaScript numbers, preserving full pointer precision on 64-bit Android builds. Each operation resolves the identifier against the current active document before acting.

## Android screen support

The Android manifest now declares both normal and small screens as supported, matching the phone-first workspace target. The activity remains resizable and supports orientation and screen-size configuration changes.

## Validation and limitations

- Static source review checked the native tool IDs against Krita's registered default-tool factories.
- The workspace continues to use Krita's native document, brush, layer, color and canvas systems; no parallel painting engine is introduced.
- The repository currently has no GitHub Actions workflow runs or commit status checks for the mobile integration.
- No Android SDK/NDK or connected Android device is available in this execution environment, so an APK build, launch, stylus/gesture test and runtime verification could not be performed here.
- Qt Quick/OpenGL coexistence, QML sizing, touch interaction, pressure/tilt and device-specific performance still require target-device testing.
- Advanced layer blend modes, masks, alpha inheritance, clipping groups, brush preset editing and brush organization are not exposed in this compact workspace yet.
- Desktop builds remain outside the Android-only workspace host path; mobile workspace hosting is guarded by `Q_OS_ANDROID`.
