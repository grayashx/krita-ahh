import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/*
 * Compact Android workspace controls.
 *
 * The native Krita canvas remains a separate QWidget below this strip. Panels
 * are mutually exclusive so the artist only sees the controls relevant to the
 * current task, instead of a permanently open desktop-style toolbox.
 */
Item {
    id: root

    property string activePanel: ""
    property string activeTool: "Brush"
    property string selectedLayerId: ""
    property string selectedLayerBlendMode: "normal"
    property string colorTarget: "foreground"
    property int selectedBrushId: -1
    property string selectedBrushName: ""
    property string selectedBrushTag: ""
    property string selectedBrushCopyName: ""
    property string selectedBrushTagUrl: ""
    property bool brushManagerVisible: false
    property color foreground: "#000000"
    property color background: "#ffffff"
    property color pickerColor: "#000000"
    property real pickerHue: 0
    property real pickerSaturation: 0
    property real pickerValue: 0
    property bool pickerDirty: false
    property var presetItems: []
    property var brushTagItems: []
    property var brushTagChoices: [{ "url": "", "name": "All brushes" }]
    property var layerItems: []
    property var layerBlendItems: []
    property var recentColorItems: []

    readonly property var quickTools: [
        "Brush", "Eraser", "Picker", "Fill", "Gradient",
        "Line", "Ellipse", "Rectangle"
    ]
    readonly property var moreTools: ["Pencil", "Path", "Text", "Move"]

    implicitHeight: 154 + (activePanel === "" ? 0 : ((activePanel === "brushes" || activePanel === "layers") ? 250 : 224))

    function refreshColors() {
        if (!kritaBridge) return
        foreground = kritaBridge.foregroundColor()
        background = kritaBridge.backgroundColor()
        if (activePanel === "colors" && !pickerDirty) {
            loadPickerColor()
        }
    }

    function refreshRecentColors() {
        recentColorItems = kritaBridge ? kritaBridge.recentColors() : []
    }

    function byteHex(value) {
        var result = Math.round(value * 255).toString(16)
        return result.length < 2 ? "0" + result : result
    }

    function colorToHex(color) {
        return "#" + byteHex(color.r) + byteHex(color.g) + byteHex(color.b)
    }

    function loadPickerColor() {
        pickerColor = colorTarget === "foreground" ? foreground : background
        pickerHue = pickerColor.hsvHue < 0 ? 0 : pickerColor.hsvHue * 360
        pickerSaturation = Math.max(0, pickerColor.hsvSaturation)
        pickerValue = Math.max(0, pickerColor.hsvValue)
        pickerDirty = false
        colorHexField.text = colorToHex(pickerColor)
    }

    function openColorPicker(target) {
        if (activePanel === "colors" && colorTarget === target) {
            activePanel = ""
            return
        }
        colorTarget = target
        activePanel = "colors"
        refreshColors()
        refreshRecentColors()
        loadPickerColor()
    }

    function applyPickerColor() {
        if (!kritaBridge) return
        var hex = colorToHex(pickerColor)
        if (colorTarget === "foreground") {
            kritaBridge.setForegroundColor(hex)
        } else {
            kritaBridge.setBackgroundColor(hex)
        }
        refreshColors()
    }

    function updatePickerColor() {
        pickerColor = Qt.hsva(pickerHue / 360, pickerSaturation, pickerValue, 1)
        pickerDirty = true
        applyPickerColor()
    }

    function updateSaturationValue(x, y, fieldWidth, fieldHeight) {
        pickerSaturation = Math.max(0, Math.min(1, x / fieldWidth))
        pickerValue = 1 - Math.max(0, Math.min(1, y / fieldHeight))
        updatePickerColor()
    }

    function chooseRecentColor(hex) {
        pickerColor = hex
        pickerHue = pickerColor.hsvHue < 0 ? 0 : pickerColor.hsvHue * 360
        pickerSaturation = Math.max(0, pickerColor.hsvSaturation)
        pickerValue = Math.max(0, pickerColor.hsvValue)
        pickerDirty = true
        applyPickerColor()
    }

    function selectTool(name) {
        if (!kritaBridge || !kritaBridge.setActiveTool(name)) return
        activeTool = name
        activePanel = ""
    }

    function togglePanel(name) {
        activePanel = activePanel === name ? "" : name
        if (activePanel === "brushes") {
            brushManagerVisible = false
            refreshBrushTags()
            refreshPresets()
        }
        if (activePanel === "layers") refreshLayers()
        if (activePanel === "colors") {
            refreshColors()
            refreshRecentColors()
            loadPickerColor()
        }
    }

    function refreshBrushTags() {
        brushTagItems = kritaBridge ? kritaBridge.brushTags() : []
        var choices = [{ "url": "", "name": "All brushes" }]
        for (var i = 0; i < brushTagItems.length; ++i)
            choices.push(brushTagItems[i])
        brushTagChoices = choices
    }

    function refreshPresets() {
        presetItems = kritaBridge
            ? kritaBridge.brushPresets(presetSearch.text, selectedBrushTag)
            : []
        if (selectedBrushId < 0) {
            for (var i = 0; i < presetItems.length; ++i) {
                if (presetItems[i].current) {
                    selectedBrushId = presetItems[i].id
                    selectedBrushName = presetItems[i].name
                    selectedBrushCopyName = presetItems[i].name + " Copy"
                    break
                }
            }
        }
    }

    function selectBrush(item) {
        if (!item || !kritaBridge) return
        selectedBrushId = item.id
        selectedBrushName = item.name
        selectedBrushCopyName = item.name + " Copy"
        if (kritaBridge.activateBrushPreset(item.id)) {
            activeTool = "Brush"
            refreshPresets()
        }
    }

    function toggleBrushFavorite(item) {
        if (!kritaBridge || !item) return
        kritaBridge.setBrushFavorite(item.id, !item.favorite)
        refreshPresets()
    }

    function renameSelectedBrush() {
        if (!kritaBridge || selectedBrushId < 0 || !renameBrushField.text.trim()) return
        if (kritaBridge.renameBrushPreset(selectedBrushId, renameBrushField.text.trim())) {
            selectedBrushName = renameBrushField.text.trim()
            renameBrushField.text = ""
            refreshPresets()
        }
    }

    function createSelectedBrushTag() {
        if (!kritaBridge || selectedBrushId < 0 || selectedBrushTagUrl === "") return
        kritaBridge.setBrushTag(selectedBrushId, selectedBrushTagUrl, true)
        refreshPresets()
    }

    function removeSelectedBrushTag() {
        if (!kritaBridge || selectedBrushId < 0 || selectedBrushTagUrl === "") return
        kritaBridge.setBrushTag(selectedBrushId, selectedBrushTagUrl, false)
        refreshPresets()
    }

    function createBrushTag() {
        if (!kritaBridge || !newBrushTagField.text.trim()) return
        if (kritaBridge.createBrushTag(newBrushTagField.text.trim())) {
            newBrushTagField.text = ""
            refreshBrushTags()
        }
    }

    function saveBrushCopy() {
        if (!kritaBridge || !selectedBrushCopyName.trim()) return
        if (kritaBridge.saveCurrentBrushPresetCopy(selectedBrushCopyName.trim())) {
            selectedBrushName = selectedBrushCopyName.trim()
            selectedBrushCopyName = selectedBrushName + " Copy"
            selectedBrushId = -1
            refreshPresets()
        }
    }

    function refreshLayers() {
        layerItems = kritaBridge ? kritaBridge.layers() : []
        selectedLayerId = ""
        selectedLayerBlendMode = "normal"
        for (var i = 0; i < layerItems.length; ++i) {
            if (layerItems[i].active) {
                selectedLayerId = layerItems[i].id
                selectedLayerBlendMode = layerItems[i].blendModeId || "normal"
                layerBlendItems = kritaBridge ? kritaBridge.layerBlendModes(selectedLayerId) : []
                return
            }
        }
        layerBlendItems = []
    }

    function selectedLayerItem() {
        for (var i = 0; i < layerItems.length; ++i) {
            if (layerItems[i].id === selectedLayerId) return layerItems[i]
        }
        return null
    }

    function selectedLayerOpacity() {
        var item = selectedLayerItem()
        return item ? item.opacity : 100
    }

    function setSelectedLayerBlendMode(modeId) {
        if (!kritaBridge || selectedLayerId === "") return
        if (kritaBridge.setLayerBlendMode(selectedLayerId, modeId)) {
            selectedLayerBlendMode = modeId
            refreshLayers()
        }
    }

    function setSelectedLayerAlphaLock(enabled) {
        if (!kritaBridge || selectedLayerId === "") return
        kritaBridge.setLayerAlphaLocked(selectedLayerId, enabled)
        refreshLayers()
    }

    function setSelectedLayerInheritAlpha(enabled) {
        if (!kritaBridge || selectedLayerId === "") return
        kritaBridge.setLayerInheritAlpha(selectedLayerId, enabled)
        refreshLayers()
    }

    function selectedLayerOpacity() {
        for (var i = 0; i < layerItems.length; ++i) {
            if (layerItems[i].id === selectedLayerId) return layerItems[i].opacity
        }
        return 100
    }

    Connections {
        target: kritaBridge
        function onColorsChanged() {
            root.refreshColors()
            root.refreshRecentColors()
        }
        function onDocumentStateChanged() {
            root.refreshColors()
            root.refreshRecentColors()
            root.refreshLayers()
        }
    }

    Component.onCompleted: {
        refreshColors()
        refreshRecentColors()
        refreshLayers()
    }

    Rectangle {
        anchors.fill: parent
        color: "#17191f"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            // Familiar, compact document bar.
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 3

                ToolButton {
                    text: "‹"
                    font.pixelSize: 22
                    onClicked: if (kritaBridge) kritaBridge.showHomeScreen()
                    ToolTip.visible: hovered
                    ToolTip.text: "Home"
                }
                ToolButton {
                    text: "↶"
                    onClicked: if (kritaBridge) kritaBridge.triggerAction("edit_undo")
                    ToolTip.visible: hovered
                    ToolTip.text: "Undo"
                }
                ToolButton {
                    text: "↷"
                    onClicked: if (kritaBridge) kritaBridge.triggerAction("edit_redo")
                    ToolTip.visible: hovered
                    ToolTip.text: "Redo"
                }
                Label {
                    text: "Krita"
                    color: "#f0eee9"
                    font.bold: true
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
                ToolButton {
                    text: "Save"
                    font.pixelSize: 11
                    onClicked: if (kritaBridge) kritaBridge.saveDocument(false)
                }
                ToolButton {
                    text: "Export"
                    font.pixelSize: 11
                    onClicked: if (kritaBridge) kritaBridge.saveDocument(true)
                }
            }

            // The common tools stay one tap away. Less-used tools live in More.
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 3

                Flickable {
                    id: quickToolScroller
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: quickToolRow.implicitWidth
                    flickableDirection: Flickable.HorizontalFlick

                    RowLayout {
                        id: quickToolRow
                        spacing: 3
                        height: quickToolScroller.height

                        Repeater {
                            model: root.quickTools
                            delegate: Button {
                                text: modelData
                                font.pixelSize: 10
                                Layout.preferredWidth: 62
                                Layout.fillHeight: true
                                highlighted: root.activeTool === modelData
                                onClicked: root.selectTool(modelData)
                            }
                        }
                    }
                }

                ToolButton {
                    text: "More"
                    font.pixelSize: 10
                    onClicked: root.togglePanel("tools")
                }
            }

            // Color swatches are direct controls; tap either to open the picker.
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 5

                Button {
                    text: "FG"
                    font.pixelSize: 10
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 27
                    background: Rectangle {
                        radius: 4
                        color: root.foreground
                        border.width: root.colorTarget === "foreground" ? 2 : 1
                        border.color: root.colorTarget === "foreground" ? "#f2a65a" : "#777b86"
                    }
                    contentItem: Text {
                        text: "FG"
                        color: root.foreground.hsvValue < 0.55 ? "white" : "black"
                        font.pixelSize: 10
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.openColorPicker("foreground")
                }
                Button {
                    text: "BG"
                    font.pixelSize: 10
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 27
                    background: Rectangle {
                        radius: 4
                        color: root.background
                        border.width: root.colorTarget === "background" ? 2 : 1
                        border.color: root.colorTarget === "background" ? "#f2a65a" : "#777b86"
                    }
                    contentItem: Text {
                        text: "BG"
                        color: root.background.hsvValue < 0.55 ? "white" : "black"
                        font.pixelSize: 10
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.openColorPicker("background")
                }
                ToolButton {
                    text: "⇄"
                    font.pixelSize: 16
                    onClicked: if (kritaBridge) kritaBridge.swapColors()
                    ToolTip.visible: hovered
                    ToolTip.text: "Swap colors"
                }
                Label { text: "Size"; color: "#c7c4be"; font.pixelSize: 10 }
                Slider {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 40
                    from: 0.1
                    to: 500
                    value: kritaBridge ? kritaBridge.brushSize() : 18
                    onMoved: if (kritaBridge) kritaBridge.setBrushSize(value)
                }
                Label { text: "Opacity"; color: "#c7c4be"; font.pixelSize: 10 }
                Slider {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 40
                    from: 1
                    to: 100
                    value: kritaBridge ? kritaBridge.brushOpacity() : 100
                    onMoved: if (kritaBridge) kritaBridge.setBrushOpacity(value)
                }
            }

            // One contextual panel at a time keeps the canvas and controls calm.
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                spacing: 5

                Button {
                    text: "Brushes"
                    font.pixelSize: 10
                    Layout.fillWidth: true
                    highlighted: root.activePanel === "brushes"
                    onClicked: root.togglePanel("brushes")
                }
                Button {
                    text: "Layers"
                    font.pixelSize: 10
                    Layout.fillWidth: true
                    highlighted: root.activePanel === "layers"
                    onClicked: root.togglePanel("layers")
                }
            }

            Rectangle {
                visible: root.activePanel !== ""
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 224 : 0
                color: "#22252d"
                radius: 6

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 4

                    // COLOR PICKER
                    ColumnLayout {
                        visible: root.activePanel === "colors"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            Label {
                                text: root.colorTarget === "foreground" ? "Foreground color" : "Background color"
                                color: "#f0eee9"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.fillWidth: true
                            }
                            ToolButton {
                                text: root.colorTarget === "foreground" ? "FG" : "BG"
                                font.pixelSize: 10
                                onClicked: root.openColorPicker(root.colorTarget === "foreground" ? "background" : "foreground")
                            }
                            ToolButton {
                                text: "×"
                                onClicked: root.activePanel = ""
                            }
                        }

                        Slider {
                            id: hueSlider
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18
                            from: 0
                            to: 359
                            value: root.pickerHue
                            onMoved: {
                                root.pickerHue = value
                                root.updatePickerColor()
                            }
                            background: Rectangle {
                                x: hueSlider.leftPadding
                                y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                                width: hueSlider.availableWidth
                                height: 10
                                radius: 5
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.00; color: "#ff0000" }
                                    GradientStop { position: 0.17; color: "#ffff00" }
                                    GradientStop { position: 0.33; color: "#00ff00" }
                                    GradientStop { position: 0.50; color: "#00ffff" }
                                    GradientStop { position: 0.67; color: "#0000ff" }
                                    GradientStop { position: 0.83; color: "#ff00ff" }
                                    GradientStop { position: 1.00; color: "#ff0000" }
                                }
                            }
                        }

                        Rectangle {
                            id: saturationValueField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 90
                            radius: 4
                            clip: true
                            color: Qt.hsva(root.pickerHue / 360, 1, 1, 1)

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "#ffffff" }
                                    GradientStop { position: 1; color: "#00ffffff" }
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0; color: "#00000000" }
                                    GradientStop { position: 1; color: "#ff000000" }
                                }
                            }
                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: "transparent"
                                border.width: 2
                                border.color: "white"
                                x: root.pickerSaturation * Math.max(0, parent.width - width)
                                y: (1 - root.pickerValue) * Math.max(0, parent.height - height)
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: root.updateSaturationValue(mouse.x, mouse.y, width, height)
                                onPositionChanged: {
                                    if (pressed) root.updateSaturationValue(mouse.x, mouse.y, width, height)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 27
                            TextField {
                                id: colorHexField
                                Layout.preferredWidth: 92
                                font.pixelSize: 11
                                text: root.colorToHex(root.pickerColor)
                                placeholderText: "#RRGGBB"
                                onAccepted: {
                                    if (/^#[0-9a-fA-F]{6}$/.test(text)) {
                                        root.pickerColor = text
                                        root.pickerHue = root.pickerColor.hsvHue < 0 ? 0 : root.pickerColor.hsvHue * 360
                                        root.pickerSaturation = Math.max(0, root.pickerColor.hsvSaturation)
                                        root.pickerValue = Math.max(0, root.pickerColor.hsvValue)
                                        root.pickerDirty = true
                                        root.applyPickerColor()
                                    }
                                }
                            }
                            Label {
                                text: "Recent"
                                color: "#c7c4be"
                                font.pixelSize: 10
                            }
                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                contentWidth: recentColorsRow.implicitWidth
                                flickableDirection: Flickable.HorizontalFlick
                                Row {
                                    id: recentColorsRow
                                    height: 25
                                    spacing: 4
                                    Repeater {
                                        model: root.recentColorItems
                                        delegate: Rectangle {
                                            width: 22
                                            height: 22
                                            radius: 3
                                            color: modelData
                                            border.color: "#777b86"
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: root.chooseRecentColor(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ADDITIONAL TOOLS
                    ColumnLayout {
                        visible: root.activePanel === "tools"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: "More tools"
                                color: "#f0eee9"
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            ToolButton { text: "×"; onClicked: root.activePanel = "" }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 4
                            rowSpacing: 4
                            columnSpacing: 4
                            Repeater {
                                model: root.moreTools
                                delegate: Button {
                                    text: modelData
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    highlighted: root.activeTool === modelData
                                    onClicked: root.selectTool(modelData)
                                }
                            }
                        }
                    }

                    // BRUSH PRESETS AND MANAGEMENT
                    ColumnLayout {
                        visible: root.activePanel === "brushes"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        ColumnLayout {
                            visible: !root.brushManagerVisible
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                TextField {
                                    id: presetSearch
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    font.pixelSize: 11
                                    placeholderText: "Search brushes"
                                    onTextChanged: root.refreshPresets()
                                }
                                ComboBox {
                                    id: brushTagFilter
                                    Layout.preferredWidth: 124
                                    Layout.preferredHeight: 28
                                    font.pixelSize: 10
                                    textRole: "name"
                                    model: root.brushTagChoices
                                    currentIndex: {
                                        for (var i = 0; i < root.brushTagChoices.length; ++i) {
                                            if (root.brushTagChoices[i].url === root.selectedBrushTag) return i
                                        }
                                        return 0
                                    }
                                    onActivated: {
                                        root.selectedBrushTag = root.brushTagChoices[index].url
                                        root.refreshPresets()
                                    }
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 1
                                model: root.presetItems
                                delegate: RowLayout {
                                    width: ListView.view.width
                                    height: 30
                                    spacing: 4
                                    Button {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: modelData.name + (modelData.current ? "  •" : "")
                                        font.pixelSize: 10
                                        highlighted: modelData.current || root.selectedBrushId === modelData.id
                                        onClicked: root.selectBrush(modelData)
                                    }
                                    ToolButton {
                                        Layout.preferredWidth: 32
                                        Layout.fillHeight: true
                                        text: modelData.favorite ? "★" : "☆"
                                        font.pixelSize: 16
                                        onClicked: root.toggleBrushFavorite(modelData)
                                        ToolTip.visible: hovered
                                        ToolTip.text: modelData.favorite ? "Remove favorite" : "Add favorite"
                                    }
                                }
                                ScrollBar.vertical: ScrollBar {}
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                Button {
                                    text: "Editor"
                                    font.pixelSize: 10
                                    Layout.fillWidth: true
                                    onClicked: if (kritaBridge) kritaBridge.triggerAction("show_brush_editor")
                                }
                                Button {
                                    text: "Save"
                                    font.pixelSize: 10
                                    Layout.fillWidth: true
                                    enabled: selectedBrushId >= 0
                                    onClicked: {
                                        if (kritaBridge) kritaBridge.saveCurrentBrushPreset()
                                        root.refreshPresets()
                                    }
                                }
                                Button {
                                    text: "Manage"
                                    font.pixelSize: 10
                                    Layout.fillWidth: true
                                    enabled: selectedBrushId >= 0
                                    onClicked: root.brushManagerVisible = true
                                }
                            }
                        }

                        ColumnLayout {
                            visible: root.brushManagerVisible
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 22
                                Label {
                                    text: "Manage brush"
                                    color: "#f0eee9"
                                    font.bold: true
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: root.selectedBrushName
                                    color: "#c7c4be"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 150
                                }
                                ToolButton {
                                    text: "‹"
                                    onClicked: root.brushManagerVisible = false
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                TextField {
                                    id: renameBrushField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    font.pixelSize: 10
                                    placeholderText: "New brush name"
                                }
                                Button {
                                    text: "Rename"
                                    font.pixelSize: 10
                                    onClicked: root.renameSelectedBrush()
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                ComboBox {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    font.pixelSize: 10
                                    textRole: "name"
                                    model: root.brushTagChoices
                                    currentIndex: {
                                        for (var i = 0; i < root.brushTagChoices.length; ++i) {
                                            if (root.brushTagChoices[i].url === root.selectedBrushTagUrl) return i
                                        }
                                        return 0
                                    }
                                    onActivated: root.selectedBrushTagUrl = root.brushTagChoices[index].url
                                }
                                Button {
                                    text: "+"
                                    font.pixelSize: 11
                                    enabled: root.selectedBrushTagUrl !== ""
                                    onClicked: root.createSelectedBrushTag()
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Add brush to selected tag"
                                }
                                Button {
                                    text: "−"
                                    font.pixelSize: 11
                                    enabled: root.selectedBrushTagUrl !== ""
                                    onClicked: root.removeSelectedBrushTag()
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Remove brush from selected tag"
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                TextField {
                                    id: newBrushTagField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    font.pixelSize: 10
                                    placeholderText: "Create a brush tag"
                                }
                                Button {
                                    text: "Add tag"
                                    font.pixelSize: 10
                                    onClicked: root.createBrushTag()
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                TextField {
                                    id: copyBrushField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    font.pixelSize: 10
                                    text: root.selectedBrushCopyName
                                    placeholderText: "Copy name"
                                    onTextChanged: root.selectedBrushCopyName = text
                                }
                                Button {
                                    text: "Save copy"
                                    font.pixelSize: 10
                                    onClicked: root.saveBrushCopy()
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                Button {
                                    text: "Save changes"
                                    Layout.fillWidth: true
                                    font.pixelSize: 10
                                    onClicked: {
                                        if (kritaBridge) kritaBridge.saveCurrentBrushPreset()
                                        root.refreshPresets()
                                    }
                                }
                                Button {
                                    text: "Brush editor"
                                    Layout.fillWidth: true
                                    font.pixelSize: 10
                                    onClicked: if (kritaBridge) kritaBridge.triggerAction("show_brush_editor")
                                }
                            }
                        }
                    }

                    // DOCUMENT LAYERS AND ADVANCED PROPERTIES
                    ColumnLayout {
                        visible: root.activePanel === "layers"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 23
                            Label {
                                text: "Layers"
                                color: "#f0eee9"
                                font.bold: true
                                font.pixelSize: 11
                                Layout.fillWidth: true
                            }
                            ToolButton {
                                text: "+"
                                onClicked: layerAddMenu.open()
                                ToolTip.visible: hovered
                                ToolTip.text: "Add layer or mask"
                            }
                            Menu {
                                id: layerAddMenu
                                MenuItem {
                                    text: "Paint layer"
                                    onTriggered: {
                                        if (kritaBridge) kritaBridge.addPaintLayer()
                                        root.refreshLayers()
                                    }
                                }
                                MenuItem {
                                    text: "Group layer"
                                    onTriggered: {
                                        if (kritaBridge) kritaBridge.addGroupLayer()
                                        root.refreshLayers()
                                    }
                                }
                                MenuItem {
                                    text: "Transparency mask"
                                    onTriggered: {
                                        if (kritaBridge) kritaBridge.addTransparencyMask()
                                        root.refreshLayers()
                                    }
                                }
                                MenuItem {
                                    text: "Filter mask"
                                    onTriggered: {
                                        if (kritaBridge) kritaBridge.addFilterMask()
                                        root.refreshLayers()
                                    }
                                }
                            }
                            ToolButton {
                                text: "Dup"
                                font.pixelSize: 9
                                enabled: root.selectedLayerId !== ""
                                onClicked: {
                                    if (kritaBridge) kritaBridge.duplicateLayer(root.selectedLayerId)
                                    root.refreshLayers()
                                }
                            }
                            ToolButton {
                                text: "Merge"
                                font.pixelSize: 9
                                enabled: root.selectedLayerId !== ""
                                onClicked: {
                                    if (kritaBridge) kritaBridge.mergeLayerDown(root.selectedLayerId)
                                    root.refreshLayers()
                                }
                            }
                            ToolButton {
                                text: "↑"
                                enabled: root.selectedLayerId !== ""
                                onClicked: {
                                    if (kritaBridge) kritaBridge.raiseLayer(root.selectedLayerId)
                                    root.refreshLayers()
                                }
                            }
                            ToolButton {
                                text: "↓"
                                enabled: root.selectedLayerId !== ""
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
                            Layout.minimumHeight: 64
                            clip: true
                            spacing: 1
                            model: root.layerItems
                            delegate: RowLayout {
                                width: ListView.view.width
                                height: 31
                                spacing: 2
                                CheckBox {
                                    checked: modelData.visible
                                    onToggled: {
                                        if (kritaBridge) kritaBridge.setLayerVisible(modelData.id, checked)
                                        root.refreshLayers()
                                    }
                                }
                                Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: modelData.name + (modelData.active ? "  •" : "")
                                    font.pixelSize: 10
                                    highlighted: modelData.active || root.selectedLayerId === modelData.id
                                    onClicked: {
                                        root.selectedLayerId = modelData.id
                                        if (kritaBridge) kritaBridge.activateLayer(modelData.id)
                                        root.refreshLayers()
                                    }
                                }
                                ToolButton {
                                    text: modelData.locked ? "L" : "U"
                                    onClicked: {
                                        if (kritaBridge) kritaBridge.setLayerLocked(modelData.id, !modelData.locked)
                                        root.refreshLayers()
                                    }
                                }
                                TextField {
                                    Layout.preferredWidth: 68
                                    Layout.preferredHeight: 27
                                    font.pixelSize: 9
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
                            Layout.preferredHeight: 23
                            Label { text: "Opacity"; color: "#c7c4be"; font.pixelSize: 10 }
                            Slider {
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: root.selectedLayerOpacity()
                                enabled: root.selectedLayerId !== ""
                                onMoved: {
                                    if (kritaBridge && root.selectedLayerId !== "")
                                        kritaBridge.setLayerOpacity(root.selectedLayerId, value)
                                }
                                onPressedChanged: if (!pressed) root.refreshLayers()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 25
                            Label { text: "Blend"; color: "#c7c4be"; font.pixelSize: 10 }
                            ComboBox {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 25
                                font.pixelSize: 10
                                model: root.layerBlendItems
                                textRole: "name"
                                currentIndex: {
                                    for (var i = 0; i < root.layerBlendItems.length; ++i) {
                                        if (root.layerBlendItems[i].id === root.selectedLayerBlendMode) return i
                                    }
                                    return 0
                                }
                                enabled: root.selectedLayerId !== "" && root.layerBlendItems.length > 0
                                onActivated: {
                                    var mode = root.layerBlendItems[index]
                                    if (mode) root.setSelectedLayerBlendMode(mode.id)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            spacing: 14
                            CheckBox {
                                text: "Alpha lock"
                                font.pixelSize: 10
                                visible: root.selectedLayerItem() ? root.selectedLayerItem().isPaintLayer : false
                                checked: root.selectedLayerItem() ? root.selectedLayerItem().alphaLocked : false
                                onToggled: root.setSelectedLayerAlphaLock(checked)
                            }
                            CheckBox {
                                text: "Inherit alpha"
                                font.pixelSize: 10
                                visible: root.selectedLayerItem() ? root.selectedLayerItem().isLayer : false
                                checked: root.selectedLayerItem() ? root.selectedLayerItem().inheritAlpha : false
                                onToggled: root.setSelectedLayerInheritAlpha(checked)
                            }
                        }
                    }
                }
            }
        }
    }

    onPickerColorChanged: {
        if (colorHexField && !colorHexField.activeFocus)
            colorHexField.text = colorToHex(pickerColor)
    }
}
