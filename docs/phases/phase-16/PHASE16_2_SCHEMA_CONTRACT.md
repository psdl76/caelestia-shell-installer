# Phase 16.2 – Catalog / Capability Schema Contract v1

## Goal

Freeze the Phase-16.1 catalog model before the Applet Registry is generated from it in Phase 16.3.

## Core catalog invariants

The built-in catalog currently requires:

- 79 built-in WebApps
- 14 categories
- 23 Featured apps
- 21 applet-capable apps
- 4 `supported` applets
- 17 `experimental` applets
- 0 applets enabled by default
- explicit icon provider + icon ID for every built-in app

These counts are intentional drift guards for the frozen Phase-16.1 catalog. A future catalog expansion must update the contract deliberately rather than silently changing it.

## Applet adapters

Allowed adapters:

- `none`
- `notifications`
- `media`
- `mail`
- `calendar`

Adapter capabilities are namespaced by adapter:

- notifications: `notifications`, `badge`, `preview`
- media: `now_playing`, `playback_controls`, `artwork`, `live_preview`, `video_crop`, `pin`
- mail: `unread`, `latest_mail`
- calendar: `next_event`, `upcoming_events`

An applet with adapter `none` must be unavailable, disabled, support `none`, and have no capabilities or match hosts.

Any non-`none` adapter requires:

- `APPLET_AVAILABLE=true`
- support `experimental` or `supported`
- at least one adapter-valid capability
- `APPLET_DEFAULT_ENABLED=false`

Media adapters currently require `APPLET_MATCH_HOSTS`; other adapters currently must not define match hosts.

## Categories

- Primary category must exist.
- Every secondary category must exist.
- The multi-category list, when present, must include the primary category.
- Duplicate categories are rejected.
- Category-owned Caelestia/Hyprland fields remain forbidden in per-app definitions.

## Icons

Every built-in definition needs explicit `ICON_PROVIDER` and `ICON_ID`.
Known provider types in the current catalog are validated explicitly. Curated non-dashboard providers require an explicit HTTP(S) `ICON_URL`.

## Validators

Source definitions:

```bash
scripts/validate_definitions.py .
```

Generated catalog:

```bash
scripts/validate_catalog.py ~/.local/share/caelestia-webapps/catalog.json
```

Stable CLI contract:

```bash
bin/caelestia-webapps validate-catalog
```

The CLI returns API v1 JSON with schema contract, catalog statistics, generated counts, icon mapping count, and zero violations on success.

## Negative tests

Phase 16.2 includes deliberate failing fixtures for:

- capability assigned to the wrong adapter
- applet enabled by default
- primary category missing from multi-category membership

This verifies that the validator rejects invalid definitions rather than only accepting the current catalog.

## contract3 — finalization

- Contract ID advanced to `phase16.2-v3`.
- Formal final contract is documented in `PHASE16_2_SCHEMA_CONTRACT_FINAL.md`.
- `caelestia-webapps validate-catalog` is human-readable on an interactive terminal.
- `caelestia-webapps validate-catalog --json` forces the stable JSON API envelope.
- Non-TTY/no-flag invocation remains JSON for backwards-compatible scripting.
- `--human` can force the readable form.
- Final negative-test matrix covers capability/adapter mismatch, default-enabled applets, primary-category drift and unsupported icon providers.
