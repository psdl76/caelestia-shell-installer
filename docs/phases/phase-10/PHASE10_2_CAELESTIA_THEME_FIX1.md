# Phase 10.2 fix1 – no row-hover trail

In light Caelestia themes the app-row background fade made two neighbouring
rows appear highlighted simultaneously while moving the pointer.

The outer app-row hover fill now switches immediately. Radius morphing remains
animated, preserving the Caelestia motion feel without a visual hover trail.

This is independent of the dynamic Material-You theme bridge.
