import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    implicitHeight: 132

    Rectangle {
        anchors.fill: parent
        color: "#17191f"

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 5

                ToolButton {
                    text: "‹ Home"
                    onClicked: if (kritaBridge) kritaBridge.showHomeScreen()
                }
                Label {
                    text: "Krita"
                    color: "#f0eee9"
                    font.bold: true
                    Layout.fillWidth: true
                }
                ToolButton {
                    text: "↶"
                    onClicked: if (kritaBridge) kritaBridge.triggerAction("edit_undo")
                }
                ToolButton {
                    text: "↷"
                    onClicked: if (kritaBridge) kritaBridge.triggerAction("edit_redo")
                }
                ToolButton {
                    text: "Save"
                    onClicked: if (kritaBridge) kritaBridge.saveDocument(false)
                }
                ToolButton {
                    text: "Export"
                    onClicked: if (kritaBridge) kritaBridge.saveDocument(true)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 3

                Repeater {
                    model: ["Brush", "Eraser", "Picker", "Shape"]
                    delegate: Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 29
                        text: modelData
                        font.pixelSize: 11
                        onClicked: {
                            if (!kritaBridge) return
                            if (modelData === "Eraser") {
                                kritaBridge.setActiveTool("Brush")
                                kritaBridge.setEraserMode(true)
                            } else {
                                if (modelData === "Brush")
                                    kritaBridge.setEraserMode(false)
                                kritaBridge.setActiveTool(modelData)
                            }
                        }
                    }
                }

                Button {
                    text: "+ Layer"
                    font.pixelSize: 11
                    Layout.preferredHeight: 29
                    onClicked: if (kritaBridge) kritaBridge.triggerAction("add_new_paint_layer")
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Label {
                    text: "Size"
                    color: "#c7c4be"
                    font.pixelSize: 10
                }
                Slider {
                    Layout.fillWidth: true
                    from: 1
                    to: 500
                    value: kritaBridge ? kritaBridge.brushSize() : 18
                    onMoved: if (kritaBridge) kritaBridge.setBrushSize(value)
                }
                Label {
                    text: "Opacity"
                    color: "#c7c4be"
                    font.pixelSize: 10
                }
                Slider {
                    Layout.fillWidth: true
                    from: 1
                    to: 100
                    value: kritaBridge ? kritaBridge.brushOpacity() : 100
                    onMoved: if (kritaBridge) kritaBridge.setBrushOpacity(value)
                }
            }
        }
    }
}
