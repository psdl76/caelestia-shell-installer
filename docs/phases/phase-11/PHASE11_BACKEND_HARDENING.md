# Phase 11 – backend-hardening-01

## Guarantees

- One global exclusive mutation lock protects all shared WebApps state.
- Catalog/status readers use a shared lock and therefore never observe a half-committed mutation.
- Direct shell entry points (`install.sh`, `repair.sh`, `uninstall.sh`) use the same lock.
- Direct `user_apps.py` mutations use the same lock.
- Nested repair -> install calls inherit the lock token and do not deadlock.
- Lock contention fails predictably with machine-readable `action_busy`.
- CLI actions have a bounded execution time and terminate their whole process group on timeout.
- Timeout is configurable with `CAELESTIA_WEBAPPS_ACTION_TIMEOUT_SECONDS` (default 120s).
- Lock wait is configurable with `CAELESTIA_WEBAPPS_LOCK_TIMEOUT_SECONDS` (default 2s).

The global scope is intentional: different apps still mutate shared catalog, Hyprland config and desktop/icon caches.

## Phase-16 UI boundary recorded

System/device applets and WebApps applets remain separate; messaging WebApps never occupy the Bluetooth/WLAN/Printer system area.
