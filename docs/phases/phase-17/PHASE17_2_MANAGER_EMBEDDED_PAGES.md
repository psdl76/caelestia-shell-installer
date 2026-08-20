# Phase 17.2 — Manager Embedded Detail Pages

Status: **IMPLEMENTATION CANDIDATE**

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
- Category and icon choices in the WebApp editor wrap responsively instead of
  widening the page beyond the available main surface.

## Modal boundary

Destructive confirmation remains modal. In particular, uninstall and local
catalog removal still require the established confirmation overlay. This is a
confirmation step, not a navigation destination.

## Architecture boundary

This phase changes only standalone Manager presentation and navigation state.
It introduces no private Caelestia QML dependency and changes no CLI, catalog,
lifecycle, applet or persistence contract frozen in Phase 16.
