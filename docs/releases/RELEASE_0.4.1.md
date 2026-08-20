# Caelestia WebApps 0.4.1

Status: **LOCAL / PRIVATE RELEASE CANDIDATE**  
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
- Real installed lifecycle: pending before tag/publication.

## Publication boundary

This remains a local/private candidate. No Git remote is configured and the
project still carries `packaging/LICENSE-PENDING.txt`. The candidate must pass
the agreed real install/uninstall check before tagging. Select a redistribution
license and canonical repository URL before public upload.
