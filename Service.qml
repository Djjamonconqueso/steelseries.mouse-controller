import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
    id: root

    property var settings: ({})

    property bool connected: false
    property string deviceName: "SteelSeries Mouse"
    property int batteryPercentage: Model.LEVEL_UNKNOWN
    property string batteryLevel: "unknown"
    property string batteryStatus: "unknown"
    property int dpiX: 0
    property int dpiY: 0
    property int dpiMin: 100
    property int dpiMax: 18000
    property var dpiPresets: [400, 800, 1600, 2400, 3200]
    property int dpiSelected: 0
    property int reportRate: 1000
    property var buttons: Model.defaultButtons()
    property string lastError: ""

    readonly property int pollIntervalSec: {
        var v = settings ? settings.pollInterval : undefined
        return Math.max(5, Number(v) || 15)
    }

    readonly property string daemonPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/steelseries.mouse-controller/bin/rivalcfg-daemon"

    function refresh() {
        if (!pollProc.running) {
            pollProc.running = true
        }
    }

    function applyStatus(status) {
        if (!status) return
        connected = (status.connected === true)
        deviceName = String(status.deviceName || "SteelSeries Mouse")
        batteryPercentage = Number(status.batteryPercentage)
        batteryLevel = String(status.batteryLevel || "unknown")
        batteryStatus = String(status.batteryStatus || "unknown")
        dpiX = Number(status.dpiX || 0)
        dpiY = Number(status.dpiY || 0)
        dpiMin = Number(status.dpiMin || 100)
        dpiMax = Number(status.dpiMax || 18000)
        dpiPresets = status.dpiPresets || [400, 800, 1600, 2400, 3200]
        dpiSelected = Number(status.dpiSelected || 0)
        reportRate = Number(status.reportRate || 1000)
        buttons = status.buttons || Model.defaultButtons()
        lastError = String(status.error || "")
    }

    function applyLine(raw) {
        if (typeof raw !== "string" || raw.length > 16384) {
            applyStatus(Model.defaultStatus())
            return
        }
        applyStatus(Model.parseStatus(raw))
    }

    // Optimistic UI updates
    function setDpiList(values) {
        if (!Array.isArray(values) || values.length === 0) return
        dpiX = values[root.dpiSelected] || values[0]
        dpiY = dpiX
        cmdProc.command = [root.daemonPath, "--set-dpi", values.join(",")]
        cmdProc.running = true
    }

    // Update the value of the currently active preset only.
    function setDpiPresetValue(value) {
        var values = root.dpiPresets.slice()
        var index = Math.min(root.dpiSelected, values.length - 1)
        values[index] = Math.round(value / 100) * 100
        dpiX = values[index]
        dpiY = values[index]
        cmdProc.command = [root.daemonPath, "--set-dpi", values.join(",")]
        cmdProc.running = true
    }

    function addPreset() {
        var values = root.dpiPresets.slice()
        if (values.length >= 5) return
        values.push(values[values.length - 1] || 800)
        root.setDpiList(values)
    }

    function removePreset() {
        var values = root.dpiPresets.slice()
        if (values.length <= 1) return
        var index = Math.min(root.dpiSelected, values.length - 1)
        values.splice(index, 1)
        if (root.dpiSelected >= values.length) {
            dpiSelected = values.length - 1
        }
        root.setDpiList(values)
    }

    function setSelected(index) {
        dpiSelected = index
        if (dpiPresets.length > 0) {
            dpiX = dpiPresets[index]
            dpiY = dpiPresets[index]
        }
        cmdProc.command = [root.daemonPath, "--set-selected", String(index)]
        cmdProc.running = true
    }

    function setReportRate(rate) {
        reportRate = rate
        cmdProc.command = [root.daemonPath, "--set-rate", String(rate)]
        cmdProc.running = true
    }

    function setButton(buttonName, action) {
        var number = buttonName.replace("button", "")
        cmdProc.command = [root.daemonPath, "--set-button", number, action]
        cmdProc.running = true
    }

    function resetAll() {
        cmdProc.command = [root.daemonPath, "--reset"]
        cmdProc.running = true
    }

    Process {
        id: cmdProc
        stdout: StdioCollector {
            id: cmdOut
            waitForEnd: true
            onStreamFinished: {
                var lines = (cmdOut.text || "").trim()
                if (lines !== "") {
                    root.applyLine(lines)
                }
            }
        }
    }


    Timer {
        id: pollTimer
        interval: root.pollIntervalSec * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: pollProc
        command: [
            root.daemonPath,
            "--once"
        ]
        stdout: StdioCollector {
            id: pollOutput
            waitForEnd: true
            onStreamFinished: {
                var text = (pollOutput.text || "").trim()
                if (text !== "") {
                    root.applyLine(text)
                }
            }
        }
    }

    Component.onCompleted: {
        root.refresh()
    }
}
