# Phase 16.5 — Optional Applet Activation

## Scope

Phase 16.5 adds a user-controlled enable/disable state for implemented Caelestia WebApp applets without changing the frozen catalog or applet-registry schemas.

## Runtime contract

- State file: `~/.local/state/caelestia-webapps/applets.json`
- Schema: `schemaVersion: 1`, `enabled: { <app-id>: <bool> }`
- Registry `defaultEnabled` remains the fallback when no explicit override exists.
- Current catalog defaults remain unchanged (`defaultEnabled: false`).
- Only registry entries with `support: supported` are activatable in this phase.
- Experimental entries remain non-activatable until a runtime implementation exists.

## CLI

- `caelestia-webapps applet-state [app-id]`
- `caelestia-webapps applet-set <app-id> on|off`
- `applet-entry <app-id>` additionally reports presentation-time `enabled` and `activationAvailable` fields without changing the persisted registry schema.
- Enabling requires the WebApp to be installed.
- Successful uninstall resets the applet activation override to `false`.

## Plugin bridge

`GenericStatusBarEntry.qml` polls `applet-state <app-id>` through the stable CLI and only becomes visible when both conditions are true:

1. the applet is enabled;
2. the WebApp window is running.

Activation polling is non-overlapping and preserves the last confirmed state across transient CLI/lock failures.

## Manager

Installed WebApps with `applet.available: true` and `applet.support: supported` receive an `Applet an` / `Applet aus` action. The toggle uses the stable CLI `applet-set` command and updates the Manager state immediately after a successful response.

## Non-goals

- No Phase 16.2 schema changes.
- No Phase 16.3 registry schema changes.
- No capability-level switches yet; those belong to Phase 16.6.
- No experimental applet activation until implementations exist.
