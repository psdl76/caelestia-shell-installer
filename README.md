# Caelestia WebApps 0.4.0

Caelestia WebApps is a standalone manager for Firefox-based WebApps on
Hyprland, visually aligned with the Caelestia Shell Nexus settings UI.

Release 0.4.0 is the accepted Phase 16.8 lifecycle and Phase 17.7 Manager
baseline. It is currently a local/private release: a public repository URL and
redistribution license have not yet been selected.

## Features

- catalog of built-in and user-defined WebApps;
- isolated Firefox profiles and Hyprland integration;
- install, launch, setup, repair and uninstall lifecycle through a stable CLI;
- optional Caelestia TopBar applets and persistent capability settings;
- standalone QML/Quickshell Manager with Nexus-style navigation and motion;
- WebApp detail pages, add/edit wizard, confirmation flows and About page;
- keyboard navigation, live runtime state and Caelestia-derived public palette
  bridge without private Caelestia QML imports.

## Requirements

- Arch Linux or a compatible userspace
- Hyprland
- Quickshell
- Firefox
- Bash and Python 3

## Run from the workspace

```bash
./manager.sh
```

The Manager performs its preflight, refreshes Catalog v2 through
`bin/caelestia-webapps` and then opens the standalone Quickshell window.

## Architecture

- CLI JSON API: v1
- catalog schema: v2
- applet registry schema: v1
- Manager-to-engine calls always use argument lists
- user definitions and persistent runtime settings remain outside package-owned
  source files
- plugin and standalone code do not import private Caelestia APIs

## Validation

The complete accepted product gate is:

```bash
bash tests/run_phase17_7_closing_gate.sh
```

It includes the Phase 17 Manager suite, the 22-test Phase 16.8 lifecycle gate,
shell syntax validation and the 17-test packaging/product gate. Destructive
lifecycle tests run in disposable HOME/XDG environments.

The local 0.4.0 release gate, including artifact builds, is:

```bash
bash tests/run_release_0_4_0_gate.sh
```

## Packaging and licensing

The runtime source archive and Arch package are suitable for local/private use.
The desktop entry intentionally uses the generic `applications-internet` icon.
Before public redistribution, replace the placeholder package URL and select an
explicit project license; see `packaging/LICENSE-PENDING.txt`.

See `docs/phases/phase-17/PHASE17_7_VISUAL_ACCEPTANCE_CLOSING_GATE.md` and
`docs/releases/RELEASE_0.4.0.md` for the accepted baseline and release notes.
