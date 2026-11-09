import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property bool showBrushes: false
    property bool showLayers: false
    property var presetItems: []
    property var layerItems: []
    property double selectedLayerId: 0
    readonly property bool tabletLayout: width >= 720
    implicitHeight: 168 + ((showBrushes || showLayers) ? 230 : 0)

    function refreshPresets() {
        presetItems = kritaBridge ? kritaBridge.brushPresets(presetSearch.text) : []
    }
    function refreshLayers() {
        layerItems = kritaBridge ? kritaBridge.layers() : []
        if (selectedLayerId === 0 && layerItems.length) {
            for (var i = 0; i < layerItems.length; ++i) {
                if (layerItems[i].active) {
                    selectedLayerId = layerItems[i].id
                    break
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#17191f"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 7
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                ToolButton { text: "‹ Home"; onClicked: if (kritaBridge) kritaBridge.showHomeScreen() }
                Label { text: "Krita"; color: "#f0eee9"; font.bold: true; Layout.fillWidth: true }
                ToolButton { text: "↶"; onClicked: if (kritaBridge) kritaBridge.triggerAction("edit_undo") }
                ToolButton { text: "↷"; onClicked: if (kritaBridge) kritaBridge.triggerAction("edit_redo") }
                ToolButton { text: "Save"; onClicked: if (kritaBridge) kritaBridge.saveDocument(false) }
                ToolButton { text: "Export"; onClicked: if (kritaBridge) kritaBridge.saveDocument(true) }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Label { text: "FG"; color: "#c7c4be"; font.pixelSize: 10 }
                TextField {
                    id: foregroundHex
                    Layout.preferredWidth: 92
                    text: kritaBridge ? kritaBridge.foregroundColor() : "#000000"
                    placeholderText: "#RRGGBB"
                    onAccepted: if (kritaBridge) kritaBridge.setForegroundColor(text)
                }
                Button {
                    text: "Set"
                    onClicked: if (kritaBridge) kritaBridge.setForegroundColor(foregroundHex.text)
                }
                Label { text: "BG"; color: "#c7c4be"; font.pixelSize: 10 }
                TextField {
                    id: backgroundHex
                    Layout.preferredWidth: 92
                    text: kritaBridge ? kritaBridge.backgroundColor() : "#ffffff"
                    placeholderText: "#RRGGBB"
                    onAccepted: if (kritaBridge) kritaBridge.setBackgroundColor(text)
                }
                Button {
                    text: "Set"
                    onClicked: if (kritaBridge) kritaBridge.setBackgroundColor(backgroundHex.text)
                }
                Button {
                    text: "Swap"
                    onClicked: {
                        if (kritaBridge) kritaBridge.swapColors()
                        foregroundHex.text = kritaBridge ? kritaBridge.foregroundColor() : "#000000"
                        backgroundHex.text = kritaBridge ? kritaBridge.backgroundColor() : "#ffffff"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 31
                spacing: 4
                Repeater {
                    model: ["Brush", "Eraser", "Picker", "Shape"]
                    delegate: Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        text: modelData
                        font.pixelSize: 11
                        onClicked: {
                            if (!kritaBridge) return
                            if (modelData === "Eraser") {
                                kritaBridge.setActiveTool("Brush")
                                kritaBridge.setEraserMode(true)
                            } else {
                                if (modelData === "Brush") kritaBridge.setEraserMode(false)
                                kritaBridge.setActiveTool(modelData)
                            }
                        }
                    }
                }
                Button {
                    text: "+ Layer"
                    font.pixelSize: 11
                    onClicked: {
                        if (kritaBridge) kritaBridge.addPaintLayer()
                        refreshLayers()
                    }
                }
                Button {
                    text: "Brushes"
                    highlighted: root.showBrushes
                    onClicked: {
                        root.showBrushes = !root.showBrushes
                        if (!root.tabletLayout) root.showLayers = false
                        if (root.showBrushes) refreshPresets()
                    }
                }
                Button {
                    text: "Layers"
                    highlighted: root.showLayers
                    onClicked: {
                        root.showLayers = !root.showLayers
                        if (!root.tabletLayout) root.showBrushes = false
                        if (root.showLayers) refreshLayers()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                Label { text: "Size"; color: "#c7c4be"; font.pixelSize: 10 }
                Slider {
                    Layout.fillWidth: true
                    from: 1; to: 500
                    value: kritaBridge ? kritaBridge.brushSize() : 18
                    onMoved: if (kritaBridge) kritaBridge.setBrushSize(value)
                }
                Label { text: "Opacity"; color: "#c7c4be"; font.pixelSize: 10 }
                Slider {
                    Layout.fillWidth: true
                    from: 1; to: 100
                    value: kritaBridge ? kritaBridge.brushOpacity() : 100
                    onMoved: if (kritaBridge) kritaBridge.setBrushOpacity(value)
                }
            }

            Rectangle {
                visible: root.showBrushes || root.showLayers
                Layout.fillWidth: true
                Layout.preferredHeight: 224
                color: "#22252d"
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    ColumnLayout {
                        visible: root.showBrushes
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        TextField {
                            id: presetSearch
                            Layout.fillWidth: true
                            placeholderText: "Search brush presets"
                            onTextChanged: root.refreshPresets()
                        }
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: root.presetItems
                            delegate: ItemDelegate {
                                width: ListView.view.width
                                height: 38
                                text: modelData.name
                                onClicked: {
                                    if (kritaBridge) kritaBridge.activateBrushPreset(modelData.id)
                                }
                            }
                            ScrollBar.vertical: ScrollBar {}
                        }
                    }

                    ColumnLayout {
                        visible: root.showLayers
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Document layers"; color: "#f0eee9"; font.bold: true; Layout.fillWidth: true }
                            ToolButton {
                                text: "↑"
                                enabled: root.selectedLayerId !== 0
                                onClicked: {
                                    if (kritaBridge) kritaBridge.raiseLayer(root.selectedLayerId)
                                    root.refreshLayers()
                                }
                            }
                            ToolButton {
                                text: "↓"
                                enabled: root.selectedLayerId !== 0
                                onClicked: {
                                    if (kritaBridge) kritaBridge.lowerLayer(root.selectedLayerId)
                                    root.refreshLayers()
                                }
                            }
                            ToolButton { text: "↻"; onClicked: root.refreshLayers() }
                        }
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 2
                            model: root.layerItems
                            delegate: RowLayout {
                                width: ListView.view.width
                                height: 38
                                CheckBox {
                                    checked: modelData.visible
                                    onToggled: {
                                        if (kritaBridge) kritaBridge.setLayerVisible(modelData.id, checked)
                                        root.refreshLayers()
                                    }
                                }
                                Button {
                                    Layout.fillWidth: true
                                    text: modelData.name + (modelData.active ? "  •" : "")
                                    highlighted: modelData.active || root.selectedLayerId === modelData.id
                                    onClicked: {
                                        root.selectedLayerId = modelData.id
                                        if (kritaBridge) kritaBridge.activateLayer(modelData.id)
                                        root.refreshLayers()
                                    }
                                }
                                ToolButton {
                                    text: modelData.locked ? "🔒" : "🔓"
                                    onClicked: {
                                        if (kritaBridge) kritaBridge.setLayerLocked(modelData.id, !modelData.locked)
                                        root.refreshLayers()
                                    }
                                }
                                TextField {
                                    Layout.preferredWidth: 100
                                    placeholderText: "Rename"
                                    onAccepted: {
                                        if (kritaBridge && text.trim().length)
                                            kritaBridge.renameLayer(modelData.id, text)
                                        text = ""
                                        root.refreshLayers()
                                    }
                                }
                                ToolButton {
                                    text: "×"
                                    onClicked: {
                                        if (kritaBridge) kritaBridge.removeLayer(modelData.id)
                                        root.refreshLayers()
                                    }
                                }
                            }
                            ScrollBar.vertical: ScrollBar {}
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Layer opacity"; color: "#c7c4be"; font.pixelSize: 10 }
                            Slider {
                                Layout.fillWidth: true
                                from: 0; to: 100
                                value: {
                                    for (var i = 0; i < root.layerItems.length; ++i)
                                        if (root.layerItems[i].id === root.selectedLayerId)
                                            return root.layerItems[i].opacity
                                    return 100
                                }
                                onMoved: {
                                    if (kritaBridge && root.selectedLayerId !== 0)
                                        kritaBridge.setLayerOpacity(root.selectedLayerId, value)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
