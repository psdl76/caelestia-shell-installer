# Phase 16.2 — Final Catalog Schema Contract

**Contract ID:** `phase16.2-v3`  
**Catalog schema:** `schemaVersion: 2`  
**Status target:** LIVE ACCEPTED / FROZEN after live validation

## Purpose

The catalog is the single source of truth for built-in Caelestia WebApps. Phase 16.2 freezes the machine-checkable contract that Phase 16.3 can safely consume to generate the applet registry.

## Required built-in fields

Every `apps/<app-id>.conf` must define:

- `APP_ID`, `APP_NAME`, `APP_GENERIC_NAME`, `APP_COMMENT`, `APP_URL`
- `APP_CATALOG_CATEGORY`
- `MOZ_APP_REMOTINGNAME`, `WINDOW_CLASS`
- `ICON_NAME`, `ICON_PROVIDER`, `ICON_ID`, `APP_PROVIDER`
- `APP_FEATURED`
- `APPLET_AVAILABLE`, `APPLET_DEFAULT_ENABLED`
- `APPLET_ADAPTER`, `APPLET_SUPPORT`
- `APPLET_CAPABILITIES`, `APPLET_MATCH_HOSTS`

`APP_CATALOG_CATEGORIES_LIST` is optional for backwards compatibility; when present, it must include the primary category.

## Allowed applet adapters

`none`, `notifications`, `media`, `mail`, `calendar`

## Allowed support levels

`none`, `experimental`, `supported`

## Capability vocabulary

- `notifications`: `notifications`, `badge`, `preview`
- `media`: `now_playing`, `playback_controls`, `artwork`, `live_preview`, `video_crop`, `pin`
- `mail`: `unread`, `latest_mail`
- `calendar`: `next_event`, `upcoming_events`
- `none`: no capabilities

Capabilities may only be used with their owning adapter.

## Cross-field rules

- `APPLET_ADAPTER=none` requires `APPLET_AVAILABLE=false`, `APPLET_DEFAULT_ENABLED=false`, `APPLET_SUPPORT=none`, no capabilities and no match hosts.
- A non-`none` adapter requires `APPLET_AVAILABLE=true` and support `experimental|supported`.
- Core catalog applets always default to disabled.
- An applet-capable entry requires at least one valid capability.
- `media` requires `APPLET_MATCH_HOSTS`; other adapters currently must not declare hosts.
- Hosts and capability lists must not contain duplicates.
- The primary category must exist and must also occur in `APP_CATALOG_CATEGORIES_LIST` when that list is defined.
- Category-owned legacy fields are forbidden in per-app definitions.
- Every built-in app requires an explicit icon provider and icon ID; curated non-Dashboard providers require an explicit HTTP(S) `ICON_URL`.

## Frozen Phase 16.1 invariants

The validator intentionally treats accidental changes to these accepted catalog counts as contract violations:

- 79 apps
- 14 categories
- 23 Featured
- 21 applet-capable
- 4 supported
- 17 experimental
- 0 default-enabled applets

Changing these values in a future catalog expansion requires an explicit contract/version update rather than silently drifting.

## Validation interface

Interactive terminal:

```bash
caelestia-webapps validate-catalog
```

prints a human-readable report.

Machine/API form:

```bash
caelestia-webapps validate-catalog --json
```

returns the stable JSON envelope. When stdout is not a TTY, JSON remains the default for backwards-compatible scripting.

`--human` forces the readable form even when output is redirected.

## Release gates

- Runtime packaging validates package definitions and a freshly generated catalog before creating an archive.
- `repair.sh` validates the package contract before modifying installed WebApps.
- The last repair validation report is stored in `~/.local/state/caelestia-webapps/catalog-contract-last.json`.
- Negative tests must prove that invalid adapter capabilities, default-enabled core applets, broken categories, unsupported icon providers, and invalid adapter/host combinations are rejected.
