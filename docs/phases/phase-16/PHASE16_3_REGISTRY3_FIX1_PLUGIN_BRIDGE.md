# Phase 16.3 registry3-fix1 — Plugin Registry Bridge

The Caelestia plugin UI is now aligned with the Phase 16.3 single-runtime-source rule.

- `GenericStatusBarEntry.qml` and `GenericStatusPopout.qml` no longer call `list` for applet metadata.
- New stable CLI read endpoint: `caelestia-webapps applet-entry <app-id>`.
- `applet-entry` reads identity, adapter, support, capabilities and icon identity exclusively from `applet-registry.json`.
- The presentation-only `iconPath` is resolved locally from `registry.icon.name` in `store-icons-v6` (`svg`, `png`, `webp`). It does not consult `catalog.json` or the legacy hicolor app icon path.
- Runtime-source validation now covers the plugin bar entry and popout and rejects a return to `list` metadata.
- Installer/uninstaller coupling remains intentionally out of scope until Phase 16.4.
