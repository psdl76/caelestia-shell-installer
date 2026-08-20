# Phase 6 – manager-live-01

## Purpose

Add live Catalog v2 observation and a separate transient runtime channel.

## Architecture rules

- `catalog.json` remains persistent read state only.
- `FileView.watchChanges` reloads catalog changes from disk.
- Running/window state is transient and MUST NOT be written to catalog.json.
- The CLI `runtime` command queries Hyprland once and returns all app window states.
- The manager polls the runtime command every 1500 ms with one Quickshell `Process`.
- Installed + running apps show a small green indicator and `Fokussieren`.
- The actual action remains `launch`; duplicate protection/focus remains owned by the engine launcher.
- A missing/unavailable Hyprland runtime must degrade gracefully without changing catalog state.

- Hyprland runtime probing is time-bounded to 1.5 seconds; unavailable or stalled Hyprland must never freeze the manager.
