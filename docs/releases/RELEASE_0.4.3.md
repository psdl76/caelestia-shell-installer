# Caelestia WebApps 0.4.3

Status: **PUBLIC RELEASE — LIVE VERIFIED**
Date: **2026-08-23**

## Changes since 0.4.2

- Atomic same-directory replacement protects live Hyprland Lua imports during
  commits and rollbacks.
- Uninstall detects concurrent edits before changing live Hyprland files.
- Catalog and applet-registry updates restore the previous consistent pair if
  a commit step fails.
- Repair and upgrade honor a custom `XDG_STATE_HOME` for persistent migration
  state.
- Manager keyboard focus, selection controls, wizard autofocus, off-screen
  focus scrolling and the About animation lifecycle are hardened.
- Rootless installer and uninstaller are directly executable from the release
  archive.
- Runtime archives contain all rootless installation metadata and are built
  reproducibly with normalized ordering, timestamps and ownership.
- The release gate installs and uninstalls the Core from the extracted archive
  rather than relying on files from the source checkout.

## Verified artifacts

- Runtime source archive: `caelestia-webapps-0.4.3.tar.gz`
- SHA256: `2709d273bc79d1c61891a77cfb9aa778796336fecde8198f4bc0cc2f3a6c8cc0`
- Phase 18.2 complete product gate: passed.
- Phase 19 AUR publication gate: passed.
- Reproducible two-build comparison: passed.
- Rootless install/uninstall from the extracted archive: passed.
- Arch package build and generated `SHA256SUMS` verification: passed.
- Real Hyprland lifecycle: passed with no new monitor modeset, no configuration
  error and unchanged keybind count; the previous Core was restored.

The published v0.4.2 tag and artifacts remain unchanged.
