# Native Sidebar PoC v3

Changes from v2:

- Explicit Material text colours are used for WebApps names and status text to avoid
  the recurring black-text fallback.
- Notifications and WebApps are no longer separate fade/offset layers.
- Both pages live in one horizontal page track. The track itself animates with
  Caelestia's `Anim`, so the transition is spatially continuous.
- The selected tab uses one sliding indicator surface instead of independently
  colouring two chips.
- Original notification content is still copied from the user's actual current
  `modules/sidebar/Content.qml` during install.

No backend install/repair/uninstall behavior has been added yet; this remains a UI PoC.
