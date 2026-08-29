import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
    id: root
    moduleName: "steelseries.mouse-controller"
    manageIpc: false

    property var anchorItem: null
    property var hostWidget: null
    property var mouse: null

    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property color urgent: bar ? bar.urgent : Color.urgent
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

    readonly property bool mouseConnected: mouse ? mouse.connected : false
    readonly property string deviceName: mouse ? mouse.deviceName : "SteelSeries Mouse"
    readonly property int batteryPercentage: mouse ? mouse.batteryPercentage : Model.LEVEL_UNKNOWN
    readonly property string batteryStatus: mouse ? mouse.batteryStatus : "unknown"
    readonly property int dpiX: mouse ? mouse.dpiX : 0
    readonly property int dpiY: mouse ? mouse.dpiY : 0
    readonly property int dpiMin: mouse ? mouse.dpiMin : 100
    readonly property int dpiMax: mouse ? mouse.dpiMax : 18000
    readonly property var dpiPresets: mouse ? mouse.dpiPresets : [400, 800, 1600, 2400, 3200]
    readonly property int dpiSelected: mouse ? mouse.dpiSelected : 0
    readonly property int reportRate: mouse ? mouse.reportRate : 1000
    readonly property var buttons: mouse ? mouse.buttons : Model.defaultButtons()
    readonly property string lastError: mouse ? mouse.lastError : ""

    property int currentTab: 0

    function open() {
        root.controller.show()
        if (mouse) mouse.refresh()
    }

    function close() {
        root.controller.hide()
    }

    function toggle() {
        if (root.opened) root.close()
        else root.open()
    }

    function switchPanel(direction) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function") {
            return root.bar.switchPanelFrom(root.hostWidget || root, direction)
        }
        return false
    }

    onOpenedChanged: if (opened) {
        if (panelFlick) panelFlick.contentY = 0
        if (mouse) mouse.refresh()
        Qt.callLater(function () { keyCatcher.forceActiveFocus() })
    }

    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(380))
        contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(720))

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            blocked: btn1DD.popupOpen || btn2DD.popupOpen || btn3DD.popupOpen
                     || btn4DD.popupOpen || btn5DD.popupOpen || btn6DD.popupOpen
            onCloseRequested: root.close()
            onTabRequested: function (direction) {
                root.switchPanel(direction);
            }

            Flickable {
                id: panelFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: content.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                interactive: contentHeight > height
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: content
                    width: panelFlick.width - (panelFlick.interactive ? Style.space(8) : 0)
                    spacing: Style.space(12)

                    // ── Dynamic Device Header ──
                    Row {
                        width: parent.width
                        spacing: Style.space(8)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰍽"
                            color: root.foreground
                            font.family: "monospace"
                            font.pixelSize: Style.font.heading
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.deviceName.toUpperCase()
                            textFormat: Text.PlainText
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.subtitle
                            font.bold: true
                        }
                    }

                    // ── Battery & Telemetry Banner ──
                    Rectangle {
                        width: parent.width
                        height: Style.space(50)
                        radius: 8
                        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.mouseConnected ? 0.08 : 0.04)
                        border.width: 1
                        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

                        Row {
                            anchors.centerIn: parent
                            spacing: Style.space(14)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.mouseConnected ? Model.batteryIcon(root.batteryPercentage, root.batteryStatus) : "󰍽"
                                color: root.foreground
                                opacity: root.mouseConnected ? 1.0 : 0.5
                                font.family: "monospace"
                                font.pixelSize: Style.font.display
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Style.space(2)

                                Text {
                                    text: root.mouseConnected ? "Battery: " + Model.batteryText(root.batteryPercentage) + " (" + root.batteryStatus + ")" : "Disconnected"
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.body
                                    font.bold: true
                                }

                                Text {
                                    text: root.mouseConnected ? "DPI: " + Model.dpiText(root.dpiX, root.dpiY) + " · " + root.reportRate + "Hz" : "Check USB connection / rivalcfg permissions"
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.bodySmall
                                    opacity: 0.6
                                }
                            }
                        }
                    }

                    // ── Tab bar ──
                    Row {
                        width: parent.width
                        height: Style.space(34)
                        spacing: Style.space(6)

                        Rectangle {
                            width: Math.floor((parent.width - Style.space(6)) / 2)
                            height: parent.height
                            radius: 6
                            color: root.currentTab === 0 ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
                            border.width: root.currentTab === 0 ? 1 : 0
                            border.color: root.foreground

                            Text {
                                anchors.centerIn: parent
                                text: "Sensitivity & Polling"
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.bodySmall
                                font.bold: root.currentTab === 0
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = 0
                            }
                        }

                        Rectangle {
                            width: Math.floor((parent.width - Style.space(6)) / 2)
                            height: parent.height
                            radius: 6
                            color: root.currentTab === 1 ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
                            border.width: root.currentTab === 1 ? 1 : 0
                            border.color: root.foreground

                            Text {
                                anchors.centerIn: parent
                                text: "Buttons Mapping"
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.bodySmall
                                font.bold: root.currentTab === 1
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = 1
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════════════
                    // ── TAB 1: SENSITIVITY (DPI PRESETS) + REPORT RATE
                    // ═══════════════════════════════════════════════════════════
                    Column {
                        width: parent.width
                        visible: root.mouseConnected && root.currentTab === 0

                        Column {
                            width: parent.width
                            spacing: Style.space(8)

                            Item {
                                width: parent.width
                                height: Style.space(20)

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "SENSITIVITY (DPI)"
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.bodySmall
                                    font.bold: true
                                    opacity: 0.6
                                }

                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Style.space(6)

                                    Rectangle {
                                        width: Style.space(20)
                                        height: Style.space(20)
                                        radius: 3
                                        color: root.dpiPresets.length > 1 ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "−"
                                            color: root.foreground
                                            opacity: root.dpiPresets.length > 1 ? 0.9 : 0.3
                                            font.family: root.fontFamily
                                            font.pixelSize: Style.font.body
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.dpiPresets.length > 1
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (root.mouse) root.mouse.removePreset()
                                        }
                                    }

                                    Rectangle {
                                        width: Style.space(20)
                                        height: Style.space(20)
                                        radius: 3
                                        color: root.dpiPresets.length < 5 ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "+"
                                            color: root.foreground
                                            opacity: root.dpiPresets.length < 5 ? 0.9 : 0.3
                                            font.family: root.fontFamily
                                            font.pixelSize: Style.font.body
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.dpiPresets.length < 5
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (root.mouse) root.mouse.addPreset()
                                        }
                                    }
                                }
                            }

                            // Preset selector buttons
                            Row {
                                width: parent.width
                                spacing: Style.space(6)
                                Repeater {
                                    model: root.dpiPresets
                                    delegate: Rectangle {
                                        width: Math.floor((parent.width - Style.space(6) * (root.dpiPresets.length - 1) - Style.space(6) * 2) / root.dpiPresets.length)
                                        height: Style.space(28)
                                        radius: 4
                                        color: root.dpiSelected === index ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                                        border.width: root.dpiSelected === index ? 1 : 0
                                        border.color: root.foreground

                                        Text {
                                            anchors.centerIn: parent
                                            text: String(modelData)
                                            textFormat: Text.PlainText
                                            color: root.foreground
                                            font.family: root.fontFamily
                                            font.pixelSize: Style.font.bodySmall
                                            font.bold: root.dpiSelected === index
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                dpiSlider.value = modelData
                                                if (root.mouse)
                                                root.mouse.setSelected(index)
                                            }
                                        }
                                    }
                                }
                            }

                            // Active preset slider (step 100)
                            Column {
                                width: parent.width
                                spacing: 0

                                Item {
                                    width: parent.width
                                    height: Style.space(20)

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Active preset " + (root.dpiSelected + 1) + " of " + root.dpiPresets.length
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.caption
                                        opacity: 0.8
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Math.round(dpiSlider.dragging ? dpiSlider.liveValue : (root.mouse ? root.mouse.dpiX : 800)) + " DPI"
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: true
                                    }
                                }

                                PanelSlider {
                                    id: dpiSlider
                                    width: parent.width
                                    bar: root.bar
                                    minimum: root.dpiMin
                                    maximum: root.dpiMax
                                    step: 100
                                    integer: true
                                    tickCount: 0
                                    value: (root.dpiX && root.dpiX > 0) ? root.dpiX : 800
                                    onMoved: function (val) {
                                        dpiSlider.value = Math.round(val / 100) * 100;
                                    }
                                    onReleased: function (val) {
                                        var target = Math.round(val / 100) * 100;
                                        dpiSlider.value = target;
                                        if (root.mouse)
                                        root.mouse.setDpiPresetValue(target);
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Style.space(14)

                                    Text {
                                        anchors.left: parent.left
                                        text: String(root.dpiMin)
                                        color: root.foreground
                                        opacity: 0.35
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(root.dpiMax / 2).toLocaleString()
                                        color: root.foreground
                                        opacity: 0.25
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        text: root.dpiMax.toLocaleString()
                                        color: root.foreground
                                        opacity: 0.35
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: root.foreground
                            opacity: 0.1
                        }


                    // ═══════════════════════════════════════════════════════════
                    // ── REPORT RATE (POLLING)
                    // ═══════════════════════════════════════════════════════════
                    Column {
                        width: parent.width
                        spacing: Style.space(8)

                        Item {
                            width: parent.width
                            height: Style.space(20)

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "REPORT RATE (POLLING)"
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.bodySmall
                                font.bold: true
                                opacity: 0.6
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.mouse ? root.mouse.reportRate : 1000) + " Hz"
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.bodySmall
                                font.bold: true
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Style.space(6)
                            Repeater {
                                model: [125, 250, 500, 1000]
                                delegate: Rectangle {
                                    width: Math.floor((parent.width - Style.space(6) * 3) / 4)
                                    height: Style.space(28)
                                    radius: 4
                                    color: (root.mouse && root.mouse.reportRate === modelData) ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                                    border.width: (root.mouse && root.mouse.reportRate === modelData) ? 1 : 0
                                    border.color: root.foreground

                                    Text {
                                        anchors.centerIn: parent
                                        text: String(modelData)
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.bodySmall
                                        font.bold: root.mouse && root.mouse.reportRate === modelData
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (root.mouse)
                                        root.mouse.setReportRate(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: root.foreground
                        opacity: 0.1
                    }
                    } // end TAB 1

                    // ═══════════════════════════════════════════════════════════
                    // ── TAB 2: BUTTONS MAPPING
                    // ═══════════════════════════════════════════════════════════
                    Column {
                        width: parent.width
                        spacing: Style.space(8)
                        visible: root.mouseConnected && root.currentTab === 1

                        Text {
                            text: "BUTTONS MAPPING"
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.bodySmall
                            font.bold: true
                            opacity: 0.6
                        }

                        Dropdown {
                            id: btn1DD
                            width: parent.width
                            height: Style.space(44)
                            label: "Button 1 (left click)"
                            foreground: root.foreground
                            value: root.buttons.button1
                            options: root.buttonOptions
                            onChanged: function (value) { if (root.mouse) root.mouse.setButton("button1", value) }
                        }
                        Dropdown {
                            id: btn2DD
                            width: parent.width
                            height: Style.space(44)
                            label: "Button 2 (right click)"
                            foreground: root.foreground
                            value: root.buttons.button2
                            options: root.buttonOptions
                            onChanged: function (value) { if (root.mouse) root.mouse.setButton("button2", value) }
                        }
                        Dropdown {
                            id: btn3DD
                            width: parent.width
                            height: Style.space(44)
                            label: "Button 3 (middle click)"
                            foreground: root.foreground
                            value: root.buttons.button3
                            options: root.buttonOptions
                            onChanged: function (value) { if (root.mouse) root.mouse.setButton("button3", value) }
                        }
                        Dropdown {
                            id: btn4DD
                            width: parent.width
                            height: Style.space(44)
                            label: "Button 4 (side back)"
                            foreground: root.foreground
                            value: root.buttons.button4
                            options: root.buttonOptions
                            onChanged: function (value) { if (root.mouse) root.mouse.setButton("button4", value) }
                        }
                        Dropdown {
                            id: btn5DD
                            width: parent.width
                            height: Style.space(44)
                            label: "Button 5 (side forward)"
                            foreground: root.foreground
                            value: root.buttons.button5
                            options: root.buttonOptions
                            onChanged: function (value) { if (root.mouse) root.mouse.setButton("button5", value) }
                        }
                        Dropdown {
                            id: btn6DD
                            width: parent.width
                            height: Style.space(44)
                            label: "Button 6 (DPI switch)"
                            foreground: root.foreground
                            value: root.buttons.button6
                            options: root.buttonOptions
                            onChanged: function (value) { if (root.mouse) root.mouse.setButton("button6", value) }
                        }

                        Row {
                            width: parent.width
                            spacing: Style.space(6)

                            Rectangle {
                                width: parent.width
                                height: Style.space(32)
                                radius: 4
                                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                                border.width: 1
                                border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)

                                Text {
                                    anchors.centerIn: parent
                                    text: "Reset button mappings"
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.mouse) {
                                        root.mouse.setButton("button1", "button1")
                                        root.mouse.setButton("button2", "button2")
                                        root.mouse.setButton("button3", "button3")
                                        root.mouse.setButton("button4", "button4")
                                        root.mouse.setButton("button5", "button5")
                                        root.mouse.setButton("button6", "dpi")
                                    }
                                }
                            }
                        }
                    }

                    // ── Error / hint footer ──
                    Text {
                        width: parent.width
                        visible: root.lastError !== ""
                        text: root.lastError
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        color: root.urgent
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        opacity: 0.85
                    }
                }
            }
        }
    }

    // Available button actions (values must match rivalcfg's accepted tokens)
    readonly property var buttonOptions: [
        { value: "button1", label: "Button 1 (left)" },
        { value: "button2", label: "Button 2 (right)" },
        { value: "button3", label: "Button 3 (middle)" },
        { value: "button4", label: "Button 4" },
        { value: "button5", label: "Button 5" },
        { value: "button6", label: "Button 6" },
        { value: "disabled", label: "Disabled" },
        { value: "dpi", label: "DPI switch" },
        { value: "ScrollUp", label: "Scroll up" },
        { value: "ScrollDown", label: "Scroll down" },
        { value: "Mute", label: "Mute" },
        { value: "Next", label: "Next track" },
        { value: "PlayPause", label: "Play / Pause" },
        { value: "Previous", label: "Previous track" },
        { value: "VolumeUp", label: "Volume up" },
        { value: "VolumeDown", label: "Volume down" },
        { value: "A", label: "Key A" }, { value: "B", label: "Key B" },
        { value: "C", label: "Key C" }, { value: "D", label: "Key D" },
        { value: "E", label: "Key E" }, { value: "F", label: "Key F" },
        { value: "G", label: "Key G" }, { value: "H", label: "Key H" },
        { value: "I", label: "Key I" }, { value: "J", label: "Key J" },
        { value: "K", label: "Key K" }, { value: "L", label: "Key L" },
        { value: "M", label: "Key M" }, { value: "N", label: "Key N" },
        { value: "O", label: "Key O" }, { value: "P", label: "Key P" },
        { value: "Q", label: "Key Q" }, { value: "R", label: "Key R" },
        { value: "S", label: "Key S" }, { value: "T", label: "Key T" },
        { value: "U", label: "Key U" }, { value: "V", label: "Key V" },
        { value: "W", label: "Key W" }, { value: "X", label: "Key X" },
        { value: "Y", label: "Key Y" }, { value: "Z", label: "Key Z" },
        { value: "Space", label: "Space" },
        { value: "Enter", label: "Enter" },
        { value: "Tab", label: "Tab" },
        { value: "Escape", label: "Escape" },
        { value: "BackSpace", label: "Backspace" },
        { value: "Delete", label: "Delete" },
        { value: "Home", label: "Home" },
        { value: "End", label: "End" },
        { value: "PageUp", label: "Page up" },
        { value: "PageDown", label: "Page down" },
        { value: "Left", label: "Left arrow" },
        { value: "Right", label: "Right arrow" },
        { value: "Up", label: "Up arrow" },
        { value: "Down", label: "Down arrow" }
    ]
}
