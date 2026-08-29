# AGENTS.md

This project is an [Omarchy Quattro](https://omarchy.org/) (Omarchy 4.0+) plugin that controls a **SteelSeries Rival 3 Gen 2** gaming mouse. The backend is a **Python** driver that wraps the system's `rivalcfg` library, and the user interface is written in **QML**.

## Goal

Provide live telemetry and hardware customization for a SteelSeries Rival mouse without SteelSeries GG.

Features include:

- Write DPI presets (up to 5, 100–18000 DPI) and select the active preset.
- Write polling rate (125 / 250 / 500 / 1000 Hz).
- Map the 6 mouse buttons to buttons, special actions, multimedia keys, or keys.
- Report battery / connection status to the Omarchy shell.

## Why local persistence?

SteelSeries mice store their DPI/polling/button settings in **onboard memory and do not report them back to the host** (unlike Logitech HID++). `rivalcfg` is write-only for these settings. So `bin/rivalcfg-daemon` writes settings via `rivalcfg` and persists the last-known configuration locally so the UI can display it. Only the battery is read live from the device.

## How it fits together

- `bin/rivalcfg-daemon` is the shipped Python driver. It wraps `rivalcfg`, exposes a CLI, reads battery live, and writes JSON status to `$XDG_RUNTIME_DIR`.
- `Service.qml` starts that driver and applies its JSON status to keep the UI in sync.
- `Model.js` and the QML views render that state as a bar widget and control panel.

## Project layout

| Path                  | Purpose                                                       |
| --------------------- | ------------------------------------------------------------- |
| `bin/rivalcfg-daemon` | Python driver that wraps `rivalcfg` (the shipped controller). |
| `Service.qml`         | Starts the controller and applies its JSON status.            |
| `Model.js`            | Converts controller JSON into QML state.                      |
| `manifest.json`       | Marketplace and plugin metadata; canonical release version.   |

## Running

The driver is a plain Python script shipped in `bin/` — no build step. It requires Python 3, the `rivalcfg` module, and HIDAPI installed on the user's system.

```bash
./bin/rivalcfg-daemon --once
./bin/rivalcfg-daemon --set-dpi "800,1600"
./bin/rivalcfg-daemon --set-rate 1000
./bin/rivalcfg-daemon --set-button 6 dpi
```

State lives at `$XDG_STATE_HOME/omarchy/rivalcfg-daemon/state.json`; live status is published to `$XDG_RUNTIME_DIR/omarchy-rivalcfg-daemon/status.json`.
