# Phase 16.7 — Repair / Upgrade / Migration

Status: test candidate; requires live validation.

## Scope

Phase 16.7 hardens the existing repair/upgrade path without changing the frozen
catalog, registry, applet activation, capability-setting, or Manager UI contracts.

## Runtime-state migration

`repair.sh` now validates and normalises the persistent Phase 16.5/16.6 state:

- `~/.local/state/caelestia-webapps/applets.json`
- `~/.local/state/caelestia-webapps/applet-settings.json`

Properties:

- schema remains `schemaVersion: 1`;
- valid explicit user choices are preserved;
- legacy flat maps and common boolean spellings (`on/off`, `true/false`, `1/0`)
  are migrated;
- malformed containers/entries are dropped instead of being coerced silently;
- malformed or changed originals are backed up under
  `~/.local/state/caelestia-webapps/migration-backups/` using a content-hash name;
- writes are atomic (`fsync` + `os.replace`);
- missing state files are left missing because registry defaults remain the source
  of truth until the user creates an explicit override;
- a second repair is idempotent and creates no additional backup/write.

## Repair preflight

`repair.sh --preflight` now includes a read-only state migration check. A stale or
partially malformed state file therefore triggers Self-Heal even when installed
app artifacts already match the package version.

## Upgrade

`upgrade.sh` remains an alias of `repair.sh`; there is still one lifecycle path.

## Non-goals

- no Manager/UI redesign;
- no catalog schema changes;
- no applet-registry schema changes;
- no automatic enabling/disabling of applets or capabilities;
- no overwrite of valid user choices.
