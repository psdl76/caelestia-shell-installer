# Phase 16.2 contract2 — Strict errors + packaging/repair gate

Status: candidate for live review

## Changes

- Schema contract bumped to `phase16.2-v2`.
- Definition validator now emits machine-readable `violations` in addition to the backwards-compatible `errors` list.
- Selected cross-field failures carry `code`, `app`, `field`, `expected`, and `actual` so CLI/UI diagnostics can point to the exact definition.
- `caelestia-webapps validate-catalog` consumes structured violations and reports concise `app.field: message` diagnostics.
- Runtime tarball creation is gated by both the built-in definition contract and a generated catalog validation. A broken catalog cannot be packaged.
- `repair.sh` validates the package definitions before changing any installed WebApp and records the last validation report at `~/.local/state/caelestia-webapps/catalog-contract-last.json`.
- Negative tests verify that malformed adapter capabilities are rejected with structured diagnostics.

## Frozen Phase 16.1 invariants

The contract still enforces: 79 apps, 14 categories, 23 featured, 21 applet-capable, 4 supported, 17 experimental, and 0 default-enabled applets.
