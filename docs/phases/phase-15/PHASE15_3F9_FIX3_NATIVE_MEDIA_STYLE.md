# Phase 15.3f.9-fix3 — native media style

Goal: make the YouTube popout visually follow Caelestia's own media player
instead of inventing a separate media-card language.

Changes:
- bundled lightweight YouTube logo in the header
- no nested media-card border around the video/details
- no logo/LIVE overlay inside the captured video
- title + subtitle use quiet native-like hierarchy
- wavy progress track with left/right time labels
- previous/next are tonal circular buttons
- play/pause is a larger filled primary button
- the normal no-player state remains the same generic status-less WebApps layout
- no FloatingWindow/PiP drag/snap/clamp code

The plugin still does not import private `qs.*` / shell components. The visual
language is reproduced with public QtQuick primitives and our exported
Caelestia palette roles.
