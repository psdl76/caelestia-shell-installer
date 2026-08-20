# Phase 7 – manager-actions-01

## Goal

Complete the standalone manager action layer through the stable CLI/JSON API.

## Implemented actions

- Launch / focus (`launch`)
- Setup (`setup`)
- Install (`install`)
- Repair (`repair`)
- Uninstall (`uninstall`)

## Rules

1. QML contains no install, repair, uninstall, Firefox, or Hyprland business logic.
2. All mutating actions go through `bin/caelestia-webapps`.
3. The manager uses exactly one reusable action `Process`.
4. Only one mutating/setup action may be active in the manager at a time.
5. `launch` remains detached because it is asynchronous by API contract.
6. Action stdout is parsed as the versioned JSON API envelope.
7. API errors are rendered in the manager instead of inferred from shell text.
8. After an action completes, Catalog v2 is reloaded and transient runtime state is refreshed.
9. Uninstall requires an in-manager confirmation step.
10. Running state remains separate from persistent catalog state.
11. Backend-wide cross-process locking remains a later engine-hardening concern; this phase guarantees manager-side serialization.
