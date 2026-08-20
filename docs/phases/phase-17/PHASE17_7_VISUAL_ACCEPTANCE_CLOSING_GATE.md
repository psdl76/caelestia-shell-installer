# Phase 17.7 — Manager Visual Acceptance and Closing Gate

Status: **ACCEPTED / FROZEN**

## Goal

Close the Phase 17 Manager redesign without adding another feature. The gate
proves that the accepted Nexus-style UI, frozen Phase 16 lifecycle contracts and
packaged standalone product continue to work together.

## Live acceptance

The graphical Manager was run in the developer's real Hyprland/Quickshell
session on 2026-08-20. The user explicitly accepted these checkpoints:

- `1A`: sidebar/category navigation, About page, hover styling, motion and
  minimum-size behavior;
- `1B`: WebApp-Info, forward/back/Escape navigation, applet settings and
  installed/uninstalled action presentation;
- `1C`: restored applet activation and capability persistence, uninstall
  confirmation cancel path, add-WebApp wizard and continued input handling;
- keyboard regression check: catalog rows are reachable by Tab/Shift+Tab,
  visibly focused and open with Enter or Space.

Quickshell logs remained clean during and after the live checks. WhatsApp's
pre-test state was verified restored: applet, notifications, badge and preview
were all enabled.

## Automated closing gate

`tests/run_phase17_7_closing_gate.sh` runs:

1. the complete Phase 17.1–17.6 UI gate;
2. the Phase 16.8 end-to-end gate (22 tests);
3. shell syntax validation;
4. the Phase 13 packaging/product gate (17 tests);
5. the Phase 17.7 freeze and keyboard-accessibility assertions.

Lifecycle and packaging tests use disposable HOME/XDG roots. No real WebApp is
installed, repaired or removed by this gate.

## Freeze

Phase 17.1 through 17.7 are accepted and frozen. The accepted Manager baseline
is the Nexus-style sidebar/main-surface UI with embedded workflow pages,
WebApp-Info actions, an About page and full-row keyboard access. Further visual
or functional changes require a reproducible regression or a new explicit
phase. The next product step is release 0.4.0 preparation.
