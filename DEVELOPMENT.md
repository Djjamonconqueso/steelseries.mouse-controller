# Development

This guide is for contributors. End-user installation and troubleshooting are in [README.md](README.md).

## Prerequisites

- Python 3 with the `rivalcfg` module and HIDAPI installed.
- Omarchy Quattro for QML/plugin validation.
- A supported SteelSeries mouse (default target: Rival 3 Wireless Gen 2, `1038:1872`).

## Project layout

| Path                    | Purpose                                                    |
| ----------------------- | ---------------------------------------------------------- |
| `bin/rivalcfg-daemon`   | Python driver that wraps `rivalcfg` (the shipped controller). |
| `Service.qml`           | Starts the driver and applies its JSON status.             |
| `Model.js`              | Converts driver JSON into QML state.                       |
| `manifest.json`         | Marketplace and plugin metadata; canonical release version.|

## Driver

`bin/rivalcfg-daemon` is a Python script (shipped in the plugin). It uses the `rivalcfg` Python library, which is installed on the user's system.

Because SteelSeries mice store their DPI/polling/button settings in onboard memory and do **not** report them back, the driver writes settings via `rivalcfg` and persists the last-known configuration locally:

- State: `$XDG_STATE_HOME/omarchy/rivalcfg-daemon/state.json`
- Status: `$XDG_RUNTIME_DIR/omarchy-rivalcfg-daemon/status.json`

The battery level is read live from the device on every poll.

Run the driver directly:

```bash
./bin/rivalcfg-daemon --once
./bin/rivalcfg-daemon --set-dpi "800,1600"
./bin/rivalcfg-daemon --set-selected 0
./bin/rivalcfg-daemon --set-rate 1000
./bin/rivalcfg-daemon --set-button 6 dpi
./bin/rivalcfg-daemon --buttons "buttons(button1=button1; ...)"
./bin/rivalcfg-daemon --reset
```

Each invocation prints one JSON status object and atomically publishes it under `$XDG_RUNTIME_DIR/omarchy-rivalcfg-daemon/`. The UI consumes the bounded stdout contract.

### CLI contract

| Flag              | Purpose                                                        |
| ----------------- | -------------------------------------------------------------- |
| `--once`          | Print status once and exit (used for polling).                 |
| `--set-dpi`       | Set the DPI preset list, e.g. `"800,1600"` (1–5 presets, 100–18000). |
| `--set-selected`  | Choose the active preset (0-based).                            |
| `--set-rate`      | Set polling rate: 125, 250, 500, or 1000 Hz.                   |
| `--set-button`    | Map one button, e.g. `--set-button 6 dpi`.                     |
| `--buttons`       | Set the full mapping string (`buttons(...)` syntax).           |
| `--reset`         | Reset all settings to factory defaults.                        |
| `--interval`      | Loop polling interval (seconds); used if run as a daemon.      |

### Buttons actions

Accepted action tokens are those understood by `rivalcfg` for this device: mouse buttons (`button1`…`button6`), special actions (`disabled`, `dpi`, `ScrollUp`, `ScrollDown`), multimedia keys (`Mute`, `Next`, `PlayPause`, `Previous`, `VolumeUp`, `VolumeDown`), and QWERTY keyboard keys.

## Local development

After QML or driver changes, copy the plugin and restart the shell:

```bash
omarchy plugin validate .
cp -a . ~/.config/omarchy/plugins/steelseries.mouse-controller/
omarchy restart shell
```

Verify the driver before testing the QML surface:

```bash
./bin/rivalcfg-daemon --once
```

Use a no-op write matching the current values to exercise a hardware write without changing the configured state:

```bash
./bin/rivalcfg-daemon --set-rate 1000
```

## Releases

`manifest.json` is the canonical plugin version. The shipped driver is a plain Python script, so no compile step is required; just bump the version in `manifest.json`, update `bin/rivalcfg-daemon` and the UI, verify, and tag the release.
