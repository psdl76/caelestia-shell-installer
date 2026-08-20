# Phase 15.3c.1 — Native per-app bar icons

Status: candidate for live validation.

## Contract

- Per-app bar entries use the app artwork only as an alpha silhouette.
- The silhouette is tinted at runtime with the current Caelestia `onSurface` role.
- Brand-coloured icons remain untouched in WebApps and per-app popouts.
- Native bar footprint stays 34×34 with a 30×30 hover target; the visual app glyph is 21×21.
- Notification badges use `primary` / `onPrimary` from the rendered Caelestia theme.
- No private `qs.*` or `Caelestia.*` QML imports are introduced.
- Rendering uses the public Qt 6 `QtQuick.Effects.MultiEffect` colourization API.

This phase changes presentation only; status protocol, CLI resolver, polling, launch/focus and per-app entry wiring are unchanged.
