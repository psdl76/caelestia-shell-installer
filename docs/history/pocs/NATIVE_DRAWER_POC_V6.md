# Native Sidebar PoC v6 — Setup / Repair / Uninstall

v6 extends the confirmed v5.1 Open/Install checkpoint.

Installed cards now expose a small native secondary-action surface:
- Setup
- Repair
- Entfernen

The surface expands inside the card using Caelestia `Anim`; the normal list layout is
kept compact until requested.

Behavior:
- Setup launches the existing generated setup launcher.
- Repair delegates to `repair.sh --app <id>`.
- Uninstall opens a native confirmation surface inside the WebApps sidebar page, then
  delegates to `uninstall.sh <id>`.
- After Repair/Uninstall the catalog is rebuilt and the watched sidebar updates live.
- All text and status colours use Caelestia theme services/components.
- No external Qt dialog/window is used.
