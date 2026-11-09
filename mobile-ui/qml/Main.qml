import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/*
 * Mobile painting shell.
 *
 * This component is deliberately an Item so it can be embedded by the
 * existing Krita application. It owns mobile navigation and presentation;
 * the real canvas, document, brush and layer operations remain in Krita.
 */
Item {
    id: root
    anchors.fill: parent

    property string page: "home"
    property string activePanel: "brushes"
    property string selectedTool: "Brush"
    property string selectedBrush: "Basic-5"
    property string statusText: "Ready"
    property real brushSize: 18
    property real brushOpacity: 100
    property real zoom: 100
    property bool showNewCanvas: false
    property bool showExport: false
    property bool showBrushEditor: false
    property bool showLayerPanel: true
    property bool engineConnected: false

    // Set by the C++ host when the Krita canvas/controller bridge is attached.
    // No fake painting implementation is provided here.
    property var kritaBridge: null

    readonly property color bg: "#111216"
    readonly property color surface: "#1a1c22"
    readonly property color raised: "#242730"
    readonly property color line: "#30343e"
    readonly property color muted: "#969ba8"
    readonly property color textColor: "#f2f3f6"
    readonly property color accent: "#f2a65a"

    function openWorkspace() {
        page = "workspace"
        activePanel = "brushes"
        statusText = "New canvas"
    }

    function dispatch(action, value) {
        if (kritaBridge) {
            var completed = false
            if (action === "setBrushSize" && typeof kritaBridge.setBrushSize === "function")
                completed = kritaBridge.setBrushSize(value)
            else if (action === "setBrushOpacity" && typeof kritaBridge.setBrushOpacity === "function")
                completed = kritaBridge.setBrushOpacity(value)
            else if (action === "setForegroundColor" && typeof kritaBridge.setForegroundColor === "function")
                completed = kritaBridge.setForegroundColor(value)
            else if (action === "setEraserMode" && typeof kritaBridge.setEraserMode === "function")
                completed = kritaBridge.setEraserMode(value)
            else if (action === "setActiveTool" && typeof kritaBridge.setActiveTool === "function")
                completed = kritaBridge.setActiveTool(value)
            else if (typeof kritaBridge.triggerAction === "function") {
                var actionId = action
                if (action === "undo") actionId = "edit_undo"
                if (action === "redo") actionId = "edit_redo"
                if (action === "addLayer") actionId = "add_new_paint_layer"
                completed = kritaBridge.triggerAction(actionId)
            }
            if (completed) {
                statusText = "Ready"
                return true
            }
        }
        statusText = "Action unavailable: " + action
        return false
    }

    function chooseTool(name) {
        var previousTool = selectedTool
        var completed = false
        if (name === "Eraser") {
            completed = dispatch("setActiveTool", "Brush")
            if (completed)
                completed = dispatch("setEraserMode", true)
        } else if (name === "Brush") {
            completed = dispatch("setActiveTool", "Brush")
            if (completed)
                completed = dispatch("setEraserMode", false)
        } else {
            completed = dispatch("setActiveTool", name)
        }

        selectedTool = completed ? name : previousTool
    }

    function choosePanel(name) {
        activePanel = name
    }

    Rectangle {
        anchors.fill: parent
        color: root.bg
    }

    // HOME / PROJECT LIBRARY
    Item {
        anchors.fill: parent
        visible: root.page === "home"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    spacing: 2
                    Label {
                        text: "STUDIO"
                        color: root.accent
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2
                    }
                    Label {
                        text: "Your canvas"
                        color: root.textColor
                        font.pixelSize: 28
                        font.bold: true
                    }
                }
                Item { Layout.fillWidth: true }
                ToolButton {
                    text: "⚙"
                    font.pixelSize: 22
                    onClicked: root.page = "settings"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    radius: 12
                    color: root.surface
                    border.color: root.line
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 13
                        Label { text: "⌕"; color: root.muted; font.pixelSize: 21 }
                        TextField {
                            Layout.fillWidth: true
                            placeholderText: "Search projects"
                            color: root.textColor
                            placeholderTextColor: root.muted
                            background: Item {}
                        }
                    }
                }
                Button {
                    text: "+ New"
                    onClicked: root.showNewCanvas = true
                    background: Rectangle { radius: 12; color: root.accent }
                    contentItem: Label {
                        text: parent.text
                        color: "#20170f"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "Recent projects"
                    color: root.textColor
                    font.pixelSize: 18
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Label { text: "View all  ›"; color: root.accent; font.pixelSize: 13 }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width > 620 ? 3 : 2
                columnSpacing: 12
                rowSpacing: 14

                Repeater {
                    model: [
                        { title: "Untitled study", detail: "2048 × 2048 · Edited today", tint: "#d9c9b7" },
                        { title: "Character sketch", detail: "1800 × 2400 · Yesterday", tint: "#b9c5cf" },
                        { title: "Color practice", detail: "1920 × 1080 · 2 days ago", tint: "#c9b8d8" },
                        { title: "Landscape", detail: "3000 × 2000 · 5 days ago", tint: "#a9c4b3" }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 176
                        radius: 14
                        color: root.surface
                        border.color: root.line
                        Column {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 8
                            Rectangle {
                                width: parent.width
                                height: 112
                                radius: 9
                                color: modelData.tint
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.54
                                    height: parent.height * 0.72
                                    color: "#f4eee6"
                                    border.color: "#d4c8bb"
                                    Rectangle {
                                        width: parent.width * 0.55
                                        height: 2
                                        color: "#85766d"
                                        rotation: -24
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                            Label {
                                text: modelData.title
                                color: root.textColor
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Label {
                                text: modelData.detail
                                color: root.muted
                                font.pixelSize: 10
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.openWorkspace()
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
            Rectangle {
                Layout.fillWidth: true
                height: 54
                radius: 14
                color: root.raised
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    Label { text: "✦"; color: root.accent; font.pixelSize: 18 }
                    Label {
                        text: "A focused workspace for drawing, painting and making."
                        color: root.muted
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // PAINTING WORKSPACE
    Item {
        anchors.fill: parent
        visible: root.page === "workspace"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Compact mobile top bar: document actions, no desktop menu bar.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                color: root.surface
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    ToolButton {
                        text: "‹"
                        font.pixelSize: 26
                        onClicked: root.page = "home"
                    }
                    Label {
                        text: "Untitled"
                        color: root.textColor
                        font.bold: true
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    ToolButton {
                        text: "↶"
                        font.pixelSize: 21
                        onClicked: root.dispatch("undo")
                    }
                    ToolButton {
                        text: "↷"
                        font.pixelSize: 21
                        onClicked: root.dispatch("redo")
                    }
                    ToolButton {
                        text: "▣"
                        onClicked: root.showExport = true
                    }
                    ToolButton {
                        text: "⋮"
                        onClicked: root.choosePanel("more")
                    }
                }
            }

            // Canvas region with touch-first tool rail and collapsible panels.
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 54
                    color: root.surface
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        spacing: 5
                        Repeater {
                            model: [
                                { name: "Brush", glyph: "✎" },
                                { name: "Eraser", glyph: "◩" },
                                { name: "Fill", glyph: "◒" },
                                { name: "Picker", glyph: "⌖" },
                                { name: "Shape", glyph: "□" },
                                { name: "Text", glyph: "T" },
                                { name: "Move", glyph: "✥" }
                            ]
                            delegate: Rectangle {
                                width: 40
                                height: 40
                                radius: 11
                                color: root.selectedTool === modelData.name ? "#4b3829" : "transparent"
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.glyph
                                    color: root.selectedTool === modelData.name ? root.accent : root.muted
                                    font.pixelSize: 20
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.chooseTool(modelData.name)
                                }
                            }
                        }
                    }
                }

                // The engine host is intentionally a replaceable surface.
                // The actual Krita canvas must be mounted here by the native host.
                Rectangle {
                    id: canvasArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#34363d"
                    clip: true

                    Rectangle {
                        id: paper
                        width: Math.min(parent.width - 28, parent.height - 28) * 0.82
                        height: width
                        anchors.centerIn: parent
                        color: "#f7f4ef"
                        border.color: "#d5d0c8"
                        border.width: 1
                        Label {
                            anchors.centerIn: parent
                            width: parent.width * 0.7
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: "KRITA CANVAS HOST\n\nThe mobile interface is ready for the native painting surface."
                            color: "#77716a"
                            font.pixelSize: 13
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 10
                        radius: 9
                        color: "#cc17191f"
                        width: 92
                        height: 30
                        Label {
                            anchors.centerIn: parent
                            text: Math.round(root.zoom) + "%"
                            color: "white"
                            font.pixelSize: 11
                        }
                    }

                    // Native Krita canvas owns stylus strokes, touch gestures and pinch zoom.
                    // Do not place a QML MouseArea over this surface: it would intercept painting input.
                }

                // Right-side panel: collapses on narrow screens.
                Rectangle {
                    visible: root.showLayerPanel && canvasArea.width > 390
                    Layout.fillHeight: true
                    Layout.preferredWidth: 190
                    color: root.surface
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 9
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: root.activePanel === "brushes" ? "Brushes" :
                                      root.activePanel === "layers" ? "Layers" :
                                      root.activePanel === "color" ? "Color" : "More"
                                color: root.textColor
                                font.bold: true
                                font.pixelSize: 15
                            }
                            Item { Layout.fillWidth: true }
                            ToolButton {
                                text: "×"
                                onClicked: root.showLayerPanel = false
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Repeater {
                                model: [
                                    { key: "brushes", glyph: "✎" },
                                    { key: "layers", glyph: "▤" },
                                    { key: "color", glyph: "◉" }
                                ]
                                delegate: ToolButton {
                                    Layout.fillWidth: true
                                    text: modelData.glyph
                                    highlighted: root.activePanel === modelData.key
                                    onClicked: root.choosePanel(modelData.key)
                                }
                            }
                        }

                        StackLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            currentIndex: root.activePanel === "brushes" ? 0 :
                                          root.activePanel === "layers" ? 1 :
                                          root.activePanel === "color" ? 2 : 3

                            // Brush presets
                            ColumnLayout {
                                spacing: 7
                                Button {
                                    Layout.fillWidth: true
                                    text: "＋ Brush Studio"
                                    onClicked: root.showBrushEditor = true
                                }
                                Repeater {
                                    model: ["Basic-5", "Pencil-2", "Ink-3", "Airbrush", "Watercolor", "Texture"]
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 37
                                        radius: 8
                                        color: root.selectedBrush === modelData ? "#4b3829" : root.raised
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 9
                                            Label {
                                                text: "◌"
                                                color: root.accent
                                                font.pixelSize: 16
                                            }
                                            Label {
                                                text: modelData
                                                color: root.textColor
                                                font.pixelSize: 11
                                                Layout.fillWidth: true
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                root.selectedBrush = modelData
                                                root.dispatch("selectBrush", modelData)
                                            }
                                        }
                                    }
                                }
                                Item { Layout.fillHeight: true }
                            }

                            // Layers
                            ColumnLayout {
                                spacing: 7
                                Button {
                                    Layout.fillWidth: true
                                    text: "＋ Add layer"
                                    onClicked: root.dispatch("addLayer")
                                }
                                Repeater {
                                    model: ["Paint Layer 2", "Sketch", "Background"]
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 42
                                        radius: 8
                                        color: index === 0 ? "#4b3829" : root.raised
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            Label { text: "▧"; color: root.accent }
                                            Label {
                                                text: modelData
                                                color: root.textColor
                                                font.pixelSize: 10
                                                Layout.fillWidth: true
                                            }
                                            Label { text: "◉"; color: root.muted }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: root.dispatch("selectLayer", modelData)
                                        }
                                    }
                                }
                                Item { Layout.fillHeight: true }
                            }

                            // Color controls
                            ColumnLayout {
                                spacing: 10
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 82
                                    radius: 10
                                    color: "#d66b4b"
                                    Label {
                                        anchors.centerIn: parent
                                        text: "Current color"
                                        color: "white"
                                        font.pixelSize: 11
                                    }
                                }
                                GridLayout {
                                    columns: 4
                                    Repeater {
                                        model: ["#202027", "#f2f2f2", "#d66b4b", "#e5b45d",
                                                "#77a88b", "#6b8fc8", "#9b7ac4", "#d88da7"]
                                        delegate: Rectangle {
                                            width: 30
                                            height: 30
                                            radius: 15
                                            color: modelData
                                            border.color: "#777"
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: root.dispatch("setForegroundColor", modelData)
                                            }
                                        }
                                    }
                                }
                                Item { Layout.fillHeight: true }
                            }

                            ColumnLayout {
                                Label { text: "Workspace"; color: root.textColor }
                                Button { text: "Canvas settings"; onClicked: root.page = "settings" }
                                Button { text: "Export"; onClicked: root.showExport = true }
                                Item { Layout.fillHeight: true }
                            }
                        }
                    }
                }
            }

            // Contextual brush strip replaces desktop tool-option dockers.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                color: root.surface
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: root.selectedTool + "  ·  " + root.selectedBrush
                            color: root.textColor
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Label { text: "Size " + Math.round(root.brushSize) + " px"; color: root.muted; font.pixelSize: 11 }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Size"; color: root.muted; font.pixelSize: 10 }
                        Slider {
                            Layout.fillWidth: true
                            from: 1
                            to: 500
                            value: root.brushSize
                            onMoved: root.brushSize = value
                            onValueChanged: root.dispatch("setBrushSize", value)
                        }
                        Label { text: Math.round(root.brushSize); color: root.textColor; font.pixelSize: 10; Layout.preferredWidth: 30 }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Opacity"; color: root.muted; font.pixelSize: 10 }
                        Slider {
                            Layout.fillWidth: true
                            from: 1
                            to: 100
                            value: root.brushOpacity
                            onMoved: root.brushOpacity = value
                            onValueChanged: root.dispatch("setBrushOpacity", value)
                        }
                        Label { text: Math.round(root.brushOpacity) + "%"; color: root.textColor; font.pixelSize: 10; Layout.preferredWidth: 34 }
                        ToolButton { text: "▤"; onClicked: root.choosePanel("layers") }
                    }
                }
            }

            // Thumb-friendly bottom navigation for the workspace panels.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                color: root.bg
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    ToolButton { text: "Brush"; onClicked: { root.showLayerPanel = true; root.choosePanel("brushes") } }
                    ToolButton { text: "Layers"; onClicked: { root.showLayerPanel = true; root.choosePanel("layers") } }
                    ToolButton { text: "Color"; onClicked: { root.showLayerPanel = true; root.choosePanel("color") } }
                    Item { Layout.fillWidth: true }
                    ToolButton { text: "−"; onClicked: root.zoom = Math.max(10, root.zoom - 10) }
                    Label { text: Math.round(root.zoom) + "%"; color: root.muted; font.pixelSize: 10 }
                    ToolButton { text: "+"; onClicked: root.zoom = Math.min(800, root.zoom + 10) }
                }
            }
        }
    }

    // SETTINGS: mobile preferences only, no desktop-only configuration pages.
    Item {
        anchors.fill: parent
        visible: root.page === "settings"
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14
            RowLayout {
                ToolButton { text: "‹"; onClicked: root.page = "home" }
                Label { text: "Settings"; color: root.textColor; font.pixelSize: 23; font.bold: true }
                Item { Layout.fillWidth: true }
            }
            Repeater {
                model: [
                    "Pressure sensitivity",
                    "Touch gestures",
                    "Stylus preferences",
                    "Canvas performance",
                    "Autosave",
                    "Interface: phone / tablet",
                    "Brush and resource management"
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 10
                    color: root.surface
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        Label { text: modelData; color: root.textColor; Layout.fillWidth: true; font.pixelSize: 13 }
                        Label { text: "›"; color: root.muted; font.pixelSize: 20 }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    // NEW CANVAS FLOW
    Rectangle {
        anchors.fill: parent
        visible: root.showNewCanvas
        color: "#99000000"
        MouseArea { anchors.fill: parent; onClicked: root.showNewCanvas = false }
        Rectangle {
            width: Math.min(parent.width - 32, 420)
            height: 390
            radius: 18
            color: root.surface
            anchors.centerIn: parent
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                Label { text: "Create canvas"; color: root.textColor; font.pixelSize: 21; font.bold: true }
                Label { text: "Choose a starting size"; color: root.muted; font.pixelSize: 12 }
                Repeater {
                    model: [
                        { title: "Square", size: "2048 × 2048 px" },
                        { title: "Portrait", size: "1800 × 2400 px" },
                        { title: "Landscape", size: "2560 × 1600 px" },
                        { title: "Custom", size: "Set width and height" }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 9
                        color: root.raised
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            Label { text: modelData.title; color: root.textColor; font.bold: true; Layout.fillWidth: true }
                            Label { text: modelData.size; color: root.muted; font.pixelSize: 10 }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.showNewCanvas = false
                                root.openWorkspace()
                                root.dispatch("createDocument", modelData.title)
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Button {
                    Layout.fillWidth: true
                    text: "Cancel"
                    onClicked: root.showNewCanvas = false
                }
            }
        }
    }

    // BRUSH STUDIO: advanced controls remain discoverable without cluttering
    // the everyday canvas workflow.
    Rectangle {
        anchors.fill: parent
        visible: root.showBrushEditor
        color: "#99000000"
        MouseArea { anchors.fill: parent; onClicked: root.showBrushEditor = false }
        Rectangle {
            width: Math.min(parent.width - 24, 520)
            height: Math.min(parent.height - 24, 620)
            radius: 18
            color: root.surface
            anchors.centerIn: parent
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10
                RowLayout {
                    Label { text: "Brush Studio"; color: root.textColor; font.pixelSize: 21; font.bold: true }
                    Item { Layout.fillWidth: true }
                    ToolButton { text: "×"; onClicked: root.showBrushEditor = false }
                }
                Label { text: "Customize the selected preset"; color: root.muted; font.pixelSize: 11 }
                Rectangle {
                    Layout.fillWidth: true
                    height: 90
                    radius: 12
                    color: "#f3f0eb"
                    Label {
                        anchors.centerIn: parent
                        text: "Brush preview"
                        color: "#6b665f"
                        font.pixelSize: 13
                    }
                }
                Repeater {
                    model: ["Tip shape", "Spacing", "Texture", "Size dynamics", "Opacity dynamics", "Tilt and rotation", "Scatter", "Color variation"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 8
                        color: root.raised
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            Label { text: modelData; color: root.textColor; font.pixelSize: 12; Layout.fillWidth: true }
                            Label { text: "›"; color: root.muted; font.pixelSize: 18 }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true
                    Button { Layout.fillWidth: true; text: "Save as new preset"; onClicked: { root.showBrushEditor = false; root.statusText = "Preset saved in UI prototype" } }
                    Button { text: "Done"; onClicked: root.showBrushEditor = false }
                }
            }
        }
    }

    // EXPORT FLOW
    Rectangle {
        anchors.fill: parent
        visible: root.showExport
        color: "#99000000"
        MouseArea { anchors.fill: parent; onClicked: root.showExport = false }
        Rectangle {
            width: Math.min(parent.width - 32, 400)
            height: 310
            radius: 18
            color: root.surface
            anchors.centerIn: parent
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12
                Label { text: "Export artwork"; color: root.textColor; font.pixelSize: 21; font.bold: true }
                Label { text: "Choose a format"; color: root.muted; font.pixelSize: 12 }
                Repeater {
                    model: ["PNG · Transparent image", "JPEG · Compressed image", "WebP · Smaller file", "KRA · Editable project"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        radius: 8
                        color: root.raised
                        Label { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12; text: modelData; color: root.textColor; font.pixelSize: 12 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.dispatch("exportDocument", modelData)
                                root.showExport = false
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Button { Layout.fillWidth: true; text: "Cancel"; onClicked: root.showExport = false }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        visible: root.statusText !== "" && root.statusText !== "Ready"
        radius: 10
        color: "#e52a2d35"
        width: Math.min(parent.width - 32, statusLabel.implicitWidth + 26)
        height: 30
        Label {
            id: statusLabel
            anchors.centerIn: parent
            text: root.statusText
            color: root.textColor
            font.pixelSize: 10
        }
        Timer {
            interval: 2200
            running: root.statusText !== "" && root.statusText !== "Ready"
            onTriggered: root.statusText = "Ready"
        }
    }
}
