# Caelestia WebApps – Manager PoC 01

Phase-5 checkpoint of the plugin-ready Caelestia WebApps project.

This package contains:

- UI-independent WebApps engine
- stable CLI/JSON API (`apiVersion: 1`)
- Catalog v2 (`schemaVersion: 2`)
- first standalone Quickshell Manager PoC

The manager is **not** integrated into the Caelestia Sidebar or Bar and does not
patch any Caelestia QML source files.

## Start the manager

```bash
./manager.sh
```

The launcher refreshes Catalog v2 through the stable CLI and then starts the
standalone Quickshell window.

## Phase-5 scope

Implemented:

- standalone `FloatingWindow`
- initial Catalog v2 load
- data-driven categories
- local search
- installed count
- icon rendering
- Open for installed apps through the stable CLI
- clean manager exit when its window closes

Intentionally deferred:

- robust live Catalog watching/recovery — Phase 6
- long-running `Process` action bridge for install/repair/uninstall — Phase 7
- Add/Edit WebApp wizard — Phase 8
- user app persistence — Phase 9
- final Caelestia styling/import decisions — Phase 10

## Architecture contract

The manager consumes only the stable Catalog and CLI boundaries. The engine does
not import, source, or otherwise depend on the manager implementation.

## Tests

```bash
./tests/run.sh
```

Current active suite: 20 tests.

See:

- `PHASE2_ENGINE_CORE.md`
- `PHASE3_ENGINE_API.md`
- `PHASE4_CATALOG_V2.md`
- `PHASE5_MANAGER_POC.md`


## Phase 6 checkpoint

See `PHASE6_MANAGER_LIVE.md` for FileView live reload and transient running-state rules.


## Phase 7 checkpoint

See `PHASE7_PROCESS_BRIDGE.md` for the complete Quickshell Process action bridge.


## Phase 8 checkpoint

See `PHASE8_USER_APPS.md` for persistent user definitions and the Add/Edit Wizard.


## Phase 8.1 checkpoint

See `PHASE8_1_ICONS_DELETE.md`.

## Phase 15.3a status capability model

The catalog now carries additive `provider`, `tags`, `featured`, and
`statusIntegration` metadata. `appletVisible` remains launcher/popout visibility;
status integration is a separate capability contract. See
`PHASE15_3A_STATUS_CAPABILITY_MODEL.md`.
