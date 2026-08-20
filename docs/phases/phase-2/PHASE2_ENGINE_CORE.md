# Phase 2 – Engine Core 01

This checkpoint extracts the proven WebApps runtime from the legacy v8.1 PoC into a UI-independent engine.

## Deliberately removed from the active engine

- native Caelestia sidebar PoC
- standalone legacy manager QML
- bar/sidebar applet QML
- Caelestia QML patchers
- notification patchers
- applet install/repair/uninstall lifecycle

These remain preserved in the frozen legacy v8.1 reference package and its archived UI tests.

## Preserved engine contracts

- app definitions and central category schema
- catalog generation
- isolated Firefox profiles
- setup/normal launchers
- activate-or-launch duplicate protection
- desktop integration
- icons and local fallbacks
- Hyprland Lua integration and special workspaces
- install / repair / uninstall ownership
- shared WebApps-owned infrastructure cleanup
- no-real-HOME test discipline

`--no-applet` is accepted by `install.sh` only as a compatibility no-op for existing automated fixtures. The engine has no applet implementation.

## Boundary

The engine may expose metadata useful to future UIs/adapters (for example applet visibility defaults in the category schema), but it must not import, patch or modify Caelestia/Quickshell UI files.
