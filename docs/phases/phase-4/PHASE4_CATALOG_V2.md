# Phase 4 — Catalog v2

Checkpoint target: `catalog-v2`

## Purpose

`catalog.json` is the stable read model consumed by the future Quickshell Manager and, later, the thin Caelestia adapter. Engine actions remain behind the CLI; the catalog is read-only from UI code.

## Contract changes from v1

- `schemaVersion` is now `2`.
- Existing v1 app fields are preserved.
- Each app adds `source` (`builtin` today, `user` reserved for the User Apps phase).
- Each app adds static `capabilities` for `launch`, `setup`, `install`, `repair`, and `uninstall`.
- Category metadata adds explicit `order` instead of relying only on array position.
- A dedicated validator enforces IDs, types, category references and counts.
- Empty/corrupt/v1 catalog files are regenerated atomically as valid v2.
- Unchanged v2 output is not rewritten, preventing unnecessary future `FileView` reloads.

## Architectural rules learned in Phase 4

1. Catalog is a **read model**, never the owner of mutations.
2. Catalog schema version and CLI API version are independent contracts.
3. Capability describes what an app type supports; it does not encode transient UI button state.
4. Runtime health remains the `status` API's responsibility; `installed=true` alone does not prove a healthy runtime.
5. Catalog generation must be atomic and idempotent because the future manager will watch the file.
6. User-app support is represented by `source`, but no user-app storage format is invented early.
7. No Caelestia plugin manifest, hooks or layout data belong in Catalog v2.
