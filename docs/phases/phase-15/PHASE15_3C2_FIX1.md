# Phase 15.3c.2 Fix 1 — Native bar colour + Firefox session guard

Status: candidate; requires live validation.

## Changes

- Per-app bar icon tint now uses the Caelestia `secondary` palette role, matching the feature branch `StatusIcons.qml`/`TrayItem.qml` semantics.
- Brand icons remain colourful in WebApps popouts/manager; only per-app bar silhouettes are tinted.
- Dedicated Firefox WebApp profiles now set both:
  - `browser.sessionstore.resume_from_crash = false`
  - `browser.sessionstore.resume_session_once = false`
- `repair` re-renders `user.js`, therefore existing profiles are migrated deterministically.
- Firefox runtime tests cover both guards and repair of an existing incomplete profile.

## Live gate

1. Repair installed WebApps and verify both prefs in every profile.
2. Reboot with several WebApps open; no Restore Session page may appear.
3. Compare per-app bar icon colour under at least Dracula, Catppuccin and darkgreen.
