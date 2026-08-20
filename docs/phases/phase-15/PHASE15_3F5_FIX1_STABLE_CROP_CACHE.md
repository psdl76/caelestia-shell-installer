# Phase 15.3f.5-fix1 — Stable pinned crop under concurrent status polling

Live finding: the normal YouTube popout cropped correctly, but the persistent pinned surface first showed the correct video and then fell back to the full YouTube window/comment column. With both surfaces open it alternated between both views.

Root cause: each surface owns an independent `GenericStatusBarEntry`/status poller. Multiple `status-feed` subprocesses can therefore ask Firefox for WebDriver BiDi state at the same time. Firefox only allows one active BiDi session. One poll succeeds while another transiently fails; the failed result omitted `videoRect`, so `VideoCropView` immediately fell back to the full Screencopy toplevel.

Fix:
- serialize browser-video BiDi polling across processes with a per-app `flock`;
- share a short last-good browser-video cache, with a bounded stale fallback;
- re-check cache after lock acquisition so duplicate pollers do not create redundant sessions;
- `VideoCropView` holds the last valid crop for six seconds to mask a transient status miss instead of flashing the full YouTube window.

This does not change the live capture source, MPRIS ownership, pin lifetime, or DOM crop geometry model.
