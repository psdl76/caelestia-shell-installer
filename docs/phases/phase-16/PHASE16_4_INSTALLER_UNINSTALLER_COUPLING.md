# Phase 16.4 – Installer / Uninstaller Coupling

Status: freeze candidate, pending live validation.

## Goal

Keep the persisted product catalog and the Phase-16.3 applet runtime registry in
lock-step across every direct app lifecycle mutation.

## Changes

- `lib/catalog.sh` now builds `catalog.json` and `applet-registry.json` as one
  validated runtime-metadata pair.
- Both files are generated in a staging directory and validated before either
  live file is replaced. A generator/validator failure therefore leaves the
  previous live pair untouched.
- direct `install.sh` and `uninstall.sh` now use this coupled path.
- `repair.sh` performs a final coupled refresh after upgrades and also refreshes
  metadata when no installed WebApps need repair.
- standalone `catalog.sh` reuses the same helper instead of maintaining a second
  registry-generation implementation.
- Phase 16.2 schema and Phase 16.3 registry schema remain unchanged.
- Manager applet activation remains out of scope for Phase 16.5.

## Live acceptance

After installing or uninstalling one WebApp, both files must be present and the
registry validator must pass without running a separate manual `refresh`:

```bash
caelestia-webapps validate-applet-registry
caelestia-webapps applet-entry youtube
```
