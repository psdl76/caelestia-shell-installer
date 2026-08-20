# Phase 5 — Standalone Quickshell Manager PoC

Checkpoint: `manager-poc-01`

## Purpose

Prove that WebApps can run as a standalone Quickshell manager without patching any
Caelestia Sidebar or Bar source files.

## This checkpoint intentionally includes

- standalone `FloatingWindow`
- Catalog v2 initial load
- data-driven categories
- local search
- installed count
- icon rendering using the existing store/icon fallback contract
- launch of already installed apps through the stable WebApps CLI
- clean process exit when the window is closed

## Intentionally deferred to later roadmap phases

- `FileView.watchChanges` live reload / recovery hardening (Phase 6)
- persistent action `Process` bridge for install/repair/uninstall (Phase 7)
- Add/Edit wizard (Phase 8)
- user app storage (Phase 9)
- final Caelestia styling/import decisions (Phase 10)

## Architectural rule added in Phase 5

The manager is a consumer of Catalog + CLI only. It must not import engine shell
libraries, source app definitions directly, or patch Caelestia QML.
