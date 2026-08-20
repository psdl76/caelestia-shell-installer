# Caelestia WebApps 0.4.1

Status: **LOCAL / PRIVATE RELEASE — VERIFIED**
Date: **2026-08-20**

## Changes since 0.4.0

- Automatic German/English Manager localization.
- Explicit `CAELESTIA_WEBAPPS_LANGUAGE=de|en` launch override.
- Localized startup progress, catalog/navigation, WebApp info/actions, applet
  settings, add/edit wizard, confirmation flow and About page.
- English built-in descriptions reuse Catalog v2 `genericName`; user content is
  preserved verbatim and the frozen catalog schema remains unchanged.

## Validation

- Phase 18.1 automated localization gate: passed.
- Full Phase 17.7, Phase 16.8 and Phase 13 regression gates: passed.
- English live Manager acceptance: passed by the user.
- German live Manager acceptance: passed by the user.
- Real rootless Core 0.4.1 install and uninstall: passed.
- Real temporary WebApp create/install/status/uninstall/delete: passed.
- The previous Core version, persistent state and all six existing WebApps were
  restored and verified after the test; no temporary artifacts remained.

## Publication boundary

This remains a local/private release. No Git remote is configured and the
project still carries `packaging/LICENSE-PENDING.txt`. Select a redistribution
license and canonical repository URL before public upload.

The real-home test is intentionally manual and requires an explicit safety
argument:

```bash
bash tests/manual_real_release_0_4_1_lifecycle.sh --confirm-real-home
```

It backs up and restores the existing rootless Core, project state, catalog and
affected Hyprland files. It must never be added to an unattended automated gate.
