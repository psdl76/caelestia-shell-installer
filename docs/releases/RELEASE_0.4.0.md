# Caelestia WebApps 0.4.0

Status: **LOCAL / PRIVATE RELEASE**  
Date: **2026-08-20**

## Highlights

- Accepted and frozen Phase 16.8 packaged lifecycle.
- Nexus-style Manager sidebar and main-surface layout.
- Embedded animated add/edit, WebApp-Info and applet-settings pages.
- Full-row All Apps navigation with actions grouped on WebApp-Info.
- Persistent applet activation and capability controls.
- Nexus-style About page with package version and project credit.
- Keyboard-accessible catalog rows with visible focus and Enter/Space support.

## Validation

- Phase 17.1–17.7 Manager acceptance and closing gate: passed.
- Phase 16.8 end-to-end lifecycle: 22/22 tests passed.
- Phase 13 packaging/product gate: 17/17 tests passed.
- Shell syntax: passed.
- Live Hyprland/Quickshell checks `1A`, `1B`, `1C` and keyboard acceptance:
  passed by the user.

## Artifacts

The release gate creates these local artifacts under `dist/release-0.4.0/`:

- `caelestia-webapps-0.4.0.tar.gz`
- `arch/caelestia-webapps-0.4.0-1-any.pkg.tar.zst`
- `SHA256SUMS`

The runtime archive contains exactly one `caelestia-webapps-0.4.0` top-level
directory and excludes repository history, tests, caches and editor metadata.

## Publication boundary

This is a local/private release. No Git remote is configured, the Arch package
URL is intentionally empty and the project still carries
`packaging/LICENSE-PENDING.txt`. Choose a redistribution license and configure
the canonical repository URL before publishing the source archive, package or
tag externally.

No real user installation is changed as part of the release build.
