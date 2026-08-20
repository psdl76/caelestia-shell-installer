# Phase 12 – e2e-01

## Goal

Prove that Caelestia WebApps is a complete standalone product before any
official third-party Caelestia plugin API is required.

## End-to-end lifecycle

The isolated test environment exercises:

1. fresh catalog read
2. stable CLI/API envelope
3. user WebApp creation
4. ownership metadata
5. installation
6. separate Firefox setup flow
7. launch when closed
8. duplicate protection + focus when running
9. repair/idempotency
10. Caelestia Material-You theme bridge
11. uninstall while preserving user definition
12. explicit user catalog removal
13. package-owned Built-ins remain untouched

Firefox and Hyprland are stubbed only at the external process boundary.
The engine, catalog, user definitions, installation layout, ownership,
theme bridge and CLI are real project code.

## Gate

`tests/run_phase12_gate.sh`

combines the lifecycle test with the important existing backend, catalog,
ownership, user-app, manager and theme contracts.

## Plugin independence

The active Manager/Engine must not:

- patch Caelestia Sidebar files
- import private `qs.*` / Caelestia Shell QML modules
- depend on the old native-drawer PoC architecture

Future Caelestia integration remains a thin adapter after the standalone
product has passed this gate.

## Historical regression-suite modernization

During the full-suite pass, five pre-Phase-10 tests were found to assert old
implementation details rather than current contracts. They were updated to:

- isolate HOME/XDG state explicitly,
- provide the current `USER_APP_DEF_DIR` catalog input,
- validate reusable ActionButton/IconButton busy semantics,
- validate the unified destructive modal instead of removed inline controls,
- keep graceful close and keyboard-flow guarantees without depending on old QML literals.

No product behavior was reverted to satisfy legacy tests.
