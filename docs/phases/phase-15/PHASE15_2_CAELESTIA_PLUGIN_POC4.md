# Phase 15.2 — Caelestia Plugin PoC4

Status: candidate for live test; not frozen.

PoC3 was live accepted for the complete functional path:

- discovery and enablement
- bar-entry rendering
- bar-popout rendering
- CLI list parsing/filtering
- rootless PATH hardening
- launch/focus of an existing ChatGPT window without spawning a duplicate

PoC4 begins the post-PoC hardening pass.

## Installer backup isolation

The PoC3 test installer stored its backup as a sibling below
`~/.config/caelestia/plugins/`. The feat/plugins scanner discovers one directory
level below that root, so the backup manifest claimed the same generated plugin
ID and Caelestia disabled both copies.

PoC4 fixes this by:

- storing backups in `~/.config/caelestia/plugin-backups/`
- staging in `~/.config/caelestia/.plugin-staging/`, outside the discovery root
- automatically moving historical `plugins/webapps.backup.*` directories out of
  the discovery root before installation
- retaining same-filesystem renames for the final plugin swap

The helper still does not modify `shell.json` or `plugins.json`.

## Next checkpoint

After the installer hardening is live accepted, the next PoC will perform the
visual/native-style pass without coupling the WebApps plugin to private `qs.*`
or private Caelestia QML APIs.
