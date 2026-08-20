# Phase 16.3 registry3 — Single Runtime Metadata Source

Status: **LIVE TEST CANDIDATE**

## Goal

Make `applet-registry.json` the sole metadata source for applet runtime behavior, while leaving the frozen Catalog Schema v2 intact.

## Runtime source of truth

The following consumers now read applet integration metadata only from the persisted registry:

- `status-feed`
- notification watcher eligibility
- MPRIS/media ownership routing
- `browser-video-state`
- `media-control`

The registry owns adapter, capabilities, match hosts, support level, browser bridge, notification matches, window class and icon identity for applet runtime use.

## Catalog compatibility mirror

`catalog.json.statusIntegration` remains generated and validated only because Phase 16.2 / Catalog Schema v2 is frozen. It is **compatibility-only** and has no runtime consumers.

`scripts/validate_applet_runtime_sources.py` mechanically enforces that quarantine.

## New audit

```bash
caelestia-webapps validate-applet-runtime-sources
```

Expected:

```json
{
  "runtimeMetadataSource": "applet-registry.json",
  "legacyCatalogMirror": "compatibility-only",
  "violations": 0,
  "consistent": true
}
```

## Packaging gate

Runtime packaging now fails if a runtime consumer starts reading the legacy catalog mirror again or if the registry source invariants are lost.

## Scope boundary

Installer, uninstaller and Manager activation are intentionally unchanged. They belong to Phase 16.4+.
