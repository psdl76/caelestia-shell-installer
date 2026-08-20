# Phase 15.2 — Caelestia Plugin PoC 1

Status: EXPERIMENTAL / NOT FROZEN

## Goal

Thin Caelestia adapter using the draft official plugin system from shell PR #1703.

Entry points:
- `bar-entry` named `webapps`
- `bar-popout` attached to `webapps`

Runtime boundary:
- plugin calls `caelestia-webapps list`
- plugin calls `caelestia-webapps launch <id>`
- plugin calls `caelestia-webapps-manager`

The core owns all business logic.

## Placement

WebApps is a dedicated app/media entry. It must NOT be placed in the
System/Devices/status-icons bubble.

## Current limitations

- PR #1703 is still open.
- The plugin API may change.
- Sidebar-page is deferred in the current PR.
- Visual styling is intentionally self-contained and does not import private
  `qs.*` or private Caelestia shell components.
- Plugin discovery/install location is intentionally NOT hard-coded until
  verified against the live feat/plugins build.
