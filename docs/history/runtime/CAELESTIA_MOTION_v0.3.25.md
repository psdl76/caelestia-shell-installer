# Caelestia Motion Pass — v0.3.25

This release is deliberately a frontend-only motion/interaction pass.

Reference principles taken from current Caelestia Shell:
- central animation/easing tokens (`Anim.qml`, `CAnim.qml`)
- animated surface colour changes (`StyledRect.qml`)
- animated text state changes (`StyledText.qml`)
- Material 3 Expressive spatial motion introduced in Caelestia 2.x
- restrained deformation: rounding, scale, spacing and surfaces communicate state

Implemented without changing the tested WebApps backend:
- expressive manager entrance
- morphing filter chips
- cards that softly deform instead of simply changing colour
- icon tiles that follow card focus
- action buttons with hover/press/busy morph states
- animated transient toast feedback
- smoother in-window uninstall modal entrance/exit
- all install/open/setup/repair/uninstall routes remain unchanged

The manager remains standalone and therefore does not import Caelestia's private QML
components directly; this avoids coupling the project to internal module paths/tokens
that upstream explicitly documents as unstable.
