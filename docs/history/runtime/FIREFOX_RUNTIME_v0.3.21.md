# Firefox Runtime — v0.3.21

## Activate-or-launch fix for Hyprland Lua

Real-world testing showed that WebApp detection itself was correct, but the legacy focus call

```bash
hyprctl dispatch focuswindow "address:0x..."
```

fails when Hyprland is using its Lua dispatcher path.

The tested working form is:

```bash
hyprctl dispatch 'hl.dsp.focus({ window = "address:0x..." })'
```

The launcher now also separates **window existence** from **focus success**. If a matching
WebApp window exists, Firefox is never launched again—even if focusing that window fails.
The same Lua focus form is used by the setup launcher.

This restores the activate-or-launch guarantee for the app menu, desktop entries and
the WebApps Manager.
