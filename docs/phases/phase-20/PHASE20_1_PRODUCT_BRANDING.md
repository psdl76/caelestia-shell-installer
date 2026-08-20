# Phase 20.1 — Product Branding

Status: **LIVE ACCEPTED / FROZEN**

## Goal

Give Caelestia WebApps a distinct project-owned identity without imitating the
Caelestia Shell mark or changing the accepted application workflows.

## Branding contract

- `assets/branding/caelestia-webapps.svg` is the canonical vector master.
- The logo uses native SVG geometry and gradients and never embeds a raster
  image.
- Transparent PNG exports cover common launcher sizes from 16 to 512 pixels.
- The desktop entry uses the stable icon name `caelestia-webapps`.
- Rootless and Arch packages install the SVG to the hicolor scalable app-icon
  directory and Core removal removes only that package-owned icon.
- The startup surface uses a static compact rendering.
- The About hero uses a standalone QtQuick animation inspired by the public
  Nexus `AnimatedLogo` entrance: rotation, scale overshoot and opacity reveal.
- The animation restarts when About becomes active and imports no private
  Caelestia APIs.

## Release boundary

The public v0.4.1 archive predates this branding work and remains immutable.
The branding integration is released as v0.4.2 with a regenerated AUR checksum;
the existing v0.4.1 release remains unchanged.

## Acceptance

1. automated branding and packaging tests pass;
2. the startup icon renders correctly in a real Quickshell session — passed;
3. the About entrance animation is visually accepted — passed with distinction;
4. the installed desktop launcher resolves the new icon;
5. the next release archive and AUR metadata contain the accepted assets.
