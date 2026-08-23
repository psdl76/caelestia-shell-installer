# Orphan Installation Recovery

Status: **REGRESSION FIX / ACCEPTED BY AUTOMATED GATES**

## Problem

Older or manually modified installations can retain a complete installed
WebApp after its user definition has disappeared. Catalog v2 correctly omits
such an unknown app, which previously made its profile, launcher, desktop
entry, icon and Hyprland membership invisible to the Manager and impossible to
remove through the supported product UI.

## Contract

- Catalog v2 and `applet-registry.json` remain unchanged and authoritative for
  defined applications and applet metadata.
- The CLI `list` response exposes recoverable remnants separately as
  `orphanInstallations`; this transient projection is never persisted.
- A remnant is exposed only when `installed.conf` parses without shell
  evaluation and its identity, URL, category, runtime identifiers and every
  stored managed path pass strict validation.
- The Manager merges the transient projection into its Installed view and
  marks it as an orphaned installation.
- A safely attributable former user WebApp offers restoration of its missing
  definition from validated installation metadata. Restoration requires the
  app ID, Firefox remoting name and window class to agree and a regular managed
  SVG icon to exist.
- Every orphan offers explicit cleanup after a destructive confirmation.
  Launch, setup, direct repair, editing, installation and applet actions remain
  unavailable until a definition has been restored.
- Cleanup derives every deletion target from the validated app ID. Metadata
  cannot redirect deletion to another path.
- A running matching Hyprland window blocks direct cleanup. The explicit close
  variant first requests a normal window close and aborts if the window remains
  open.
- Recovery may remove exact app membership from existing managed rules, but it
  never retires shared Hyprland infrastructure whose ownership cannot be
  established without the missing definition.

## Regression evidence

`tests/test_orphan_installation_recovery_01.sh` reproduces definition loss in a
disposable HOME/XDG environment and verifies discovery, catalog/registry
isolation, runtime projection, definition restoration without profile loss,
complete cleanup and rejection of path-tampered metadata.
`tests/test_manager_orphan_recovery.py` verifies the Manager recovery surface.
Both tests are part of the Phase 16.8 and Phase 17.7 gates.
