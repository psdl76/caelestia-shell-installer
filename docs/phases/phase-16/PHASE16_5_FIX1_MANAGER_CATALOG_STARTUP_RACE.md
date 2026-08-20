# Phase 16.5-fix1 — Manager catalog startup race

The Manager launches immediately while `scripts/manager_preflight.sh` prepares theme/icons and refreshes the persisted catalog. Previously `FileView` watched `~/.local/share/caelestia-webapps/catalog.json` immediately, producing repeated missing-file warnings during normal startup before preflight had created the file.

Fix:
- gate the catalog `FileView.path` and `watchChanges` on `startupReady`;
- after preflight emits `ready`, enable the FileView and reload on the next Qt turn;
- no schema, lifecycle, applet-state, or runtime changes.
