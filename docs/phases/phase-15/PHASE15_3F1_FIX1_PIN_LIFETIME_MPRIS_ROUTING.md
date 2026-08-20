# Phase 15.3f.1-fix1 — Persistent pin lifetime + MPRIS routing

Live findings fixed:

1. The pinned `PanelWindow` was created inside the transient bar-popout object.
   Caelestia destroys/unloads that object when the pointer leaves the popout,
   so the supposedly pinned video disappeared with it.
2. `youtube.com` also matched `music.youtube.com`; therefore YouTube controls
   could accidentally target the YouTube Music MPRIS player.

Fix:

- The persistent YouTube `PanelWindow` is now owned by `YouTubeBarEntry.qml`,
  whose lifetime follows the bar entry rather than the transient popout.
- Pin state crosses the stable CLI boundary via `pin-state` / `pin-set` and is
  persisted under `$XDG_STATE_HOME/caelestia-webapps/pins.json`.
- The popout only toggles state; it no longer owns the detached surface.
- MPRIS ownership is resolved globally across media apps. Exact/more-specific
  hosts win, so `music.youtube.com` belongs to `youtube-music`, while
  `youtube.com` belongs to `youtube`.
