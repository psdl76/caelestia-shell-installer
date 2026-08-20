# Phase 16.6 — Applet capability settings

Status: freeze candidate; requires live validation.

## Scope

Phase 16.6 adds user-controlled capability settings without changing the frozen catalog/schema-v2 or applet-registry schema.

- Persistent state: `~/.local/state/caelestia-webapps/applet-settings.json`
- Read API: `caelestia-webapps applet-settings [app-id]`
- Write API: `caelestia-webapps applet-setting-set <app-id> <capability> <on|off>`
- Only capabilities present in the persisted applet registry can be written.
- Registry capabilities default to enabled; the state file stores only explicit user choices.
- Manager exposes a settings dialog only for installed/supported applets.
- Plugin polls the settings API and applies changes without a shell restart.

## Runtime presentation mapping

- `notifications`: notification presentation/status indicator
- `badge`: notification count badge
- `preview`: notification event cards
- `now_playing`: media card presentation
- `playback_controls`: previous/play-pause/next controls
- `live_preview`: screencopy live preview
- `video_crop`: video-region crop versus full window capture
- `pin`: pin control
- `artwork`: media artwork

No adapters, capability declarations, catalog fields, or registry fields are added or changed.
