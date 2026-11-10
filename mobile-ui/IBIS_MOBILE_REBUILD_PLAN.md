# Mobile-first ibis-style application rebuild

## Goal

Turn the Android build into a phone-first painting application with an ibis Paint-inspired interaction model and visual hierarchy, while retaining Krita's native painting engine and document capabilities. This is a mobile product shell over a deliberately selected native engine dependency set, not the desktop application compressed onto a phone.

The existing Android APK workflow is a protected baseline. This branch must not change its build runner, KDE dependency setup, toolchain, native build command, package command, artifact naming, or upload behavior during the UI migration foundation.

## Current repository facts

- Android currently embeds QML controls alongside Krita's native QWidget/OpenGL canvas through the Android-specific view host.
- `mobile-ui/qml/Main.qml` and `WorkspaceBar.qml` provide a custom compact mobile interface, but they are not an implementation of the requested ibis-style workflow.
- `mobile-ui/mobile-ui.qrc` registers those QML files.
- The C++ bridge already exposes document, brush, layer, color, tool and action operations. The replacement UI must reuse and, where necessary, deliberately extend this bridge rather than inventing a second painting/document model.
- The current APK workflow invokes Krita's Android native build via KDE's dependency-management scripts, then `build-android-package.py`. A successful APK artifact proves packaging, not that the app launches, renders, accepts stylus input, or is usable on a physical phone.

## Non-negotiable architecture

1. **Keep the engine.** Preserve the native canvas/OpenGL path, brush engines, paint operations, document/image model, node/layer model, undo stack, resource loading, file I/O, color management, and Android tablet/touch input path.
2. **Replace the presentation.** Android must enter a dedicated mobile shell. The old desktop menus, dockers, toolbars, and desktop workspace must not be visible or required for normal phone use.
3. **Do not fork engine behavior into QML.** QML owns layout, navigation, gestures on controls, and presentation. Painting, documents, tools, brush presets, layers, and undo remain native Krita responsibilities exposed through a narrow bridge.
4. **Do not delete source files just because they look desktop-related.** Remove or disable a component only after tracing its Android target, CMake dependency graph, runtime registration, and transitive link/resource requirements. Prefer Android-specific target selection and feature flags over destructive source-tree deletion.
5. **Keep desktop builds isolated.** All mobile-shell selection and desktop UI suppression must be guarded by Android build conditions. Desktop behavior must remain unchanged.
6. **Do not alter the APK workflow during the first UI replacement pass.** A workflow change is allowed only when a demonstrated Android build failure requires it, and must be isolated from UI changes.

## Target mobile experience

Use ibis Paint as a product-workflow reference, not as a source of copied proprietary code or artwork. The Android shell should be designed around:

- A canvas-first workspace with maximum practical drawing area.
- Compact top actions: back/home, undo, redo, document title, save/export, and overflow.
- A thumb-accessible tool rail with recognizable drawing-tool icons and clear active states.
- A brush control surface with brush preview, size, opacity, stabilization where supported, and a searchable preset browser.
- A dedicated layer panel with thumbnails, visibility, selection, reorder, opacity, blend mode, add/duplicate/delete/group actions.
- A color surface with wheel/square or equivalent picker, foreground/background, recent colors, and hex/RGB entry.
- A secondary tool/options panel that changes with the selected tool.
- Responsive portrait and landscape layouts, small-phone support, safe-area handling, and large touch targets.
- Stylus pressure/tilt where the Android device reports it, plus finger pan/pinch/rotate without stealing stylus strokes.
- Home/document library with new canvas, open/import, recent files, and export.

Do not claim feature parity with ibis Paint until each interaction is implemented and tested. Prioritize a coherent, usable core workflow over a crowded imitation.

## Implementation sequence

### Phase 0 — Protect and measure the baseline

- Keep this branch based on the current `main` commit.
- Record the current Android workflow file and its build/package/artifact steps.
- Run the existing mobile static checks unchanged.
- Run the Android APK workflow on this branch before any risky refactor, if the current baseline is not already proven by a successful APK artifact from the latest source.
- Save the artifact/run URL and distinguish build success from phone runtime success.
- No deletions, CMake pruning, or workflow edits in this phase.

### Phase 1 — Map the Android dependency boundary

- Trace the Android startup path from the Android application entry point through `KisMainWindow`, `KisView`, the mobile host, QML resource registration, and the native canvas.
- Inventory Android-required libraries and runtime resources: image/document, paintop, resources, color, input, canvas, Qt Quick host, and file access.
- Inventory desktop-only presentation and optional features: desktop menus/dockers, desktop-only dialogs, optional plugins, scripting, and non-mobile integration points.
- For every candidate exclusion, record its CMake option/target, direct and transitive dependencies, Android references, and a test that proves it can be disabled.
- Output a dependency matrix before changing any build selection. No speculative source deletion.

### Phase 2 — Replace the Android shell, not the engine

- Introduce a dedicated Android mobile application root (QML) with a single explicit entry point and resource registration.
- Keep the native Krita canvas as the drawing surface and place mobile controls around it using the existing host boundary. Do not overlay a QML item over the OpenGL canvas if that intercepts tablet events.
- Replace the current generic studio/home/workspace visual system with the ibis-inspired mobile information architecture.
- Split QML into small components: document bar, tool rail, brush controls, brush browser, layer panel, color picker, tool options, dialogs, and home/library.
- Keep desktop UI code available for desktop builds; select the mobile shell only on Android.
- Preserve and test all existing bridge operations before adding new ones. Add bridge methods only for missing real native actions.

### Phase 3 — Reduce the Android build to the required product

- Use the Phase 1 dependency matrix to disable optional desktop-only plugins, integrations, tools, and packaging components through supported CMake/KDECI options.
- Keep required native engine libraries and their runtime resources.
- Avoid deleting upstream directories from the repository. A mobile-only distribution can be produced by selecting Android targets and excluding unneeded runtime plugins/resources from the package manifest.
- Compare build graph, installed tree size, APK contents, startup dependencies, and runtime behavior before/after each exclusion.
- Keep a small allowlist of required modules and a denylist of confirmed desktop-only modules, both backed by automated checks.
- Do not call this a reduced mobile build until the produced APK launches and passes the smoke tests.

### Phase 4 — Validate the actual app

Automated gates:
- Existing source-level mobile checks pass.
- QML lint/compilation succeeds for every shipped QML file.
- Android build completes and emits exactly one APK artifact, not just logs.
- APK archive integrity, package ID, ABI, native libraries, QML resources, and required runtime resources are checked.
- A smoke test launches the package on an Android emulator/device and verifies home screen, new document, canvas display, stroke, undo/redo, brush selection, color change, layer add/select, save, reopen, and export.

Physical-device gates:
- Test at least one phone in portrait and landscape.
- Test stylus pressure/tilt where supported, finger gestures, palm rejection, edge strokes, and panel interaction.
- Confirm no desktop menus, dockers, or cramped desktop dialogs appear in normal mobile use.
- Test a long session and a large canvas for memory/performance regressions.

### Phase 5 — Release branch and cleanup

- Only after the mobile app passes runtime acceptance, prepare a release configuration, app identity, signing, icons, and licensing/branding review.
- Keep the current debug APK workflow available for development.
- Remove deprecated mobile QML and Android host paths only after the replacement is proven and no longer referenced.
- Merge the mobile implementation into `main) only after all acceptance gates pass.

## Regression guardrails

- Do not modify `.github/workflows/build-android-apk.yml` as part of a visual/UI change.
- Do not change the KDE Android dependency setup, Android NDK version, CMake toolchain, ABI, native build command, or APK packaging command without a separately evidenced reason.
- Do not replace Krita's native canvas with a WebView, Tauri canvas, HTML canvas, or a second painting engine.
- Do not claim "working app" based only on C++ compilation, a green static-check job, or the existence of a build log.
- A valid deliverable is an APK artifact plus verified launch and core painting workflow on Android hardware/emulator.

## First implementation PR scope

The first implementation PR after this plan should be limited to Phase 1: dependency/startup audit, a documented Android target map, and regression checks. It must not change the Android build workflow or remove native components. Once the dependency map is reviewed, the next PR can replace the QML shell in one coherent pass.
