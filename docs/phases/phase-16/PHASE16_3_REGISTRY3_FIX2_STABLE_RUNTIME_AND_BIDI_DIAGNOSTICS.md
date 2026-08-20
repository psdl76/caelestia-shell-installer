# Phase 16.3 registry3-fix2 — Stable Runtime State + BiDi Diagnostics

Status: TEST CANDIDATE

This patch fixes three regressions found during live testing of registry3-fix1:

1. `status-feed <app-id>` now resolves the app through `applet_runtime_entry()` and therefore uses `applet-registry.json`, matching the all-app status feed.
2. `GenericStatusBarEntry.qml` preserves the last confirmed `appRunning` value across transient `running-feed` transport/parse failures. Visibility changes only after a successful feed explicitly reports the app stopped/missing.
3. WebDriver BiDi diagnostics now distinguish `topLevelContexts`, `totalContexts`, and `matchingContexts`, and expose bounded context summaries plus the selected match host. This removes the misleading old `contexts: 0` diagnostic which counted only matching contexts.

No speculative browser workaround is included. If Firefox still returns no matching browsing context, the new diagnostic output is intended to show exactly what Firefox exposed so the next fix can target the real failure mode.

Installer/uninstaller behavior is unchanged.
