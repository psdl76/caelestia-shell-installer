# Phase 15.2 — Caelestia Plugin PoC5

Status: candidate for live visual acceptance.

Changes over PoC4:
- keeps the live-accepted plugin discovery, PATH hardening and installer backup isolation;
- adds a self-contained `PluginTheme.qml` using the already established rendered Caelestia WebApps theme file;
- removes the plugin's opaque inner popout background so the shell-provided popout surface remains visually dominant;
- applies dynamic text/accent/hover colours with safe local fallbacks;
- tightens spacing, row radii and manager styling;
- keeps the plugin independent from private `qs.*` and private Caelestia QML imports.

The feature branch is still experimental. This visual pass is not frozen until live-tested inside the isolated shell.
