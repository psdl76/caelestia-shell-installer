# Caelestia WebApps 0.4.2

Status: **PUBLIC RELEASE — VERIFIED**
Date: **2026-08-20**

## Changes since 0.4.1

- New project-owned Caelestia WebApps logo with a transparent native SVG
  master and launcher-size PNG exports.
- Scalable `caelestia-webapps` desktop icon installed for rootless and Arch
  packages.
- Static compact logo on the startup surface.
- Nexus-inspired animated logo entrance on the About page using only public
  QtQuick APIs.
- Animation restarts whenever the About destination is opened.

## Validation

- Phase 20.1 graphical acceptance: passed with distinction by the user.
- SVG structure, transparency and PNG export contract: passed.
- QML lint for the standalone animation component: passed.
- Rootless installation of the desktop entry and hicolor icon: passed.
- Full Phase 18.2 product regression gate: passed.
- Phase 19 AUR candidate regression gate: passed before the v0.4.2 metadata
  refresh.

## Release boundary

The v0.4.1 tag and artifacts remain unchanged. Version 0.4.2 is a branding-only
release on top of the accepted v0.4.1 lifecycle and localization baseline.
