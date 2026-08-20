# Phase 15.3f.1 — YouTube pinned live preview

Adds an optional persistent picture-in-shell mode to the YouTube per-app popout.

## Behaviour

- The regular YouTube popout gets a Material Symbols `push_pin` action.
- Pinning creates a separate Quickshell `PanelWindow` rather than forcing the
  transient Caelestia bar popout to remain open.
- The pinned surface uses `ExclusionMode.Ignore`, reserves no desktop space,
  renders above ordinary windows, and is anchored near the left bar.
- The video is the same public Wayland `ScreencopyView` source already proven
  in Phase 15.3e.2-fix1.
- Clicking the live preview activates the real YouTube WebApp window.
- `keep_off` unpins the preview.
- The normal popout suspends its own screencopy while pinned so the compositor
  does not need to export the same window twice for our UI.
- Pin support is opt-in. YouTube Music does not enable it.

## Design boundary

This is an additive capability, not a replacement for Caelestia's native MPRIS
media UI. It is intended for video WebApps where a persistent live preview is
useful while working in other windows.
