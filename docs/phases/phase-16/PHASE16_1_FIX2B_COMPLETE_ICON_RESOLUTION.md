# Phase 16.1-fix2b — Complete Icon Resolution Audit

## Why fix2a still showed missing icons

fix2a correctly stopped caching the generic globe, but it also removed the useful
website favicon fallback from fix2. The result was a clean but incomplete v5 cache:
66/79 apps resolved locally on the live test system.

## fix2b

Resolution order is now deterministic and explicit:

1. cached local icon
2. Dashboard Icons via explicit `ICON_ID` only (SVG -> PNG -> WEBP)
3. explicit curated external provider for catalog entries that intentionally use one
4. bundled app-specific local icon
5. real website favicon, downloaded once and cached locally
6. generic globe only as non-cached runtime emergency fallback

The generic globe is never written into the store cache.

## Diagnostics

Every run writes:

`~/.local/state/caelestia-webapps/icon-pipeline.log`

with one line per app and a final `total/resolved/unresolved` summary.

The startup loader also shows the real icon summary. `prepare_store_icons.sh` returns
non-zero when any built-in icon is unresolved; the manager preflight deliberately
continues so a transient network failure cannot prevent the UI from opening.

## Cache generation

The cache was bumped to `store-icons-v6` to ensure old incomplete/poisoned cache
entries cannot influence the fix2b validation.

## Strict validator

`scripts/validate_store_icons.py` independently verifies the live cache and only
returns PASS for exactly 79 built-in apps, 79 explicit mappings and 79 valid local
icon files. This prevents a future `PASS` with an incomplete cache.
