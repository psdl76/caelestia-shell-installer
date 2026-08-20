# Phase 15.3f.5 — Picture-in-Shell crop renderer

This phase consumes the live-tested Firefox WebDriver BiDi `<video>` geometry
from phase 15.3f.4-fix1 and applies it to both YouTube preview surfaces.

## Runtime flow

1. Firefox exposes the YouTube `<video>` rectangle and DOM playback timing via
   the localhost WebDriver BiDi bridge.
2. `status-feed youtube` publishes the normalized rectangle as `videoRect`, the
   browser viewport as `videoViewport`, plus DOM position/duration/play state.
3. `VideoCropView.qml` keeps the public Wayland `ScreencopyView` capture source
   as the full YouTube toplevel, scales/translates it uniformly, and clips the
   presentation to the detected `<video>` rectangle.
4. The same renderer is used by the transient YouTube popout and the persistent
   pinned PanelWindow so the two surfaces cannot drift into different crop
   implementations.
5. If BiDi geometry is temporarily unavailable, the renderer deliberately
   falls back to the complete toplevel preview instead of rendering nothing.

No private Caelestia QML APIs are introduced.
