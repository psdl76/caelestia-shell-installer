# Phase 15.3e.3 — YouTube Music generic media instance

Adds YouTube Music as the second real media-capable WebApp instance.

- App id/window class: `youtube-music`
- URL: `https://music.youtube.com/`
- Status type: `media`
- Reuses the existing generic MPRIS adapter, media renderer, playback controls,
  and Hyprland/Wayland live-preview binding.
- Adds only thin bar-entry/popout wrappers. No YouTube-Music-specific rendering
  logic is added to `GenericStatusPopout.qml`.

Live validation is required before this phase can be frozen.
