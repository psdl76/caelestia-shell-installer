# Hyprland hardening — v0.3.11

This release completes roadmap point 9: WebApp-managed Hyprland changes are prepared transactionally and never overwrite unrelated user configuration.

## Ownership boundaries

- New `opaque_tag` memberships are marked `Caelestia WebApps`.
- New messaging memberships are marked, while the native `communication_app_tag` and its `special:communication` `create_tag` remain owned by Caelestia.
- `streaming_app_tag`, `special:streaming` and `SUPER+Y` are WebApps-owned and carry explicit markers.
- Existing unmarked entries are treated as user/native configuration and are not rewritten merely to normalize them.

## Keybind policy

- The native Caelestia music and communication bindings (`vars.kbMusicWs`, `vars.kbCommunicationWs`, corresponding to the user's SUPER+M/SUPER+D setup) are only checked, never replaced.
- WebApps owns only the marked `SUPER+Y -> special:streaming` binding.
- If another literal SUPER+Y binding already exists, installation aborts before either live Hyprland file is changed.
- The legacy marked SUPER+V streaming bind can still be migrated to SUPER+Y when Y is free.

## Transaction

1. Snapshot live `rules.lua` and `keybinds.lua`.
2. Prepare all edits on temporary copies.
3. Detect ownership/key conflicts.
4. Validate Lua syntax when `luac` is available.
5. Detect concurrent edits to the live files.
6. Create one backup per changed live file.
7. Commit the prepared files.
8. Reload Hyprland and inspect `configerrors`.
9. Restore the original files automatically if reload/config validation fails.

This keeps user rules/keybinds outside the managed ownership markers untouched and avoids partially-applied Hyprland edits.
