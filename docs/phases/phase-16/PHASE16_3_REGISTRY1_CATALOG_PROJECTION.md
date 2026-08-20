# Phase 16.3 registry1 — Catalog-derived Applet Registry

Status: TEST CANDIDATE

This step introduces the first generated Applet Registry. It does not change Phase 15 runtime behavior and does not yet couple the installer, manager, or QML plugin to the registry.

## Source of truth

The validated catalog schema v2 remains authoritative. The registry is a deterministic projection of catalog entries where `applet.available == true`.

## Registry schema v1

The registry contains only applet-relevant data:

- app id and display name
- source
- adapter
- support state
- default-enabled state
- capabilities
- media match hosts
- window class
- notification match strings
- browser bridge metadata
- icon identity

Entries are sorted by app id. No generated timestamp is stored, so identical catalog input produces byte-identical registry output.

## Commands

- `caelestia-webapps applet-registry` returns the generated registry in the stable CLI envelope.
- `caelestia-webapps validate-applet-registry` validates that the generated registry is the exact catalog projection.

## Frozen catalog expectations

For the current built-in catalog the generated registry contains 21 applet-capable apps: 4 supported and 17 experimental, with 0 default-enabled.

## Deliberate non-goals

No manager/installer coupling in registry1. No Phase 15 QML/runtime rewrites. No private Caelestia APIs.

## Persisted lifecycle

`catalog.sh` writes `~/.local/share/caelestia-webapps/applet-registry.json` after catalog generation and validates it immediately. The stable CLI reads that persisted registry. The standalone registry validator independently reconstructs the expected projection, so a stale or manually changed registry is rejected.
