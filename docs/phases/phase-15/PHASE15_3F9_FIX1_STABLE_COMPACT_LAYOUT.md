# Phase 15.3f.9-fix1 — stable compact layout

Fixes two failures seen in the live test:

1. `youtube.svg` repeatedly exceeded Qt's 256 MB image allocation limit.
   Compact YouTube no longer decodes the external SVG at all. Header and empty
   preview fallback use the Material `smart_display` glyph instead.

2. `GenericStatusPopout.qml` entered a `ColumnLayout` polish loop.
   Compact YouTube now uses fixed, stable geometry for the video hero and media
   card instead of deriving preferred height from `parent.width` / layout
   implicit height while the same layout is being polished.

No PiP/FloatingWindow code is reintroduced.
No drag/snap/clamp code is present.
The test-shell pin patch from 3f9 is unchanged.
