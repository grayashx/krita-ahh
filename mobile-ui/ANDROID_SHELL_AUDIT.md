# Android shell and dependency audit

## Confirmed current startup and UI path

The current Android implementation is not a separate mobile-only application target yet. It is the Krita application with Android-specific QML entry points embedded in its existing UI layer.

| Area | Current source | Confirmed behavior |
|---|---|---|
| Android app/window shell | `libs/ui/KisMainWindow.cpp` / `.h` | Still constructs the shared Krita main-window architecture. The Android path also loads `qrc:/mobile-ui/qml/Main.qml` for the home/welcome surface. |
| Painting view | `libs/ui/KisView.cpp` | Under `Q_OS_ANDROID`, creates a `QQuickWidget` that loads `WorkspaceBar.qml`, then places the existing `KisCanvasController` below it. |
| Mobile native API | `libs/ui/KisMobileBridge.cpp` / `.h` | Existing QObject bridge exposes native document, tool, brush, color, layer, save/export and action operations to QML. |
| QML resources | `mobile-ui/mobile-ui.qrc` | Registers `Main.qml` and `WorkspaceBar.qml`. |
| Mobile controls | `mobile-ui/qml/Main.qml`, `WorkspaceBar.qml` | Existing custom home/workspace UI. It is not yet the requested ibis-inspired interaction design. |
| UI library build | `libs/ui/CMakeLists.txt` | Adds the mobile bridge and QML resource to the shared `kritaui` target. The source list also contains many desktop-facing dialogs, menus, managers, and widgets. |
| APK pipeline | `.github/workflows/build-android-apk.yml` | Uses KDE's Android dependency environment, builds the Krita Android native project with `run-ci-build.py`, then packages with `build-android-package.py`. |

## Architectural diagnosis

The present design adds mobile controls around the existing desktop-oriented application shell. It does not replace the application shell with a mobile-first product architecture. The home screen and canvas controls are separate QML entry points, while the common `KisMainWindow` and `kritaui` implementation still provide much of the surrounding application structure.

This explains why another round of styling `WorkspaceBar.qml` alone would not satisfy the requirement. The migration must own the Android startup/home/navigation path and the painting workspace as one coherent mobile experience.

## Safe engine boundary

### Preserve unless dependency analysis proves otherwise

- Krita image/document model and document I/O.
- Native canvas, OpenGL rendering and canvas controller.
- Paintop/brush engines, preset/resource loading and brush settings.
- Layer/node model, node operations, masks and blend modes.
- Undo/redo and action infrastructure used by the bridge.
- Color spaces, color management and foreground/background resources.
- Input manager, Android tablet events, pressure/tilt and canvas gestures.
- Android platform integration and runtime resources required by those systems.

### Candidates for Android-only exclusion, pending proof

- Desktop-only dockers and docker factories.
- Desktop menu/tool-bar presentation and window-layout persistence.
- Desktop-only welcome/startup widgets if replaced by the mobile home screen.
- Optional plugins, scripting integrations, desktop platform integrations and optional import/export filters not included in the mobile product scope.
- Desktop-only dialogs and auxiliary widgets not reachable from mobile workflows.

These are candidates, not approved deletions. Several UI classes that appear desktop-facing may still be referenced by shared managers or native document workflows.

## Build-system facts and constraints

- The APK workflow currently builds the Android-configured Krita project, not a separately defined minimal mobile-engine target.
- The workflow already disables tests with `-DBUILD_TESTING=OFF` and limits native compilation to two jobs.
- The APK packaging script consumes the Android install tree produced by the native build.
- The workflow file must remain unchanged while the first mobile shell is introduced. UI changes should not be mixed with toolchain, dependency setup, packaging, or artifact changes.
- A green static source-check job is not evidence that the QML loads or that the app is usable on a phone.

## Required next audit work

1. Trace Android startup from the Android application/Qt entry point into `KisMainWindow`, the welcome/home widget, document creation/opening, and `KisView`.
2. Inspect the full `kritaui` source list and target links. Separate files into: engine-required, mobile-host-required, desktop-only, and uncertain.
3. Trace each proposed exclusion through CMake target links, runtime plugin discovery, resource installation, action registration, and document import/export.
4. Inspect the Android install tree and APK contents to identify which desktop plugins/resources are actually shipped.
5. Produce a tested CMake option/target matrix. No deletion is allowed until the matrix identifies a safe exclusion and a regression test.

## Proposed target architecture

- Android application shell: dedicated QML home/library and canvas workspace, selected only under Android.
- Native host: small Qt host responsible for lifecycle, safe areas, screen orientation, file intents and attaching the Krita canvas.
- Engine adapter: a narrow bridge to existing Krita document, brush, layer, color, tool, undo and export APIs.
- Native engine/dependencies: only the CMake targets and runtime resources required by the supported mobile workflows.
- Desktop app: retained separately for desktop builds and not loaded in the Android product flow.

The first UI replacement should reuse the existing bridge and canvas. Build pruning follows only after the mobile workflow works, because changing the shell and removing build dependencies simultaneously would make failures difficult to isolate.
