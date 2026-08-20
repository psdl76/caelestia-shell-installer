# Phase 17.2 — Manager Embedded Detail Pages

Status: **ACCEPTED / FROZEN**

## Goal

Keep the Caelestia Nexus navigation frame intact when the user opens a WebApp
workflow. The right-hand main surface changes page instead of opening a second,
visually unrelated dialog above the Manager.

## Navigation contract

- The catalog, More Actions, WebApp editor and applet settings are pages of the
  same main surface.
- The left navigation stays visible and spatially stable during page changes.
- Forward navigation fades and moves the incoming page horizontally using the
  project-owned effect and spatial animation primitives.
- Every detail page has a consistent back button and Manager close button.
- Closing a create flow returns to the catalog.
- Closing an edit flow or applet settings returns to the originating More
  Actions page.
- Choosing a catalog category returns directly to the catalog page.
- Category and icon choices in the WebApp editor use styled select popouts
  constrained to the available main surface.

## Nexus settings visual grammar

- Window close is a single global control in a project-owned connected surface
  dock at the top-right window edge. It is not repeated as a circular button in
  page headers.
- Detail-page headers contain the tonal back action, a large page title and no
  independent close capsule.
- More Actions uses connected `surfaceContainer`-style groups: large outer
  corners, small inner corners, compact gaps and no card outlines.
- Action rows share the main page's typography, spacing and semantic colours;
  destructive actions change emphasis without becoming a different layout.
- The Manager does not use native Qt tooltips. Every catalog action has a
  visible text label, and source ownership is written beside its icon.
- Content rows use the Nexus `surfaceContainer` role; secondary row text uses
  the `outline` role while navigation descriptions use `onSurfaceVariant`.
- Hover feedback is clipped to the control's actual rounded corner geometry;
  non-interactive catalog rows do not acquire a misleading hover selection.

## Modal boundary

Destructive confirmation remains modal. In particular, uninstall and local
catalog removal still require the established confirmation overlay. This is a
confirmation step, not a navigation destination.

## Architecture boundary

This phase changes only standalone Manager presentation and navigation state.
It introduces no private Caelestia QML dependency and changes no CLI, catalog,
lifecycle, applet or persistence contract frozen in Phase 16.
