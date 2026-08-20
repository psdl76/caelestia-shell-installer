# Phase 15.3f.4 — YouTube DOM video crop via Firefox WebDriver BiDi

This phase keeps Wayland `ScreencopyView` as the actual live-pixel source, but
adds a loopback-only Firefox WebDriver BiDi bridge for geometry and timing.

For the YouTube WebApp only, the launcher starts Firefox with a dedicated
`--remote-debugging-port`. The status backend asks the active YouTube browsing
context for the first visible `<video>` element and publishes:

- normalized video rectangle (`videoRect`)
- viewport dimensions (`videoViewport`)
- DOM currentTime / duration as a fallback for incomplete MPRIS timing
- DOM playing state

The QML renderer still captures the whole Wayland toplevel, but scales and
clips the capture so only the detected `<video>` rectangle is visible. The same
crop data is used by the normal YouTube popout and the persistent pinned card.

If the browser bridge is unavailable, the renderer falls back to the previous
full-window live preview and MPRIS timing. No remote interface is exposed beyond
Firefox's loopback listener.
