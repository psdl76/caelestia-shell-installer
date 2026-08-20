# Phase 16.1-fix2c — Gemini PNG rendering fix

Live testing of fix2b showed that all visually expected catalog icons were present except Gemini.
The icon pipeline log proved that Gemini itself resolved successfully as `google-gemini` /
`dashboard-svg`, so this was not a slug or download failure.

The project already documented the same historical UI-only regression: Qt/Quickshell does not
render the Dashboard Icons Gemini SVG reliably. Dashboard Icons publishes the same icon as a
generated PNG.

fix2c therefore restores the narrow presentation workaround:

- `prepare_store_icons.sh` always obtains `google-gemini.png` for Gemini, even if an older SVG is cached;
- `generate_catalog.py` prefers the local Gemini PNG over its SVG;
- all other apps retain the fix2b resolution order unchanged;
- no remote runtime dependency is introduced.

Canva remains a separate resolver observation and is intentionally not mixed into this minimal
Gemini rendering patch.
