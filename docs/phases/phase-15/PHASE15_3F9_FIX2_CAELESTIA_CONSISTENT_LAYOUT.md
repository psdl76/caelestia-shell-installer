# Phase 15.3f.9-fix2 — Caelestia-consistent YouTube applet

Changes are intentionally limited to presentation.

- `compactMedia` now becomes active only while YouTube has a real media status.
  With no player/status, YouTube uses the same generic sizing, spacing, typography
  and open-button layout as YouTube Music.
- The live video surface has no plugin-specific overlay: no YouTube glyph and no
  LIVE/VIDEO badge.
- The header keeps a small Material YouTube-style glyph so the broken external
  youtube.svg is never decoded.
- Media-card/root height is increased just enough so the compact transport controls
  are fully visible instead of being clipped.
- Previous / play-pause / next stay deliberately small.
- The separate PiP/FloatingWindow path remains removed.
- Pin behavior/test-shell patch is unchanged.

This keeps the plugin visually aligned with Caelestia's existing rounded surfaces,
subtle outline, normal empty-state layout, Material symbols, and compact spacing.
