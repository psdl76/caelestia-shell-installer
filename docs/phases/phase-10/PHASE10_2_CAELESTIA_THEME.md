# Phase 10.2 – manager-caelestia-theme-01

WebApps Manager now follows Caelestia's real Material-You palette through the
official Caelestia CLI user-template mechanism.

- source template: `data/caelestia/caelestia-webapps.json`
- installed template: `$XDG_CONFIG_HOME/caelestia/templates/caelestia-webapps.json`
- rendered state: `$XDG_STATE_HOME/caelestia/theme/caelestia-webapps.json`
- Theme.qml uses FileView with live reload.
- Current `scheme.json` is used only to hydrate the initial palette immediately.
- No private Caelestia Shell QML services are imported.
- Invalid/missing theme data falls back to the accepted Phase-10.1 palette.
