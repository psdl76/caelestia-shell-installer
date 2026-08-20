# Phase 15.3d.2b — Notification lifecycle

- `status-feed` best-effort autostarts the real notification watcher.
- Watcher is singleton-guarded by an advisory runtime lock + pid file.
- Watches freedesktop `Notify`, method returns and `NotificationClosed`.
- Correlates daemon notification ids through `reply_serial`.
- `replaces_id` replaces old events instead of incrementing the badge.
- `NotificationClosed` removes the exact event and therefore decrements/clears badges.
- No second notification server and no private Caelestia QML service import.
