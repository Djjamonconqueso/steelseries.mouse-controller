// Model.js — Pure JS helper for parsing rivalcfg-daemon JSON output.

var LEVEL_UNKNOWN = -1

function defaultButtons() {
  return {
    button1: "button1",
    button2: "button2",
    button3: "button3",
    button4: "button4",
    button5: "button5",
    button6: "dpi"
  }
}

function defaultStatus() {
  return {
    ok: true,
    connected: false,
    deviceName: "SteelSeries Mouse",
    batteryPercentage: LEVEL_UNKNOWN,
    batteryLevel: "unknown",
    batteryStatus: "unknown",
    dpiX: 0,
    dpiY: 0,
    dpiMin: 100,
    dpiMax: 18000,
    dpiPresets: [400, 800, 1600, 2400, 3200],
    dpiSelected: 0,
    reportRate: 1000,
    buttons: defaultButtons(),
    error: ""
  }
}

function externalText(value, fallback, maxLength) {
  if (value === undefined || value === null) return fallback
  return String(value)
    .replace(/[<>&\u0000-\u001f\u007f]/g, "")
    .slice(0, maxLength) || fallback
}

function parseStatus(raw) {
  var s = defaultStatus()
  if (!raw || raw === "") return s

  var data
  try { data = JSON.parse(raw) }
  catch (e) { s.ok = false; s.error = "Invalid daemon status"; return s }

  s.connected = !!data.connected
  s.deviceName = externalText(data.deviceName, s.deviceName, 128)
  if (data.battery) {
    s.batteryPercentage = typeof data.battery.percentage === "number" ? data.battery.percentage : LEVEL_UNKNOWN
    s.batteryLevel = externalText(data.battery.level, "unknown", 32)
    s.batteryStatus = externalText(data.battery.status, "unknown", 32)
  }

  if (data.dpi) {
    s.dpiX = data.dpi.dpiX || 0
    s.dpiY = data.dpi.dpiY || 0
  }

  if (typeof data.dpiMin === "number") s.dpiMin = data.dpiMin
  if (typeof data.dpiMax === "number") s.dpiMax = data.dpiMax
  if (Array.isArray(data.dpiPresets) && data.dpiPresets.length > 0) {
    s.dpiPresets = data.dpiPresets
  }
  if (typeof data.dpiSelected === "number") {
    s.dpiSelected = data.dpiSelected
  }

  if (data.reportRate) {
    s.reportRate = Number(data.reportRate) || 1000
  }

  if (data.buttons && typeof data.buttons === "object") {
    var mapped = defaultButtons()
    for (var i = 1; i <= 6; i++) {
      var key = "button" + i
      if (data.buttons[key]) mapped[key] = externalText(data.buttons[key], mapped[key], 64)
    }
    s.buttons = mapped
  }

  if (data.error) s.error = externalText(data.error, "", 512)
  s.ok = true
  return s
}

// Standard glyphs matching Omarchy power & input plugins
function mouseIcon() {
  return "󰍽"  // nf-md-mouse
}

function batteryIcon(percentage, status) {
  var chargingIcons = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
  var defaultIcons  = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

  if (percentage === LEVEL_UNKNOWN) return "󰍽"
  var idx = Math.max(0, Math.min(9, Math.floor(percentage / 10)))

  if (status === "charging" || status === "charging_slow") {
    return chargingIcons[idx]
  }
  if (status === "full") return "󰂅"
  return defaultIcons[idx]
}

function batteryText(percentage) {
  if (percentage === LEVEL_UNKNOWN) return "--"
  return String(percentage) + "%"
}

function dpiText(dpiX, dpiY) {
  if (dpiX <= 0) return "--"
  if (dpiY > 0 && dpiY !== dpiX) return String(dpiX) + "×" + String(dpiY)
  return String(dpiX)
}

function buttonLabel(action) {
  if (action === "disabled") return "Disabled"
  if (action === "dpi") return "DPI switch"
  if (action === "default") return "Default"
  return action
}

function barTooltip(mouse) {
  var name = (mouse && mouse.deviceName) ? mouse.deviceName : "SteelSeries Mouse"
  if (!mouse || !mouse.connected) return name + " (Disconnected)"
  var parts = [name]
  if (mouse.batteryPercentage !== LEVEL_UNKNOWN) {
    parts.push(batteryText(mouse.batteryPercentage) + " (" + mouse.batteryStatus + ")")
  }
  if (mouse.dpiX > 0) {
    parts.push(dpiText(mouse.dpiX, mouse.dpiY) + " DPI")
  }
  return parts.join(" · ")
}

if (typeof module !== "undefined") {
  module.exports = {
    LEVEL_UNKNOWN: LEVEL_UNKNOWN,
    defaultStatus: defaultStatus,
    defaultButtons: defaultButtons,
    parseStatus: parseStatus,
    mouseIcon: mouseIcon,
    batteryIcon: batteryIcon,
    batteryText: batteryText,
    dpiText: dpiText,
    barTooltip: barTooltip,
    buttonLabel: buttonLabel
  }
}
