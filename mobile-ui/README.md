# Mobile application shell

This directory contains the first mobile-first application interface for the Krita-derived painting app.

## Product direction

- Android-first, adaptive for phones and tablets.
- Touch-first interaction. Desktop menu bars, dockers, keyboard-shortcut workflows and desktop-only panels are not part of the mobile experience.
- Existing Krita painting, document, brush, layer, color and export systems remain the source of truth.
- ibisPaint is a workflow and usability reference only. This is an independent interface and product.

## Current contents

- \`qml/Main.qml\`: home/project library, create-canvas flow, painting workspace layout, touch tool rail, contextual brush controls, brush/layer/color panels, Brush Studio entry, mobile settings and export flow.

## Integration contract

\`Main.qml\` is an embeddable \`Item\`, not a second application window. The native host should mount the existing Krita canvas in the marked canvas surface and expose a QObject bridge through \`kritaBridge\`.

The first native bridge is implemented as `KisMobileBridge`, exposed by `KisMainWindow::mobileBridge`. It invokes existing `QAction` entries by their Krita action IDs and reports whether an action is enabled or a document is active. Undo and redo in the QML shell now use Krita's existing `edit_undo` and `edit_redo` actions.

The bridge remains intentionally thin. Further UI controls should forward intent to existing Krita controllers/actions for:

- document creation/open/save/export
- active tool, undo and redo
- active brush preset and brush parameters
- active layer and layer visibility
- foreground color
- canvas zoom and navigation

Do not duplicate the painting engine, document model, brush engine, layer stack or file-format implementation in QML.

## Interaction policy

- Primary actions must be reachable by touch.
- Undo/redo are visible controls, not keyboard-only shortcuts.
- Tool selection, panels and brush controls are thumb-accessible.
- Stylus pressure/tilt and multi-touch canvas gestures are handled by the native canvas/input layer.
- Physical keyboard shortcuts may remain available as optional accessories, but are never required for core workflows.

## Status and limitations

This is the mobile UI shell and navigation prototype. The canvas rectangle is a clearly marked host slot, not a replacement painting surface. The QML controls can call the bridge once the mobile QML host supplies `KisMainWindow::mobileBridge`. The bridge is compiled into `kritaui`, but the QML shell is not yet mounted in the Android window and canvas embedding is still a separate integration step. This change has not been built or run in an Android target. No desktop source files have been removed or rewritten by this UI addition.

The repository's upstream Krita license and copyright notices continue to apply to upstream code. Keep new application-specific code clearly separated and retain all applicable notices.
