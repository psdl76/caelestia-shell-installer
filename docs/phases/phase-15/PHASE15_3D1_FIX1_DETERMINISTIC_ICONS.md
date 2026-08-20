# Phase 15.3d.1 Fix 1 — Deterministic per-app bar icon load

Status: candidate / live validation pending.

## Live issue
On the first launch of the isolated feature shell, WhatsApp's notification badge could render while the app icon itself stayed invisible. Restarting Quickshell made the icon appear. The behavior was reproducible.

## Change
`GenericStatusBarEntry.qml` no longer creates a layered `Image` while `iconSource` is still empty. A `Loader` becomes active only after the CLI resolves a concrete icon path. The `MultiEffect` layer is enabled only after `Image.Ready`.

No timer/delay workaround is used. Notification protocol, multi-event popout, theme roles, CLI resolver and Firefox session settings are unchanged.

## Live acceptance gate
1. Start the feature shell from a fresh process.
2. Verify WhatsApp and Google Messages icons are visible on the first launch.
3. Repeat at least three cold Quickshell starts.
4. Verify notification badge and popout still work.
