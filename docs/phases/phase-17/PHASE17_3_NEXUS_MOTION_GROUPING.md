# Phase 17.3 — Nexus Motion and Grouping

Status: **ACCEPTED / FROZEN**

## Goal

Match the temporal and structural grammar visible in Caelestia Nexus instead of
only approximating its static surfaces. Page transitions must never expose two
fully composed Manager pages at the same time.

## Reference baseline

The implementation was compared against the official `caelestia-dots/shell`
source at commit `b1c9bbd` (2026-08-20), in particular:

- `modules/nexus/Pages.qml`
- `modules/nexus/common/StackPage.qml`
- `modules/nexus/common/SectionHeader.qml`
- `modules/nexus/common/ConnectedRect.qml`
- `components/Anim.qml`
- `components/StateLayer.qml`

The project reproduces those public visual patterns with project-owned QML. It
does not add a private Caelestia QML dependency.

## Motion contract

- Main-page navigation is sequential: fade the outgoing page, exchange the
  displayed route while invisible, then fade and move in the incoming page.
- Forward pages enter from the right; back navigation enters from the left.
- Catalog category changes follow the Nexus top-level page sequence: fade out,
  exchange the category, then fade in with vertical movement.
- Independent page-level opacity and position `Behavior`s are forbidden because
  they produce the overlapping cross-fade seen in the review video.
- Every transition captures fixed outgoing and incoming objects before it
  starts. Changing the displayed route must not retarget a running animation or
  leave an invisible page enabled above the Manager controls.
- A page at zero opacity is never input-enabled, providing a fail-safe against
  invisible surfaces intercepting clicks.

## Grouping contract

- WebApp details are divided into WebApp, Applet, Verwaltung and Entfernen
  sections as applicable to the selected entry.
- Each section has a subdued Nexus-style label above it.
- Rows within one section use large outer and small inner connected corners.
- Destructive confirmation remains the established modal overlay above page
  transitions.
- Hover state and radial press feedback are clipped by the control's actual
  per-corner rounded Shape path, matching Nexus connected rows.

## Architecture boundary

This phase changes only Manager presentation and navigation timing. CLI,
catalog, lifecycle, applet and persistence contracts remain frozen.
