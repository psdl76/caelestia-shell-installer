# Phase 17.1 — Manager Caelestia Nexus Layout

Status: **ACCEPTED / FROZEN**

## Goal

Move the standalone WebApps Manager from the frozen Phase 16.6 toolbar/list
layout to a Caelestia-Nexus-inspired navigation and content layout.

## Visual contract

- Search and catalog filters live in a persistent left navigation pane.
- Featured, all and installed form the first connected group.
- Catalog categories form a second connected group.
- The Phase 16 horizontal category strip is superseded by this persistent
  vertical navigation while preserving every filter and search semantic.
- Connected rows use large outer radii, small inner radii and an expanded active
  capsule with a primary icon surface.
- The main pane owns the current page title, runtime status, primary create
  action and app list.
- Category changes use a fade plus vertical spatial transition.
- Buttons and navigation rows use a shared project-owned state layer with hover,
  press ripple and shape motion.

## Architecture boundary

The implementation is visually derived from the locally installed Caelestia
Nexus settings UI, but it does not import `qs.*` or private `Caelestia.*` QML.
Palette data continues to use the accepted public CLI template bridge. Motion,
rounding and state-layer primitives are owned by this project.

No catalog, CLI, lifecycle, applet or capability-setting contract changes.
