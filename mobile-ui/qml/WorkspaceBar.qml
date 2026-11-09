import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property bool showBrushes: false
    property bool showLayers: false
    property var presetItems: []
    property var layerItems: []
    implicitHeight: 132 + ((showBrushes || showLayers) ? 194 : 0)

    function refreshPresets() {
        presetItems = kritaBridge ? kritaBridge.brushPresets(presetSearch.text) : []
    }
    function refreshLayers() {
        layerItems = kritaBridge ? kritaBridge.layers() : []
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
                        root.showLayers = false
                        if (root.showBrushes) refreshPresets()
                    }
                }
                Button {
                    text: "Layers"
                    highlighted: root.showLayers
                    onClicked: {
                        root.showLayers = !root.showLayers
                        root.showBrushes = false
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
                Layout.preferredHeight: 188
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
                                height: 40
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
                                    highlighted: modelData.active
                                    onClicked: {
                                        if (kritaBridge) kritaBridge.activateLayer(modelData.id)
                                        root.refreshLayers()
                                    }
                                }
                                TextField {
                                    Layout.preferredWidth: 150
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
                    }
                }
            }
        }
    }
}
