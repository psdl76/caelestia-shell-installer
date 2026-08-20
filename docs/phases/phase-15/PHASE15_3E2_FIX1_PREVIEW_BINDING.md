# Phase 15.3e.2-fix1 — deterministic live-preview binding

- Uses the public `Quickshell.Hyprland` toplevel model first.
- Matches the stable WebApp Hyprland `class` / `initialClass` to the app id.
- Passes `HyprlandToplevel.wayland` to `ScreencopyView`, which is the required Wayland `Toplevel` capture source.
- Falls back to `ToplevelManager.appId` matching.
- Rebuilds the `ScreencopyView` on source changes or `stopped()` via `Qt.callLater`, without an arbitrary delay timer.
- Existing MPRIS metadata, media controls, notification lifecycle and avatar paths remain unchanged.
