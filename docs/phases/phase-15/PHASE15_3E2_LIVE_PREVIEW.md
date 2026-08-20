# Phase 15.3e.2 — Live Media Preview + Controls

Adds a generic live window preview for media WebApps using Quickshell.Wayland ScreencopyView and ToplevelManager.

- Matches the WebApp toplevel by appId/window class.
- Uses ScreencopyView with `live: true`; no screenshot polling.
- Falls back to MPRIS artwork, then WebApp icon.
- Adds generic MPRIS previous / play-pause / next controls through the stable CLI boundary.
- No private Caelestia QML imports.
