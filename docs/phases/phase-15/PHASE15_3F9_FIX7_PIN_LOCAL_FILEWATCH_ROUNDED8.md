# Phase 15.3f.9-fix7 — local Interactions pin state + radius 8

Root cause after fix6:
- `Interactions.qml` receives `required property Bar.BarWrapper bar`.
- fix6 incorrectly checked `bar.webappsYoutubePinned`.
- `webappsYoutubePinned` lives on inner `Bar.qml`, not on the BarWrapper contract.

Fix7:
- Bar.qml keeps its local FileView state for checkPopout().
- Interactions.qml gets its own local FileView on the same pins.json.
- Both real close paths use root.webappsYoutubePinned.
- No undeclared BarWrapper -> Bar property bridge is required.
- Live-video hero/mask radius is raised minimally from 6px to 8px.
