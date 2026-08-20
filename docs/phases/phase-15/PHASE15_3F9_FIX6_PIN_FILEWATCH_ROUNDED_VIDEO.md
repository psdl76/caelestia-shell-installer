# Phase 15.3f.9-fix6 — FileView pin state + minimally rounded video

Pin:
- removes recurring `pin-state` subprocess reads from the plugin;
- reads the existing atomic `pins.json` using Quickshell `FileView`;
- isolated test-shell `Bar.qml` reads the same file;
- keeps the exact close-only guards based on the supplied `Bar.qml` / `Interactions.qml`;
- avoids the empty/truncated stdout race behind `pin-state parse failed`.

Video style:
- live-video content is layer-masked with `MultiEffect`;
- corner radius is intentionally only 6 px.

Unchanged: runtime-only icons, native media controls/progress, MPRIS, crop geometry and launcher runtime.
