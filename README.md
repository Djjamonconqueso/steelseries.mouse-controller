# SteelSeries Mouse Controller

An [Omarchy Quattro](https://omarchy.org/) bar widget and control panel for a **SteelSeries Rival 3 / Rival 3 Wireless Gen 2** gaming mouse. It reads the battery level live and lets you adjust DPI presets, polling rate, and per-button mapping — using `rivalcfg` on Linux (no SteelSeries GG needed).

This is a **fork** of [ttymayor/oma-logitech-g-mouse](https://github.com/ttymayor/oma-logitech-g-mouse), adapted for SteelSeries mice. Because SteelSeries mice do **not** report their DPI or polling settings back to the host (unlike Logitech HID++), this plugin persists the last-known configuration locally and reads only the battery from the device.

## Features

- **Battery** (`Rival 3 Wireless Gen 2`): live battery percentage and charge status in the bar and panel.
- **DPI presets**: up to 5 presets (100–18000 DPI, in 100-DPI steps), with the active preset selectable and value editable via a slider. Use **+ / −** to add or remove presets. Defaults: 400 / 800 / 1600 / 2400 / 3200 DPI.
- **Polling rate**: 125 / 250 / 500 / 1000 Hz.
- **Button mapping**: map any of the 6 buttons to another button, a special action (Disabled, DPI switch, scroll), multimedia keys, or QWERTY keyboard keys.
- **Auto-reconnect**: the widget reconnects automatically after the mouse is plugged back in.

## Requirements

- Omarchy Quattro on Linux.
- A supported SteelSeries mouse (default target: Rival 3 Wireless Gen 2, `1038:1872`).
- `rivalcfg` (≥ 4.x) with udev rules installed. Install the package using [aur](https://aur.archlinux.org/packages/rivalcfg) or using the official [source](https://rivalcfg.flozz.org/download.html) , and ensure udev rules are updated.

The plugin ships a lightweight Python driver (`bin/rivalcfg-daemon`) that wraps the installed `rivalcfg` library. Python 3 with HIDAPI and the `rivalcfg` module are the only runtime requirements.

## Install

### From a local checkout

```bash
mkdir -p ~/.config/omarchy/plugins/steelseries.mouse-controller
cp -a . ~/.config/omarchy/plugins/steelseries.mouse-controller/
omarchy plugin validate ~/.config/omarchy/plugins/steelseries.mouse-controller
omarchy bar put steelseries.mouse-controller --section right
omarchy restart shell
```

## Use

- **Left-click** the bar widget to open the control panel.
- **Right-click** it to toggle battery percentage text.
- **Sensitivity (DPI)**: the Rival holds up to 5 presets cycled with the button under the wheel. Select a preset, edit its value with the slider (100–18000 DPI in 100-DPI steps), and use **+/−** to add or remove presets.
- **Report rate**: choose 125, 250, 500, or 1000 Hz.
- **Buttons mapping**: map any of the 6 buttons to another button, a special action (Disabled, DPI switch, scroll), multimedia keys, or QWERTY keyboard keys.

The widget reconnects automatically after the mouse is plugged back in.

## Screenshots

| Control panel                                        |
| ---------------------------------------------------- |
|<img width="377" height="349" alt="imagen" src="https://github.com/user-attachments/assets/0a0aad70-2bf8-43a9-9a68-89d6608fdd3f" /> <img width="376" height="540" alt="imagen" src="https://github.com/user-attachments/assets/28501e1f-2e72-4f9d-9b17-f8a0eaca1b7b" />|

## Compatible devices

The plugin is powered by [`rivalcfg`](https://github.com/flozz/rivalcfg), so it is able to **write** settings to every SteelSeries mouse that `rivalcfg` supports. Supported devices (rivalcfg ≥ 4.17):

| Family | Models |
| ------ | ------ |
| Rival | 3, 3 Gen 2, 3 Wireless, 3 Wireless Gen 2, 5, 95, 100, 105, 106, 110, 300, 300S, 310, 500, 600, 650, 700, 710, original Rival |
| Sensei | Sensei 310, Sensei [RAW], Sensei TEN |
| Aerox | Aerox 3, Aerox 3 Wireless, Aerox 5, Aerox 5 Wireless, Aerox 9 Wireless |
| Prime | Prime, Prime Mini, Prime Wireless, Prime+ |
| Other | Kana v2, Kinzu v2 |

### Compatibility notes / caveats

Because SteelSeries mice don't report their settings back to the host, **every** device is treated as write-only and the plugin persists the last-known configuration locally. Beyond that, there are per-device nuances you should know before using this plugin with a mouse other than the Rival 3 Gen 2:

- **Fully tested / default target**: the **Rival 3 Wireless Gen 2** (`1038:1872`). This is the only device it is tested against.
- **Button count**: the panel is hardcoded to **6 buttons** (`button1`…`button6`). Devices with a different button layout — for example the **Rival 5 (9 buttons)** or the **Rival 100** — will show a button set that doesn't match the physical mouse (more or fewer entries than it has).
- **Battery**: only wireless mice expose a battery. The **Rival 3 Wireless Gen 2** reports it live. On a **wired** mouse (e.g. the Rival 3 Gen 2, Rival 3, Aerox 5, Prime, etc.), `rivalcfg` has no battery to read, so the widget shows "unknown" — the driver handles this gracefully and never crashes, it just has nothing to display.
- **DPI range**: the panel slider assumes **100–18000 DPI** in 100-DPI steps (the Rival 3 Gen 2 range). Other mice differ — e.g. the **Rival 100** is 250–4000, the **Rival 300** is 50–12000 — so the slider's min/max won't match those devices.
- **Generated methods**: the driver calls the `set_sensitivity`, `set_polling_rate`, and `set_buttons_mapping` methods that `rivalcfg` generates for a given model. If a device lacks one of those (feature not implemented in `rivalcfg` for that model), the driver reports a clear error instead of crashing.
- **Write-only persistence**: with any device, the widget shows the last configuration it wrote. If you change the DPI preset using the mouse's hardware button, the widget can't detect that until you re-select a preset in the panel.

**In short:** writing settings usually works on any `rivalcfg`-supported mouse, but the UI (button count, DPI range, battery indicator) is tuned for the Rival 3 Gen 2. To use this plugin with a different SteelSeries mouse, you may need to adjust the hardcoded UI limits in `Model.js` / `Service.qml` (and, for batteries, `bin/rivalcfg-daemon`).

## Troubleshooting

Some SteelSeries mice expose more than one HID interface (2.4 GHz receiver, Bluetooth, etc.). The plugin targets the **2.4 GHz (`0x1872`)** interface. Verify `rivalcfg` sees the device:

```bash
rivalcfg --list
rivalcfg --battery-level
```

Check the driver directly:

```bash
~/.config/omarchy/plugins/steelseries.mouse-controller/bin/rivalcfg-daemon --once
```

If it reports `no device found` or `permission denied`, ensure `rivalcfg`'s udev rules are installed (see Requirements) and that your user is in the `plugdev` group, or re-login so `uaccess` applies.

## Uninstall

```bash
omarchy plugin disable steelseries.mouse-controller
rm -rf "${XDG_RUNTIME_DIR:-/run/user/$UID}/omarchy-rivalcfg-daemon"
rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/rivalcfg-daemon"
omarchy restart shell
```

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for the driver, CLI contract, and verification steps.

## License

[MIT License](LICENSE). SteelSeries and Rival are trademarks of SteelSeries. This project is an independent third-party open-source plugin and is not affiliated with SteelSeries. `rivalcfg` is by Florian Zingg (flozz) — see https://github.com/flozz/rivalcfg.
