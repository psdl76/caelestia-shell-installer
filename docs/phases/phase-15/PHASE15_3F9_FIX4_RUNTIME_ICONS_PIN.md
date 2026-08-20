# Phase 15.3f.9-fix4 — runtime-only applet icons + pin v2

- Per-app bar icons only exist while the matching WebApp window is running.
- Applies generically to WhatsApp, Google Messages, YouTube, YouTube Music and
  future per-app wrappers using GenericStatusBarEntry.
- The central WebApps manager entry remains permanently available.
- The redundant YouTube-open footer is removed.
- Pin v2 reads persistent `pin-state youtube` through the stable CLI and guards
  Caelestia's shell-owned popout selection via `popouts.currentName`.
- The previous `popouts.current?.pinned` test-shell PoC is upgraded if found.
- The patch refuses shell revisions without the exact contracts it needs.
- Only the isolated test shell is modified by default.
