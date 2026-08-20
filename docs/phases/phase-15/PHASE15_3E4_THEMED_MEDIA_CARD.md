# Phase 15.3e.4 — Adaptive Caelestia Media Card

- Keeps the generic media renderer: app-specific wrappers only select presentation policy.
- YouTube uses `mediaPresentation: live_preview`.
- YouTube Music uses `mediaPresentation: artwork` and no live screencopy.
- All surfaces, outlines, glow, progress, text, visualizer, and controls derive from `PluginTheme`, which reads the rendered Caelestia Material palette.
- Adds MPRIS position/duration to the public status protocol for time labels.
- Adds a lightweight playback activity visualizer. It is intentionally UI motion, not audio-spectrum analysis.
- Does not add fake queue/likes data or private Caelestia imports.
