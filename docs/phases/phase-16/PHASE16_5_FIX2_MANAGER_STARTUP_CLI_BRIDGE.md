# Phase 16.5-fix2 — Manager startup / CLI catalog bridge

## Problem

Live diagnostics showed that normal CLI reads indirectly executed `catalog.sh json`,
while `catalog.sh` rebuilt `catalog.json` unconditionally before every command. The
Manager polls runtime/state commands, so the persisted catalog was rewritten many
times per second. Quickshell `FileView` then observed transient replacement/truncate
states and emitted `File does not exist`, `Permission denied`, `Not a file` and
related warnings.

## Fix

- `catalog.sh list` and `catalog.sh json` are now strictly read-only when the persisted
  metadata pair exists.
- First-use bootstrap is handled explicitly by the stable CLI under an exclusive lock.
- `caelestia-webapps refresh` explicitly rebuilds the validated catalog + applet registry pair.
- Manager QML no longer reads/watches `catalog.json` through `FileView`; it loads catalog
  data through `caelestia-webapps list`.
- Startup handoff waits for preflight, first catalog load and initial applet-state load.
- Applet-state is no longer started before preflight completes.
- The startup surface receives a 500 ms final handoff window so the compositor can
  visibly present it before the main Manager window replaces it.

## Contract

Phase 16.2 schema v2 and Phase 16.3 applet-registry schema v1 are unchanged.
Phase 16.4 coupled catalog/registry generation remains the only normal mutation path.
