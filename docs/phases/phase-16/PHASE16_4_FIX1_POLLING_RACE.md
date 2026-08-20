# Phase 16.4 fix1 — polling race guard

Prevents overlapping GenericStatusBarEntry `running-feed` and `status-feed` Process executions while lifecycle actions hold the engine lock. Empty collector output is treated as transient and never parsed as JSON.

No schema, registry, installer, uninstaller, or runtime protocol changes.
