# Phase 15.3f.9 — Compact pinned YouTube applet

This phase removes the separate YouTube PiP/FloatingWindow experiment completely.

YouTube is again only a Caelestia `bar-entry` + `bar-popout`:
- live cropped video preview remains in the popout
- MPRIS previous / play-pause / next remain in the popout
- title/subtitle remain in the popout
- the open action remains in the popout
- no second window, drag, snap, clamp, layout persistence, or PiP window state

The YouTube renderer opts into a compact media mode:
- 344 px media popout width
- smaller header
- tighter spacing
- smaller media controls
- slimmer open button
- other generic media adapters remain unchanged

## Pin boundary

Current Caelestia `feat/plugins` owns plugin popout activation inside
`modules/bar/Bar.qml`; plugin content does not receive `PopoutState`.

The plugin therefore does not use a private import or parent-tree hack.

For the isolated `caelestia-plugin-test` shell only, this phase includes an
optional generic PoC patch:

`integrations/caelestia/tools/apply-pinned-popout-test-shell.py`

It makes `Bar.checkPopout()` keep the current popout selected while the loaded
popout root exposes `pinned === true`.

The patch:
- is generic (no YouTube id)
- refuses unknown shell revisions
- creates a timestamped backup
- only targets the isolated test shell by default
- has a matching restore helper

This should become an upstream/public plugin contract before production packaging.
